// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

/// An [OverlayEntry] that allows an [Conduit] to display and manage
/// its [Conduit.remoteChildBuilder]'s visual content on.
///
/// When given an [ProxyOverlayEntry], an [Conduit] will attach the render
/// object of its [Conduit.remoteChildBuilder] to the [ProxyOverlayEntry]'s [mountPoint].
///
/// See also:
///
/// * [Conduit], the widget that displays and manages the visual content
///   of its [Conduit.remoteChildBuilder] on the given [ProxyOverlayEntry] .
class ProxyOverlayEntry extends OverlayEntry {
  /// Creates a [ProxyOverlayEntry] that allows an [Conduit] to attach its
  /// `overlayItem`'s render object to.
  ProxyOverlayEntry({
    bool opaque = false,
    bool maintainState = false,
  }) : this._(key: AnchorKey(), opaque: opaque, maintainState: maintainState);

  ProxyOverlayEntry._({
    AnchorKey key,
    bool opaque = false,
    bool maintainState = false,
  }) : mountPointKey = key,
       super(
         builder: (BuildContext context) => ConduitAnchor(key: key),
         opaque: opaque,
         maintainState: maintainState,
       );

  final AnchorKey mountPointKey;

  /// The element whose render object will be the parent of [Conduit.remoteChildBuilder]'s
  /// render object.
  LeafRenderObjectElement get mountPointElement => mountPointKey.currentContext;

  RenderProxyBox get mountRenderObject => mountPointElement?.renderObject as RenderProxyBox;
}

Widget conduitWithEntry({
  Key key,
  Widget remoteChild,
  ProxyOverlayEntry overlayEntry,
  Widget child,
}) {
  return Conduit(
    key: key,
    remoteChildBuilder: overlayEntry == null
      ? null
      : (BuildContext context, BoxConstraints constraints) => remoteChild,
    remoteKey: overlayEntry?.mountPointKey,
    child: child,
  );
}

