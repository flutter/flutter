import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_swiper/flutter_swiper.dart';

void main() {
  testWidgets('Default Swiper', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
        home: Swiper(
            itemBuilder: (context, index) {
              return Text("0");
            },
            itemCount: 10)));

    expect(find.text("0", skipOffstage: false), findsOneWidget);
  });

  testWidgets('Default Swiper loop:false', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
        home: Swiper(
      onTap: (int inde) {},
      itemBuilder: (context, index) {
        return Text("0");
      },
      itemCount: 10,
      loop: false,
    )));

    expect(find.text("0", skipOffstage: true), findsOneWidget);
  });

  testWidgets('Create Swiper with children', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
        home: Swiper.children(
      children: <Widget>[Text("0"), Text("1")],
    )));

    expect(find.text("0", skipOffstage: false), findsOneWidget);
  });

  testWidgets('Create Swiper with list', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
        home: Swiper.list(
      list: ["0", "1"],
      builder: (BuildContext context, dynamic data, int index) {
        return Text(data);
      },
    )));

    expect(find.text("0", skipOffstage: false), findsOneWidget);
  });

  testWidgets('Swiper with default plugins', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    SwiperController controller = SwiperController();
    await tester.pumpWidget(MaterialApp(
        home: Swiper(
      controller: controller,
      itemBuilder: (context, index) {
        return Text("0");
      },
      itemCount: 10,
      pagination: SwiperPagination(),
      control: SwiperControl(),
    )));

    expect(find.text("0", skipOffstage: false), findsOneWidget);
  });

  const List<String> titles = [
    "Flutter Swiper is awosome",
    "Really nice",
    "Yeap"
  ];

  testWidgets('Customize pagination', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    SwiperController controller = SwiperController();
    await tester.pumpWidget(MaterialApp(
        home: Swiper(
      controller: controller,
      itemBuilder: (context, index) {
        return Text("0");
      },
      itemCount: 10,
      pagination: SwiperCustomPagination(
          builder: (BuildContext context, SwiperPluginConfig config) {
        return ConstrainedBox(
          child: Row(
            children: <Widget>[
              Text(
                "${titles[config.activeIndex]} ${config.activeIndex + 1}/${config.itemCount}",
                style: TextStyle(fontSize: 20.0),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: DotSwiperPaginationBuilder(
                          color: Colors.black12,
                          activeColor: Colors.black,
                          size: 10.0,
                          activeSize: 20.0)
                      .build(context, config),
                ),
              )
            ],
          ),
          constraints: BoxConstraints.expand(height: 50.0),
        );
      }),
      control: SwiperControl(),
    )));

    controller.startAutoplay();

    controller.stopAutoplay();

    await controller.move(0, animation: false);
    await controller.move(0, animation: false);

    await controller.next(animation: false);
    await controller.previous(animation: false);

    expect(find.text("0", skipOffstage: false), findsOneWidget);
  });

  testWidgets('Swiper fraction', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    SwiperController controller = SwiperController();
    await tester.pumpWidget(MaterialApp(
        home: Swiper(
      controller: controller,
      itemBuilder: (context, index) {
        return Text("0");
      },
      itemCount: 10,
      pagination: SwiperPagination(builder: SwiperPagination.fraction),
      control: SwiperControl(),
    )));

    expect(find.text("0", skipOffstage: false), findsOneWidget);
  });

  testWidgets('Zero itemCount', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    SwiperController controller = SwiperController();
    await tester.pumpWidget(MaterialApp(
        home: Swiper(
      controller: controller,
      itemBuilder: (context, index) {
        return Text("0");
      },
      itemCount: 0,
      pagination: SwiperPagination(builder: SwiperPagination.fraction),
      control: SwiperControl(),
    )));

    expect(find.text("0", skipOffstage: false), findsNothing);
  });
}
