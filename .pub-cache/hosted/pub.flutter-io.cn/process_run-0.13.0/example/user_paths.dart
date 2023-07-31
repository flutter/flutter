import 'dart:async';
import 'dart:io';

import 'package:process_run/src/user_config.dart';

Future main() async {
  var userPaths = getUserPaths(Platform.environment);
  for (var path in userPaths) {
    print(path);
  }
}
