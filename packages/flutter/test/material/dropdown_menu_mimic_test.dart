import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('DropdownMenu mimic app test with OverlayPortal', (WidgetTester tester) async {
    // SemanticsTester is required to enable semantics collection.
    final semantics = SemanticsTester(tester);

    final intController = TextEditingController(text: '1');
    final controller = OverlayPortalController();
    final isOverlayOpen = ValueNotifier<bool>(false);

    final intEntries = <DropdownMenuEntry<int>>[];
    for (var i = 0; i < 5; i++) {
      intEntries.add(DropdownMenuEntry<int>(value: i, label: i.toString()));
    }

    await tester.pumpWidget(
      MaterialApp(
        title: 'Flutter Demo',
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Semantics(
                    button: true,
                    child: OverlayPortal(
                      controller: controller,
                      accessibilityOpaque: true,
                      overlayChildBuilder: (BuildContext context) {
                        return Positioned(
                          width: 200,
                          child: Material(
                            elevation: 8,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: intEntries.map((entry) {
                                return ListTile(
                                  title: Text(entry.label),
                                  onTap: () {
                                    intController.text = entry.label;
                                    controller.hide();
                                    isOverlayOpen.value = false;
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isOverlayOpen,
                        builder: (context, isOpen, child) {
                          return TextField(
                            controller: intController,
                            onTap: () {
                              controller.show();
                              isOverlayOpen.value = true;
                            },
                            readOnly: true,
                            decoration: const InputDecoration(
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Text('hello'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Verify initial text.
    expect(find.text('1'), findsOneWidget);

    // Open the overlay.
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // Assert semantics of the TextField using find instead of brittle full tree matching.
    final SemanticsNode node = tester.semantics.find(find.byType(TextField));
    final SemanticsData data = node.getSemanticsData();
    debugDumpSemanticsTree();
    // Verify accessibility is blocked when open.
    expect(data.flagsCollection.isAccessibilityFocusBlocked, isTrue);

    semantics.dispose();
  });
}
