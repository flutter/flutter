// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  final Object delegate = GlobalCupertinoLocalizations.delegate;
  final Object delegates = GlobalCupertinoLocalizations.delegates;
  final Set<String> languages = kCupertinoSupportedLanguages;
  final Object translationFn = getCupertinoTranslation;
  const Type afType = CupertinoLocalizationAf;
  const Type enType = CupertinoLocalizationEn;
  const Type zhHantTwType = CupertinoLocalizationZhHantTw;
  print(
    '$delegate $delegates $languages $translationFn $afType $enType $zhHantTwType',
  );
}
