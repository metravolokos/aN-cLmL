import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'webdav_client.dart';

abstract interface class CredentialVault {
  Future<CloudCredentials?> read();
  Future<void> save(CloudCredentials credentials);
  Future<void> clear();
}

/// Protected encrypted storage on Android and Windows.
class DeviceCredentialVault implements CredentialVault {
  DeviceCredentialVault({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _userKey = 'cloudmail_account';
  static const _passwordKey = 'cloudmail_app_password';

  @override
  Future<CloudCredentials?> read() async {
    final user = await _storage.read(key: _userKey);
    final password = await _storage.read(key: _passwordKey);
    if (user == null || user.isEmpty || password == null || password.isEmpty) {
      return null;
    }
    return CloudCredentials(user, password);
  }

  @override
  Future<void> save(CloudCredentials credentials) async {
    await _storage.write(key: _userKey, value: credentials.username);
    await _storage.write(key: _passwordKey, value: credentials.password);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _userKey);
  }
}
