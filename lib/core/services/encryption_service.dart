import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class EncryptionService {
  static final EncryptionService instance = EncryptionService._internal();
  EncryptionService._internal();

  enc.Key? _key;

  final _random = Random.secure();

  bool get isInitialized => _key != null;

  /// Initialize the encryption key using the stored PIN
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(AppConstants.userPinKey) ?? '';
    if (pin.isEmpty) {
      throw Exception('PIN not set.');
    }
    _deriveKey(pin);
  }

  /// Initialize directly from pin entered by user
  void initializeFromPin(String pin) {
    _deriveKey(pin);
  }

  void _deriveKey(String pin) {
    final hash = sha256.convert(utf8.encode(pin));
    final keyBytes = Uint8List.fromList(hash.bytes);
    _key = enc.Key(keyBytes);
  }

  /// Encrypt plain text and return base64 of IV + ciphertext
  String encrypt(String plainText) {
    if (_key == null) {
      throw Exception('EncryptionService not initialized');
    }
    // Generate random IV (16 bytes)
    final ivBytes = Uint8List(16);
    for (int i = 0; i < ivBytes.length; i++) {
      ivBytes[i] = _random.nextInt(256);
    }
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Store iv + cipher together
    final combined = ivBytes + encrypted.bytes;
    return base64Encode(combined);
  }

  /// Decrypt base64 encoded IV + ciphertext
  String decrypt(String base64Cipher) {
    if (_key == null) {
      throw Exception('EncryptionService not initialized');
    }
    final combined = base64Decode(base64Cipher);
    if (combined.length < 16) {
      throw Exception('Invalid cipher text');
    }
    final ivBytes = combined.sublist(0, 16);
    final cipherBytes = combined.sublist(16);
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
    final enc.Encrypted encrypted = enc.Encrypted(Uint8List.fromList(cipherBytes));
    return encrypter.decrypt(encrypted, iv: iv);
  }
} 