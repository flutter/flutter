// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widgets running with runApp can find View', (WidgetTester tester) async {
    FlutterView? viewOf;
    FlutterView? viewMaybeOf;

    runApp(
      Builder(
        builder: (BuildContext context) {
          viewOf = View.of(context);
          viewMaybeOf = View.maybeOf(context);
          return Container();
        },
      ),
    );

    expect(viewOf, isNotNull);
    expect(viewOf, isA<FlutterView>());
    expect(viewMaybeOf, isNotNull);
    expect(viewMaybeOf, isA<FlutterView>());
  });

  testWidgets('Widgets running with pumpWidget can find View', (WidgetTester tester) async {
    FlutterView? view;
    FlutterView? viewMaybeOf;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          view = View.of(context);
          viewMaybeOf = View.maybeOf(context);
          return Container();
        },
      ),
    );

    expect(view, isNotNull);
    expect(view, isA<FlutterView>());
    expect(viewMaybeOf, isNotNull);
    expect(viewMaybeOf, isA<FlutterView>());
  });

  testWidgets('cannot find View behind a LookupBoundary', (WidgetTester tester) async {
    await tester.pumpWidget(
      LookupBoundary(
        child: Container(),
      ),
    );

    final BuildContext context = tester.element(find.byType(Container));

    expect(View.maybeOf(context), isNull);
    expect(
      () => View.of(context),
      throwsA(isA<FlutterError>().having(
        (FlutterError error) => error.message,
        'message',
        contains('The context provided to View.of() does have a View widget ancestor, but it is hidden by a LookupBoundary.'),
      )),
    );
  });

  testWidgets('child of view finds view, viewHooks, mediaQuery', (WidgetTester tester) async {
    FlutterView? outsideView;
    FlutterView? insideView;
    ViewHooks? outsideHooks;
    ViewHooks? insideHooks;

    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: Builder(
        builder: (BuildContext context) {
          outsideView = View.maybeOf(context);
          outsideHooks = ViewHooks.of(context);
          return View(
            view: tester.view,
            child: Builder(
              builder: (BuildContext context) {
                insideView = View.maybeOf(context);
                insideHooks = ViewHooks.of(context);
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );
    expect(outsideView, isNull);
    expect(insideView, equals(tester.view));

    expect(outsideHooks, isNotNull);
    expect(insideHooks, isNotNull);
    expect(outsideHooks, isNot(equals(insideHooks)));
    expect(outsideHooks!.renderViewRepository, equals(insideHooks!.renderViewRepository));
    expect(outsideHooks!.pipelineOwner, isNot(equals(insideHooks!.pipelineOwner)));

    expect(outsideHooks!.pipelineOwner, tester.binding.rootPipelineOwner);
    expect(insideHooks!.pipelineOwner, equals(tester.renderObject(find.byType(SizedBox)).owner));

    final List<PipelineOwner> pipelineOwners = <PipelineOwner> [];
    tester.binding.rootPipelineOwner.visitChildren((PipelineOwner child) {
      pipelineOwners.add(child);
    });
    expect(pipelineOwners.single, equals(insideHooks!.pipelineOwner));
  });

  testWidgets('cannot have multiple views with same FlutterView', (WidgetTester tester) async {
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: ViewCollection(
        views: <Widget>[
          View(
            view: tester.view,
            child: const SizedBox(),
          ),
          View(
            view: tester.view,
            child: const SizedBox(),
          ),
        ],
      ),
    );

    expect(
      tester.takeException(),
      isFlutterError.having(
        (FlutterError e) => e.message,
        'message',
        contains('Multiple widgets used the same GlobalKey'),
      ),
    );
  });
}

Future<void> pumpWidgetWithoutViewWrapper({required WidgetTester tester, required  Widget widget}) {
  tester.binding.attachRootWidget(widget);
  tester.binding.scheduleFrame();
  return tester.binding.pump();
}
