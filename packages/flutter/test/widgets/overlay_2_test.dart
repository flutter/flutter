// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _DescendantMatcher extends Matcher {
  const _DescendantMatcher({ required this.ancestor });

  final RenderObject ancestor;

  @override
  Description describe(Description description) {
    return description.add('is a descendant of RenderObject: $ancestor');
  }

  @override
  bool matches(covariant RenderObject object, Map<dynamic, dynamic> matchState) {
    RenderObject node = object;
    while (node.depth > ancestor.depth) {
      final AbstractNode? parent = node.parent;
      if (parent is RenderObject) {
        node = parent;
      } else {
        return false;
      }
    }
    return node == ancestor;
  }
}

Matcher _isDescendantRenderObjectOf({ required RenderObject ancestor }) => _DescendantMatcher(ancestor: ancestor);

class _ManyRelayoutBoundaries extends StatelessWidget {
  const _ManyRelayoutBoundaries({
    required this.levels,
    required this.child,
  });

  final Widget child;

  final int levels;

  @override
  Widget build(BuildContext context) {
    final Widget result = levels <= 1
      ? child
      : _ManyRelayoutBoundaries(levels: levels - 1, child: child);
    return SizedBox.square(dimension: 50, child: result);
  }
}

void rebuildLayoutBuilderSubtree(RenderBox descendant) {
  assert(descendant is! RenderConstrainedLayoutBuilder<BoxConstraints, RenderBox>);

  AbstractNode? node = descendant.parent;
  while (node != null) {
    if (node is! RenderConstrainedLayoutBuilder<BoxConstraints, RenderBox>) {
      node = node.parent;
    } else {
      node.markNeedsBuild();
      return;
    }
  }
  assert(false);
}

void verifyTreeIsClean() {
   final RenderObject renderObject = RendererBinding.instance.renderView;
   bool hasDirtyNode = renderObject.debugNeedsLayout;

   void visitor(RenderObject renderObject) {
     expect(renderObject.debugNeedsLayout, false, reason: '$renderObject is dirty');
     hasDirtyNode = hasDirtyNode || renderObject.debugNeedsLayout;
     if (!hasDirtyNode) {
       renderObject.visitChildren(visitor);
     }
   }
   visitor(renderObject);
}

void verifyOverlayChildReadyForLayout(GlobalKey overlayWidgetKey) {
  final RenderObjectElement element = overlayWidgetKey.currentContext! as RenderObjectElement;
  final RenderBox layoutSurrogate = element.renderObject as RenderBox;
  assert(element.runtimeType.toString() == '_OverlayPortalElement');

  if (layoutSurrogate.debugNeedsLayout) {
    assert(layoutSurrogate.debugDoingThisLayout);
  }
  expect(!layoutSurrogate.debugNeedsLayout || layoutSurrogate.debugDoingThisLayout, true);
}

