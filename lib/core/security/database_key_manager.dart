import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:task_flow/core/error/exceptions.dart';

/// Cryptographic Key Management Service for SQLCipher AES-256 Encryption at Rest.
///
/// Ensures deterministic retrieval and generation of a 256-bit cryptographically
/// strong encryption key using hardware-backed secure storage (Android KeyStore / iOS Keychain).
class DatabaseKeyManager {
  static const String keyStorageAlias = 'task_flow_db_encryption_key_v1';

  final FlutterSecureStorage _secureStorage;

  const DatabaseKeyManager({
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  }) : _secureStorage = secureStorage;

  /// Retrieves the existing 256-bit encryption key or generates, persists,
  /// and returns a new cryptographically secure Base64-encoded key.
  Future<String> getOrCreateEncryptionKey() async {
    try {
      final existingKey = await _secureStorage.read(key: keyStorageAlias);
      if (existingKey != null && existingKey.trim().isNotEmpty) {
        return existingKey;
      }

      // Generate 256 bits (32 bytes) of cryptographic entropy
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final newKey = base64UrlEncode(keyBytes);

      await _secureStorage.write(
        key: keyStorageAlias,
        value: newKey,
      );

      return newKey;
    } catch (error) {
      throw LocalDatabaseException(
        message: 'Failed to access or generate database encryption key in secure storage.',
        cause: error,
      );
    }
  }

  /// Deletes the encryption key from hardware storage (used for factory reset / data wipe).
  Future<void> clearEncryptionKey() async {
    try {
      await _secureStorage.delete(key: keyStorageAlias);
    } catch (error) {
      throw LocalDatabaseException(
        message: 'Failed to clear database encryption key from secure storage.',
        cause: error,
      );
    }
  }
}
