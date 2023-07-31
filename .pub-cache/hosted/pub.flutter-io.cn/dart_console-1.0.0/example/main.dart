import 'package:dart_console/dart_console.dart';

void main() {
  final console = Console();
  console.setBackgroundColor(ConsoleColor.blue);
  console.setForegroundColor(ConsoleColor.white);
  console.writeLine('Simple Demo', TextAlignment.center);
  console.resetColorAttributes();

  console.writeLine();

  console.writeLine('This console window has ${console.windowWidth} cols and '
      '${console.windowHeight} rows.');
  console.writeLine();

  console.writeLine('This text is left aligned.', TextAlignment.left);
  console.writeLine('This text is center aligned.', TextAlignment.center);
  console.writeLine('This text is right aligned.', TextAlignment.right);

  for (final color in ConsoleColor.values) {
    console.setForegroundColor(color);
    console.writeLine(color.toString().split('.').last);
  }
  console.resetColorAttributes();
}
