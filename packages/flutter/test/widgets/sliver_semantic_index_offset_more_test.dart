import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SliverGrid.builder applies semanticIndexOffset', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
              addSemanticIndexes: true,
              semanticIndexOffset: 5,
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(height: 50, child: Text('G$index'));
              },
              itemCount: 2,
            ),
          ],
        ),
      ),
    );
    final Finder semantics0 = find.bySemanticsLabel('G0');
    expect(tester.getSemantics(semantics0).index, 5);
  });

  testWidgets('SliverFixedExtentList.builder applies semanticIndexOffset', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverFixedExtentList.builder(
              itemExtent: 20,
              addSemanticIndexes: true,
              semanticIndexOffset: 3,
              itemBuilder: (BuildContext context, int index) => Text('F$index'),
              itemCount: 1,
            ),
          ],
        ),
      ),
    );
    final Finder semantics0 = find.bySemanticsLabel('F0');
    expect(tester.getSemantics(semantics0).index, 3);
  });

  testWidgets('SliverVariedExtentList.builder applies semanticIndexOffset', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverVariedExtentList.builder(
              itemExtentBuilder: (int index) => 30,
              addSemanticIndexes: true,
              semanticIndexOffset: 4,
              itemBuilder: (BuildContext context, int index) => Text('V$index'),
              itemCount: 1,
            ),
          ],
        ),
      ),
    );
    final Finder semantics0 = find.bySemanticsLabel('V0');
    expect(tester.getSemantics(semantics0).index, 4);
  });
}
