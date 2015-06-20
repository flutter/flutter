// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' show Color;

/// [Color] constants which represent Material design's
/// [color palette](http://www.google.com/design/spec/style/color.html).

const White = const Color(0xFFFFFFFF);
const Black = const Color(0x00000000);

const Map<int, Color> Red = const {
   50: const Color(0xFFFFEBEE),
  100: const Color(0xFFFFCDD2),
  200: const Color(0xFFEF9A9A),
  300: const Color(0xFFE57373),
  400: const Color(0xFFEF5350),
  500: const Color(0xFFF44336),
  600: const Color(0xFFE53935),
  700: const Color(0xFFD32F2F),
  800: const Color(0xFFC62828),
  900: const Color(0xFFB71C1C),
};

const Map<int, Color> Pink = const {
   50: const Color(0xFFFCE4EC),
  100: const Color(0xFFF8BBD0),
  200: const Color(0xFFF48FB1),
  300: const Color(0xFFF06292),
  400: const Color(0xFFEC407A),
  500: const Color(0xFFE91E63),
  600: const Color(0xFFD81B60),
  700: const Color(0xFFC2185B),
  800: const Color(0xFFAD1457),
  900: const Color(0xFF880E4F),
};

const Map<int, Color> Purple = const {
   50: const Color(0xFFF3E5F5),
  100: const Color(0xFFE1BEE7),
  200: const Color(0xFFCE93D8),
  300: const Color(0xFFBA68C8),
  400: const Color(0xFFAB47BC),
  500: const Color(0xFF9C27B0),
  600: const Color(0xFF8E24AA),
  700: const Color(0xFF7B1FA2),
  800: const Color(0xFF6A1B9A),
  900: const Color(0xFF4A148C),
};

const Map<int, Color> DeepPurple = const {
   50: const Color(0xFFEDE7F6),
  100: const Color(0xFFD1C4E9),
  200: const Color(0xFFB39DDB),
  300: const Color(0xFF9575CD),
  400: const Color(0xFF7E57C2),
  500: const Color(0xFF673AB7),
  600: const Color(0xFF5E35B1),
  700: const Color(0xFF512DA8),
  800: const Color(0xFF4527A0),
  900: const Color(0xFF311B92),
};

const Map<int, Color> Indigo = const {
   50: const Color(0xFFE8EAF6),
  100: const Color(0xFFC5CAE9),
  200: const Color(0xFF9FA8DA),
  300: const Color(0xFF7986CB),
  400: const Color(0xFF5C6BC0),
  500: const Color(0xFF3F51B5),
  600: const Color(0xFF3949AB),
  700: const Color(0xFF303F9F),
  800: const Color(0xFF283593),
  900: const Color(0xFF1A237E),
};

const Map<int, Color> Blue = const {
   50: const Color(0xFFE3F2FD),
  100: const Color(0xFFBBDEFB),
  200: const Color(0xFF90CAF9),
  300: const Color(0xFF64B5F6),
  400: const Color(0xFF42A5F5),
  500: const Color(0xFF2196F3),
  600: const Color(0xFF1E88E5),
  700: const Color(0xFF1976D2),
  800: const Color(0xFF1565C0),
  900: const Color(0xFF0D47A1),
};

const Map<int, Color> LightBlue = const {
   50: const Color(0xFFE1F5FE),
  100: const Color(0xFFB3E5FC),
  200: const Color(0xFF81D4FA),
  300: const Color(0xFF4FC3F7),
  400: const Color(0xFF29B6F6),
  500: const Color(0xFF03A9F4),
  600: const Color(0xFF039BE5),
  700: const Color(0xFF0288D1),
  800: const Color(0xFF0277BD),
  900: const Color(0xFF01579B),
};

const Map<int, Color> Cyan = const {
   50: const Color(0xFFE0F7FA),
  100: const Color(0xFFB2EBF2),
  200: const Color(0xFF80DEEA),
  300: const Color(0xFF4DD0E1),
  400: const Color(0xFF26C6DA),
  500: const Color(0xFF00BCD4),
  600: const Color(0xFF00ACC1),
  700: const Color(0xFF0097A7),
  800: const Color(0xFF00838F),
  900: const Color(0xFF006064),
};

const Map<int, Color> Teal = const {
   50: const Color(0xFFE0F2F1),
  100: const Color(0xFFB2DFDB),
  200: const Color(0xFF80CBC4),
  300: const Color(0xFF4DB6AC),
  400: const Color(0xFF26A69A),
  500: const Color(0xFF009688),
  600: const Color(0xFF00897B),
  700: const Color(0xFF00796B),
  800: const Color(0xFF00695C),
  900: const Color(0xFF004D40),
};

