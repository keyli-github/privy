import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class VaultCrypto {
  static final _aes = AesGcm.with256bits();
  static List<int> random(int n) => List.generate(n, (_) => Random.secure().nextInt(256));
  static String id() => base64UrlEncode(random(18));
  static Future<SecretKey> derive(String password, String salt) => Argon2id(memory: 65536, parallelism: 2, iterations: 3, hashLength: 32).deriveKeyFromPassword(password: password, nonce: base64Decode(salt));
  static Future<String> seal(Object data, SecretKey key, String context) async {
    final b = await _aes.encrypt(utf8.encode(jsonEncode(data)), secretKey:key, aad:utf8.encode('privy-v1:$context'));
    return base64Encode(b.concatenation());
  }
  static Future<dynamic> open(String encoded, SecretKey key, String context) async {
    final b=SecretBox.fromConcatenation(base64Decode(encoded),nonceLength:12,macLength:16);
    return jsonDecode(utf8.decode(await _aes.decrypt(b,secretKey:key,aad:utf8.encode('privy-v1:$context'))));
  }
}
