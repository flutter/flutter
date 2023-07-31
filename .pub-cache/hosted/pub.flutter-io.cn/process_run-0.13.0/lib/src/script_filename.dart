import 'dart:io';

/// 'flutter' => 'flutter.bat' (windows) or 'flutter'
String getBashOrBatExecutableFilename(String command) {
  return Platform.isWindows ? '$command.bat' : command;
}

/// 'firebase' => 'firebase.cmd' (windows) or firebase'
String getBashOrCmdExecutableFilename(String command) {
  return Platform.isWindows ? '$command.cmd' : command;
}

/// 'dart' => 'dart.exe' (windows) or dart'
String getBashOrExeExecutableFilename(String command) {
  return Platform.isWindows ? '$command.exe' : command;
}
