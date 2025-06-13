import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoService {
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}