import 'dart:async';

import 'package:process_run/cmd_run.dart';
import 'package:process_run/which.dart';

Future main() async {
  print('flutter: ${await which('flutter')}');
  var flutterBinVersion = await getFlutterBinVersion();
  print('flutterBinVersion: $flutterBinVersion');
}
