import 'package:flutter_launcher_icons/constants.dart';
import 'package:flutter_launcher_icons/main.dart' as flutter_launcher_icons;
import 'package:flutter_launcher_icons/src/version.dart';

void main(List<String> arguments) {
  print(introMessage(packageVersion));
  flutter_launcher_icons.createIconsFromArguments(arguments);
}
