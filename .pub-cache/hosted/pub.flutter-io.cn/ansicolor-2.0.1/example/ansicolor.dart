import 'package:ansicolor/ansicolor.dart';

void main() {
  ansiColorDisabled = false;
  print(ansi_demo());
}

/// Due to missing sprintf(), this is my cheap "%03d".
String _toSpace(int i, [int width = 3]) {
  if (width <= 0 && i == 0) return '';
  return '${_toSpace(i ~/ 10, --width)}${i % 10}';
}

/// Return a reference table for foreground and background colors.
String ansi_demo() {
  final sb = StringBuffer();
  final pen = AnsiPen();

  for (var c = 0; c < 16; c++) {
    pen
      ..reset()
      ..white(bold: true)
      ..xterm(c, bg: true);
    sb.write(pen('${_toSpace(c)} '));
    pen
      ..reset()
      ..xterm(c);
    sb.write(pen(' ${_toSpace(c)} '));
    if (c == 7 || c == 15) {
      sb.write('\n');
    }
  }

  for (var r = 0; r < 6; r++) {
    sb.write('\n');
    for (var g = 0; g < 6; g++) {
      for (var b = 0; b < 6; b++) {
        var c = r * 36 + g * 6 + b + 16;
        pen
          ..reset()
          ..rgb(r: r / 5, g: g / 5, b: b / 5, bg: true)
          ..white(bold: true);
        sb.write(pen(' ${_toSpace(c)} '));
        pen
          ..reset()
          ..rgb(r: r / 5, g: g / 5, b: b / 5);
        sb.write(pen(' ${_toSpace(c)} '));
      }
      sb.write('\n');
    }
  }

  for (var c = 0; c < 24; c++) {
    if (0 == c % 8) {
      sb.write('\n');
    }
    pen
      ..reset()
      ..gray(level: c / 23, bg: true)
      ..white(bold: true);
    sb.write(pen(' ${_toSpace(c + 232)} '));
    pen
      ..reset()
      ..gray(level: c / 23);
    sb.write(pen(' ${_toSpace(c + 232)} '));
  }
  return sb.toString();
}
