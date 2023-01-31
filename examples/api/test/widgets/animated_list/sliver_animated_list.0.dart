import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/animated_list/sliver_animated_list.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Items can be selected, added, and removed fromSliverAnimatedList',
    (WidgetTester tester) async {
      await tester.pumpWidget(const example.SliverAnimatedListSample());

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);

      //add item at the end of the list
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pumpAndSettle();
      expect(find.text('Item 3'), findsOneWidget);

      //select Item 1
      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();
      //add item at the top of the list
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pumpAndSettle();
      expect(find.text('Item 4'), findsOneWidget);

      //remove Item 1 that was selected before
      await tester.tap(find.byIcon(Icons.remove_circle));
      //one frame ahead the Item 1 is still animating on the screen
      await tester.pump();
      expect(find.text('Item 1'), findsOneWidget);

      //when the animation complete, the Item 1 disappear
      await tester.pumpAndSettle();
      expect(find.text('Item 1'), findsNothing);
    },
  );
}
