import 'dart:async';

import 'package:process_run/src/user_config.dart';

Future main() async {
  var userPaths = getUserPaths(<String, String>{});
  for (var path in userPaths) {
    print(path);
  }
}
