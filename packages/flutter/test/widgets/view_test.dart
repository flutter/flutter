// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    expect(outsideHooks!.renderViewManager, equals(insideHooks!.renderViewManager));
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

  testWidgets('ViewHooks tests', (WidgetTester tester) async {
    final PipelineOwner owner1 = PipelineOwner();
    final PipelineOwner owner2 = PipelineOwner();
    final RenderViewManager manager1 = FakeRenderViewManager();
    final RenderViewManager manager2 = FakeRenderViewManager();

    final ViewHooks hooks11 = ViewHooks(renderViewManager: manager1, pipelineOwner: owner1);
    final ViewHooks hooks12 = ViewHooks(renderViewManager: manager1, pipelineOwner: owner2);
    final ViewHooks hooks21 = ViewHooks(renderViewManager: manager2, pipelineOwner: owner1);
    final ViewHooks hooks22 = ViewHooks(renderViewManager: manager2, pipelineOwner: owner2);
    expect(hooks11, isNot(hooks12));
    expect(hooks11, isNot(hooks21));
    expect(hooks11, isNot(hooks22));
    expect(ViewHooks(renderViewManager: hooks11.renderViewManager, pipelineOwner: hooks11.pipelineOwner), hooks11);
    expect(hooks12.copyWith(pipelineOwner: hooks11.pipelineOwner), hooks11);
    expect(hooks21.copyWith(renderViewManager: hooks11.renderViewManager), hooks11);
  });

  testWidgets('ViewCollection must have one view', (WidgetTester tester) async {
    expect(() => ViewCollection(views: const <Widget>[]), throwsAssertionError);
  });

  testWidgets('ViewAnchor.child does not see surrounding view', (WidgetTester tester) async {
    FlutterView? inside;
    FlutterView? outside;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          outside = View.maybeOf(context);
          return ViewAnchor(
            view: Builder(
              builder: (BuildContext context) {
                inside = View.maybeOf(context);
                return View(view: FakeView(tester.view), child: const SizedBox());
              },
            ),
            child: const SizedBox(),
          );
        },
      ),
    );
    expect(inside, isNull);
    expect(outside, isNotNull);
  });

  testWidgets('ViewAnchor layout order', (WidgetTester tester) async {
    Finder findSpyWidget(int label) {
      return find.byWidgetPredicate((Widget w) => w is SpyRenderWidget && w.label == label);
    }

    final List<String> log = <String>[];
    await tester.pumpWidget(
      SpyRenderWidget(
        label: 1,
        log: log,
        child: ViewAnchor(
          view: View(
            view: FakeView(tester.view),
            child: SpyRenderWidget(label: 2, log: log),
          ),
          child: SpyRenderWidget(label: 3, log: log),
        ),
      ),
    );
    log.clear();
    tester.renderObject(findSpyWidget(3)).markNeedsLayout();
    tester.renderObject(findSpyWidget(2)).markNeedsLayout();
    tester.renderObject(findSpyWidget(1)).markNeedsLayout();
    await tester.pump();
    expect(log, <String>['layout 1', 'layout 3', 'layout 2']);
  });

  testWidgets('visitChildren of ViewAnchor visits both children', (WidgetTester tester) async {
    await tester.pumpWidget(
      ViewAnchor(
        view: View(
          view: FakeView(tester.view),
          child: const ColoredBox(color: Colors.green),
        ),
        child: const SizedBox(),
      ),
    );
    final Element viewAnchorElement = tester.element(find.byElementPredicate((Element e) => e.runtimeType.toString() == '_MultiChildComponentElement'));
    final List<Element> children = <Element>[];
    viewAnchorElement.visitChildren((Element element) {
      children.add(element);
    });
    expect(children, hasLength(2));

    await tester.pumpWidget(
      const ViewAnchor(
        child: SizedBox(),
      ),
    );
    children.clear();
    viewAnchorElement.visitChildren((Element element) {
      children.add(element);
    });
    expect(children, hasLength(1));
  });

  testWidgets('visitChildren of ViewCollection visits all children', (WidgetTester tester) async {
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: ViewCollection(
        views: <Widget>[
          View(
            view: tester.view,
            child: const SizedBox(),
          ),
          View(
            view: FakeView(tester.view),
            child: const SizedBox(),
          ),
          View(
            view: FakeView(tester.view, viewId: 423),
            child: const SizedBox(),
          ),
        ],
      ),
    );
    final Element viewAnchorElement = tester.element(find.byElementPredicate((Element e) => e.runtimeType.toString() == '_MultiChildComponentElement'));
    final List<Element> children = <Element>[];
    viewAnchorElement.visitChildren((Element element) {
      children.add(element);
    });
    expect(children, hasLength(3));

    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: ViewCollection(
        views: <Widget>[
          View(
            view: tester.view,
            child: const SizedBox(),
          ),
        ],
      ),
    );
    children.clear();
    viewAnchorElement.visitChildren((Element element) {
      children.add(element);
    });
    expect(children, hasLength(1));
  });

  group('renderObject getter', () {
    testWidgets('ancestors of view see RenderView as renderObject', (WidgetTester tester) async {
      late BuildContext builderContext;
      await pumpWidgetWithoutViewWrapper(
        tester: tester,
        widget: Builder(
          builder: (BuildContext context) {
            builderContext = context;
            return View(
              view: tester.view,
              child: const SizedBox(),
            );
          },
        ),
      );

      final RenderObject? renderObject = builderContext.findRenderObject();
      expect(renderObject, isNotNull);
      expect(renderObject, isA<RenderView>());
      expect(renderObject, tester.renderObject(find.byType(View)));
      expect(tester.element(find.byType(Builder)).renderObject, renderObject);
    });

    testWidgets('ancestors of ViewCollection get null for renderObject', (WidgetTester tester) async {
      late BuildContext builderContext;
      await pumpWidgetWithoutViewWrapper(
        tester: tester,
        widget: Builder(
          builder: (BuildContext context) {
            builderContext = context;
            return ViewCollection(
              views: <Widget>[
                View(
                  view: tester.view,
                  child: const SizedBox(),
                ),
                View(
                  view: FakeView(tester.view),
                  child: const SizedBox(),
                ),
              ],
            );
          },
        ),
      );

      final RenderObject? renderObject = builderContext.findRenderObject();
      expect(renderObject, isNull);
      expect(tester.element(find.byType(Builder)).renderObject, isNull);
    });

    testWidgets('ancestors of a ViewAnchor see the right RenderObject', (WidgetTester tester) async {
      late BuildContext builderContext;
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            builderContext = context;
            return ViewAnchor(
              view: View(
                view: FakeView(tester.view),
                child: const ColoredBox(color: Colors.green),
              ),
              child: const SizedBox(),
            );
          },
        ),
      );

      final RenderObject? renderObject = builderContext.findRenderObject();
      expect(renderObject, isNotNull);
      expect(renderObject, isA<RenderConstrainedBox>());
      expect(renderObject, tester.renderObject(find.byType(SizedBox)));
      expect(tester.element(find.byType(Builder)).renderObject, renderObject);
    });
  });

  testWidgets('correctly switches between view configurations', (WidgetTester tester) async {
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: View(
        view: tester.view,
        deprecatedDoNotUseWillBeRemovedWithoutNoticePipelineOwner: tester.binding.pipelineOwner,
        deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView: tester.binding.renderView,
        child: const SizedBox(),
      ),
    );
    RenderObject renderView = tester.renderObject(find.byType(View));
    expect(renderView, same(tester.binding.renderView));
    expect(renderView.owner, same(tester.binding.pipelineOwner));
    expect(tester.renderObject(find.byType(SizedBox)).owner, same(tester.binding.pipelineOwner));

    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: View(
        view: tester.view,
        child: const SizedBox(),
      ),
    );
    renderView = tester.renderObject(find.byType(View));
    expect(renderView, isNot(same(tester.binding.renderView)));
    expect(renderView.owner, isNot(same(tester.binding.pipelineOwner)));
    expect(tester.renderObject(find.byType(SizedBox)).owner, isNot(same(tester.binding.pipelineOwner)));

    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: View(
        view: tester.view,
        deprecatedDoNotUseWillBeRemovedWithoutNoticePipelineOwner: tester.binding.pipelineOwner,
        deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView: tester.binding.renderView,
        child: const SizedBox(),
      ),
    );
    renderView = tester.renderObject(find.byType(View));
    expect(renderView, same(tester.binding.renderView));
    expect(renderView.owner, same(tester.binding.pipelineOwner));
    expect(tester.renderObject(find.byType(SizedBox)).owner, same(tester.binding.pipelineOwner));

    expect(() => View(
      view: tester.view,
      deprecatedDoNotUseWillBeRemovedWithoutNoticePipelineOwner: tester.binding.pipelineOwner,
      child: const SizedBox(),
    ), throwsAssertionError);
    expect(() => View(
      view: tester.view,
      deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView: tester.binding.renderView,
      child: const SizedBox(),
    ), throwsAssertionError);
    expect(() => View(
      view: FakeView(tester.view),
      deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView: tester.binding.renderView,
      deprecatedDoNotUseWillBeRemovedWithoutNoticePipelineOwner: tester.binding.pipelineOwner,
      child: const SizedBox(),
    ), throwsAssertionError);
  });
}

Future<void> pumpWidgetWithoutViewWrapper({required WidgetTester tester, required  Widget widget}) {
  tester.binding.attachRootWidget(widget);
  tester.binding.scheduleFrame();
  return tester.binding.pump();
}

class FakeRenderViewManager extends Fake implements RenderViewManager { }

class FakeView extends TestFlutterView{
  FakeView(FlutterView view, { this.viewId = 100 }) : super(
    view: view,
    platformDispatcher: view.platformDispatcher as TestPlatformDispatcher,
    display: view.display as TestDisplay,
  );

  @override
  final int viewId;
}

class SpyRenderWidget extends SizedBox {
  const SpyRenderWidget({super.key, required this.label, required this.log, super.child});

  final int label;
  final List<String> log;

  @override
  RenderSpy createRenderObject(BuildContext context) {
    return RenderSpy(
      additionalConstraints: const BoxConstraints(),
      label: label,
      log: log,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSpy renderObject) {
    renderObject
      ..label = label
      ..log = log;
  }
}

class RenderSpy extends RenderConstrainedBox {
  RenderSpy({required super.additionalConstraints, required this.label, required this.log});

  int label;
  List<String> log;

  @override
  void performLayout() {
    log.add('layout $label');
    super.performLayout();
  }
}
