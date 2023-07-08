// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RawView.builder rebuilds on dependency changes', (WidgetTester tester) async {
    final List<String> texts = <String>[];
    final Widget child = RawView(
      view: tester.view,
      builder: (BuildContext context, PipelineOwner owner) {
        texts.add(InheritedText.of(context));
        return const SizedBox();
      },
    );

    await pumpWidgetWithoutViewWrapper(
        tester: tester,
        widget: InheritedText(
          text: 'Hello',
          child: child,
        ),
    );
    expect(texts.single, 'Hello');
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: InheritedText(
        text: 'Hello',
        child: child,
      ),
    );
    expect(texts.single, 'Hello');

    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: InheritedText(
        text: 'World',
        child: child,
      ),
    );
    expect(texts, hasLength(2));
    expect(texts.last, 'World');
  });

  testWidgets('RawView.builder get current pipelineOwner', (WidgetTester tester) async {
    late PipelineOwner builderOwner;
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: Builder(
        builder: (BuildContext context) {
          return RawView(
            view: tester.view,
            builder: (BuildContext context, PipelineOwner owner) {
              builderOwner = owner;
              return const SizedBox();
            }
          );
        }
      ),
    );
    final PipelineOwner rawViewOwner = tester.renderObject(find.byType(RawView)).owner!;
    expect(builderOwner, rawViewOwner);
    expect(builderOwner, isNot(tester.binding.rootPipelineOwner));
  });

  testWidgets('RawView.builder throws', (WidgetTester tester) async {
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: RawView(
        view: tester.view,
        builder: (BuildContext context, PipelineOwner owner) {
          throw StateError('Behave!');
        }
      ),
    );
    expect(
      tester.takeException(),
      isStateError.having((StateError e) => e.message, 'message', 'Behave!'),
    );
    expect(find.byType(ErrorWidget), findsOneWidget);
    expect(tester.widget<ErrorWidget>(find.byType(ErrorWidget)).message, startsWith('Bad state: Behave!'));
  });

  testWidgets('RawView attaches/detaches itself to surrounding pipeline owner', (WidgetTester tester) async {
    late final PipelineOwner parentOwner;
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: Builder(
        builder: (BuildContext context) {
          parentOwner = View.pipelineOwnerOf(context);
          return RawView(
            view: tester.view,
            builder: (BuildContext context, PipelineOwner owner) {
              return const SizedBox();
            },
          );
        }
      ),
    );

    final RenderView rawView = tester.renderObject<RenderView>(find.byType(RawView));

    expect(RendererBinding.instance.renderViews, contains(rawView));
    final List<PipelineOwner> children = <PipelineOwner>[];
    parentOwner.visitChildren((PipelineOwner child) {
      children.add(child);
    });
    final PipelineOwner rawViewOwner = rawView.owner!;
    expect(children, contains(rawViewOwner));

    // Remove that RawView from the tree.
    late final PipelineOwner parentOwner2;
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: Builder(
        builder: (BuildContext context) {
          parentOwner2 = View.pipelineOwnerOf(context);
          return RawView(
            view: FakeView(tester.view),
            builder: (BuildContext context, PipelineOwner owner) {
              return const SizedBox();
            },
          );
        }
      ),
    );

    expect(parentOwner2, parentOwner);
    expect(rawView.owner, isNull);
    expect(RendererBinding.instance.renderViews, isNot(contains(rawView)));
    children.clear();
    parentOwner.visitChildren((PipelineOwner child) {
      children.add(child);
    });
    expect(children, isNot(contains(rawViewOwner)));
  });
}

Future<void> pumpWidgetWithoutViewWrapper({required WidgetTester tester, required  Widget widget}) {
  tester.binding.attachRootWidget(widget);
  tester.binding.scheduleFrame();
  return tester.binding.pump();
}

class InheritedText extends InheritedWidget {
  const InheritedText({
    super.key,
    required this.text,
    required super.child,
  });

  final String text;

  static String of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedText>()!.text;
  }

  @override
  bool updateShouldNotify(InheritedText oldWidget) => text != oldWidget.text;
}

class FakeView extends TestFlutterView{
  FakeView(FlutterView view, { this.viewId = 100 }) : super(
    view: view,
    platformDispatcher: view.platformDispatcher as TestPlatformDispatcher,
    display: view.display as TestDisplay,
  );

  @override
  final int viewId;
}
