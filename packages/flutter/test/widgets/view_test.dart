// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'multi_view_testing.dart';

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

  testWidgets('child of view finds view, parentPipelineOwner, mediaQuery', (WidgetTester tester) async {
    FlutterView? outsideView;
    FlutterView? insideView;
    PipelineOwner? outsideParent;
    PipelineOwner? insideParent;

    await tester.pumpWidget(
      wrapWithView: false,
      Builder(
        builder: (BuildContext context) {
          outsideView = View.maybeOf(context);
          outsideParent = View.pipelineOwnerOf(context);
          return View(
            view: tester.view,
            child: Builder(
              builder: (BuildContext context) {
                insideView = View.maybeOf(context);
                insideParent = View.pipelineOwnerOf(context);
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );
    expect(outsideView, isNull);
    expect(insideView, equals(tester.view));

    expect(outsideParent, isNotNull);
    expect(insideParent, isNotNull);
    expect(outsideParent, isNot(equals(insideParent)));

    expect(outsideParent, tester.binding.rootPipelineOwner);
    expect(insideParent, equals(tester.renderObject(find.byType(SizedBox)).owner));

    final List<PipelineOwner> pipelineOwners = <PipelineOwner> [];
    tester.binding.rootPipelineOwner.visitChildren((PipelineOwner child) {
      pipelineOwners.add(child);
    });
    expect(pipelineOwners.single, equals(insideParent));
  });

  testWidgets('cannot have multiple views with same FlutterView', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapWithView: false,
      ViewCollection(
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

  testWidgets('ViewCollection may start with zero views', (WidgetTester tester) async {
    expect(() => const ViewCollection(views: <Widget>[]), returnsNormally);
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
    await tester.pumpWidget(
      wrapWithView: false,
      ViewCollection(
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

    await tester.pumpWidget(
      wrapWithView: false,
      ViewCollection(
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
      await tester.pumpWidget(
        wrapWithView: false,
        Builder(
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
      await tester.pumpWidget(
        wrapWithView: false,
        Builder(
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
    await tester.pumpWidget(
      wrapWithView: false,
      View(
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

    await tester.pumpWidget(
      wrapWithView: false,
      View(
        view: tester.view,
        child: const SizedBox(),
      ),
    );
    renderView = tester.renderObject(find.byType(View));
    expect(renderView, isNot(same(tester.binding.renderView)));
    expect(renderView.owner, isNot(same(tester.binding.pipelineOwner)));
    expect(tester.renderObject(find.byType(SizedBox)).owner, isNot(same(tester.binding.pipelineOwner)));

    await tester.pumpWidget(
      wrapWithView: false,
      View(
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

  testWidgets('attaches itself correctly', (WidgetTester tester) async {
    final Key viewKey = UniqueKey();
    late final PipelineOwner parentPipelineOwner;
    await tester.pumpWidget(
      ViewAnchor(
        view: Builder(
          builder: (BuildContext context) {
            parentPipelineOwner = View.pipelineOwnerOf(context);
            return View(
              key: viewKey,
              view: FakeView(tester.view),
              child: const SizedBox(),
            );
          },
        ),
        child: const ColoredBox(color: Colors.green),
      ),
    );

    expect(parentPipelineOwner, isNot(RendererBinding.instance.rootPipelineOwner));

    final RenderView rawView = tester.renderObject<RenderView>(find.byKey(viewKey));
    expect(RendererBinding.instance.renderViews,  contains(rawView));

    final List<PipelineOwner> children = <PipelineOwner>[];
    parentPipelineOwner.visitChildren((PipelineOwner child) {
      children.add(child);
    });
    final PipelineOwner rawViewOwner = rawView.owner!;
    expect(children, contains(rawViewOwner));

    // Remove that View from the tree.
    await tester.pumpWidget(
      const ViewAnchor(
        child: ColoredBox(color: Colors.green),
      ),
    );

    expect(rawView.owner, isNull);
    expect(RendererBinding.instance.renderViews, isNot(contains(rawView)));
    children.clear();
    parentPipelineOwner.visitChildren((PipelineOwner child) {
      children.add(child);
    });
    expect(children, isNot(contains(rawViewOwner)));
  });

  testWidgets('RenderView does not use size of child if constraints are tight', (WidgetTester tester) async {
    const Size physicalSize = Size(300, 600);
    final Size logicalSize = physicalSize / tester.view.devicePixelRatio;
    tester.view.physicalConstraints = ViewConstraints.tight(physicalSize);
    await tester.pumpWidget(const Placeholder());

    final RenderView renderView = tester.renderObject<RenderView>(find.byType(View));
    expect(renderView.constraints, BoxConstraints.tight(logicalSize));
    expect(renderView.size, logicalSize);

    final RenderBox child = renderView.child!;
    expect(child.constraints, BoxConstraints.tight(logicalSize));
    expect(child.debugCanParentUseSize, isFalse);
    expect(child.size, logicalSize);
  });

  testWidgets('RenderView sizes itself to child if constraints allow it (unconstrained)', (WidgetTester tester) async {
    const Size size = Size(300, 600);
    tester.view.physicalConstraints = const ViewConstraints(); // unconstrained
    await tester.pumpWidget(SizedBox.fromSize(size: size));

    final RenderView renderView = tester.renderObject<RenderView>(find.byType(View));
    expect(renderView.constraints, const BoxConstraints());
    expect(renderView.size, size);

    final RenderBox child = renderView.child!;
    expect(child.constraints, const BoxConstraints());
    expect(child.debugCanParentUseSize, isTrue);
    expect(child.size, size);
  });

  testWidgets('RenderView sizes itself to child if constraints allow it (constrained)', (WidgetTester tester) async {
    const Size size = Size(30, 60);
    const ViewConstraints viewConstraints = ViewConstraints(maxWidth: 333, maxHeight: 666);
    final BoxConstraints boxConstraints = BoxConstraints.fromViewConstraints(viewConstraints / tester.view.devicePixelRatio);
    tester.view.physicalConstraints = viewConstraints;
    await tester.pumpWidget(SizedBox.fromSize(size: size));

    final RenderView renderView = tester.renderObject<RenderView>(find.byType(View));
    expect(renderView.constraints, boxConstraints);
    expect(renderView.size, size);

    final RenderBox child = renderView.child!;
    expect(child.constraints, boxConstraints);
    expect(child.debugCanParentUseSize, isTrue);
    expect(child.size, size);
  });

  testWidgets('RenderView respects constraints when child wants to be bigger than allowed', (WidgetTester tester) async {
    const Size size = Size(3000, 6000);
    const ViewConstraints viewConstraints = ViewConstraints(maxWidth: 300, maxHeight: 600);
    tester.view.physicalConstraints = viewConstraints;
    await tester.pumpWidget(SizedBox.fromSize(size: size));

    final RenderView renderView = tester.renderObject<RenderView>(find.byType(View));
    expect(renderView.size, const Size(100, 200)); // viewConstraints.biggest / devicePixelRatio

    final RenderBox child = renderView.child!;
    expect(child.debugCanParentUseSize, isTrue);
    expect(child.size, const Size(100, 200));
  });
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
