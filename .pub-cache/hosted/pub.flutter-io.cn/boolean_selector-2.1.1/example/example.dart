import 'package:boolean_selector/boolean_selector.dart';

void main(List<String> args) {
  var selector = BooleanSelector.parse('(x && y) || z');
  print(selector.evaluate((variable) => args.contains(variable)));
}
