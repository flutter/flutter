import 'dart:io' as io;

import 'package:sqflite_common/src/platform/platform.dart';

class _PlatformIo extends Platform {
  @override
  bool get isWindows => io.Platform.isWindows;

  @override
  bool get isIOS => io.Platform.isIOS;

  @override
  bool get isAndroid => io.Platform.isAndroid;

  @override
  bool get isLinux => io.Platform.isLinux;

  @override
  bool get isMacOS => io.Platform.isMacOS;
}

/// Platform (IO)
final platform = _PlatformIo();
