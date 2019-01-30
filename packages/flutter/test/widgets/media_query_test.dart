// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('MediaQuery does not have a default', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          tested = true;
          MediaQuery.of(context); // should throw
          return Container();
        }
      )
    );
    expect(tested, isTrue);
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('MediaQuery defaults to null', (WidgetTester tester) async {
    bool tested = false;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          final MediaQueryData data = MediaQuery.of(context, nullOk: true);
          expect(data, isNull);
          tested = true;
          return Container();
        }
      )
    );
    expect(tested, isTrue);
  });

  testWidgets('MediaQueryData is sane', (WidgetTester tester) async {
    final MediaQueryData data = MediaQueryData.fromWindow(ui.window);
    expect(data, hasOneLineDescription);
    expect(data.hashCode, equals(data.copyWith().hashCode));
    expect(data.size, equals(ui.window.physicalSize / ui.window.devicePixelRatio));
    expect(data.accessibleNavigation, false);
    expect(data.invertColors, false);
    expect(data.disableAnimations, false);
    expect(data.boldText, false);
  });

  testWidgets('MediaQueryData.copyWith defaults to source', (WidgetTester tester) async {
    final MediaQueryData data = MediaQueryData.fromWindow(ui.window);
    final MediaQueryData copied = data.copyWith();
    expect(copied.size, data.size);
    expect(copied.devicePixelRatio, data.devicePixelRatio);
    expect(copied.textScaleFactor, data.textScaleFactor);
    expect(copied.padding, data.padding);
    expect(copied.viewInsets, data.viewInsets);
    expect(copied.alwaysUse24HourFormat, data.alwaysUse24HourFormat);
    expect(copied.accessibleNavigation, data.accessibleNavigation);
    expect(copied.invertColors, data.invertColors);
    expect(copied.disableAnimations, data.disableAnimations);
    expect(copied.boldText, data.boldText);
  });

  testWidgets('MediaQuery.copyWith copies specified values', (WidgetTester tester) async {
    final MediaQueryData data = MediaQueryData.fromWindow(ui.window);
    final MediaQueryData copied = data.copyWith(
      size: const Size(3.14, 2.72),
      devicePixelRatio: 1.41,
      textScaleFactor: 1.62,
      padding: const EdgeInsets.all(9.10938),
      viewInsets: const EdgeInsets.all(1.67262),
      alwaysUse24HourFormat: true,
      accessibleNavigation: true,
      invertColors: true,
      disableAnimations: true,
      boldText: true,
    );
    expect(copied.size, const Size(3.14, 2.72));
    expect(copied.devicePixelRatio, 1.41);
    expect(copied.textScaleFactor, 1.62);
    expect(copied.padding, const EdgeInsets.all(9.10938));
    expect(copied.viewInsets, const EdgeInsets.all(1.67262));
    expect(copied.alwaysUse24HourFormat, true);
    expect(copied.accessibleNavigation, true);
    expect(copied.invertColors, true);
    expect(copied.disableAnimations, true);
    expect(copied.boldText, true);
  });

 testWidgets('MediaQuery.removePadding removes specified padding', (WidgetTester tester) async {
   const Size size = Size(2.0, 4.0);
   const double devicePixelRatio = 2.0;
   const double textScaleFactor = 1.2;
   const EdgeInsets padding = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);
   const EdgeInsets viewInsets = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);

   MediaQueryData unpadded;
   await tester.pumpWidget(
     MediaQuery(
       data: const MediaQueryData(
         size: size,
         devicePixelRatio: devicePixelRatio,
         textScaleFactor: textScaleFactor,
         padding: padding,
         viewInsets: viewInsets,
         alwaysUse24HourFormat: true,
         accessibleNavigation: true,
         invertColors: true,
         disableAnimations: true,
         boldText: true,
       ),
       child: Builder(
         builder: (BuildContext context) {
           return MediaQuery.removePadding(
             context: context,
             removeLeft: true,
             removeTop: true,
             removeRight: true,
             removeBottom: true,
             child: Builder(
               builder: (BuildContext context) {
                 unpadded = MediaQuery.of(context);
                 return Container();
               }
             ),
           );
         },
       ),
     )
   );

   expect(unpadded.size, size);
   expect(unpadded.devicePixelRatio, devicePixelRatio);
   expect(unpadded.textScaleFactor, textScaleFactor);
   expect(unpadded.padding, EdgeInsets.zero);
   expect(unpadded.viewInsets, viewInsets);
   expect(unpadded.alwaysUse24HourFormat, true);
   expect(unpadded.accessibleNavigation, true);
   expect(unpadded.invertColors, true);
   expect(unpadded.disableAnimations, true);
   expect(unpadded.boldText, true);
  });

  testWidgets('MediaQuery.removeViewInsets removes specified viewInsets', (WidgetTester tester) async {
    const Size size = Size(2.0, 4.0);
    const double devicePixelRatio = 2.0;
    const double textScaleFactor = 1.2;
    const EdgeInsets padding = EdgeInsets.only(top: 5.0, right: 6.0, left: 7.0, bottom: 8.0);
    const EdgeInsets viewInsets = EdgeInsets.only(top: 1.0, right: 2.0, left: 3.0, bottom: 4.0);

    MediaQueryData unpadded;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: devicePixelRatio,
          textScaleFactor: textScaleFactor,
          padding: padding,
          viewInsets: viewInsets,
          alwaysUse24HourFormat: true,
          accessibleNavigation: true,
          invertColors: true,
          disableAnimations: true,
          boldText: true,
        ),
        child: Builder(
          builder: (BuildContext context) {
            return MediaQuery.removeViewInsets(
              context: context,
              removeLeft: true,
              removeTop: true,
              removeRight: true,
              removeBottom: true,
              child: Builder(
                builder: (BuildContext context) {
                  unpadded = MediaQuery.of(context);
                  return Container();
                }
              ),
            );
          },
        ),
      )
    );

    expect(unpadded.size, size);
    expect(unpadded.devicePixelRatio, devicePixelRatio);
    expect(unpadded.textScaleFactor, textScaleFactor);
    expect(unpadded.padding, padding);
    expect(unpadded.viewInsets, EdgeInsets.zero);
    expect(unpadded.alwaysUse24HourFormat, true);
    expect(unpadded.accessibleNavigation, true);
    expect(unpadded.invertColors, true);
    expect(unpadded.disableAnimations, true);
    expect(unpadded.boldText, true);
  });

 testWidgets('MediaQuery.textScaleFactorOf', (WidgetTester tester) async {
   double outsideTextScaleFactor;
   double insideTextScaleFactor;

   await tester.pumpWidget(
     Builder(
       builder: (BuildContext context) {
         outsideTextScaleFactor = MediaQuery.textScaleFactorOf(context);
         return MediaQuery(
           data: const MediaQueryData(
             textScaleFactor: 4.0,
           ),
           child: Builder(
             builder: (BuildContext context) {
               insideTextScaleFactor = MediaQuery.textScaleFactorOf(context);
               return Container();
             },
           ),
         );
       },
     ),
   );

   expect(outsideTextScaleFactor, 1.0);
   expect(insideTextScaleFactor, 4.0);
 });

  testWidgets('MediaQuery.boldTextOverride', (WidgetTester tester) async {
    bool outsideBoldTextOverride;
    bool insideBoldTextOverride;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          outsideBoldTextOverride = MediaQuery.boldTextOverride(context);
          return MediaQuery(
            data: const MediaQueryData(
              boldText: true,
            ),
            child: Builder(
              builder: (BuildContext context) {
                insideBoldTextOverride = MediaQuery.boldTextOverride(context);
                return Container();
              },
            ),
          );
        },
      ),
    );

    expect(outsideBoldTextOverride, false);
    expect(insideBoldTextOverride, true);
  });
}
