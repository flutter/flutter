// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// جميع الحقوق محفوظة لمطوري Flutter لعام 2014.
// يخضع استخدام هذا الكود لرخصة من نوع BSD ويمكن العثور عليها في ملف LICENSE.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/arabic.dart' as hello_world;

void main() {
  testWidgets('اختبار مرحبا بالعالم', (WidgetTester tester) async {
    hello_world.main(); // تشغيل التطبيق
    await tester.pump(); // انتظار بناء واجهة المستخدم

    expect(
      find.byKey(const Key('title')), // البحث عن العنصر باستخدام المفتاح
      findsOneWidget, // ينجح الاختبار إذا تم العثور على عنصر واحد
    );

  });
}