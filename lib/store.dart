import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'crypto.dart';

typedef Obj = Map<String,dynamic>;
class VaultStore {
  final SupabaseClient api;
  VaultStore(this.api): uid=api.auth.currentUser!.id;
  final String uid;
  Obj? row;
  SecretKey? key;
  List<dynamic> folders=[];
  String get bioName => 'privy_$uid';
  Future<void> load() async { row=await api.from('privy_vaults').select().eq('owner',uid).maybeSingle(); }
  Future<void> create(String password) async {
    final salt=base64Encode(VaultCrypto.random(24));
    final k=SecretKey(VaultCrypto.random(32));
    final wrapped=await VaultCrypto.seal(base64Encode(await k.extractBytes()),await VaultCrypto.derive(password,salt),'key:$uid');
    final payload=await VaultCrypto.seal([],k,'vault:$uid');
    final r=await api.from('privy_vaults').insert({'owner':uid,'salt':salt,'wrapped_key':wrapped,'payload':payload}).select().single();
    row=r; key=k; folders=[];
  }
  Future<void> unlock(String password) async {
    final r=row!;
    final raw=await VaultCrypto.open(r['wrapped_key'],await VaultCrypto.derive(password,r['salt']),'key:$uid');
    await unlockKey(SecretKey(base64Decode(raw as String)));
  }
  Future<void> unlockKey(SecretKey k) async {
    final data=await VaultCrypto.open(row!['payload'],k,'vault:$uid');
    folders=List<dynamic>.from(data as List); key=k;
  }
  Future<bool> bioEnabled() async => (await SharedPreferences.getInstance()).getBool(bioName)??false;
  Future<void> enableBio() async {
    if(await BiometricStorage().canAuthenticate()!=CanAuthenticateResponse.success) {throw StateError('Biometría no disponible');}
    final storage=await BiometricStorage().getStorage(bioName,options:StorageFileInitOptions(authenticationRequired:true));
    await storage.write(base64Encode(await key!.extractBytes()));
    await (await SharedPreferences.getInstance()).setBool(bioName,true);
  }
  Future<void> disableBio() async {
    final storage=await BiometricStorage().getStorage(bioName,options:StorageFileInitOptions(authenticationRequired:true));
    await storage.delete();
    await (await SharedPreferences.getInstance()).remove(bioName);
  }
  Future<void> biometric() async {
    if(!await bioEnabled()) throw StateError('Activa la biometría primero');
    final storage=await BiometricStorage().getStorage(bioName,options:StorageFileInitOptions(authenticationRequired:true));
    final raw=await storage.read(); if(raw==null) throw StateError('Sin clave biométrica');
    await unlockKey(SecretKey(base64Decode(raw)));
  }
  void lock(){key=null;folders=[];}
  Future<void> save(List<dynamic> next) async {
    final r=row!; final k=key!; final rev=r['revision'] as int;
    final payload=await VaultCrypto.seal(next,k,'vault:$uid');
    final result=await api.from('privy_vaults').update({'payload':payload,'revision':rev+1}).eq('owner',uid).eq('revision',rev).select().maybeSingle();
    if(result==null) throw StateError('Conflicto de sincronización. Bloquea y vuelve a abrir para cargar los cambios.');
    row=result; if(key==k) folders=next;
  }
  List<dynamic> copy() => jsonDecode(jsonEncode(folders)) as List<dynamic>;
  static Future<Obj> folder(String name,String description,String password) async {
    final id=VaultCrypto.id();
    final f=<String,dynamic>{'id':id,'name':name,'description':description,'protected':password.isNotEmpty};
    if(password.isEmpty){f['items']=[];} else { final salt=base64Encode(VaultCrypto.random(24)); f['salt']=salt; f['box']=await VaultCrypto.seal([],await VaultCrypto.derive(password,salt),'folder:$id'); }
    return f;
  }
}
