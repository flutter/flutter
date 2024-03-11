import 'dart:io';
import 'package:path/path.dart' as path;

import '../../../dev/bots/custom_rules/analyze.dart';
import '../../../dev/bots/utils.dart';

Future<void> main() async {
  await analyzeToolWithRules(path.join(Directory.current.path, '..', '..'));
  print('${reset}done');
}
