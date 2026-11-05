import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'credential_vault.dart';
import 'webdav_client.dart';

final credentialVaultProvider = Provider<CredentialVault>(
  (ref) => DeviceCredentialVault(),
);

final cloudProbeProvider = Provider<CloudProbe>(
  (ref) => CloudWebDav(),
);
