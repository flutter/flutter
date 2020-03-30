// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'stock_strings.dart';

// ignore_for_file: unnecessary_brace_in_string_interps

/// The translations for Spanish Castilian (`es`).
class StockStringsEs extends StockStrings {
  StockStringsEs([String locale = 'es']) : super(locale);

  @override
  String get title => 'Acciones';

  @override
  String get market => 'MERCADO';

  @override
  String get portfolio => 'CARTERA';
}
