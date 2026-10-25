// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  final Object delegate = GlobalMaterialLocalizations.delegate;
  final Object delegates = GlobalMaterialLocalizations.delegates;
  final Set<String> languages = kMaterialSupportedLanguages;
  final Object translationFn = getMaterialTranslation;
  const Type afType = MaterialLocalizationAf;
  const Type enType = MaterialLocalizationEn;
  const Type zhHantTwType = MaterialLocalizationZhHantTw;
  print(
    '$delegate $delegates $languages $translationFn $afType $enType $zhHantTwType',
  );
}