void main() {
  testWidgets(
    'remote child inherits from the right BuildContext',
    (WidgetTester tester) async {
      final ProxyOverlayEntry proxyEntry = ProxyOverlayEntry();
      const MediaQueryData data = MediaQueryData(textScaleFactor: 1234.567);

      MediaQueryData mediaQueryForChild;
      MediaQueryData mediaQueryForRemoteChild;

      StateSetter stateSetter;
      bool hasEntry = true;

      final OverlayEntry entry = OverlayEntry(
        builder: (BuildContext context) {
          return MediaQuery(
            data: data,
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setter) {
              stateSetter = setter;
              return conduitWithEntry(
                child: Builder(builder: (BuildContext context) {
                  mediaQueryForChild = MediaQuery.of(context);
                  return const Placeholder();
                }),
                overlayEntry: hasEntry ? proxyEntry : null,
                remoteChild: hasEntry
                  ? Builder(builder: (BuildContext context) {
                      mediaQueryForRemoteChild = MediaQuery.of(context);
                      return const Placeholder();
                    })
                  : null,
              );
            }),
          );
        }
      );

      await tester.pumpWidget(withDirectionality(<OverlayEntry>[entry, proxyEntry]));

      expect(mediaQueryForChild, data);
      expect(mediaQueryForRemoteChild, data);

      mediaQueryForRemoteChild = null;
      mediaQueryForChild = null;

      // Remove overlay.
      stateSetter(() { hasEntry = false; });
      proxyEntry.remove();

      await tester.pump();
      expect(mediaQueryForChild, data);
      expect(mediaQueryForRemoteChild, null);

      mediaQueryForRemoteChild = null;
      mediaQueryForChild = null;

      // Add the overlay back.
      stateSetter(() { hasEntry = true; });
      overlayKey.currentState.insert(proxyEntry);

      await tester.pump();
      expect(mediaQueryForChild, data);
      expect(mediaQueryForRemoteChild, data);
  });

  testWidgets('Can dock to descendant and see the right dependencies', (WidgetTester tester) async {
    final AnchorKey key = AnchorKey();
    TextDirection seenByRemoteChild;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Conduit(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ConduitAnchor(key: key),
          ),
          remoteKey: key,
          remoteChildBuilder: (BuildContext context, BoxConstraints constraints) {
            seenByRemoteChild = Directionality.of(context);
            return const Placeholder();
          },
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(seenByRemoteChild, TextDirection.ltr);
  });

  //testWidgets('Throws if there is a cycle', (WidgetTester tester) async {
  //  final AnchorKey key = AnchorKey();

  //  await tester.pumpWidget(
  //    Conduit(
  //      remoteKey: key,
  //      remoteChildBuilder: (BuildContext context, BoxConstraints constraints) {
  //        return SizedBox(child: ConduitAnchor(key: key));
  //      }),
  //  );

  //  expect(tester.takeException().toString(), contains('node != child'));
  //});

  testWidgets('Can have a barebone Conduit', (WidgetTester tester) async {
    await tester.pumpWidget(const Conduit());

    expect(tester.takeException(), isNull);
  });

  testWidgets('Regular child global key reparenting forgetChild', (WidgetTester tester) async {
      final Widget keyedChild = Placeholder(key: GlobalKey());

      await tester.pumpWidget(
        Column(children: <Widget>[Conduit(child: keyedChild)]),
      );

      await tester.pumpWidget(
        Column(children: <Widget>[
          keyedChild,
          const Conduit(),
        ]),
      );

      expect(tester.takeException(), isNull);
  });

  testWidgets(
    "Which OverlayEntry gets built first doesn't matter.",
    (WidgetTester tester) async {
      final ProxyOverlayEntry proxyEntry = ProxyOverlayEntry();
      const MediaQueryData data = MediaQueryData(textScaleFactor: 1234.567);

      MediaQueryData mediaQueryForChild;
      MediaQueryData mediaQueryForRemoteChild;

      final OverlayEntry entry = OverlayEntry(
        builder: (BuildContext context) {
          return MediaQuery(
            data: data,
            child: conduitWithEntry(
              child: Builder(builder: (BuildContext context) {
                mediaQueryForChild = MediaQuery.of(context);
                return const Placeholder();
              }),
              overlayEntry: proxyEntry,
              remoteChild: Builder(builder: (BuildContext context) {
                mediaQueryForRemoteChild = MediaQuery.of(context);
                return const Placeholder();
              }),
            ),
          );
        }
      );

      await tester.pumpWidget(withDirectionality(<OverlayEntry>[proxyEntry, entry]));

      expect(mediaQueryForChild, data);
      expect(mediaQueryForRemoteChild, data);
  });

  testWidgets(
    'Replacing the overlayItem replaces the renderObject',
    (WidgetTester tester) async {
      final ProxyOverlayEntry proxyEntry = ProxyOverlayEntry();
      final AnchorKey anchorKey = proxyEntry.mountPointKey;

      bool buildDifferently = false;
      StateSetter stateSetter;

      final OverlayEntry entry = OverlayEntry(
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setter) {
              stateSetter = setter;
              return Conduit(
                child: const SizedBox(),
                remoteChildBuilder: (BuildContext context, BoxConstraints constraints) {
                  return buildDifferently ? const SizedBox() : const Placeholder();
                },
                remoteKey: anchorKey,
              );
            },
          );
        },
      );

      await tester.pumpWidget(withDirectionality(<OverlayEntry>[proxyEntry, entry]));

      expect(find.byType(Placeholder), findsOneWidget);
      // Placeholder's render object is attached.
      final RenderObject oldRenderObject = proxyEntry?.mountRenderObject?.child;
      expect(oldRenderObject, isNotNull);

      stateSetter(() { buildDifferently = true; });
      await tester.pump();

      expect(find.byType(Placeholder), findsNothing);
      // Placeholder's render object is removed.
      expect(proxyEntry.mountRenderObject.child, isNotNull);
      expect(proxyEntry.mountRenderObject.child.runtimeType, isNot(oldRenderObject.runtimeType));
      expect(oldRenderObject.parent, isNull);
  });

  testWidgets(
    'Removing the overlayItem removes the renderObject',
    (WidgetTester tester) async {
      final ProxyOverlayEntry proxyEntry = ProxyOverlayEntry();

      bool buildDifferently = false;
      StateSetter stateSetter;

      final OverlayEntry entry = OverlayEntry(
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setter) {
              stateSetter = setter;
              return Conduit(
                child: const SizedBox(),
                remoteKey: proxyEntry.mountPointKey,
                remoteChildBuilder: buildDifferently
                  ? null
                  : (BuildContext context, BoxConstraints constraints) => const Placeholder(),
              );
            },
          );
        },
      );

      await tester.pumpWidget(withDirectionality(<OverlayEntry>[proxyEntry, entry]));

      expect(find.byType(Placeholder), findsOneWidget);
      // Placeholder's render object is attached.
      expect(proxyEntry.mountRenderObject.child, isNotNull);

      stateSetter(() { buildDifferently = true; });
      await tester.pump();

      expect(find.byType(Placeholder), findsNothing);
      // Placeholder's render object is removed.
      expect(proxyEntry.mountRenderObject.child, isNull);
  });

  testWidgets(
    'Nested Conduits',
    (WidgetTester tester) async {
      final List<ProxyOverlayEntry> proxyEntry = List<ProxyOverlayEntry>.generate(4, (int i) => ProxyOverlayEntry());
      const MediaQueryData data = MediaQueryData(textScaleFactor: 1234.567);

      MediaQueryData mediaQueryForRemoteChild;

      final OverlayEntry entry = OverlayEntry(
        builder: (BuildContext context) {
          return MediaQuery(
            data: data,
            child: conduitWithEntry(
              child: const Placeholder(),
              overlayEntry: proxyEntry[3],
              remoteChild: conduitWithEntry(
                child: const Placeholder(),
                overlayEntry: proxyEntry[2],
                remoteChild: conduitWithEntry(
                  child: const Placeholder(),
                  overlayEntry: proxyEntry[1],
                  remoteChild: conduitWithEntry(
                    child: const Placeholder(),
                    overlayEntry: proxyEntry[0],
                    remoteChild: Builder(builder: (BuildContext context) {
                      mediaQueryForRemoteChild = MediaQuery.of(context);
                      return const Placeholder();
                    }),
                  ),
                ),
              ),
            ),
          );
        },
      );

      await tester.pumpWidget(withDirectionality(<OverlayEntry>[entry, ...proxyEntry.reversed]));

      expect(mediaQueryForRemoteChild, data);
      expect(find.byType(Placeholder), findsNWidgets(5));

      for (final ProxyOverlayEntry e in proxyEntry) {
        expect(e.mountRenderObject.child, isNotNull);
      }
  });

  testWidgets('Conduit ListView interaction', (WidgetTester tester) async {
    final ProxyOverlayEntry proxyEntry = ProxyOverlayEntry();

    final ScrollController controller1 = ScrollController();
    final ScrollController controller2 = ScrollController();

    final ListView overlayListView = ListView(
      controller: controller2,
      children: <Widget>[Container(height: 5000)],
    );


    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) {
        return ListView(
          controller: controller1,
          children: <Widget>[
            conduitWithEntry(
              // Make the height non-zero so the widget will be onstage.
              child: const SizedBox(height: 10),
              overlayEntry: proxyEntry,
              remoteChild: overlayListView,
            ),
            Container(height: 4000),
          ],
        );
      },
    );

    await tester.pumpWidget(withDirectionality(<OverlayEntry>[entry, proxyEntry]));

    // Placeholder's render object is attached.
    expect(proxyEntry.mountRenderObject.child, isNotNull);
    await tester.fling(find.byWidget(overlayListView), const Offset(0, -100), 100);
    await tester.pumpAndSettle();

    expect(controller2.offset, 100);

    // Scroll so the Conduit gets garbage collected.
    controller1.jumpTo(3000);
    await tester.pumpAndSettle();

    // Placeholder's render object is removed.
    expect(proxyEntry.mountRenderObject.child, isNull);
  });

  testWidgets(
    'remote child works with localToGlobal',
    (WidgetTester tester) async {
      final List<ProxyOverlayEntry> proxyEntry = List<ProxyOverlayEntry>.generate(4, (int i) => ProxyOverlayEntry());
      const Key childKey = Key('child');
      const Key itemKey = Key('item');

      final OverlayEntry entry = OverlayEntry(
        builder: (BuildContext context) {
          return conduitWithEntry(
            child: const Placeholder(),
            overlayEntry: proxyEntry[3],
            remoteChild: Padding(
              padding: const EdgeInsets.only(left: 10, top: 20),
              child: conduitWithEntry(
                child: const Placeholder(),
                overlayEntry: proxyEntry[2],
                remoteChild: conduitWithEntry(
                  child: const Placeholder(),
                  overlayEntry: proxyEntry[1],
                  remoteChild: conduitWithEntry(
                    child: const Placeholder(key: childKey),
                    overlayEntry: proxyEntry[0],
                    remoteChild: const Padding(
                      padding: EdgeInsets.only(left: 30, top: 50),
                      child: Padding(child: SizedBox(key: itemKey), padding: EdgeInsets.all(3)),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      await tester.pumpWidget(withDirectionality(<OverlayEntry>[entry, ...proxyEntry]));
      final RenderBox child = tester.renderObject(find.byKey(childKey));
      final RenderBox item = tester.renderObject(find.byKey(itemKey));

      expect(item.localToGlobal(Offset.zero), const Offset(33, 53));
      expect(child.localToGlobal(Offset.zero), Offset.zero);
  });

  testWidgets('Remote child can use Positioned', (WidgetTester tester) async {
    final AnchorKey key = AnchorKey();

    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) {
        return Conduit(
          child: const SizedBox(),
          remoteKey: key,
          remoteChildBuilder: (BuildContext context, BoxConstraints constriants) => const Placeholder(),
        );
      }
    );

    await tester.pumpWidget(withDirectionality(<OverlayEntry>[
      entry,
      OverlayEntry(builder: (BuildContext context) {
        return Positioned(
          width: 30,
          height: 30,
          child: ConduitAnchor(key: key),
        );
      }),
    ]));

    expect(tester.getTopLeft(find.byType(Placeholder)), Offset.zero) ;
    expect(tester.getSize(find.byType(Placeholder)), const Size(30, 30)) ;
  });

  group('GlobalKey reparenting', () {
    testWidgets(
      'Basic Conduit reparenting',
      (WidgetTester tester) async {
        final ProxyOverlayEntry proxyEntry = ProxyOverlayEntry();
        const MediaQueryData data = MediaQueryData(textScaleFactor: 1234.567);

        MediaQueryData mediaQueryForChild;
        MediaQueryData mediaQueryForRemoteChild;

        final Key gk = GlobalKey();

        // If true, change the tree depth so global key reparenting takes place.
        bool buildDifferently = false;
        StateSetter stateSetter;

        final OverlayEntry entry = OverlayEntry(
          builder: (BuildContext context) {
            return MediaQuery(
              data: data,
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setter) {
                  stateSetter = setter;
                  final Widget subtree = conduitWithEntry(
                    key: gk,
                    child: Builder(builder: (BuildContext context) {
                      mediaQueryForChild = MediaQuery.of(context);
                      return const Placeholder();
                    }),
                    overlayEntry: proxyEntry,
                    remoteChild: Builder(builder: (BuildContext context) {
                      mediaQueryForRemoteChild = MediaQuery.of(context);
                      return const Placeholder();
                    }),
                  );

                  return buildDifferently ? Container(child: subtree) : subtree;
                },
              ),
            );
          },
        );

        await tester.pumpWidget(withDirectionality(<OverlayEntry>[entry, proxyEntry]));

        expect(mediaQueryForChild, data);
        expect(mediaQueryForRemoteChild, data);

        // Reparent the entire Conduit.
        stateSetter(() { buildDifferently = true; });
        await tester.pump();

        //expect(tester.takeException(), null);
        expect(mediaQueryForChild, data);
        expect(mediaQueryForRemoteChild, data);
    });

    testWidgets('reparent Conduit but also remove overlayItem', (WidgetTester tester) async {
      final ProxyOverlayEntry proxyEntry = ProxyOverlayEntry();

      bool shouldReparent = false;

      final Key globalKey = GlobalKey();
      StateSetter stateSetter;

      final OverlayEntry entry = OverlayEntry(
        builder: (BuildContext context) {
          final Widget subtree = StatefulBuilder(
            builder: (BuildContext context, StateSetter setter) {
              stateSetter = setter;
              return conduitWithEntry(
                key: globalKey,
                child: const Placeholder(),
                overlayEntry: proxyEntry,
                remoteChild: shouldReparent ? Container() : const Placeholder(),
              );
            },
          );
          return shouldReparent ? Container(child: subtree) : subtree;
        },
      );

      await tester.pumpWidget(withDirectionality(<OverlayEntry>[entry, proxyEntry]));

      // Reparent
      stateSetter(() { shouldReparent = true; });
      await tester.pump();

      expect(tester.takeException(), null);

      // proxyEntry should no longer have placeholder's render object attached.
      expect(
        find.byType(ConduitAnchor),
        findsNWidgets(1)
      );
      expect(proxyEntry.mountRenderObject.child, isInstanceOf<RenderLimitedBox>());
    });

    testWidgets('providing Conduit with a new overlayEntry throws for now', (WidgetTester tester) async {
      final ProxyOverlayEntry proxyEntry0 = ProxyOverlayEntry();
      final ProxyOverlayEntry proxyEntry1 = ProxyOverlayEntry();

      ProxyOverlayEntry proxyEntryToUse = proxyEntry0;

      final Key gk = GlobalKey();
      StateSetter stateSetter;

      final OverlayEntry entry = OverlayEntry(
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setter) {
              stateSetter = setter;
              return conduitWithEntry(
                key: gk,
                child: const Placeholder(),
                overlayEntry: proxyEntryToUse,
                remoteChild: const Placeholder(),
              );
            },
          );
        },
      );

      await tester.pumpWidget(withDirectionality(<OverlayEntry>[entry, proxyEntry0, proxyEntry1]));

      // Reparent
      proxyEntryToUse = proxyEntry1;
      stateSetter(() {});
      await tester.pump();

      expect(tester.takeException().toString(), contains('oldWidget.remoteKey == newWidget.remoteKey'));
    });

    testWidgets('Reparent Conduit to a different overlay', (WidgetTester tester) async {
      final ProxyOverlayEntry proxyEntry = ProxyOverlayEntry();
      const MediaQueryData data = MediaQueryData(textScaleFactor: 1234.567);

      MediaQueryData mediaQueryForChild;
      MediaQueryData mediaQueryForRemoteChild;

      final Key globalKey = GlobalKey();

      final OverlayEntry entry = OverlayEntry(
        builder: (BuildContext context) {
          return MediaQuery(
            data: data,
            child: conduitWithEntry(
              key: globalKey,
              child: Builder(builder: (BuildContext context) {
                  mediaQueryForChild = MediaQuery.of(context);
                  return const Placeholder();
              }),
              overlayEntry: proxyEntry,
              remoteChild: Builder(builder: (BuildContext context) {
                  mediaQueryForRemoteChild = MediaQuery.of(context);
                  return const Placeholder();
              }),
            ),
          );
        },
      );

      await tester.pumpWidget(withDirectionality(<OverlayEntry>[proxyEntry, entry]));

      expect(mediaQueryForChild, data);
      expect(mediaQueryForRemoteChild, data);
      expect(find.byType(Placeholder), findsNWidgets(2));
      final RenderBox oldRenderProxyBox = proxyEntry.mountRenderObject;

      int calculateDepth(AbstractNode node) => node == null ? 0 : calculateDepth(node.parent) + 1;
      final int oldDepth = calculateDepth(oldRenderProxyBox);

      // Move the Conduit to a different Overlay.
      proxyEntry.remove();
      entry.remove();
      overlayKey.currentState.insert(
        OverlayEntry(builder: (BuildContext context) => Overlay(initialEntries: <OverlayEntry>[entry, proxyEntry])),
      );

      await tester.pump();

      expect(tester.takeException(), null);

      // The same renderObject is still attached to this element.
      expect(oldRenderProxyBox, proxyEntry.mountPointElement.renderObject);
      expect(proxyEntry.mountPointElement.renderObject, isNotNull);
      // It now should have more ancestor nodes.
      expect(oldDepth, isNot(calculateDepth(oldRenderProxyBox)));

      expect(mediaQueryForChild, data);
      expect(mediaQueryForRemoteChild, data);
      expect(find.byType(Placeholder), findsNWidgets(2));
    });

    testWidgets(
      'moving ProxyOverlayEntries around',
      (WidgetTester tester) async {
        final ProxyOverlayEntry proxyEntry = ProxyOverlayEntry();
        const MediaQueryData data = MediaQueryData(textScaleFactor: 1234.567);
        const MediaQueryData innerData = MediaQueryData(textScaleFactor: 567.1234);

        MediaQueryData mediaQueryForChild;
        MediaQueryData mediaQueryForRemoteChild;

        final Key globalKey = GlobalKey();
        final GlobalKey<OverlayState> innerOverlayKey = GlobalKey();

        final OverlayEntry entry = OverlayEntry(
          builder: (BuildContext context) {
            return conduitWithEntry(
              key: globalKey,
              child: Builder(builder: (BuildContext context) {
                mediaQueryForChild = MediaQuery.of(context);
                return const Placeholder();
              }),
              overlayEntry: proxyEntry,
              remoteChild: Builder(builder: (BuildContext context) {
                mediaQueryForRemoteChild = MediaQuery.of(context);
                return const Placeholder();
              }),
            );
          }
        );

        await tester.pumpWidget(
          MediaQuery(
            data: data,
            child: withDirectionality(<OverlayEntry>[
              OverlayEntry(
                builder: (BuildContext context) {
                  return MediaQuery(
                    data: innerData,
                    child: Overlay(
                      key: innerOverlayKey,
                      initialEntries: <OverlayEntry>[entry, proxyEntry]
                    ),
                  );
                },
              ),
            ]),
          ),
        );

        expect(mediaQueryForChild, innerData);
        expect(mediaQueryForRemoteChild, innerData);

        mediaQueryForChild = null;
        mediaQueryForRemoteChild = null;

        // Move proxyEntry back, should still use innerData.
        proxyEntry.remove();
        overlayKey.currentState.insert(proxyEntry);

        await tester.pump();
        expect(mediaQueryForChild, innerData);
        expect(mediaQueryForRemoteChild, innerData);

        // Move proxyEntry back.
        proxyEntry.remove();
        innerOverlayKey.currentState.insert(proxyEntry);
        await tester.pump();
        expect(tester.takeException(), isNull);

        mediaQueryForChild = null;
        mediaQueryForRemoteChild = null;

        // Move entry out this time, now data should be in effect.
        entry.remove();
        overlayKey.currentState.insert(entry);

        await tester.pump();
        expect(tester.takeException(), isNull);

        expect(mediaQueryForChild, data);
        expect(mediaQueryForRemoteChild, data);
    });

    testWidgets(
    'Conduit.child and Conduit.remoteChild swap using GlobalKey',
      (WidgetTester tester) async {
        final ProxyOverlayEntry proxyEntry = ProxyOverlayEntry();

        final Key conduitGlobalKey = GlobalKey();
        final Key globalKey1 = LabeledGlobalKey('child 1');
        final Key globalKey2 = LabeledGlobalKey('child 2');

        Widget subtree = conduitWithEntry(
          key: conduitGlobalKey,
          child: SizedBox(key: globalKey1),
          overlayEntry: proxyEntry,
          remoteChild: SizedBox(key: globalKey2),
        );

        StateSetter stateSetter;

        final OverlayEntry entry = OverlayEntry(
          builder: (BuildContext context) {
            return StatefulBuilder(builder: (BuildContext context, StateSetter setter) {
              stateSetter = setter;
              return subtree;
            });
          },
        );

        await tester.pumpWidget(withDirectionality(<OverlayEntry>[entry, proxyEntry]));
        expect(tester.takeException(), null);

        final RenderObject oldChildRenderObject = tester.renderObject(find.byKey(globalKey1));
        final RenderObject oldRemoteChildRenderObject = tester.renderObject(find.byKey(globalKey2));
        final RenderObject oldChildRenderObjectParent = oldChildRenderObject.parent as RenderObject;
        final RenderObject oldRemoteChildRenderObjectParent = oldRemoteChildRenderObject.parent as RenderObject;

        // Swap overlayItem and child
        subtree = conduitWithEntry(
          key: conduitGlobalKey,
          child: Builder(
            builder: (BuildContext context) => SizedBox(key: globalKey2),
          ),
          overlayEntry: proxyEntry,
          remoteChild: Builder(
            builder: (BuildContext context) => SizedBox(key: globalKey1),
          ),
        );

        stateSetter(() { });
        await tester.pump();

        expect(tester.takeException(), null);

        // Render Objects should be swapped.
        expect(tester.renderObject(find.byKey(globalKey1)), oldChildRenderObject);
        expect(tester.renderObject(find.byKey(globalKey2)), oldRemoteChildRenderObject);

        expect(tester.renderObject(find.byKey(globalKey1)).parent, isNot(oldChildRenderObjectParent));
        expect(tester.renderObject(find.byKey(globalKey2)).parent, isNot(oldRemoteChildRenderObjectParent));

        expect(tester.renderObject(find.byKey(globalKey1)).parent, oldRemoteChildRenderObjectParent);
        expect(tester.renderObject(find.byKey(globalKey2)).parent, oldChildRenderObjectParent);

        // Change height of the tree, no exceptions should be thrown.
        subtree = Container(child: subtree);
        stateSetter(() { });

        await tester.pump();
        expect(tester.takeException(), null);
    });

    testWidgets(
    'Nested Conduits switch orders using GlobalKey',
      (WidgetTester tester) async {
        final ProxyOverlayEntry proxyEntry1 = ProxyOverlayEntry();
        final ProxyOverlayEntry proxyEntry2 = ProxyOverlayEntry();

        const Key child1Key = Key('child1');
        const Key child2Key = Key('child2');
        const Key placeholderKey = Key('placeholder');
        final Key globalKey1 = GlobalKey(debugLabel: 'Global Key 1');
        final Key globalKey2 = GlobalKey(debugLabel: 'Global Key 2');

        Widget subtree = conduitWithEntry(
          key: globalKey1,
          child: const SizedBox(key: child1Key),
          overlayEntry: proxyEntry1,
          remoteChild: conduitWithEntry(
            key: globalKey2,
            child: const Placeholder(key: child2Key),
            overlayEntry: proxyEntry2,
            remoteChild: const Placeholder(key: placeholderKey),
          ),
        );

        StateSetter stateSetter;

        final OverlayEntry entry = OverlayEntry(
          builder: (BuildContext context) {
            return StatefulBuilder(builder: (BuildContext context, StateSetter setter) {
              stateSetter = setter;
              return subtree;
            });
          },
        );

        await tester.pumpWidget(withDirectionality(<OverlayEntry>[entry, proxyEntry1, proxyEntry2]));
        expect(tester.takeException(), null);

        final RenderObject oldChild1RenderObject = tester.renderObject(find.byKey(child1Key));
        final RenderObject oldChild2RenderObject = tester.renderObject(find.byKey(child2Key));
        final RenderObject oldConduit1RenderObject = tester.renderObject(find.byKey(globalKey1));
        final RenderObject oldConduit2RenderObject = tester.renderObject(find.byKey(globalKey2));
        final RenderObject placeholderRenderObject = tester.renderObject(find.byKey(placeholderKey));

        final RenderObject oldChild1RenderObjectParent = oldChild1RenderObject.parent as RenderObject;
        final RenderObject oldChild2RenderObjectParent = oldChild2RenderObject.parent as RenderObject;
        final RenderObject oldConduit1RenderObjectParent = oldConduit1RenderObject.parent as RenderObject;
        final RenderObject oldConduit2RenderObjectParent = oldConduit2RenderObject.parent as RenderObject;
        final RenderObject placeholderRenderObjectParent = placeholderRenderObject.parent as RenderObject;

        // the 2 Conduits swaps.
        subtree = conduitWithEntry(
          key: globalKey2,
          child: const Placeholder(key: child2Key),
          overlayEntry: proxyEntry2,
          remoteChild: conduitWithEntry(
            key: globalKey1,
            child: const SizedBox(key: child1Key),
            overlayEntry: proxyEntry1,
            remoteChild: const Placeholder(key: placeholderKey),
          ),
        );

        stateSetter(() { });
        await tester.pump();

        expect(tester.takeException(), null);
        expect(tester.renderObject(find.byKey(child1Key)), oldChild1RenderObject);
        expect(tester.renderObject(find.byKey(child2Key)), oldChild2RenderObject);

        // The child render objects are still with their parents respectively.
        expect(tester.renderObject(find.byKey(child1Key)).parent, oldChild1RenderObjectParent);
        expect(tester.renderObject(find.byKey(child2Key)).parent, oldChild2RenderObjectParent);

        expect(tester.renderObject(find.byKey(globalKey1)), oldConduit1RenderObject);
        expect(tester.renderObject(find.byKey(globalKey2)), oldConduit2RenderObject);

        // But the Conduits' render objects are no longer with their old parents.
        expect(tester.renderObject(find.byKey(globalKey1)).parent, isNot(oldConduit1RenderObjectParent));
        expect(tester.renderObject(find.byKey(globalKey2)).parent, isNot(oldConduit2RenderObjectParent));

        expect(tester.renderObject(find.byKey(placeholderKey)).parent, isNot(placeholderRenderObjectParent));

        // Change height of the tree, no exceptions should be thrown.
        subtree = Container(child: subtree);
        stateSetter(() { });

        await tester.pump();
        expect(tester.takeException(), null);
    });

  });

  group('LayoutBuilders', () {
    const MediaQueryData data1 = MediaQueryData(textScaleFactor: 1234.567);
    const MediaQueryData data2 = MediaQueryData(textScaleFactor: 567.1234);

    MediaQueryData mediaQueryForChild;
    MediaQueryData mediaQueryForRemoteChild;

    setUp(() {
      mediaQueryForChild = null;
      mediaQueryForRemoteChild = null;
    });

    testWidgets(
      'RemoteChild inherits from the right BuildContext, with a LayoutBuilder ancestor',
      (WidgetTester tester) async {
        final ProxyOverlayEntry proxyEntry = ProxyOverlayEntry();
        MediaQueryData data = data1;

        StateSetter stateSetter;

        final Widget conduit = conduitWithEntry(
          child: Builder(builder: (BuildContext context) {
            mediaQueryForChild = MediaQuery.of(context);
            return const Placeholder();
          }),
          overlayEntry: proxyEntry,
          remoteChild: Builder(builder: (BuildContext context) {
            mediaQueryForRemoteChild = MediaQuery.of(context);
            return const Placeholder();
          }),
        );

        final OverlayEntry entry = OverlayEntry(builder: (BuildContext context) {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setter) {
                  stateSetter = setter;
                  return MediaQuery(
                    data: data,
                    child: conduit,
                  );
                },
              );
            },
          );
        });

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(key: overlayKey, initialEntries: <OverlayEntry>[entry, proxyEntry]),
           ),
        );

        expect(mediaQueryForChild, data1);
        expect(mediaQueryForRemoteChild, data1);

        // Depedency updates should not fall behind with layout builder.
        stateSetter(() { data = data2; });
        await tester.pump();

        expect(mediaQueryForChild, data2);
        expect(mediaQueryForRemoteChild, data2);
    });

    testWidgets(
      'RemoteChild inherits from the right BuildContext, with a LayoutBuilder in remote child',
      (WidgetTester tester) async {
        final ProxyOverlayEntry proxyEntry1 = ProxyOverlayEntry();
        final ProxyOverlayEntry proxyEntry2 = ProxyOverlayEntry();
        MediaQueryData data = data1;

        StateSetter stateSetter;

        final Widget conduit = conduitWithEntry(
          child: Builder(builder: (BuildContext context) {
            mediaQueryForChild = MediaQuery.of(context);
            return const Placeholder();
          }),
          overlayEntry: proxyEntry2,
          remoteChild: LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
            mediaQueryForRemoteChild = MediaQuery.of(context);
            return const Placeholder();
          }),
        );

        final OverlayEntry entry = OverlayEntry(
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setter) {
                stateSetter = setter;
                return MediaQuery(
                  data: data,
                  child: conduitWithEntry(
                    child: LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
                      mediaQueryForChild = MediaQuery.of(context);
                      return const Placeholder();
                    }),
                    overlayEntry: proxyEntry1,
                    remoteChild: conduit,
                  ),
                ) ;
              },
            );
          },
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(key: overlayKey, initialEntries: <OverlayEntry>[entry, proxyEntry1, proxyEntry2]),
          ),
        );

        expect(mediaQueryForChild, data1);
        expect(mediaQueryForRemoteChild, data1);

        // Depedency updates should not fall behind with layout builder.
        stateSetter(() { data = data2; });
        await tester.pump();

        expect(mediaQueryForChild, data2);
        expect(mediaQueryForRemoteChild, data2);
    });

    testWidgets('One does not simply layout twice', (WidgetTester tester) async {
      Widget deepWidget(int depth, Widget child) => depth < 1 ? child : SizedBox(child: deepWidget(depth - 1, child));
      final ProxyOverlayEntry proxyEntry = ProxyOverlayEntry();

      int layoutCounter = 0;
      StateSetter stateSetter;
      Color color = const Color(0xFF123456);

      const Key layoutBuilderKey = Key('LayoutBuilder');

      final Widget conduit = LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setter) {
            stateSetter = setter;
            return conduitWithEntry(
              child: LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
                return const Placeholder();
              }),
              overlayEntry: proxyEntry,
              remoteChild: LayoutBuilder(key: layoutBuilderKey, builder: (BuildContext context, BoxConstraints box) {
                layoutCounter++;
                return Placeholder(color: color);
              }),
            );
          }
        );
      });

      final OverlayEntry entry = OverlayEntry(builder: (BuildContext context) => deepWidget(500, conduit));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(key: overlayKey, initialEntries: <OverlayEntry>[entry, proxyEntry]),
        ),
      );

      expect(layoutCounter, 1);

      // Once the LayoutBuilder callback runs, the remote child's renderObject
      // will be marked dirty again.
      stateSetter(() { color = const Color(0xFF654321); });
      tester.element(find.byWidget(conduit)).markNeedsBuild();
      tester.renderObject(find.byKey(layoutBuilderKey)).markNeedsLayout();
      layoutCounter = 0;

      await tester.pump();

      // This would fail if _RenderConduitAnchor's depth override is commented out.
      expect(layoutCounter, 1);
    });

    testWidgets('One does not simply layout twice, even with nested Conduits', (WidgetTester tester) async {
      final ProxyOverlayEntry proxyEntry1 = ProxyOverlayEntry();
      final ProxyOverlayEntry proxyEntry2 = ProxyOverlayEntry();
      final ProxyOverlayEntry proxyEntry3 = ProxyOverlayEntry();

      int layoutCounter1 = 0;
      int layoutCounter2 = 0;
      int layoutCounter3 = 0;

      StateSetter stateSetter;
      Color color = const Color(0xFF123456);

      const Key layoutBuilderKey1 = Key('LayoutBuilder1');
      const Key layoutBuilderKey2 = Key('LayoutBuilder2');
      const Key layoutBuilderKey3 = Key('LayoutBuilder3');

      final Widget overlayConduit = LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setter) {
            stateSetter = setter;
            return conduitWithEntry(
              child: const Placeholder(),
              overlayEntry: proxyEntry1,
              remoteChild: deepWidget(10, LayoutBuilder(key: layoutBuilderKey1, builder: (BuildContext context, BoxConstraints box) {
                layoutCounter1++;
                return conduitWithEntry(
                  child: Placeholder(color: color),
                  overlayEntry: proxyEntry2,
                  remoteChild: LayoutBuilder(key: layoutBuilderKey2, builder: (BuildContext context, BoxConstraints box) {
                    layoutCounter2++;
                    return conduitWithEntry(
                      child: Placeholder(color: color),
                      overlayEntry: proxyEntry3,
                      remoteChild: LayoutBuilder(key: layoutBuilderKey3, builder: (BuildContext context, BoxConstraints box) {
                        layoutCounter3++;
                        return Placeholder(color: color);
                      }),
                    );
                  }),
                );
              }),
            ));
          },
        );
      });

      final OverlayEntry entry = OverlayEntry(builder: (BuildContext context) => deepWidget(50, overlayConduit));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(key: overlayKey, initialEntries: <OverlayEntry>[proxyEntry1, entry, proxyEntry2, proxyEntry3]),
        ),
      );

      expect(layoutCounter1, 1);
      expect(layoutCounter2, 1);
      expect(layoutCounter3, 1);

      // Once the overlayConduit LayoutBuilder callback runs, the overlayItem renderObject
      // will be marked dirty again.
      stateSetter(() { color = const Color(0xFF654321); });
      tester.element(find.byWidget(overlayConduit)).markNeedsBuild();
      final RenderBox lb1 = tester.renderObject(find.byKey(layoutBuilderKey1));
      final RenderBox lb2 = tester.renderObject(find.byKey(layoutBuilderKey2));
      lb1.markNeedsLayout();
      lb2.markNeedsLayout();
      tester.renderObject(find.byKey(layoutBuilderKey3)).markNeedsLayout();
      layoutCounter1 = 0;
      layoutCounter2 = 0;
      layoutCounter3 = 0;

      await tester.pump();

      expect(layoutCounter1, 1);
      expect(layoutCounter2, 1);
      expect(layoutCounter3, 1);
    });

    testWidgets(
      'One does not simply layout twice 3: a LayoutBuilder with a GlobalKey and gradually becomes deeper each build',
      (WidgetTester tester) async {
        final ProxyOverlayEntry proxyEntry = ProxyOverlayEntry();

        int layoutCounter = 0;
        StateSetter stateSetter;
        int layoutBuilderDepth = 100;
        Color color = const Color(0xFF123456);

        const Key layoutBuilderKey = Key('LayoutBuilder');

        final Widget overlayConduit = StatefulBuilder(
          builder: (BuildContext context, StateSetter setter) {
            stateSetter = setter;
            // The LayoutBuilder will become deeper and deeper.
            return deepWidget(layoutBuilderDepth,
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints box) {
                  return conduitWithEntry(
                    child: LayoutBuilder(builder: (BuildContext context, BoxConstraints box) => const Placeholder()),
                    overlayEntry: proxyEntry,
                    remoteChild: LayoutBuilder(key: layoutBuilderKey, builder: (BuildContext context, BoxConstraints box) {
                      layoutCounter++;
                      return Placeholder(color: color);
                    }),
                  );
                },
              )
            );
          }
        );

        final OverlayEntry entry = OverlayEntry(builder: (BuildContext context) => overlayConduit);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(key: overlayKey, initialEntries: <OverlayEntry>[entry, proxyEntry]),
          ),
        );

        expect(layoutCounter, 1);

        // Once the Conduit LayoutBuilder callback runs, the remote child's renderObject
        // will be marked dirty again.
        stateSetter(() {
          color = const Color(0xFF654321);
          layoutBuilderDepth += 100;
        });
        tester.element(find.byWidget(overlayConduit)).markNeedsBuild();
        tester.renderObject(find.byKey(layoutBuilderKey)).markNeedsLayout();
        layoutCounter = 0;

        await tester.pump();

        // This would fail if _RenderConduitAnchor's depth override is commented out.
        expect(layoutCounter, 1);

        stateSetter(() {
            color = const Color(0x87654321);
            layoutBuilderDepth += 100;
        });
        tester.element(find.byWidget(overlayConduit)).markNeedsBuild();
        tester.renderObject(find.byKey(layoutBuilderKey)).markNeedsLayout();
        layoutCounter = 0;

        await tester.pump();

        // This would fail if _RenderConduitAnchor's depth override is commented out.
        expect(layoutCounter, 1);

    });

    testWidgets(
      "Remote child does not layout twice case 4: when ConduitAnchor's parent render object is dirty",
      (WidgetTester tester) async {
        int layoutCounter = 0;
        StateSetter setState;
        final AnchorKey remoteKey = AnchorKey();
        final LabeledGlobalKey layoutBuilderKey = LabeledGlobalKey('layoutBuilder');
        bool shouldChangeLayout = false;

        await tester.pumpWidget(
          withDirectionality(
            <OverlayEntry>[
              OverlayEntry(builder: (BuildContext context) {
                // Ensure the ConduitAnchor's parent is laid out first.
                return deepWidget(
                  10,
                  LayoutBuilder(key: layoutBuilderKey, builder: (BuildContext context, BoxConstraints constraints) {
                    return Conduit(
                      child: const Placeholder(),
                      remoteKey: remoteKey,
                      remoteChildBuilder: (BuildContext context, BoxConstraints constraints) {
                        layoutCounter += 1;
                        return Container();
                      },
                    );
                  }),
                );
              }),
              OverlayEntry(builder: (BuildContext context) {
                return StatefulBuilder(builder: (BuildContext context, StateSetter setter) {
                  setState = setter;
                  return Center(
                    child: Container(
                      width: shouldChangeLayout ? 100 : 200,
                      child: ConduitAnchor(key: remoteKey),
                    ),
                  );
                });
              }),
            ],
          ),
        );

        expect(layoutCounter, 1);

        // Mark ConduitAnchor's layout boundary dirty.
        setState(() { shouldChangeLayout = true; });
        // Mark Conduit's layout boundary dirty.
        (layoutBuilderKey.currentContext as Element).markNeedsBuild();
        await tester.pump();
        // Only layout once.
        expect(layoutCounter, 2);
    });
  });
}

final GlobalKey<OverlayState> overlayKey = GlobalKey();

Widget withDirectionality(List<OverlayEntry> entries) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Overlay(key: overlayKey, initialEntries: entries),
  );
}

Widget deepWidget(int depth, Widget child) => depth < 1 ? child : SizedBox(child: deepWidget(depth - 1, child));
