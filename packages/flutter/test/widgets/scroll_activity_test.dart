// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

List<Widget> children(int n) {
  return List<Widget>.generate(n, (int i) {
    return SizedBox(height: 100.0, child: Text('$i'));
  });
}

void main() {
  testWidgets('Scrolling with list view changes, leaving the overscroll', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(MaterialApp(home: ListView(controller: controller, children: children(30))));
    final double thirty = controller.position.maxScrollExtent;
    controller.jumpTo(thirty);
    await tester.pump();
    controller.jumpTo(thirty + 100.0); // past the end
    await tester.pump();
    await tester.pumpWidget(MaterialApp(home: ListView(controller: controller, children: children(31))));
    expect(controller.position.pixels, thirty + 100.0); // has the same position, but no longer overscrolled
    expect(await tester.pumpAndSettle(), 1); // doesn't have ballistic animation...
    expect(controller.position.pixels, thirty + 100.0); // and ends up at the end
  });

  testWidgets('Scrolling with list view changes, remaining overscrolled', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(MaterialApp(home: ListView(controller: controller, children: children(30))));
    final double thirty = controller.position.maxScrollExtent;
    controller.jumpTo(thirty);
    await tester.pump();
    controller.jumpTo(thirty + 200.0); // past the end
    await tester.pump();
    await tester.pumpWidget(MaterialApp(home: ListView(controller: controller, children: children(31))));
    expect(controller.position.pixels, thirty + 200.0); // has the same position, still overscrolled
    expect(await tester.pumpAndSettle(), 8); // now it goes ballistic...
    expect(controller.position.pixels, thirty + 100.0); // and ends up at the end
  });

  testWidgets('Ability to keep a PageView at the end manually (issue 62209)', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PageView62209()));
    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 100'), findsNothing);
    await tester.drag(find.byType(PageView62209), const Offset(-800.0, 0.0));
    await tester.pump();
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 100'), findsNothing);
    await tester.drag(find.byType(PageView62209), const Offset(-800.0, 0.0));
    await tester.pump();
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 3'), findsOneWidget);
    expect(find.text('Page 100'), findsNothing);
    await tester.drag(find.byType(PageView62209), const Offset(-800.0, 0.0));
    await tester.pump();
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 4'), findsOneWidget);
    expect(find.text('Page 100'), findsNothing);
    await tester.drag(find.byType(PageView62209), const Offset(-800.0, 0.0));
    await tester.pump();
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 5'), findsOneWidget);
    expect(find.text('Page 100'), findsNothing);
    await tester.drag(find.byType(PageView62209), const Offset(-800.0, 0.0));
    await tester.pump();
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 5'), findsNothing);
    expect(find.text('Page 100'), findsOneWidget);
    await tester.tap(find.byType(TextButton)); // 6
    await tester.pump();
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 6'), findsNothing);
    expect(find.text('Page 5'), findsNothing);
    expect(find.text('Page 100'), findsOneWidget);
    await tester.tap(find.byType(TextButton)); // 7
    await tester.pump();
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 6'), findsNothing);
    expect(find.text('Page 7'), findsNothing);
    expect(find.text('Page 5'), findsNothing);
    expect(find.text('Page 100'), findsOneWidget);
    await tester.drag(find.byType(PageView62209), const Offset(800.0, 0.0));
    await tester.pump();
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 5'), findsOneWidget);
    expect(find.text('Page 100'), findsNothing);
    await tester.drag(find.byType(PageView62209), const Offset(800.0, 0.0));
    await tester.pump();
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 4'), findsOneWidget);
    expect(find.text('Page 5'), findsNothing);
    expect(find.text('Page 100'), findsNothing);
    await tester.tap(find.byType(TextButton)); // 8
    await tester.pump();
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 8'), findsNothing);
    expect(find.text('Page 4'), findsOneWidget);
    expect(find.text('Page 5'), findsNothing);
    expect(find.text('Page 100'), findsNothing);
    await tester.drag(find.byType(PageView62209), const Offset(800.0, 0.0));
    await tester.pump();
    expect(find.text('Page 3'), findsOneWidget);
    await tester.drag(find.byType(PageView62209), const Offset(800.0, 0.0));
    await tester.pump();
    expect(find.text('Page 2'), findsOneWidget);
    await tester.drag(find.byType(PageView62209), const Offset(800.0, 0.0));
    await tester.pump();
    expect(find.text('Page 6'), findsOneWidget);
    await tester.drag(find.byType(PageView62209), const Offset(800.0, 0.0));
    await tester.pump();
    expect(find.text('Page 7'), findsOneWidget);
    await tester.drag(find.byType(PageView62209), const Offset(800.0, 0.0));
    await tester.pump();
    expect(find.text('Page 8'), findsOneWidget);
    await tester.drag(find.byType(PageView62209), const Offset(800.0, 0.0));
    await tester.pump();
    expect(find.text('Page 1'), findsOneWidget);
    await tester.tap(find.byType(TextButton)); // 9
    await tester.pump();
    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 9'), findsNothing);
    await tester.drag(find.byType(PageView62209), const Offset(-800.0, 0.0));
    await tester.pump();
    expect(find.text('Page 9'), findsOneWidget);
  });

  List<Widget> childrenSizeIncrease(int n) {
    return List<Widget>.generate(n, (int i) {
      return SizedBox(height: 40.0 + i * 3, child: Text('$i'));
    });
  }

  testWidgets('Check for duplicate pixels with ClampingScrollPhysics', (WidgetTester tester) async {
    final List<double> scrollSimulationXList = <double>[];
    final TestScrollPhysics testScrollPhysics = TestScrollPhysics(
      scrollSimulationXList,
      parent: const ClampingScrollPhysics(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          physics: testScrollPhysics,
          children: childrenSizeIncrease(100),
        ),
      ),
    );
    await tester.fling(find.byType(ListView), const Offset(0.0, -4000.0), 4000.0);
    await tester.pumpAndSettle();
    final Set<double> checkSet = <double>{};
    checkSet.addAll(scrollSimulationXList);
    /// checkSet.length + 1 is because:
    /// simulation.x(0.0) will be called in _startSimulation.
    /// The first frame of the animation will also call simulation.x(0.0).
    /// It can be tolerated that it has at most one duplicate value.
    final bool hasOnlyOneDuplicate = scrollSimulationXList.length == checkSet.length + 1;
    expect(true, hasOnlyOneDuplicate); // and ends up at the end
  });

  testWidgets('Check for duplicate pixels with BouncingScrollPhysics', (WidgetTester tester) async {
    final List<double> scrollSimulationXList = <double>[];
    final TestScrollPhysics testScrollPhysics = TestScrollPhysics(
      scrollSimulationXList,
      parent: const BouncingScrollPhysics(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          physics: testScrollPhysics,
          children: childrenSizeIncrease(100),
        ),
      ),
    );
    await tester.fling(find.byType(ListView), const Offset(0.0, -4000.0), 4000.0);
    await tester.pumpAndSettle();
    final Set<double> checkSet = <double>{};
    checkSet.addAll(scrollSimulationXList);
    /// checkSet.length + 1 is because:
    /// simulation.x(0.0) will be call in _startSimulation.
    /// The first frame of the animation will also call simulation.x(0.0).
    /// It can be tolerated that it has at most one duplicate value.
    final bool noDuplicate = scrollSimulationXList.length == checkSet.length + 1;
    expect(true, noDuplicate); // and ends up at the end
  });
}

