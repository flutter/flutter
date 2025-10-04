import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SliverList.builder applies semanticIndexOffset', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverList.builder(
              addSemanticIndexes: true,
              semanticIndexOffset: 2,
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(height: 50, child: Text('Item $index'));
              },
              itemCount: 3,
            ),
          ],
        ),
      ),
    );

    final Finder semantics0 = find.bySemanticsLabel('Item 0');
    // IndexedSemantics should map first child to index 2
    expect(tester.getSemantics(semantics0).index, 2);
  });
}
