// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gallery/deferred_widget.dart';
import 'package:gallery/main.dart';
import 'package:gallery/pages/demo.dart';
import 'package:gallery/pages/home.dart';
import 'package:gallery/studies/crane/app.dart' deferred as crane;
import 'package:gallery/studies/crane/routes.dart' as crane_routes;
import 'package:gallery/studies/fortnightly/app.dart' deferred as fortnightly;
import 'package:gallery/studies/fortnightly/routes.dart' as fortnightly_routes;
import 'package:gallery/studies/rally/app.dart' deferred as rally;
import 'package:gallery/studies/rally/routes.dart' as rally_routes;
import 'package:gallery/studies/reply/app.dart' as reply;
import 'package:gallery/studies/reply/routes.dart' as reply_routes;
import 'package:gallery/studies/shrine/app.dart' deferred as shrine;
import 'package:gallery/studies/shrine/routes.dart' as shrine_routes;
import 'package:gallery/studies/starter/app.dart' as starter_app;
import 'package:gallery/studies/starter/routes.dart' as starter_app_routes;

typedef PathWidgetBuilder = Widget Function(BuildContext, String?);

class Path {
  const Path(this.pattern, this.builder, {this.openInSecondScreen = false});

  /// A RegEx string for route matching.
  final String pattern;

  /// The builder for the associated pattern route. The first argument is the
  /// [BuildContext] and the second argument a RegEx match if that is included
  /// in the pattern.
  ///
  /// ```dart
  /// Path(
  ///   'r'^/demo/([\w-]+)$',
  ///   (context, matches) => Page(argument: match),
  /// )
  /// ```
  final PathWidgetBuilder builder;

  /// If the route should open on the second screen on foldables.
  final bool openInSecondScreen;
}

class RouteConfiguration {
  /// List of [Path] to for route matching. When a named route is pushed with
  /// [Navigator.pushNamed], the route name is matched with the [Path.pattern]
  /// in the list below. As soon as there is a match, the associated builder
  /// will be returned. This means that the paths higher up in the list will
  /// take priority.
  static List<Path> paths = [
    Path(
      r'^' + DemoPage.baseRoute + r'/([\w-]+)$',
      (context, match) => DemoPage(slug: match),
      openInSecondScreen: false,
    ),
    Path(
      r'^' + rally_routes.homeRoute,
      (context, match) => StudyWrapper(
        study: DeferredWidget(rally.loadLibrary,
            () => rally.RallyApp()), // ignore: prefer_const_constructors
      ),
      openInSecondScreen: true,
    ),
    Path(
      r'^' + shrine_routes.homeRoute,
      (context, match) => StudyWrapper(
        study: DeferredWidget(shrine.loadLibrary,
            () => shrine.ShrineApp()), // ignore: prefer_const_constructors
      ),
      openInSecondScreen: true,
    ),
    Path(
      r'^' + crane_routes.defaultRoute,
      (context, match) => StudyWrapper(
        study: DeferredWidget(crane.loadLibrary,
            () => crane.CraneApp(), // ignore: prefer_const_constructors
            placeholder: const DeferredLoadingPlaceholder(name: 'Crane')),
      ),
      openInSecondScreen: true,
    ),
    Path(
      r'^' + fortnightly_routes.defaultRoute,
      (context, match) => StudyWrapper(
        study: DeferredWidget(
            fortnightly.loadLibrary,
            // ignore: prefer_const_constructors
            () => fortnightly.FortnightlyApp()),
      ),
      openInSecondScreen: true,
    ),
    Path(
      r'^' + reply_routes.homeRoute,
      // ignore: prefer_const_constructors
      (context, match) =>
          const StudyWrapper(study: reply.ReplyApp(), hasBottomNavBar: true),
      openInSecondScreen: true,
    ),
    Path(
      r'^' + starter_app_routes.defaultRoute,
      (context, match) => const StudyWrapper(
        study: starter_app.StarterApp(),
      ),
      openInSecondScreen: true,
    ),
    Path(
      r'^/',
      (context, match) => const RootPage(),
      openInSecondScreen: false,
    ),
  ];

  /// The route generator callback used when the app is navigated to a named
  /// route. Set it on the [MaterialApp.onGenerateRoute] or
  /// [WidgetsApp.onGenerateRoute] to make use of the [paths] for route
  /// matching.
  static Route<dynamic>? onGenerateRoute(
    RouteSettings settings,
    bool hasHinge,
  ) {
    for (final path in paths) {
      final regExpPattern = RegExp(path.pattern);
      if (regExpPattern.hasMatch(settings.name!)) {
        final firstMatch = regExpPattern.firstMatch(settings.name!)!;
        final match = (firstMatch.groupCount == 1) ? firstMatch.group(1) : null;
        if (kIsWeb) {
          return NoAnimationMaterialPageRoute<void>(
            builder: (context) => path.builder(context, match),
            settings: settings,
          );
        }
        if (path.openInSecondScreen && hasHinge) {
          return TwoPanePageRoute<void>(
            builder: (context) => path.builder(context, match),
            settings: settings,
          );
        } else {
          return MaterialPageRoute<void>(
            builder: (context) => path.builder(context, match),
            settings: settings,
          );
        }
      }
    }

    // If no match was found, we let [WidgetsApp.onUnknownRoute] handle it.
    return null;
  }
}

class NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationMaterialPageRoute({
    required super.builder,
    super.settings,
  });

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class TwoPanePageRoute<T> extends OverlayRoute<T> {
  TwoPanePageRoute({
    required this.builder,
    super.settings,
  });

  final WidgetBuilder builder;

  @override
  Iterable<OverlayEntry> createOverlayEntries() sync* {
    yield OverlayEntry(builder: (context) {
      final hinge = MediaQuery.of(context).hinge?.bounds;
      if (hinge == null) {
        return builder.call(context);
      } else {
        return Positioned(
            top: 0,
            left: hinge.right,
            right: 0,
            bottom: 0,
            child: builder.call(context));
      }
    });
  }
}
