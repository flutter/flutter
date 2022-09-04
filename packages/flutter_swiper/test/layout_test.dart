import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_swiper/flutter_swiper.dart';

void main() {
  testWidgets('STACK', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Swiper(
            layout: SwiperLayout.STACK,
            itemWidth: 300.0,
            itemHeight: 200.0,
            itemBuilder: (context, index) {
              return new Container(
                color: Colors.grey,
                child: new Center(
                  child: new Text("$index"),
                ),
              );
            },
            itemCount: 10)));
  });

  testWidgets('TINDER', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Swiper(
            layout: SwiperLayout.TINDER,
            itemWidth: 300.0,
            itemHeight: 200.0,
            itemBuilder: (context, index) {
              return new Container(
                color: Colors.grey,
                child: new Center(
                  child: new Text("$index"),
                ),
              );
            },
            itemCount: 10)));
  });

  testWidgets('DEFAULT', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Swiper(
            layout: SwiperLayout.DEFAULT,
            viewportFraction: 0.8,
            scale: 0.9,
            itemBuilder: (context, index) {
              return new Container(
                color: Colors.grey,
                child: new Center(
                  child: new Text("$index"),
                ),
              );
            },
            itemCount: 10)));
  });

  testWidgets('CUSTOM', (WidgetTester tester) async {
    CustomLayoutOption customLayoutOption;
    customLayoutOption = new CustomLayoutOption(startIndex: -1, stateCount: 3)
        .addRotate([-45.0 / 180, 0.0, 45.0 / 180]).addTranslate([
      new Offset(-370.0, -40.0),
      new Offset(0.0, 0.0),
      new Offset(370.0, -40.0)
    ]);
    await tester.pumpWidget(MaterialApp(
        home: Swiper(
            layout: SwiperLayout.CUSTOM,
            itemWidth: 300.0,
            itemHeight: 200.0,
            customLayoutOption: customLayoutOption,
            itemBuilder: (context, index) {
              return new Container(
                color: Colors.grey,
                child: new Center(
                  child: new Text("$index"),
                ),
              );
            },
            itemCount: 10)));
  });
}
