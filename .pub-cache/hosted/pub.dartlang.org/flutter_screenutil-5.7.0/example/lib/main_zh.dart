import 'package:flutter/widgets.dart';
import 'src_zh/first_method.dart' as firstMethod;
import 'src_zh/second_method.dart' as secondMethod;

void main() {
  const method = int.fromEnvironment('method', defaultValue: 1);

  runApp(method == 1 ? firstMethod.MyApp() : secondMethod.MyApp());
}
