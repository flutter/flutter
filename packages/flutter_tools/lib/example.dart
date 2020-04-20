

import 'dart:io';

void main() {
  print(File(r'C:\Users\Jonah\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.ttf')
    .readAsBytesSync().sublist(0, 12));
}