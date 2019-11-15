import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/tasks/integration_tests.dart';

Future<void> main() async {
  await task(createFlutterCreateOfflineTest());
}
