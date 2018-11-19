import 'package:flutter/material.dart';

class PlaygroundDemo {
  PlaygroundDemo({
    this.demoWidget,
    this.tabName,
  });

  final Widget demoWidget;
  final String tabName;
}

class PlaygroundPage extends StatelessWidget {
  const PlaygroundPage({
    this.title,
    this.demos,
  });

  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  final String title;
  final List<PlaygroundDemo> demos;

  PlaygroundDemo _currentDemo(BuildContext context) {
    return demos[DefaultTabController.of(context).index];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: demos.length,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
              icon: const BackButtonIcon(),
              tooltip: 'Back',
              onPressed: () {
                Navigator.maybePop(context);
              }),
          bottom: TabBar(
            isScrollable: true,
            tabs: demos.map<Widget>((PlaygroundDemo demo) {
              return Tab(text: demo.tabName);
            }).toList(),
          ),
        ),
        body: TabBarView(
            children: demos.map<Widget>((PlaygroundDemo demo) {
          return demo.demoWidget;
        }).toList()),
      ),
    );
  }
}
