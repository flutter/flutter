// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for custom [PageTransitionsBuilder].

void main() => runApp(const PageTransitionsBuilderExampleApp());

class PageTransitionsBuilderExampleApp extends StatelessWidget {
  const PageTransitionsBuilderExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Page Transitions',
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: SlideRightPageTransitionsBuilder(),
            TargetPlatform.iOS: SlideRightPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomePage(),
    );
  }
}

class SlideRightPageTransitionsBuilder extends PageTransitionsBuilder {
  const SlideRightPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const Offset begin = Offset(1.0, 0.0);
    const Offset end = Offset.zero;
    final Animatable<Offset> tween = Tween<Offset>(
      begin: begin,
      end: end,
    ).chain(CurveTween(curve: Curves.ease));

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

class CustomPageRoute<T> extends PageRoute<T> {
  CustomPageRoute({
    required this.builder,
    this.transitionsBuilder = const SlideRightPageTransitionsBuilder(),
    super.settings,
  });

  final WidgetBuilder builder;
  final PageTransitionsBuilder transitionsBuilder;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return transitionsBuilder.buildTransitions(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Page Transitions')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              CustomPageRoute<void>(
                builder: (BuildContext context) => const SecondPage(),
              ),
            );
          },
          child: const Text('Navigate with Custom Transition'),
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second Page')),
      body: const Center(
        child: Text('This page appeared with a custom transition!'),
      ),
    );
  }
}
