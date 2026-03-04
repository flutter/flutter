import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'screens/account_screen.dart';
import 'screens/coach_screen.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'services/app_controller.dart';
import 'services/training_service.dart';
import 'theme/app_theme.dart';

class TrainingApp extends StatefulWidget {
  const TrainingApp({super.key});

  @override
  State<TrainingApp> createState() => _TrainingAppState();
}

class _TrainingAppState extends State<TrainingApp> {
  final AppController _controller = AppController();
  final TrainingService _service = const TrainingService();

  @override
  void initState() {
    super.initState();
    _controller.hydrateHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TrainFlow',
          themeMode: ThemeMode.light,
          darkTheme: AppTheme.dark(),
          theme: AppTheme.light(),
          home: _AppScaffold(
            controller: _controller,
            service: _service,
          ),
        );
      },
    );
  }
}

class _AppScaffold extends StatelessWidget {
  const _AppScaffold({
    required this.controller,
    required this.service,
  });

  final AppController controller;
  final TrainingService service;

  @override
  Widget build(BuildContext context) {
    final HomeTab tab = controller.currentTab;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (tab) {
            HomeTab.home => 'Home',
            HomeTab.stats => 'Statistik',
            HomeTab.coach => 'Coach',
            HomeTab.account => 'Konto',
          },
          key: const Key('title'),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: tab.index,
          children: <Widget>[
            HomeScreen(controller: controller, service: service),
            StatsScreen(controller: controller, service: service),
            CoachScreen(service: service),
            AccountScreen(controller: controller, service: service),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (int index) => controller.setTab(HomeTab.values[index]),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(CupertinoIcons.house),
            selectedIcon: Icon(CupertinoIcons.house_fill),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.chart_bar),
            selectedIcon: Icon(CupertinoIcons.chart_bar_fill),
            label: 'Statistik',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.person_2),
            selectedIcon: Icon(CupertinoIcons.person_2_fill),
            label: 'Coach',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.person),
            selectedIcon: Icon(CupertinoIcons.person_fill),
            label: 'Konto',
          ),
        ],
      ),
    );
  }
}
