import 'package:flutter/material.dart';
import 'package:flutter/src/material/chip_set.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChipSet Tests', () {
    late List<String> selectedItems;
    late ChipSet<String> testChipSet;

    setUp(() {
      selectedItems = <String>[];
      testChipSet = ChipSet<String>(
        items: const <String>['Apple', 'Banana', 'Cherry'],
        isSelected: (String item) => selectedItems.contains(item),
        onSelected: (String item, bool isSelected) {
          if (isSelected) {
            selectedItems.add(item);
          } else {
            selectedItems.remove(item);
          }
        },
      );
    });

    testWidgets('Initial state', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: testChipSet)));

      expect(find.byType(RawChip), findsNWidgets(3));
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('Select a chip', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: testChipSet)));

      await tester.tap(find.text('Apple'));
      await tester.pump();

      expect(selectedItems, contains('Apple'));
    });

    testWidgets('Deselect a chip', (WidgetTester tester) async {
      selectedItems.add('Banana');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: testChipSet)));

      await tester.tap(find.text('Banana'));
      await tester.pump();

      expect(selectedItems, isNot(contains('Banana')));
    });

    testWidgets('Select and deselect multiple chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: testChipSet)));

      await tester.tap(find.text('Apple'));
      await tester.tap(find.text('Cherry'));
      await tester.pumpAndSettle();

      expect(selectedItems, containsAll(<String>['Apple', 'Cherry']));

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(selectedItems, isNot(contains('Apple')));
      expect(selectedItems, contains('Cherry'));
    });

    testWidgets('Custom chip builder', (WidgetTester tester) async {
      testChipSet = ChipSet<String>(
        items: const <String>['Apple', 'Banana', 'Cherry'],
        isSelected: (String item) => selectedItems.contains(item),
        onSelected: (String item, bool isSelected) {
          if (isSelected) {
            selectedItems.add(item);
          } else {
            selectedItems.remove(item);
          }
        },
        chipBuilder: (BuildContext context, String item, bool selected, onSelected) {
          return ChoiceChip(
            selected: selected,
            label: Text(item),
            onSelected: onSelected,
          );
        },
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: testChipSet)));

      expect(find.byType(ChoiceChip), findsNWidgets(3));
    });
  });

  testWidgets('Constraints are applied correctly', (WidgetTester tester) async {
    final BoxConstraints constraints = BoxConstraints(
        minWidth: 80, maxWidth: 100, minHeight: 40, maxHeight: 60);

    final Set<String> selectedItems = <String>{};

    final ChipSet<String> chipSet = ChipSet<String>(
      items: <String>['Apple', 'Banana', 'Cherry'],
      isSelected: (String item) => selectedItems.contains(item),
      onSelected: (String item, bool isSelected) {
        if (isSelected) {
          selectedItems.add(item);
        } else {
          selectedItems.remove(item);
        }
      },
      constraints: constraints,
    );

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: chipSet)));

    final Finder constrainedBoxes = find.byWidgetPredicate((Widget widget) {
      return widget is ConstrainedBox && widget.constraints == constraints;
    });

    for (final Element box in constrainedBoxes.evaluate()) {
      final Size boxSize = tester.getSize(find.byWidget(box.widget));
      expect(boxSize.width, greaterThanOrEqualTo(constraints.minWidth));
      expect(boxSize.width, lessThanOrEqualTo(constraints.maxWidth));
      expect(boxSize.height, greaterThanOrEqualTo(constraints.minHeight));
      expect(boxSize.height, lessThanOrEqualTo(constraints.maxHeight));
    }
  });
}
