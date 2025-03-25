import 'asset.dart' show FlutterHookResult;
import 'build_info.dart' show TargetPlatform;
import 'build_system/build_system.dart' show Environment;

abstract class DartBuilder {
  DartBuilder();

  FlutterHookResult? dartDataHookResult;

  Future<FlutterHookResult> runHooks({
    required TargetPlatform targetPlatform,
    required Environment environment,
  });
}