const Map<int, Color> Green = const {
   50: const Color(0xFFE8F5E9),
  100: const Color(0xFFC8E6C9),
  200: const Color(0xFFA5D6A7),
  300: const Color(0xFF81C784),
  400: const Color(0xFF66BB6A),
  500: const Color(0xFF4CAF50),
  600: const Color(0xFF43A047),
  700: const Color(0xFF388E3C),
  800: const Color(0xFF2E7D32),
  900: const Color(0xFF1B5E20),
};

const Map<int, Color> LightGreen = const {
   50: const Color(0xFFF1F8E9),
  100: const Color(0xFFDCEDC8),
  200: const Color(0xFFC5E1A5),
  300: const Color(0xFFAED581),
  400: const Color(0xFF9CCC65),
  500: const Color(0xFF8BC34A),
  600: const Color(0xFF7CB342),
  700: const Color(0xFF689F38),
  800: const Color(0xFF558B2F),
  900: const Color(0xFF33691E),
};

const Map<int, Color> Lime = const {
   50: const Color(0xFFF9FBE7),
  100: const Color(0xFFF0F4C3),
  200: const Color(0xFFE6EE9C),
  300: const Color(0xFFDCE775),
  400: const Color(0xFFD4E157),
  500: const Color(0xFFCDDC39),
  600: const Color(0xFFC0CA33),
  700: const Color(0xFFAFB42B),
  800: const Color(0xFF9E9D24),
  900: const Color(0xFF827717),
};

const Map<int, Color> Yellow = const {
   50: const Color(0xFFFFFDE7),
  100: const Color(0xFFFFF9C4),
  200: const Color(0xFFFFF59D),
  300: const Color(0xFFFFF176),
  400: const Color(0xFFFFEE58),
  500: const Color(0xFFFFEB3B),
  600: const Color(0xFFFDD835),
  700: const Color(0xFFFBC02D),
  800: const Color(0xFFF9A825),
  900: const Color(0xFFF57F17),
};

const Map<int, Color> Amber = const {
   50: const Color(0xFFFFF8E1),
  100: const Color(0xFFFFECB3),
  200: const Color(0xFFFFE082),
  300: const Color(0xFFFFD54F),
  400: const Color(0xFFFFCA28),
  500: const Color(0xFFFFC107),
  600: const Color(0xFFFFB300),
  700: const Color(0xFFFFA000),
  800: const Color(0xFFFF8F00),
  900: const Color(0xFFFF6F00),
};

const Map<int, Color> Orange = const {
   50: const Color(0xFFFFF3E0),
  100: const Color(0xFFFFE0B2),
  200: const Color(0xFFFFCC80),
  300: const Color(0xFFFFB74D),
  400: const Color(0xFFFFA726),
  500: const Color(0xFFFF9800),
  600: const Color(0xFFFB8C00),
  700: const Color(0xFFF57C00),
  800: const Color(0xFFEF6C00),
  900: const Color(0xFFE65100),
};

const Map<int, Color> DeepOrange = const {
   50: const Color(0xFFFBE9E7),
  100: const Color(0xFFFFCCBC),
  200: const Color(0xFFFFAB91),
  300: const Color(0xFFFF8A65),
  400: const Color(0xFFFF7043),
  500: const Color(0xFFFF5722),
  600: const Color(0xFFF4511E),
  700: const Color(0xFFE64A19),
  800: const Color(0xFFD84315),
  900: const Color(0xFFBF360C),
};

const Map<int, Color> Brown = const {
   50: const Color(0xFFEFEBE9),
  100: const Color(0xFFD7CCC8),
  200: const Color(0xFFBCAAA4),
  300: const Color(0xFFA1887F),
  400: const Color(0xFF8D6E63),
  500: const Color(0xFF795548),
  600: const Color(0xFF6D4C41),
  700: const Color(0xFF5D4037),
  800: const Color(0xFF4E342E),
  900: const Color(0xFF3E2723),
};

const Map<int, Color> Grey = const {
   50: const Color(0xFFFAFAFA),
  100: const Color(0xFFF5F5F5),
  200: const Color(0xFFEEEEEE),
  300: const Color(0xFFE0E0E0),
  350: const Color(0xFFD6D6D6), // only for raised button while pressed or disabled
  400: const Color(0xFFBDBDBD),
  500: const Color(0xFF9E9E9E),
  600: const Color(0xFF757575),
  700: const Color(0xFF616161),
  800: const Color(0xFF424242),
  900: const Color(0xFF212121),
};

const Map<int, Color> BlueGrey = const {
   50: const Color(0xFFECEFF1),
  100: const Color(0xFFCFD8DC),
  200: const Color(0xFFB0BEC5),
  300: const Color(0xFF90A4AE),
  400: const Color(0xFF78909C),
  500: const Color(0xFF607D8B),
  600: const Color(0xFF546E7A),
  700: const Color(0xFF455A64),
  800: const Color(0xFF37474F),
  900: const Color(0xFF263238),
};
