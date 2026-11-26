import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';
import 'package:privy/crypto.dart';
void main(){test('authenticated encryption and context isolation',()async{final k=SecretKey(VaultCrypto.random(32));final box=await VaultCrypto.seal({'title':'test'},k,'vault:test');expect(await VaultCrypto.open(box,k,'vault:test'),{'title':'test'});await expectLater(VaultCrypto.open(box,k,'vault:other'),throwsA(anything));await expectLater(VaultCrypto.open(box,SecretKey(VaultCrypto.random(32)),'vault:test'),throwsA(anything));});}
