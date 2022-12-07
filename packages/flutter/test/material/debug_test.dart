// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debugCheckHasMaterial control test', (WidgetTester tester) async {
    await tester.pumpWidget(const Chip(label: Text('label')));
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    final FlutterError error = exception as FlutterError;
    expect(error.diagnostics.length, 5);
    expect(error.diagnostics[2].level, DiagnosticLevel.hint);
    expect(
      error.diagnostics[2].toStringDeep(),
      equalsIgnoringHashCodes(
        'To introduce a Material widget, you can either directly include\n'
        'one, or use a widget that contains Material itself, such as a\n'
        'Card, Dialog, Drawer, or Scaffold.\n',
      ),
    );
    expect(error.diagnostics[3], isA<DiagnosticsProperty<Element>>());
    expect(error.diagnostics[4], isA<DiagnosticsBlock>());
    expect(
      error.toStringDeep(),
      'FlutterError\n'
      '   No Material widget found.\n'
      '   Chip widgets require a Material widget ancestor.\n'
      '   In Material Design, most widgets are conceptually "printed" on a\n'
      "   sheet of material. In Flutter's material library, that material\n"
      '   is represented by the Material widget. It is the Material widget\n'
      '   that renders ink splashes, for instance. Because of this, many\n'
      '   material library widgets require that there be a Material widget\n'
      '   in the tree above them.\n'
      '   To introduce a Material widget, you can either directly include\n'
      '   one, or use a widget that contains Material itself, such as a\n'
      '   Card, Dialog, Drawer, or Scaffold.\n'
      '   The specific widget that could not find a Material ancestor was:\n'
      '     Chip\n'
      '   The ancestors of this widget were:\n'
      '     [root]\n',
    );
  });

  testWidgets('debugCheckHasMaterialLocalizations control test', (WidgetTester tester) async {
    await tester.pumpWidget(const BackButton());
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    final FlutterError error = exception as FlutterError;
    expect(error.diagnostics.length, 6);
    expect(error.diagnostics[3].level, DiagnosticLevel.hint);
    expect(
      error.diagnostics[3].toStringDeep(),
      equalsIgnoringHashCodes(
        'To introduce a MaterialLocalizations, either use a MaterialApp at\n'
        'the root of your application to include them automatically, or\n'
        'add a Localization widget with a MaterialLocalizations delegate.\n',
      ),
    );
    expect(error.diagnostics[4], isA<DiagnosticsProperty<Element>>());
    expect(error.diagnostics[5], isA<DiagnosticsBlock>());
    expect(
      error.toStringDeep(),
      'FlutterError\n'
      '   No MaterialLocalizations found.\n'
      '   BackButton widgets require MaterialLocalizations to be provided\n'
      '   by a Localizations widget ancestor.\n'
      '   The material library uses Localizations to generate messages,\n'
      '   labels, and abbreviations.\n'
      '   To introduce a MaterialLocalizations, either use a MaterialApp at\n'
      '   the root of your application to include them automatically, or\n'
      '   add a Localization widget with a MaterialLocalizations delegate.\n'
      '   The specific widget that could not find a MaterialLocalizations\n'
      '   ancestor was:\n'
      '     BackButton\n'
      '   The ancestors of this widget were:\n'
      '     [root]\n',
    );
  });

  testWidgets('debugCheckHasScaffold control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
        ),
        home: Builder(
          builder: (BuildContext context) {
            showBottomSheet<void>(
              context: context,
              builder: (BuildContext context) => Container(),
            );
            return Container();
          },
        ),
      ),
    );
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    final FlutterError error = exception as FlutterError;
    expect(error.diagnostics.length, 5);
    expect(error.diagnostics[2], isA<DiagnosticsProperty<Element>>());
    expect(error.diagnostics[3], isA<DiagnosticsBlock>());
    expect(error.diagnostics[4].level, DiagnosticLevel.hint);
    expect(
      error.diagnostics[4].toStringDeep(),
      equalsIgnoringHashCodes(
        'Typically, the Scaffold widget is introduced by the MaterialApp\n'
        'or WidgetsApp widget at the top of your application widget tree.\n',
      ),
    );
    expect(error.toStringDeep(), equalsIgnoringHashCodes(
      'FlutterError\n'
      '   No Scaffold widget found.\n'
      '   Builder widgets require a Scaffold widget ancestor.\n'
      '   The specific widget that could not find a Scaffold ancestor was:\n'
      '     Builder\n'
      '   The ancestors of this widget were:\n'
      '     Semantics\n'
      '     Builder\n'
      '     RepaintBoundary-[GlobalKey#00000]\n'
      '     IgnorePointer\n'
      '     AnimatedBuilder\n'
      '     FadeTransition\n'
      '     FractionalTranslation\n'
      '     SlideTransition\n'
      '     _FadeUpwardsPageTransition\n'
      '     AnimatedBuilder\n'
      '     RepaintBoundary\n'
      '     _FocusMarker\n'
      '     Semantics\n'
      '     FocusScope\n'
      '     PrimaryScrollController\n'
      '     _ActionsMarker\n'
      '     Actions\n'
      '     Builder\n'
      '     PageStorage\n'
      '     Offstage\n'
      '     _ModalScopeStatus\n'
      '     UnmanagedRestorationScope\n'
      '     RestorationScope\n'
      '     AnimatedBuilder\n'
      '     _ModalScope<dynamic>-[LabeledGlobalKey<_ModalScopeState<dynamic>>#00000]\n'
      '     Semantics\n'
      '     _EffectiveTickerMode\n'
      '     TickerMode\n'
      '     _OverlayEntryWidget-[LabeledGlobalKey<_OverlayEntryWidgetState>#00000]\n'
      '     _Theatre\n'
      '     Overlay-[LabeledGlobalKey<OverlayState>#00000]\n'
      '     UnmanagedRestorationScope\n'
      '     _FocusMarker\n'
      '     Focus\n'
      '     _FocusMarker\n'
      '     Focus\n'
      '     _FocusTraversalGroupMarker\n'
      '     FocusTraversalGroup\n'
      '     AbsorbPointer\n'
      '     Listener\n'
      '     HeroControllerScope\n'
      '     Navigator-[GlobalObjectKey<NavigatorState> _WidgetsAppState#00000]\n'
      '     _FocusMarker\n'
      '     Semantics\n'
      '     FocusScope\n'
      '     DefaultSelectionStyle\n'
      '     IconTheme\n'
      '     IconTheme\n'
      '     _InheritedCupertinoTheme\n'
      '     CupertinoTheme\n'
      '     _InheritedTheme\n'
      '     Theme\n'
      '     AnimatedTheme\n'
      '     DefaultSelectionStyle\n'
      '     _ScaffoldMessengerScope\n'
      '     ScaffoldMessenger\n'
      '     Builder\n'
      '     DefaultTextStyle\n'
      '     CustomPaint\n'
      '     Banner\n'
      '     CheckedModeBanner\n'
      '     Title\n'
      '     Directionality\n'
      '     _LocalizationsScope-[GlobalKey#00000]\n'
      '     Semantics\n'
      '     Localizations\n'
      '     MediaQuery\n'
      '     _MediaQueryFromWindow\n'
      '     Semantics\n'
      '     _FocusMarker\n'
      '     Focus\n'
      '     Shortcuts\n'
      '     _ShortcutRegistrarMarker\n'
      '     ShortcutRegistrar\n'
      '     TapRegionSurface\n'
      '     _FocusMarker\n'
      '     Focus\n'
      '     _FocusTraversalGroupMarker\n'
      '     FocusTraversalGroup\n'
      '     _ActionsMarker\n'
      '     Actions\n'
      '${kIsWeb
          ? '     Semantics\n'
            '     _FocusMarker\n'
            '     Focus\n'
            '     Shortcuts\n'
           : ''}'
      '     Semantics\n'
      '     _FocusMarker\n'
      '     Focus\n'
      '     Shortcuts\n'
      '     DefaultTextEditingShortcuts\n'
      '     Semantics\n'
      '     _FocusMarker\n'
      '     Focus\n'
      '     Shortcuts\n'
      '     _SharedAppModel\n'
      '     SharedAppData\n'
      '     UnmanagedRestorationScope\n'
      '     RestorationScope\n'
      '     UnmanagedRestorationScope\n'
      '     RootRestorationScope\n'
      '     WidgetsApp-[GlobalObjectKey _MaterialAppState#00000]\n'
      '     Semantics\n'
      '     _FocusMarker\n'
      '     Focus\n'
      '     HeroControllerScope\n'
      '     ScrollConfiguration\n'
      '     MaterialApp\n'
      '     [root]\n'
      '   Typically, the Scaffold widget is introduced by the MaterialApp\n'
      '   or WidgetsApp widget at the top of your application widget tree.\n'
    ));
  });

  testWidgets('debugCheckHasScaffoldMessenger control test', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    final SnackBar snackBar = SnackBar(
      content: const Text('Snack'),
      action: SnackBarAction(label: 'Test', onPressed: () {}),
    );
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: ScaffoldMessenger(
          key: scaffoldMessengerKey,
          child: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                key: scaffoldKey,
                body: Container(),
              );
            },
          ),
        ),
      ),
    ));
    final List<dynamic> exceptions = <dynamic>[];
    final FlutterExceptionHandler? oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      exceptions.add(details.exception);
    };
    // ScaffoldMessenger shows SnackBar.
    scaffoldMessengerKey.currentState!.showSnackBar(snackBar);
    await tester.pumpAndSettle();

    // Pump widget to rebuild without ScaffoldMessenger
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Scaffold(
          key: scaffoldKey,
          body: Container(),
        ),
      ),
    ));
    // Tap SnackBarAction to dismiss.
    // The SnackBarAction should assert we still have an ancestor
    // ScaffoldMessenger in order to dismiss the SnackBar from the
    // Scaffold.
    await tester.tap(find.text('Test'));
    FlutterError.onError = oldHandler;

    expect(exceptions.length, 1);
    // ignore: avoid_dynamic_calls
    expect(exceptions.single.runtimeType, FlutterError);
    final FlutterError error = exceptions.first as FlutterError;
    expect(error.diagnostics.length, 5);
    expect(error.diagnostics[2], isA<DiagnosticsProperty<Element>>());
    expect(error.diagnostics[3], isA<DiagnosticsBlock>());
    expect(error.diagnostics[4].level, DiagnosticLevel.hint);
    expect(
      error.diagnostics[4].toStringDeep(),
      equalsIgnoringHashCodes(
        'Typically, the ScaffoldMessenger widget is introduced by the\n'
        'MaterialApp at the top of your application widget tree.\n',
      ),
    );
    expect(error.toStringDeep(), equalsIgnoringHashCodes(
      'FlutterError\n'
      '   No ScaffoldMessenger widget found.\n'
      '   SnackBarAction widgets require a ScaffoldMessenger widget\n'
      '   ancestor.\n'
      '   The specific widget that could not find a ScaffoldMessenger\n'
      '   ancestor was:\n'
      '     SnackBarAction\n'
      '   The ancestors of this widget were:\n'
      '     TextButtonTheme\n'
      '     Padding\n'
      '     Row\n'
      '     Wrap\n'
      '     Padding\n'
      '     MediaQuery\n'
      '     Padding\n'
      '     SafeArea\n'
      '     FadeTransition\n'
      '     DefaultSelectionStyle\n'
      '     IconTheme\n'
      '     IconTheme\n'
      '     _InheritedCupertinoTheme\n'
      '     CupertinoTheme\n'
      '     _InheritedTheme\n'
      '     Theme\n'
      '     DefaultTextStyle\n'
      '     AnimatedDefaultTextStyle\n'
      '     _InkFeatures-[GlobalKey#00000 ink renderer]\n'
      '     NotificationListener<LayoutChangedNotification>\n'
      '     PhysicalModel\n'
      '     AnimatedPhysicalModel\n'
      '     Material\n'
      '     KeyedSubtree-[GlobalKey#00000]\n'
      '     FractionalTranslation\n'
      '     SlideTransition\n'
      '     Listener\n'
      '     _GestureSemantics\n'
      '     RawGestureDetector\n'
      '     GestureDetector\n'
      "     Dismissible-[<'dismissible'>]\n"
      '     Semantics\n'
      '     Align\n'
      '     AnimatedBuilder\n'
      '     ClipRect\n'
      '     KeyedSubtree-[GlobalKey#00000]\n'
      '     _EffectiveTickerMode\n'
      '     TickerMode\n'
      '     Offstage\n'
      '     SizedBox\n'
      '     Hero\n'
      '     SnackBar-[#00000]\n'
      '     MediaQuery\n'
      '     LayoutId-[<_ScaffoldSlot.snackBar>]\n'
      '     CustomMultiChildLayout\n'
      '     _ActionsMarker\n'
      '     Actions\n'
      '     AnimatedBuilder\n'
      '     DefaultTextStyle\n'
      '     AnimatedDefaultTextStyle\n'
      '     _InkFeatures-[GlobalKey#00000 ink renderer]\n'
      '     NotificationListener<LayoutChangedNotification>\n'
      '     PhysicalModel\n'
      '     AnimatedPhysicalModel\n'
      '     Material\n'
      '     _ScrollNotificationObserverScope\n'
      '     NotificationListener<ScrollNotification>\n'
      '     NotificationListener<ScrollMetricsNotification>\n'
      '     ScrollNotificationObserver\n'
      '     _ScaffoldScope\n'
      '     Scaffold-[LabeledGlobalKey<ScaffoldState>#00000]\n'
      '     MediaQuery\n'
      '     Directionality\n'
      '     [root]\n'
      '   Typically, the ScaffoldMessenger widget is introduced by the\n'
      '   MaterialApp at the top of your application widget tree.\n'
    ));
  });
}
