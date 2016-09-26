// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';


class InheritedValue extends InheritedWidget {
  InheritedValue({ Key key, Widget child, this.value }) : super(key: key, child: child);

  final double value;

  @override
  bool updateShouldNotify(InheritedValue oldWidget) => value != oldWidget.value;

  @override
  String toString() => "InheritedValue(value=$value)";
}

void main() {
  testWidgets('InheritedWidgetLink basics', (WidgetTester tester) async {
    GlobalKey linkParentKey = new GlobalKey();
    GlobalKey linkChildKey = new GlobalKey();
    Key containerKey = new UniqueKey();
    double inheritedValue = 100.0;

    // The first row element's subtree depends on an InheritedValue. The
    // second row element's subtree links to the leaf Container element
    // in the first subtree.
    Widget buildFrame() {
      return new InheritedValue(
        value: 500.0, // This value is subverted by the child's link.
        child: new Row(
          children: <Widget>[
            new InheritedValue(
              value: inheritedValue,
              child: new Builder(
                builder: (BuildContext context) {
                  final InheritedValue inheritedValue = context.inheritFromWidgetOfExactType(InheritedValue);
                  return new InheritedWidgetLinkParent(
                    key: linkParentKey,
                    link: linkChildKey,
                    child: new Container(
                      width: inheritedValue.value
                    )
                  );
                }
              )
            ),
            new InheritedWidgetLinkChild(
              key: linkChildKey,
              link: linkParentKey,
              child: new Builder(
                builder: (BuildContext context) {
                  // The InheritedWidgetLinkChild causes this lookup to redirect to the
                  // ancestors of the InheritedWidgetLinkParent above.
                  final InheritedValue inheritedValue = context.inheritFromWidgetOfExactType(InheritedValue);
                  return new Container(
                    key: containerKey,
                    width: inheritedValue.value
                  );
                }
              )
            )
          ]
        )
      );
    }

    await tester.pumpWidget(buildFrame());
    RenderBox box = tester.renderObject(find.byKey(containerKey));
    expect(box.size.width, equals(100.0));

    inheritedValue = 200.0;
    await tester.pumpWidget(buildFrame());
    expect(box.size.width, equals(200.0));

    linkParentKey = null;
    await tester.pumpWidget(buildFrame());
    expect(box.size.width, equals(500.0));
  });

  testWidgets('InheritedWidgetLink basics, deep target', (WidgetTester tester) async {
    GlobalKey linkParentKey = new GlobalKey();
    GlobalKey linkChildKey = new GlobalKey();
    Key containerKey = new UniqueKey();
    double inheritedValue = 100.0;

    // In this case, the widget tree depth of the InheritedValue being linked
    // to is greater than the InheritedWidgetLink's depth.
    Widget buildFrame() {
      return new Row(
        children: <Widget>[
          new Container(
            child: new Container(
              child: new Container(
                child: new Container(
                  child: new InheritedValue(
                    value: inheritedValue,
                    child: new Builder(
                      builder: (BuildContext context) {
                        final InheritedValue inheritedValue = context.inheritFromWidgetOfExactType(InheritedValue);
                        return new InheritedWidgetLinkParent(
                          key: linkParentKey,
                          link: linkChildKey,
                          child: new Container(
                            width: inheritedValue.value
                          )
                        );
                      }
                    )
                  )
                )
              )
            )
          ),
          new InheritedWidgetLinkChild(
            key: linkChildKey,
            link: linkParentKey,
            child: new Builder(
              builder: (BuildContext context) {
                final InheritedValue inheritedValue = context.inheritFromWidgetOfExactType(InheritedValue);
                return new Container(
                  key: containerKey,
                  width: inheritedValue.value
                );
              }
            )
          )
        ]
      );
    }

    await tester.pumpWidget(buildFrame());
    RenderBox box = tester.renderObject(find.byKey(containerKey));
    expect(box.size.width, equals(100.0));

    inheritedValue = 200.0;
    await tester.pumpWidget(buildFrame());
    expect(box.size.width, equals(200.0));
  });

  testWidgets('InheritedWidgetLink basics, link target subtree changes', (WidgetTester tester) async {
    GlobalKey linkParentKey = new GlobalKey(debugLabel: 'linkParentKey');
    GlobalKey linkChildKey = new GlobalKey(debugLabel: 'linkChildKey');
    Key containerKey = new UniqueKey();

    // This is the same widget three as in the'InheritedWidgetLink basics,
    // deep target' test. In the next step the four Container ancestors of
    // the InheritedWidgetLinkParent will be removed, causing the
    // InheritedWidgetLinkParent widget to be deactivated and then rebuilt
    // in its new location.
    await tester.pumpWidget(
      new Row(
        children: <Widget>[
          new Container(
            child: new Container(
              child: new Container(
                child: new Container(
                  child: new InheritedValue(
                    value: 100.0,
                    child: new Builder(
                      builder: (BuildContext context) {
                        final InheritedValue inheritedValue = context.inheritFromWidgetOfExactType(InheritedValue);
                        return new InheritedWidgetLinkParent(
                          key: linkParentKey,
                          link: linkChildKey,
                          child: new Container(
                            width: inheritedValue.value
                          )
                        );
                      }
                    )
                  )
                )
              )
            )
          ),
          new InheritedWidgetLinkChild(
            key: linkChildKey,
            link: linkParentKey,
            child: new Builder(
              builder: (BuildContext context) {
                final InheritedValue inheritedValue = context.inheritFromWidgetOfExactType(InheritedValue);
                return new Container(
                  key: containerKey,
                  width: inheritedValue.value
                );
              }
            )
          )
        ]
      )
    );

    RenderBox box = tester.renderObject(find.byKey(containerKey));
    expect(box.size.width, equals(100.0));

    // Move the InheritedValue widget subtree up by removing the enclosing
    // Containers. The width of the Container below the InheritedWidgetLinkChild
    // should not change but it should be rebuilt.
    bool rebuilt = false;
    await tester.pumpWidget(
      new Row(
        children: <Widget>[
          new InheritedValue(
            value: 500.0,
            child: new Builder(
              builder: (BuildContext context) {
                final InheritedValue inheritedValue = context.inheritFromWidgetOfExactType(InheritedValue);
                return new InheritedWidgetLinkParent(
                  key: linkParentKey,
                  link: linkChildKey,
                  child: new Container(
                    width: inheritedValue.value
                   )
                );
              }
            )
          ),
          new InheritedWidgetLinkChild(
            key: linkChildKey,
            link: linkParentKey,
            child: new Builder(
              builder: (BuildContext context) {
                rebuilt = true;
                final InheritedValue inheritedValue = context.inheritFromWidgetOfExactType(InheritedValue);
                return new Container(
                  key: containerKey,
                  width: inheritedValue.value
                );
              }
            )
          )
        ]
      )
    );

    box = tester.renderObject(find.byKey(containerKey));
    expect(rebuilt, isTrue);
    expect(box.size.width, equals(500.0));

  });

  testWidgets('InheritedWidgetLink redirect the child\'s link', (WidgetTester tester) async {
    GlobalKey linkChildKey = new GlobalKey(debugLabel: 'link child');
    GlobalKey linkParentKey200 = new GlobalKey(debugLabel: 'InheritedWidgetLinkParent, width: 200.0');
    GlobalKey linkParentKey100 = new GlobalKey(debugLabel: 'InheritedWidgetLinkChild, width: 100.0');
    GlobalKey linkParentKey = linkParentKey100;
    Key containerKey = new UniqueKey();

    Widget buildFrame() {
      return new Row(
        children: <Widget>[
          new InheritedValue(
            value: 200.0,
            child: new Builder(
              builder: (BuildContext context) {
                final InheritedValue inheritedValue = context.inheritFromWidgetOfExactType(InheritedValue);
                return new InheritedWidgetLinkParent(
                  key: linkParentKey200, // If the child links here, it inherits value=200
                  link: linkChildKey,
                  child: new Container(
                    width: inheritedValue.value,
                    child: new InheritedValue(
                      value: 100.0,
                      child: new Builder(
                        builder: (BuildContext context) {
                          final InheritedValue inheritedValue = context.inheritFromWidgetOfExactType(InheritedValue);
                          return new InheritedWidgetLinkParent(
                            key: linkParentKey100, // If the child links here, it inherits value=100
                            link: linkChildKey,
                            child: new Container(width: inheritedValue.value)
                          );
                        }
                      )
                    )
                  )
                );
              }
            )
          ),
          new InheritedWidgetLinkChild(
            key: linkChildKey,
            link: linkParentKey, // Initially linkParentKey100, then linkParentKey200
            child: new Builder(
              builder: (BuildContext context) {
                final InheritedValue inheritedValue = context.inheritFromWidgetOfExactType(InheritedValue);
                return new Container(
                  key: containerKey,
                  width: inheritedValue.value
                );
              }
            )
          ),
        ]
      );
    }

    await tester.pumpWidget(buildFrame());

    RenderBox box = tester.renderObject(find.byKey(containerKey));
    expect(box.size.width, equals(100.0));

    // Rebuild the InheritedWidgetLink subtree with the new link value.
    linkParentKey = linkParentKey200;
    await tester.pumpWidget(buildFrame());
    await tester.pump();
    box = tester.renderObject(find.byKey(containerKey));
    expect(box.size.width, equals(200.0));
  });

  testWidgets('InheritedWidgetLink redirect the parent\'s link', (WidgetTester tester) async {
    // Keys for the Containers whose width is defined an InheritedValue.
    GlobalKey parentKey = new GlobalKey(debugLabel: 'parent');
    GlobalKey childOneKey = new GlobalKey(debugLabel: 'childOne');
    GlobalKey childTwoKey = new GlobalKey(debugLabel: 'childTwo');

    // Keys and link values for the InheritedWidgetLinkParent widget and
    // the two InheritedWidgetLinkChild widgets. Initially child one is linked
    // to the parent and child two isn't linked.
    GlobalKey linkParentKey = new GlobalKey(debugLabel: 'InheritedWidgetLinkParent');
    GlobalKey linkChildOneKey = new GlobalKey(debugLabel: 'InheritedWidgetLinkChild one');
    GlobalKey linkChildTwoKey = new GlobalKey(debugLabel: 'InheritedWidgetLinkChild two');
    GlobalKey parentLink = linkChildOneKey;
    GlobalKey childOneLink = linkParentKey;
    GlobalKey childTwoLink;

    Widget buildFrame() {
      return new InheritedValue(
        value: 200.0,
        child: new Row(
          children: <Widget>[
            // Parent
            new InheritedValue(
              value: 100.0,
              child: new InheritedWidgetLinkParent(
                key: linkParentKey,
                link: parentLink, // Initially points to child one, then child two
                child: new Builder(
                  builder: (BuildContext context) {
                    final InheritedValue inheritedValue = context.inheritFromWidgetOfExactType(InheritedValue);
                    return new Container(
                      key: parentKey,
                      width: inheritedValue.value
                    );
                  }
                )
              )
            ),
            // Child one
            new InheritedWidgetLinkChild(
              key: linkChildOneKey,
              link: childOneLink, // Initially points to parent, then null
              child: new Builder(
                builder: (BuildContext context) {
                  final InheritedValue inheritedValue = context.inheritFromWidgetOfExactType(InheritedValue);
                  return new Container(
                    key: childOneKey,
                    width: inheritedValue.value,
                  );
                }
              )
            ),
            // Child two
            new InheritedWidgetLinkChild(
              key: linkChildTwoKey,
              link: childTwoLink, // Initially null, then points to parent
              child: new Builder(
                builder: (BuildContext context) {
                  final InheritedValue inheritedValue = context.inheritFromWidgetOfExactType(InheritedValue);
                  return new Container(
                    key: childTwoKey,
                    width: inheritedValue.value,
                  );
                }
              )
            ),
          ]
        )
      );
    }

    // -- Initially the parent and child one are linked.
    await tester.pumpWidget(buildFrame());
    RenderBox box = tester.renderObject(find.byKey(parentKey));
    expect(box.size.width, equals(100.0));

    box = tester.renderObject(find.byKey(childOneKey));
    expect(box.size.width, equals(100.0));

    // Child two is not actually linked to anything (link is null),
    // so it inherits via the usual path to the tree's root.
    box = tester.renderObject(find.byKey(childTwoKey));
    expect(box.size.width, equals(200.0));

    // -- Make the parent link to child two instead of child one.
    parentLink = linkChildTwoKey;
    childOneLink = null;
    childTwoLink = linkParentKey;

    await tester.pumpWidget(buildFrame());
    await tester.pump();

    box = tester.renderObject(find.byKey(parentKey));
    expect(box.size.width, equals(100.0));

    box = tester.renderObject(find.byKey(childOneKey));
    expect(box.size.width, equals(200.0));

    box = tester.renderObject(find.byKey(childTwoKey));
    expect(box.size.width, equals(100.0));
  });

}
