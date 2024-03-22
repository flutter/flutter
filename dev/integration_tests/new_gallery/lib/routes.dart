// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'deferred_widget.dart';
import 'main.dart';
import 'pages/demo.dart';
import 'pages/home.dart';
import 'studies/crane/app.dart' deferred as crane;
import 'studies/crane/routes.dart' as crane_routes;
import 'studies/fortnightly/app.dart' deferred as fortnightly;
import 'studies/fortnightly/routes.dart' as fortnightly_routes;
import 'studies/rally/app.dart' deferred as rally;
import 'studies/rally/routes.dart' as rally_routes;
import 'studies/reply/app.dart' as reply;
import 'studies/reply/routes.dart' as reply_routes;
import 'studies/shrine/app.dart' deferred as shrine;
import 'studies/shrine/routes.dart' as shrine_routes;
import 'studies/starter/app.dart' as starter_app;
import 'studies/starter/routes.dart' as starter_app_routes;

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
  static List<Path> paths = <Path>[
    Path(
      r'^' + DemoPage.baseRoute + r'/([\w-]+)$',
      (BuildContext context, String? match) => DemoPage(slug: match),
    ),
    Path(
      r'^' + rally_routes.homeRoute,
      (BuildContext context, String? match) => StudyWrapper(
        study: DeferredWidget(rally.loadLibrary,
            () => rally.RallyApp()), // ignore: prefer_const_constructors
      ),
      openInSecondScreen: true,
    ),
    Path(
      r'^' + shrine_routes.homeRoute,
      (BuildContext context, String? match) => StudyWrapper(
        study: DeferredWidget(shrine.loadLibrary,
            () => shrine.ShrineApp()), // ignore: prefer_const_constructors
      ),
      openInSecondScreen: true,
    ),
    Path(
      r'^' + crane_routes.defaultRoute,
      (BuildContext context, String? match) => StudyWrapper(
        study: DeferredWidget(crane.loadLibrary,
            () => crane.CraneApp(), // ignore: prefer_const_constructors
            placeholder: const DeferredLoadingPlaceholder(name: 'Crane')),
      ),
      openInSecondScreen: true,
    ),
    Path(
      r'^' + fortnightly_routes.defaultRoute,
      (BuildContext context, String? match) => StudyWrapper(
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
      (BuildContext context, String? match) =>
          const StudyWrapper(study: reply.ReplyApp(), hasBottomNavBar: true),
      openInSecondScreen: true,
    ),
    Path(
      r'^' + starter_app_routes.defaultRoute,
      (BuildContext context, String? match) => const StudyWrapper(
        study: starter_app.StarterApp(),
      ),
      openInSecondScreen: true,
    ),
    Path(
      r'^/',
      (BuildContext context, String? match) => const RootPage(),
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
    for (final Path path in paths) {
      final RegExp regExpPattern = RegExp(path.pattern);
      if (regExpPattern.hasMatch(settings.name!)) {
        final RegExpMatch firstMatch = regExpPattern.firstMatch(settings.name!)!;
        final String? match = (firstMatch.groupCount == 1) ? firstMatch.group(1) : null;
        if (kIsWeb) {
          return NoAnimationMaterialPageRoute<void>(
            builder: (BuildContext context) => path.builder(context, match),
            settings: settings,
          );
        }
        if (path.openInSecondScreen && hasHinge) {
          return TwoPanePageRoute<void>(
            builder: (BuildContext context) => path.builder(context, match),
            settings: settings,
          );
        } else {
          return MaterialPageRoute<void>(
            builder: (BuildContext context) => path.builder(context, match),
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
    yield OverlayEntry(builder: (BuildContext context) {
      final Rect? hinge = MediaQuery.of(context).hinge?.bounds;
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
