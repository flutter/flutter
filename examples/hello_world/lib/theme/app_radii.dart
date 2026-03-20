import 'package:flutter/widgets.dart';

class AppRadii {
  const AppRadii._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius input = BorderRadius.all(Radius.circular(md));
  static const BorderRadius button = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius full = BorderRadius.all(Radius.circular(pill));
}
