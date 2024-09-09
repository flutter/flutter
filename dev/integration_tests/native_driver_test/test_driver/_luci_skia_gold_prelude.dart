import 'dart:io' as io;

/// Whether the current environment is LUCI.
bool get isLuci => io.Platform.environment['LUCI_CI'] == 'True';
