// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test Responsiveness', (WidgetTester tester) async {
    // Declare Sizes
    const Size designSize = Size(360, 640);
    const Size initialSize = designSize;
    const Size biggerSize = Size(480, 920);
    const Size smallerSize = Size(300, 560);

    // We'll use MediaQuery to simulate diffrent screen sizes
    MediaQueryData currentData = MediaQueryData(size: initialSize);
    const MediaQueryData biggerData = MediaQueryData(size: biggerSize);
    const MediaQueryData smallerData = MediaQueryData(size: smallerSize);

    // Used to find a widget. See [CommonFinders.byKey].
    final _key = UniqueKey();

    // Click on button. See code bellow.
    Future<int> tap() async {
      await tester.tap(find.byKey(_key));
      return tester.pumpAndSettle();
    }

    void testSize(Size size) {
      expect(1.w, equals(size.width / designSize.width));
      expect(1.h, equals(size.height / designSize.height));
      print('[OK] Size: $size, width: ${1.w}, height: ${1.h}');
    }

    await tester.pumpWidget(StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return MediaQuery(
          data: currentData,
          child: ScreenUtilInit(
            useInheritedMediaQuery: true,
            designSize: designSize,
            builder: (context, child) => MaterialApp(
              home: Material(
                child: TextButton(
                  key: _key,
                  child: Text('Change data'),
                  onPressed: () {
                    setState(() {
                      currentData = currentData.size == initialSize
                          // First test with bigger screen
                          ? biggerData
                          // Test with smaller screen
                          : smallerData;
                    });
                  },
                ),
              ),
            ),
          ),
        );
      },
    ));

    // Tests with initial screen size
    testSize(initialSize);

    // Click On button to simulate changing screen size
    await tap();
    // Tests with bigger screen size
    testSize(biggerSize);

    // Click On button to simulate changing screen size
    await tap();
    // Tests with bigger screen size
    testSize(smallerSize);

    await tester.pumpAndSettle();
  });
}