void main() {
  testWidgets('The overlay child sees the right inherited widgets', (WidgetTester tester) async {
    int buildCount = 0;
    TextDirection? directionSeenByOverlayChild;
    TextDirection textDirection = TextDirection.rtl;
    late StateSetter setState;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setter) {
                    setState = setter;
                    return Directionality(
                      textDirection: textDirection,
                      child: OverlayPortal(
                        overlayInfo: OverlayInfo.of(context),
                        overlayChild: Builder(builder: (BuildContext context) {
                          buildCount += 1;
                          directionSeenByOverlayChild = Directionality.maybeOf(context);
                          return const SizedBox();
                        }),
                        child: const SizedBox(),
                      ),
                    );
                  }
                );
              },
            ),
          ],
        ),
      ),
    );
    expect(buildCount, 1);
    expect(directionSeenByOverlayChild, textDirection);

    setState(() {
      textDirection = TextDirection.ltr;
    });
    await tester.pump();
    expect(buildCount, 2);
    expect(directionSeenByOverlayChild, textDirection);
  });

  testWidgets('overlay child can use Positioned', (WidgetTester tester) async {
    double dimensions = 30;
    late StateSetter setState;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setter) {
                    setState = setter;
                    return OverlayPortal(
                      overlayInfo: OverlayInfo.of(context),
                      overlayChild: Positioned(
                        width: dimensions,
                        height: dimensions,
                        child: const Placeholder(),
                      ),
                      child: const SizedBox(),
                    );
                  }
                );
              },
            ),
          ],
        ),
      ),
    );

    expect(tester.getTopLeft(find.byType(Placeholder)), Offset.zero) ;
    expect(tester.getSize(find.byType(Placeholder)), const Size(30, 30)) ;


    setState(() {
      dimensions = 50;
    });
    await tester.pump();
    expect(tester.getTopLeft(find.byType(Placeholder)), Offset.zero) ;
    expect(tester.getSize(find.byType(Placeholder)), const Size(50, 50)) ;
  });

  testWidgets('overlay child can be hit tested', (WidgetTester tester) async {
    double offset = 0;
    late StateSetter setState;

    bool isHit = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setter) {
                    setState = setter;
                    return OverlayPortal(
                      overlayInfo: OverlayInfo.of(context),
                      overlayChild: Positioned(
                        left: offset,
                        top: offset,
                        width: 1.0,
                        height: 1.0,
                        child: GestureDetector(onTap: () { isHit = true; }),
                      ),
                      child: const SizedBox(),
                    );
                  }
                );
              },
            ),
          ],
        ),
      ),
    );
    assert(!isHit);
    await tester.tapAt(const Offset(0.5, 0.5));
    expect(isHit, true);
    isHit = false;

    setState(() {
      offset = 50;
    });
    await tester.pump();
    assert(!isHit);

    await tester.tapAt(const Offset(0.5, 0.5));
    expect(isHit, false);
    isHit = false;

    await tester.tapAt(const Offset(50.5, 50.5));
    expect(isHit, true);
  });

  testWidgets('works in a LayoutBuilder', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return OverlayPortal(
                      overlayInfo: OverlayInfo.of(context),
                      overlayChild: const SizedBox(),
                      child: const SizedBox(),
                    );
                  }
                );
              },
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('throws when no Overlay', (WidgetTester tester) async {
    final Widget widget = Builder(
      builder: (BuildContext context) {
        return SizedBox.square(
          dimension: 50,
          child: OverlayPortal(
            overlayInfo: OverlayInfo.of(context),
            overlayChild: const SizedBox(),
            child: const SizedBox(),
          ),
        );
      },
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    );

    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('widget is laid out before overlay child', (WidgetTester tester) async {
    final GlobalKey widgetKey = GlobalKey(debugLabel: 'widget');
    final RenderBox childBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
    final RenderBox overlayChildBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
    int layoutCount = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return _ManyRelayoutBoundaries(levels: 50, child: Builder(builder: (BuildContext context) {
                  return OverlayPortal(
                    key: widgetKey,
                    overlayInfo: OverlayInfo.of(context),
                    overlayChild: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                      verifyOverlayChildReadyForLayout(widgetKey);
                      layoutCount += 1;
                      return WidgetToRenderBoxAdapter(renderBox: overlayChildBox);
                    }),
                    child: WidgetToRenderBoxAdapter(renderBox: childBox),
                  );
                }));
              }
            ),
          ],
        ),
      ),
    );
    expect(layoutCount, 1);

    // Make the widget's render object dirty and verifies in the LayoutBuilder's
    // callback that the widget's render object is already laid out.
    final RenderObject renderChild1 = widgetKey.currentContext!.findRenderObject()!;
    renderChild1.markNeedsLayout();
    // Dirty both render subtree branches.
    childBox.markNeedsLayout();
    rebuildLayoutBuilderSubtree(overlayChildBox);

    // Make sure childBox's depth is greater than that of the overlay
    // child, and childBox's parent isn't dirty (childBox is a dirty relayout
    // boundary).
    expect(widgetKey.currentContext!.findRenderObject()!.depth, lessThan(overlayChildBox.depth));

    await tester.pump();
    expect(layoutCount, 2);
    verifyTreeIsClean();
  });

  testWidgets('adding/removing overlay child does not redirty overlay more than once', (WidgetTester tester) async {
    final GlobalKey widgetKey = GlobalKey(debugLabel: 'widget');
    final GlobalKey overlayKey = GlobalKey(debugLabel: 'overlay');
    final RenderBox childBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
    final RenderBox overlayChildBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
    final _RenderLayoutCounter overlayLayoutCounter = _RenderLayoutCounter();
    int layoutCount = 0;
    late StateSetter setState;
    bool buildWithOverlayChild = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            // Overlay.performLayout will call layoutCounter.layout.
            OverlayEntry(builder: (BuildContext context) => WidgetToRenderBoxAdapter(renderBox: overlayLayoutCounter)),
            OverlayEntry(
              builder: (BuildContext context) {
                return _ManyRelayoutBoundaries(levels: 50, child: Builder(builder: (BuildContext context) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter stateSetter) {
                      setState = stateSetter;
                      return OverlayPortal(
                        key: widgetKey,
                        overlayInfo: OverlayInfo.of(context),
                        overlayChild: !buildWithOverlayChild ? null : LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                          layoutCount += 1;
                          expect(tester.renderObject(find.byType(Overlay)).debugNeedsLayout, false);
                          return WidgetToRenderBoxAdapter(renderBox: overlayChildBox);
                        }),
                        child: WidgetToRenderBoxAdapter(renderBox: childBox),
                      );
                    },
                  );
                }));
              }
            ),
          ],
        ),
      ),
    );
    expect(layoutCount, 0);
    expect(overlayLayoutCounter.layoutCount, 1);
    verifyTreeIsClean();

    // Add overlay child.
    setState(() { buildWithOverlayChild = true; });
    await tester.pump();
    expect(layoutCount, 1);
    // Unfortunately adding/removing child from overlay still redirties the
    // overlay, since freshly inserted render trees need a tree walk from its
    // parent to do layout. This is necessary if we can report the child
    // directly to the PipelineOwner.
    expect(overlayLayoutCounter.layoutCount, 2);
    verifyTreeIsClean();

    // Remove the overlay child back.
    setState(() { buildWithOverlayChild = false; });
    await tester.pump();
    expect(layoutCount, 1);
    expect(overlayLayoutCounter.layoutCount, 3);
    verifyTreeIsClean();
  });

  testWidgets('Change overlay constraints', (WidgetTester tester) async {
    final GlobalKey widgetKey = GlobalKey(debugLabel: 'widget outer');
    final GlobalKey overlayKey = GlobalKey(debugLabel: 'overlay');
    final RenderBox childBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
    final RenderBox overlayChildBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
    final _RenderLayoutCounter overlayLayoutCounter = _RenderLayoutCounter();
    int layoutCount = 0;
    late StateSetter setState;
    double dimension = 100;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          setState = stateSetter;
          return Center(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox.square(
                dimension: dimension,
                child: Overlay(
                  key: overlayKey,
                  initialEntries: <OverlayEntry>[
                    // Overlay.performLayout will call layoutCounter.layout.
                    OverlayEntry(builder: (BuildContext context) => WidgetToRenderBoxAdapter(renderBox: overlayLayoutCounter)),
                    OverlayEntry(
                      builder: (BuildContext outerEntryContext) {
                        return Center(
                          child: _ManyRelayoutBoundaries(
                            levels: 50,
                            child: Builder(builder: (BuildContext context) {
                              return OverlayPortal(
                                key: widgetKey,
                                overlayInfo: OverlayInfo.of(outerEntryContext), // The outer widget targets the outer Overlay.
                                overlayChild: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                                  layoutCount += 1;
                                  // Both overlays need to be clean at this point.
                                  expect(
                                    tester.renderObjectList(find.byType(Overlay)),
                                    everyElement(wrapMatcher((RenderObject object) => !object.debugNeedsLayout || object.debugDoingThisLayout)),
                                  );
                                  return WidgetToRenderBoxAdapter(renderBox: overlayChildBox);
                                }),
                                child: WidgetToRenderBoxAdapter(renderBox: childBox),
                              );
                            }),
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );

    expect(layoutCount, 1);
    expect(overlayLayoutCounter.layoutCount, 1);
    expect(childBox.size, const Size.square(50));
    expect(overlayChildBox.size, const Size.square(100));
    verifyTreeIsClean();

    //print('!!! > $overlayLayoutCounter: ${overlayLayoutCounter.layoutCount}');
    //debugPrintLayouts = true;
    // The incoming constraints changed.
    setState(() {
      dimension = 150;
    });
    await tester.pump();
    //debugPrintLayouts = false;
    expect(childBox.size, const Size.square(50));
    expect(overlayChildBox.size, const Size.square(150));

    expect(layoutCount, 2);
    expect(overlayLayoutCounter.layoutCount, 2);
    verifyTreeIsClean();
  });

  testWidgets('Nested OverlayWidgets with Nested Overlay do not create depedency cycles', (WidgetTester tester) async {
    final GlobalKey widgetOuterKey = GlobalKey(debugLabel: 'widget outer');
    final GlobalKey widgetInnerKey = GlobalKey(debugLabel: 'widget inner');
    final GlobalKey overlayKey = GlobalKey(debugLabel: 'overlay');
    final RenderBox childBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
    final RenderBox overlayChildBox1 = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
    final RenderBox overlayChildBox2 = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
    final _RenderLayoutCounter overlayLayoutCounterInner = _RenderLayoutCounter();
    final _RenderLayoutCounter overlayLayoutCounterOuter = _RenderLayoutCounter();
    int layoutCountOuter = 0;
    int layoutCountInner = 0;
    late StateSetter setState;
    double dimension = 100;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          setState = stateSetter;
          return Center(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox.square(
                dimension: dimension,
                child: Overlay(
                  key: overlayKey,
                  initialEntries: <OverlayEntry>[
                    // Overlay.performLayout will call layoutCounter.layout.
                    OverlayEntry(builder: (BuildContext context) => WidgetToRenderBoxAdapter(renderBox: overlayLayoutCounterOuter)),
                    OverlayEntry(
                      builder: (BuildContext outerEntryContext) {
                        return _ManyRelayoutBoundaries(
                          levels: 50,
                          child: Overlay(
                            initialEntries: <OverlayEntry>[
                              OverlayEntry(builder: (BuildContext context) => WidgetToRenderBoxAdapter(renderBox: overlayLayoutCounterInner)),
                              OverlayEntry(builder: (BuildContext innerEntryContext) {
                                return OverlayPortal(
                                  key: widgetOuterKey,
                                  overlayInfo: OverlayInfo.of(outerEntryContext), // The outer widget targets the outer Overlay.
                                  overlayChild: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                                    layoutCountOuter += 1;
                                    // Both overlays need to be clean at this point.
                                    expect(
                                      tester.renderObjectList(find.byType(Overlay)),
                                      everyElement(wrapMatcher((RenderObject object) => !object.debugNeedsLayout || object.debugDoingThisLayout)),
                                    );
                                    return OverlayPortal(
                                      key: widgetInnerKey,
                                      overlayInfo: OverlayInfo.of(innerEntryContext),
                                      overlayChild: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                                        layoutCountInner += 1;
                                        // Both overlays need to be clean at this point.
                                        expect(
                                          tester.renderObjectList(find.byType(Overlay)),
                                          everyElement(wrapMatcher((RenderObject object) => !object.debugNeedsLayout || object.debugDoingThisLayout)),
                                        );
                                        return WidgetToRenderBoxAdapter(renderBox: overlayChildBox2);
                                      }),
                                      child: WidgetToRenderBoxAdapter(renderBox: overlayChildBox1),
                                    );
                                  }),
                                  child: WidgetToRenderBoxAdapter(renderBox: childBox),
                                );
                              }),
                            ],
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );

    expect(layoutCountOuter, 1);
    expect(layoutCountInner, 1);
    expect(overlayLayoutCounterOuter.layoutCount, 1);
    // Adding the inner widget's overlay child will unfortunately mark the
    // inner overlay dirty again.
    expect(overlayLayoutCounterInner.layoutCount, 1);
    verifyTreeIsClean();

    // The incoming constraints changed.
    setState(() {
      dimension = 150;
    });
    await tester.pump();
    expect(childBox.size, const Size.square(150));
    expect(overlayChildBox1.size, const Size.square(150));
    expect(overlayChildBox2.size, const Size.square(150));

    expect(layoutCountOuter, 2);
    expect(layoutCountInner, 2);
    expect(overlayLayoutCounterOuter.layoutCount, 2);
    expect(overlayLayoutCounterInner.layoutCount, 2);
    verifyTreeIsClean();
  });

  testWidgets('Nested OverlayWidgets with Nested Overlay + LayoutBuilder', (WidgetTester tester) async {
    final GlobalKey widgetOuterKey = GlobalKey(debugLabel: 'widget outer');
    final GlobalKey widgetInnerKey = GlobalKey(debugLabel: 'widget inner');
    final GlobalKey overlayKey = GlobalKey(debugLabel: 'overlay');
    final RenderBox childBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
    final RenderBox overlayChildBox1 = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
    final RenderBox overlayChildBox2 = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
    final _RenderLayoutCounter overlayLayoutCounterInner = _RenderLayoutCounter();
    final _RenderLayoutCounter overlayLayoutCounterOuter = _RenderLayoutCounter();
    int layoutCountOuter = 0;
    int layoutCountInner = 0;
    late StateSetter setState;
    double dimension = 100;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          setState = stateSetter;
          return Center(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox.square(
                dimension: dimension,
                child: Overlay(
                  key: overlayKey,
                  initialEntries: <OverlayEntry>[
                    // Overlay.performLayout will call layoutCounter.layout.
                    OverlayEntry(builder: (BuildContext context) => WidgetToRenderBoxAdapter(renderBox: overlayLayoutCounterOuter)),
                    OverlayEntry(
                      builder: (BuildContext outerEntryContext) {
                        return LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            return Overlay(
                              initialEntries: <OverlayEntry>[
                                OverlayEntry(builder: (BuildContext context) => WidgetToRenderBoxAdapter(renderBox: overlayLayoutCounterInner)),
                                OverlayEntry(builder: (BuildContext innerEntryContext) {
                                  return OverlayPortal(
                                    key: widgetOuterKey,
                                    overlayInfo: OverlayInfo.of(outerEntryContext), // The outer widget targets the outer Overlay.
                                    overlayChild: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                                      layoutCountOuter += 1;
                                      // Both overlays need to be clean at this point.
                                      expect(
                                        tester.renderObjectList(find.byType(Overlay)),
                                        everyElement(wrapMatcher((RenderObject object) => !object.debugNeedsLayout || object.debugDoingThisLayout)),
                                      );
                                      return OverlayPortal(
                                        key: widgetInnerKey,
                                        overlayInfo: OverlayInfo.of(innerEntryContext),
                                        overlayChild: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                                          layoutCountInner += 1;
                                          // Both overlays need to be clean at this point.
                                          expect(
                                            tester.renderObjectList(find.byType(Overlay)),
                                            everyElement(wrapMatcher((RenderObject object) => !object.debugNeedsLayout || object.debugDoingThisLayout)),
                                          );
                                          return WidgetToRenderBoxAdapter(renderBox: overlayChildBox2);
                                        }),
                                        child: WidgetToRenderBoxAdapter(renderBox: overlayChildBox1),
                                      );
                                    }),
                                    child: WidgetToRenderBoxAdapter(renderBox: childBox),
                                  );
                                }),
                              ],
                            );
                          }
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );

    expect(layoutCountOuter, 1);
    expect(layoutCountInner, 1);
    expect(overlayLayoutCounterOuter.layoutCount, 1);
    // Adding the inner widget's overlay child will unfortunately mark the
    // inner overlay dirty again.
    expect(overlayLayoutCounterInner.layoutCount, 1);
    verifyTreeIsClean();

    // The incoming constraints changed.
    setState(() {
      dimension = 150;
    });
    await tester.pump();
    expect(childBox.size, const Size.square(150));
    expect(overlayChildBox1.size, const Size.square(150));
    expect(overlayChildBox2.size, const Size.square(150));

    expect(layoutCountOuter, 2);
    expect(layoutCountInner, 2);
    expect(overlayLayoutCounterOuter.layoutCount, 2);
    expect(overlayLayoutCounterInner.layoutCount, 2);
    verifyTreeIsClean();

    // Change the incoming constraints for overlays and tell the overlay
    // children to update their layout.
    setState(() {
      dimension = 50;
    });
    rebuildLayoutBuilderSubtree(overlayChildBox1);
    rebuildLayoutBuilderSubtree(overlayChildBox2);
    await tester.pump();
    expect(childBox.size, const Size.square(50));
    expect(overlayChildBox1.size, const Size.square(50));
    expect(overlayChildBox2.size, const Size.square(50));

    expect(layoutCountOuter, 3);
    expect(layoutCountInner, 3);
    expect(overlayLayoutCounterOuter.layoutCount, 3);
    expect(overlayLayoutCounterInner.layoutCount, 3);
    verifyTreeIsClean();
  });

  group('GlobalKey Reparenting', () {
    testWidgets('child is laid out before overlay child after OverlayEntry shuffle', (WidgetTester tester) async {
      int layoutCount = 0;

      final GlobalKey widgetKey = GlobalKey(debugLabel: 'widget');
      final RenderBox childBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
      final RenderBox overlayChildBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
      final OverlayEntry overlayEntry1 = OverlayEntry(builder: (BuildContext context) {
        return _ManyRelayoutBoundaries(
          levels: 50,
          child: Builder(builder: (BuildContext context) {
            return OverlayPortal(
              key: widgetKey,
              overlayInfo: OverlayInfo.of(context),
              overlayChild: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                layoutCount += 1;
                verifyOverlayChildReadyForLayout(widgetKey);
                return WidgetToRenderBoxAdapter(renderBox: overlayChildBox);
              }),
              child: WidgetToRenderBoxAdapter(renderBox: childBox),
            );
          }),
        );
      });
      final OverlayEntry overlayEntry2 = OverlayEntry(builder: (BuildContext context) => const Placeholder());
      final OverlayEntry overlayEntry3 = OverlayEntry(builder: (BuildContext context) => const Placeholder());

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            initialEntries: <OverlayEntry>[overlayEntry1, overlayEntry2, overlayEntry3],
          ),
        ),
      );
      expect(layoutCount, 1);
      verifyTreeIsClean();

      widgetKey.currentContext!.findRenderObject()!.markNeedsLayout();
      childBox.markNeedsLayout();
      rebuildLayoutBuilderSubtree(overlayChildBox);
      // Make sure childBox's depth is greater than that of the overlay child.
      expect(
        widgetKey.currentContext!.findRenderObject()!.depth,
        lessThan(overlayChildBox.depth),
      );

      tester.state<OverlayState>(find.byType(Overlay)).rearrange(<OverlayEntry>[overlayEntry3, overlayEntry2, overlayEntry1]);
      await tester.pump();
      expect(layoutCount, 2);
      expect(widgetKey.currentContext!.findRenderObject()!.depth, lessThan(overlayChildBox.depth));
      verifyTreeIsClean();
    });

    testWidgets('widget is laid out before overlay child after reparenting', (WidgetTester tester) async {
      final GlobalKey targetGlobalKey = GlobalKey(debugLabel: 'target widget');
      final RenderBox childBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
      final RenderBox overlayChildBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());

      late StateSetter setState1, setState2;
      bool targetMovedToOverlayEntry3 = false;

      int layoutCount1 = 0;
      int layoutCount2 = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(builder: (BuildContext context) {
                return _ManyRelayoutBoundaries(
                  levels: 50,
                  child: StatefulBuilder(builder: (BuildContext context, StateSetter stateSetter) {
                    setState1 = stateSetter;
                    return targetMovedToOverlayEntry3 ? const SizedBox() : OverlayPortal(
                      key: targetGlobalKey,
                      overlayInfo: OverlayInfo.of(context),
                      overlayChild: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                        layoutCount1 += 1;
                        verifyOverlayChildReadyForLayout(targetGlobalKey);
                        return WidgetToRenderBoxAdapter(renderBox: overlayChildBox);
                      }),
                      child: WidgetToRenderBoxAdapter(renderBox: childBox),
                    );
                  }),
                );
              }),
              OverlayEntry(builder: (BuildContext context) => const Placeholder()),
              OverlayEntry(builder: (BuildContext context) {
                return SizedBox(
                  child: StatefulBuilder(builder: (BuildContext context, StateSetter stateSetter) {
                    setState2 = stateSetter;
                    return !targetMovedToOverlayEntry3 ? const SizedBox() : OverlayPortal(
                      key: targetGlobalKey,
                      overlayInfo: OverlayInfo.of(context),
                      overlayChild: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                        layoutCount2 += 1;
                        verifyOverlayChildReadyForLayout(targetGlobalKey);
                        return WidgetToRenderBoxAdapter(renderBox: overlayChildBox);
                      }),
                      child: WidgetToRenderBoxAdapter(renderBox: childBox),
                    );
                  }),
                );
              }),
            ],
          ),
        ),
      );

      expect(layoutCount1, 1);
      expect(layoutCount2, 0);

      targetGlobalKey.currentContext!.findRenderObject()!.markNeedsLayout();
      childBox.markNeedsLayout();
      rebuildLayoutBuilderSubtree(overlayChildBox);
      setState1(() {});
      setState2(() {});
      targetMovedToOverlayEntry3 = true;

      await tester.pump();

      expect(
        targetGlobalKey.currentContext!.findRenderObject()!.depth,
        lessThan(overlayChildBox.depth),
      );
      verifyTreeIsClean();
      expect(layoutCount1, 1);
      expect(layoutCount2, 1);
    });

    testWidgets('child is laid out before overlay child after reparenting to a different overlay', (WidgetTester tester) async {
      final GlobalKey outerOverlayKey = GlobalKey(debugLabel: 'Outer Overlay');
      final GlobalKey innerOverlayKey = GlobalKey(debugLabel: 'Inner Overlay');
      final GlobalKey targetGlobalKey = GlobalKey(debugLabel: 'target widget');
      final RenderBox childBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
      final RenderBox overlayChildBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());

      late StateSetter setState1, setState2;
      int layoutCount1 = 0;
      int layoutCount2 = 0;
      bool targetMovedToOverlayEntry3 = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            key: outerOverlayKey,
            initialEntries: <OverlayEntry>[
              OverlayEntry(builder: (BuildContext context) {
                return _ManyRelayoutBoundaries(
                  levels: 50,
                  child: StatefulBuilder(builder: (BuildContext context, StateSetter stateSetter) {
                    setState1 = stateSetter;
                    return targetMovedToOverlayEntry3 ? const SizedBox() : OverlayPortal(
                      key: targetGlobalKey,
                      overlayInfo: OverlayInfo.of(context),
                      overlayChild: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                        layoutCount1 += 1;
                        verifyOverlayChildReadyForLayout(targetGlobalKey);
                        return WidgetToRenderBoxAdapter(renderBox: overlayChildBox);
                      }),
                      child: WidgetToRenderBoxAdapter(renderBox: childBox),
                    );
                  }),
                );
              }),
              OverlayEntry(builder: (BuildContext context) => const Placeholder()),
              OverlayEntry(builder: (BuildContext context) {
                return Overlay(
                  key: innerOverlayKey,
                  initialEntries: <OverlayEntry>[
                    OverlayEntry(builder: (BuildContext context) {
                      return StatefulBuilder(builder: (BuildContext context, StateSetter stateSetter) {
                        setState2 = stateSetter;
                        return !targetMovedToOverlayEntry3 ? const SizedBox() : OverlayPortal(
                          key: targetGlobalKey,
                          overlayInfo: OverlayInfo.of(context),
                          overlayChild: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                            layoutCount2 += 1;
                            verifyOverlayChildReadyForLayout(targetGlobalKey);
                            return WidgetToRenderBoxAdapter(renderBox: overlayChildBox);
                          }),
                          child: WidgetToRenderBoxAdapter(renderBox: childBox),
                        );
                      });
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      );

      expect(layoutCount1, 1);
      expect(layoutCount2, 0);

      childBox.markNeedsLayout();
      rebuildLayoutBuilderSubtree(overlayChildBox);

      expect(
        targetGlobalKey.currentContext!.findRenderObject()!.depth,
        lessThan(overlayChildBox.depth),
      );

      setState1(() {});
      setState2(() {});
      // Reparent a nested overlay.
      targetMovedToOverlayEntry3 = true;

      await tester.pump();
      verifyTreeIsClean();
      expect(layoutCount1, 1);
      expect(layoutCount2, 1);
      expect(
        overlayChildBox,
        _isDescendantRenderObjectOf(ancestor: innerOverlayKey.currentContext!.findRenderObject()!),
      );
      expect(
        childBox,
        _isDescendantRenderObjectOf(ancestor: innerOverlayKey.currentContext!.findRenderObject()!),
      );
      expect(
        find.descendant(
          of:find.byKey(innerOverlayKey),
          matching: find.byWidgetPredicate((Widget widget) => widget is WidgetToRenderBoxAdapter && widget.renderBox == overlayChildBox),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'child is laid out before overlay child after reparenting to a different overlay and remove the overlay child',
      (WidgetTester tester) async {
        final GlobalKey targetGlobalKey = GlobalKey(debugLabel: 'target widget');
        final RenderBox childBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
        final RenderBox overlayChildBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());

        late StateSetter setState1, setState2;
        bool targetMovedToOverlayEntry3 = false;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(
              initialEntries: <OverlayEntry>[
                OverlayEntry(builder: (BuildContext context) {
                  return _ManyRelayoutBoundaries(
                    levels: 50,
                    child: StatefulBuilder(builder: (BuildContext context, StateSetter stateSetter) {
                      setState1 = stateSetter;
                      return targetMovedToOverlayEntry3 ? const SizedBox() : OverlayPortal(
                        key: targetGlobalKey,
                        overlayInfo: OverlayInfo.of(context),
                        overlayChild: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                          verifyOverlayChildReadyForLayout(targetGlobalKey);
                          return WidgetToRenderBoxAdapter(renderBox: overlayChildBox);
                        }),
                        child: WidgetToRenderBoxAdapter(renderBox: childBox),
                      );
                    }),
                  );
                }),
                OverlayEntry(builder: (BuildContext context) => const Placeholder()),
                OverlayEntry(builder: (BuildContext context) {
                  return Overlay(
                    initialEntries: <OverlayEntry>[
                      OverlayEntry(builder: (BuildContext context) {
                        return StatefulBuilder(builder: (BuildContext context, StateSetter stateSetter) {
                          setState2 = stateSetter;
                          return !targetMovedToOverlayEntry3 ? const SizedBox() : OverlayPortal(
                            key: targetGlobalKey,
                            overlayInfo: OverlayInfo.of(context),
                            overlayChild: null,
                            child: WidgetToRenderBoxAdapter(renderBox: childBox),
                          );
                        });
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        );

        childBox.markNeedsLayout();
        rebuildLayoutBuilderSubtree(overlayChildBox);
        // Make sure childBox's depth is greater than that of the overlay child.
        expect(targetGlobalKey.currentContext!.findRenderObject()!.depth, lessThan(overlayChildBox.depth));
        assert(childBox.debugNeedsLayout);
        // childBox is a relayout boundary.
        assert(!(childBox.parent! as RenderObject).debugNeedsLayout);
        setState1(() {});
        setState2(() {});
        // Reparent a nested overlay.
        targetMovedToOverlayEntry3 = true;

        await tester.pump();
        verifyTreeIsClean();
    });

    testWidgets('Swap child and overlayChild', (WidgetTester tester) async {
      final RenderBox childBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
      final RenderBox overlayChildBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());

      late StateSetter setState;
      bool swapChildAndRemoteChild = false;

      // WidgetToRenderBoxAdapter has its own builtin GlobalKey.
      final Widget child1 = WidgetToRenderBoxAdapter(renderBox: overlayChildBox);
      final Widget child2 = WidgetToRenderBoxAdapter(renderBox: childBox);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(builder: (BuildContext context) {
                return _ManyRelayoutBoundaries(
                  levels: 50,
                  child: StatefulBuilder(builder: (BuildContext context, StateSetter stateSetter) {
                    setState = stateSetter;
                    return OverlayPortal(
                      overlayInfo: OverlayInfo.of(context),
                      overlayChild: swapChildAndRemoteChild ? child1 : child2,
                      child: swapChildAndRemoteChild ? child2 : child1,
                    );
                  }),
                );
              }),
            ],
          ),
        ),
      );

      setState(() { swapChildAndRemoteChild = true; });
      await tester.pump();
      verifyTreeIsClean();
    });

    testWidgets('forgotChild', (WidgetTester tester) async {
      final RenderBox childBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
      final RenderBox overlayChildBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());

      late StateSetter setState1;
      late StateSetter setState2;
      bool takeChildren = false;

      // WidgetToRenderBoxAdapter has its own builtin GlobalKey.
      final Widget child1 = WidgetToRenderBoxAdapter(renderBox: overlayChildBox);
      final Widget child2 = WidgetToRenderBoxAdapter(renderBox: childBox);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(builder: (BuildContext context) {
                return StatefulBuilder(builder: (BuildContext context, StateSetter stateSetter) {
                  setState2 = stateSetter;
                  return OverlayPortal(
                    overlayInfo: OverlayInfo.of(context),
                    overlayChild: takeChildren ? child2 : null,
                    child: takeChildren ? child1 : null,
                  );
                });
              }),
              OverlayEntry(builder: (BuildContext context) {
                return _ManyRelayoutBoundaries(
                  levels: 50,
                  child: StatefulBuilder(builder: (BuildContext context, StateSetter stateSetter) {
                    setState1 = stateSetter;
                    return OverlayPortal(
                      overlayInfo: OverlayInfo.of(context),
                      overlayChild: takeChildren ? null : child1,
                      child: takeChildren ? null : child2,
                    );
                  }),
                );
              }),
            ],
          ),
        ),
      );

      setState2(() { takeChildren = true; });
      setState1(() { });
      await tester.pump();
      verifyTreeIsClean();
    });

    testWidgets('Nested OverlayWidget: swap inner and outer', (WidgetTester tester) async {
      final GlobalKey outerKey = GlobalKey(debugLabel: 'Original Outer Widget');
      final GlobalKey innerKey = GlobalKey(debugLabel: 'Original Inner Widget');

      final RenderBox child1Box = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
      final RenderBox child2Box = RenderConstrainedBox(additionalConstraints: const BoxConstraints());
      final RenderBox overlayChildBox = RenderConstrainedBox(additionalConstraints: const BoxConstraints());

      late StateSetter setState;
      bool swapped = false;

      // WidgetToRenderBoxAdapter has its own builtin GlobalKey.
      final Widget child1 = WidgetToRenderBoxAdapter(renderBox: child1Box);
      final Widget child2 = WidgetToRenderBoxAdapter(renderBox: child2Box);
      final Widget child3 = WidgetToRenderBoxAdapter(renderBox: overlayChildBox);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(builder: (BuildContext context) {
                return StatefulBuilder(builder: (BuildContext context, StateSetter stateSetter) {
                  setState = stateSetter;
                  return OverlayPortal(
                    key: swapped ? outerKey : innerKey,
                    overlayInfo: OverlayInfo.of(context),
                    overlayChild: Builder(builder: (BuildContext context) {
                      return OverlayPortal(
                        key: swapped ? innerKey : outerKey,
                        overlayInfo: OverlayInfo.of(context),
                        overlayChild: OverlayPortal(
                          overlayInfo: OverlayInfo.of(context),
                          child: null,
                          overlayChild: child3,
                        ),
                        child: child2,
                      );
                    }),
                    child: child1,
                  );
                });
              }),
            ],
          ),
        ),
      );

      setState(() { swapped = true; });
      await tester.pump();
      verifyTreeIsClean();
    });

    group('Swapping', () {
      StateSetter? setState1, setState2;
      bool swapped = false;

      void setState({ required bool newValue }) {
        swapped = newValue;
        setState1?.call(() {});
        setState2?.call(() {});
      }

      tearDown(() {
        swapped = false;
        setState1 = null;
        setState2 = null;
      });

      testWidgets('between OverlayEntry & overlayChild', (WidgetTester tester) async {
        final _RenderLayoutCounter counter1 = _RenderLayoutCounter();
        final _RenderLayoutCounter counter2 = _RenderLayoutCounter();

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(
              initialEntries: <OverlayEntry>[
                OverlayStatefulEntry(builder: (BuildContext context, StateSetter stateSetter) {
                  setState1 = stateSetter;
                  // WidgetToRenderBoxAdapter is keyed by the render box.
                  return WidgetToRenderBoxAdapter(renderBox: swapped ? counter2 : counter1);
                }),
                OverlayStatefulEntry(builder: (BuildContext context, StateSetter stateSetter) {
                  setState2 = stateSetter;
                  return OverlayPortal(
                    overlayInfo: OverlayInfo.of(context),
                    overlayChild: WidgetToRenderBoxAdapter(renderBox: swapped ? counter1 : counter2),
                    child: const SizedBox(),
                  );
                }),
              ],
            ),
          ),
        );

        expect(counter1.layoutCount, 1);
        expect(counter2.layoutCount, 1);

        setState(newValue: true);
        await tester.pump();

        expect(counter1.layoutCount, 2);
        expect(counter2.layoutCount, 2);

        setState(newValue: false);
        await tester.pump();

        expect(counter1.layoutCount, 3);
        expect(counter2.layoutCount, 3);
      });

      testWidgets('between OverlayEntry & overlayChild, featuring LayoutBuilder', (WidgetTester tester) async {
        final _RenderLayoutCounter counter1 = _RenderLayoutCounter();
        final _RenderLayoutCounter counter2 = _RenderLayoutCounter();

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(
              initialEntries: <OverlayEntry>[
                OverlayStatefulEntry(builder: (BuildContext context, StateSetter stateSetter) {
                  setState1 = stateSetter;
                  return  WidgetToRenderBoxAdapter(renderBox: swapped ? counter2 : counter1);
                }),
                OverlayStatefulEntry(builder: (BuildContext context, StateSetter stateSetter) {
                  setState2 = stateSetter;
                  return LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return OverlayPortal(
                        overlayInfo: OverlayInfo.of(context),
                        overlayChild: WidgetToRenderBoxAdapter(renderBox: swapped ? counter1 : counter2),
                        child: const SizedBox(),
                      );
                    }
                  );
                }),
              ],
            ),
          ),
        );

        expect(counter1.layoutCount, 1);
        expect(counter2.layoutCount, 1);

        setState(newValue: true);
        await tester.pump();

        expect(counter1.layoutCount, 2);
        expect(counter2.layoutCount, 2);

        setState(newValue: false);
        await tester.pump();

        expect(counter1.layoutCount, 3);
        expect(counter2.layoutCount, 3);
      });

      testWidgets('between overlayChild & overlayChild', (WidgetTester tester) async {
        final _RenderLayoutCounter counter1 = _RenderLayoutCounter();
        final _RenderLayoutCounter counter2 = _RenderLayoutCounter();

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(
              initialEntries: <OverlayEntry>[
                OverlayStatefulEntry(builder: (BuildContext context, StateSetter stateSetter) {
                  setState1 = stateSetter;
                  return OverlayPortal(
                    overlayInfo: OverlayInfo.of(context),
                    // WidgetToRenderBoxAdapter is keyed by the render box.
                    overlayChild: WidgetToRenderBoxAdapter(renderBox: swapped ? counter2 : counter1),
                    child: const SizedBox(),
                  );
                }),
                OverlayStatefulEntry(builder: (BuildContext context, StateSetter stateSetter) {
                  setState2 = stateSetter;
                  return OverlayPortal(
                    overlayInfo: OverlayInfo.of(context),
                    overlayChild: WidgetToRenderBoxAdapter(renderBox: swapped ? counter1 : counter2),
                    child: const SizedBox(),
                  );
                }),
              ],
            ),
          ),
        );

        expect(counter1.layoutCount, 1);
        expect(counter2.layoutCount, 1);

        setState(newValue: true);
        await tester.pump();

        expect(counter1.layoutCount, 2);
        expect(counter2.layoutCount, 2);

        setState(newValue: false);
        await tester.pump();

        expect(counter1.layoutCount, 3);
        expect(counter2.layoutCount, 3);
      });

      testWidgets('between overlayChild & overlayChild, featuring LayoutBuilder', (WidgetTester tester) async {
        final _RenderLayoutCounter counter1 = _RenderLayoutCounter();
        final _RenderLayoutCounter counter2 = _RenderLayoutCounter();

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(
              initialEntries: <OverlayEntry>[
                OverlayStatefulEntry(builder: (BuildContext context, StateSetter stateSetter) {
                  setState1 = stateSetter;
                  return LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return OverlayPortal(
                        overlayInfo: OverlayInfo.of(context),
                        overlayChild: WidgetToRenderBoxAdapter(renderBox: swapped ? counter2 : counter1),
                        child: const SizedBox(),
                      );
                    }
                  );
                }),
                OverlayStatefulEntry(builder: (BuildContext context, StateSetter stateSetter) {
                  setState2 = stateSetter;
                  return LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return OverlayPortal(
                        overlayInfo: OverlayInfo.of(context),
                        overlayChild: WidgetToRenderBoxAdapter(renderBox: swapped ? counter1 : counter2),
                        child: const SizedBox(),
                      );
                    }
                  );
                }),
              ],
            ),
          ),
        );

        expect(counter1.layoutCount, 1);
        expect(counter2.layoutCount, 1);

        setState(newValue: true);
        await tester.pump();

        expect(counter1.layoutCount, 2);
        expect(counter2.layoutCount, 2);

        setState(newValue: false);
        await tester.pump();

        expect(counter1.layoutCount, 3);
        expect(counter2.layoutCount, 3);
      });

      testWidgets('between child & overlayChild', (WidgetTester tester) async {
        final _RenderLayoutCounter counter1 = _RenderLayoutCounter();
        final _RenderLayoutCounter counter2 = _RenderLayoutCounter();

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(
              initialEntries: <OverlayEntry>[
                OverlayStatefulEntry(builder: (BuildContext context, StateSetter stateSetter) {
                  setState1 = stateSetter;
                  return OverlayPortal(
                    overlayInfo: OverlayInfo.of(context),
                    // WidgetToRenderBoxAdapter is keyed by the render box.
                    overlayChild: WidgetToRenderBoxAdapter(renderBox: swapped ? counter2 : counter1),
                    child: WidgetToRenderBoxAdapter(renderBox: swapped ? counter1 : counter2),
                  );
                }),
              ],
            ),
          ),
        );

        expect(counter1.layoutCount, 1);
        expect(counter2.layoutCount, 1);

        setState(newValue: true);
        await tester.pump();

        expect(counter1.layoutCount, 2);
        expect(counter2.layoutCount, 2);

        setState(newValue: false);
        await tester.pump();

        expect(counter1.layoutCount, 3);
        expect(counter2.layoutCount, 3);
      });

      testWidgets('between child & overlayChild, featuring LayoutBuilder', (WidgetTester tester) async {
        final _RenderLayoutCounter counter1 = _RenderLayoutCounter();
        final _RenderLayoutCounter counter2 = _RenderLayoutCounter();

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(
              initialEntries: <OverlayEntry>[
                OverlayStatefulEntry(builder: (BuildContext context, StateSetter stateSetter) {
                  setState1 = stateSetter;
                  return LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return OverlayPortal(
                        overlayInfo: OverlayInfo.of(context),
                        // WidgetToRenderBoxAdapter is keyed by the render box.
                        overlayChild: WidgetToRenderBoxAdapter(renderBox: swapped ? counter2 : counter1),
                        child: WidgetToRenderBoxAdapter(renderBox: swapped ? counter1 : counter2),
                      );
                    }
                  );
                }),
              ],
            ),
          ),
        );

        expect(counter1.layoutCount, 1);
        expect(counter2.layoutCount, 1);

        setState(newValue: true);
        await tester.pump();

        expect(counter1.layoutCount, 2);
        expect(counter2.layoutCount, 2);

        setState(newValue: false);
        await tester.pump();

        expect(counter1.layoutCount, 3);
        expect(counter2.layoutCount, 3);
      });
    });
  });
}

class OverlayStatefulEntry extends OverlayEntry {
  OverlayStatefulEntry({
    required StatefulWidgetBuilder builder,
  }) : super(builder: (BuildContext context) => StatefulBuilder(builder: builder));
}

class _RenderLayoutCounter extends RenderProxyBox {
  int layoutCount = 0;
  bool _parentDoingLayout = false;
  @override
  void layout(Constraints constraints, {bool parentUsesSize = false}) {
    assert(!_parentDoingLayout);
    _parentDoingLayout = true;
    layoutCount += 1;
    super.layout(constraints, parentUsesSize: parentUsesSize);
    _parentDoingLayout = false;
  }

  @override
  void performLayout() {
    super.performLayout();
    if (!_parentDoingLayout) {
      layoutCount += 1;
    }
  }
}
