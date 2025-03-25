import 'asset.dart' show DartDataHookResult;
import 'build_info.dart' show TargetPlatform;
import 'build_system/build_system.dart' show Environment;

abstract class DartBuilder {
  DartBuilder();

  DartDataHookResult? dartDataHookResult;

  Future<DartDataHookResult> runDartBuild({
    required TargetPlatform targetPlatform,
    required Environment environment,
  });
}
