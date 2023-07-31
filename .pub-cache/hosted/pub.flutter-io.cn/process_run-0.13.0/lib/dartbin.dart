/// Prefer using shell.
///
/// {@canonicalFor flutterbin_cmd.getFlutterBinChannel}
/// {@canonicalFor flutterbin_cmd.getFlutterBinVersion}
/// {@canonicalFor flutterbin_cmd.isFlutterSupported}
/// {@canonicalFor flutterbin_cmd.isFlutterSupportedSync}
/// {@canonicalFor dartbin.dartChannel}
/// {@canonicalFor dartbin.dartExecutable}
/// {@canonicalFor dartbin.dartVersion}
library process_run.dartbin;

export 'package:process_run/src/flutterbin_cmd.dart'
    show
        getFlutterBinVersion,
        getFlutterBinChannel,
        isFlutterSupported,
        isFlutterSupportedSync;

export 'src/common/dartbin.dart';