class TestScrollPhysics extends ScrollPhysics {
  const TestScrollPhysics(this.scrollSimulationXList, { super.parent });

  final List<double> scrollSimulationXList;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final Simulation? scrollSimulation = super.createBallisticSimulation(
      position,
      velocity,
    );
    if (scrollSimulation != null && scrollSimulationXList != null) {
      return TestScrollScrollSimulation(
        scrollSimulation,
        scrollSimulationXList,
      );
    }
    return scrollSimulation;
  }

  @override
  TestScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TestScrollPhysics(
      scrollSimulationXList,
      parent: buildParent(ancestor),
    );
  }
}

class TestScrollScrollSimulation extends Simulation {
  TestScrollScrollSimulation(
    this.innerScrollSimulation,
    this.scrollSimulationXList,
  );

  final Simulation innerScrollSimulation;

  final List<double> scrollSimulationXList;

  @override
  double dx(double time) => innerScrollSimulation.dx(time);

  @override
  bool isDone(double time) => innerScrollSimulation.isDone(time);

  @override
  double x(double time) {
    final double simulationX = innerScrollSimulation.x(time);
    if (scrollSimulationXList != null) {
      scrollSimulationXList.add(simulationX);
    }
    return simulationX;
  }
}

class PageView62209 extends StatefulWidget {
  const PageView62209({super.key});

  @override
  State<PageView62209> createState() => _PageView62209State();
}

class _PageView62209State extends State<PageView62209> {
  int _nextPageNum = 1;
  final List<Carousel62209Page> _pages = <Carousel62209Page>[];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 5; i++) {
      _pages.add(Carousel62209Page(
        key: Key('$_nextPageNum'),
        number: _nextPageNum++,
      ));
    }
    _pages.add(const Carousel62209Page(number: 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(child: Carousel62209(pages: _pages)),
          TextButton(
            child: const Text('ADD PAGE'),
            onPressed: () {
              setState(() {
                _pages.insert(
                  1,
                  Carousel62209Page(
                    key: Key('$_nextPageNum'),
                    number: _nextPageNum++,
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }
}

class Carousel62209Page extends StatelessWidget {
  const Carousel62209Page({required this.number, super.key});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Page $number'));
  }
}

class Carousel62209 extends StatefulWidget {
  const Carousel62209({super.key, required this.pages});

  final List<Carousel62209Page> pages;

  @override
  State<Carousel62209> createState() => _Carousel62209State();
}

class _Carousel62209State extends State<Carousel62209> {
  // page variables
  late PageController _pageController;
  int _currentPage = 0;

  // controls updates outside of user interaction
  late List<Carousel62209Page> _pages;
  bool _jumpingToPage = false;

  @override
  void initState() {
    super.initState();
    _pages = widget.pages.toList();
    _pageController = PageController(keepPage: false);
  }

  @override
  void didUpdateWidget(Carousel62209 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_jumpingToPage) {
      int newPage = -1;
      for (int i = 0; i < widget.pages.length; i++) {
        if (widget.pages[i].number == _pages[_currentPage].number) {
          newPage = i;
        }
      }
      if (newPage == _currentPage) {
        _pages = widget.pages.toList();
      } else {
        _jumpingToPage = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _pages = widget.pages.toList();
              _currentPage = newPage;
              _pageController.jumpToPage(_currentPage);
              SchedulerBinding.instance.addPostFrameCallback((_) {
                _jumpingToPage = false;
              });
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final int page = _pageController.page!.round();
      if (!_jumpingToPage && _currentPage != page) {
        _currentPage = page;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,
        itemBuilder: (BuildContext context, int index) {
          return _pages[index];
        },
      ),
    );
  }
}
