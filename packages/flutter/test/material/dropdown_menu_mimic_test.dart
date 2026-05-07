import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('DropdownMenu mimic app test', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    final intController = TextEditingController();

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
                    child: DropdownMenu<int>(
                      initialSelection: 1,
                      controller: intController,
                      dropdownMenuEntries: intEntries,
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
    debugDumpSemanticsTree();

    // Verify initial selection label is in the text field.
    expect(find.text('1'), findsOneWidget);

    // Open the dropdown.
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // Assert semantics tree.
    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                TestSemantics(), // Placeholder for node 2
                TestSemantics(
                  flags: ui.SemanticsFlags(isAccessibilityFocusBlocked: true),
                  children: <TestSemantics>[
                    TestSemantics(
                      children: <TestSemantics>[
                        TestSemantics(
                          flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                          children: <TestSemantics>[
                            TestSemantics(
                              flags: <SemanticsFlag>[SemanticsFlag.isButton],
                              children: <TestSemantics>[
                                TestSemantics(
                                  inputType: ui.SemanticsInputType.text,
                                  flags: <SemanticsFlag>[
                                    SemanticsFlag.isTextField,
                                    SemanticsFlag.isFocusable,
                                    SemanticsFlag.hasEnabledState,
                                    SemanticsFlag.isEnabled,
                                    SemanticsFlag.isReadOnly,
                                    SemanticsFlag.isButton,
                                    SemanticsFlag.hasExpandedState,
                                    SemanticsFlag.isExpanded,
                                  ],
                                  actions: <SemanticsAction>[
                                    SemanticsAction.collapse,
                                    SemanticsAction.focus,
                                  ],
                                  value: '1',
                                  textDirection: TextDirection.ltr,
                                  currentValueLength: 1,
                                ),
                              ],
                            ),
                            TestSemantics(label: 'hello', textDirection: TextDirection.ltr),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                TestSemantics(
                  children: <TestSemantics>[
                    TestSemantics(
                      children: <TestSemantics>[
                        TestSemantics(
                          children: <TestSemantics>[
                            TestSemantics(
                              flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
                              children: <TestSemantics>[
                                TestSemantics(
                                  children: <TestSemantics>[
                                    TestSemantics(
                                      label: '0',
                                      flags: <SemanticsFlag>[
                                        SemanticsFlag.hasEnabledState,
                                        SemanticsFlag.isEnabled,
                                        SemanticsFlag.isFocusable,
                                      ],
                                      actions: <SemanticsAction>[
                                        SemanticsAction.focus,
                                        SemanticsAction.tap,
                                      ],
                                      textDirection: TextDirection.ltr,
                                    ),
                                  ],
                                ),
                                TestSemantics(
                                  children: <TestSemantics>[
                                    TestSemantics(
                                      label: '1',
                                      flags: <SemanticsFlag>[
                                        SemanticsFlag.hasEnabledState,
                                        SemanticsFlag.isEnabled,
                                        SemanticsFlag.isFocusable,
                                      ],
                                      actions: <SemanticsAction>[
                                        SemanticsAction.focus,
                                        SemanticsAction.tap,
                                      ],
                                      textDirection: TextDirection.ltr,
                                    ),
                                  ],
                                ),
                                TestSemantics(
                                  children: <TestSemantics>[
                                    TestSemantics(
                                      label: '2',
                                      flags: <SemanticsFlag>[
                                        SemanticsFlag.hasEnabledState,
                                        SemanticsFlag.isEnabled,
                                        SemanticsFlag.isFocusable,
                                      ],
                                      actions: <SemanticsAction>[
                                        SemanticsAction.focus,
                                        SemanticsAction.tap,
                                      ],
                                      textDirection: TextDirection.ltr,
                                    ),
                                  ],
                                ),
                                TestSemantics(
                                  children: <TestSemantics>[
                                    TestSemantics(
                                      label: '3',
                                      flags: <SemanticsFlag>[
                                        SemanticsFlag.hasEnabledState,
                                        SemanticsFlag.isEnabled,
                                        SemanticsFlag.isFocusable,
                                      ],
                                      actions: <SemanticsAction>[
                                        SemanticsAction.focus,
                                        SemanticsAction.tap,
                                      ],
                                      textDirection: TextDirection.ltr,
                                    ),
                                  ],
                                ),
                                TestSemantics(
                                  children: <TestSemantics>[
                                    TestSemantics(
                                      label: '4',
                                      flags: <SemanticsFlag>[
                                        SemanticsFlag.hasEnabledState,
                                        SemanticsFlag.isEnabled,
                                        SemanticsFlag.isFocusable,
                                      ],
                                      actions: <SemanticsAction>[
                                        SemanticsAction.focus,
                                        SemanticsAction.tap,
                                      ],
                                      textDirection: TextDirection.ltr,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
        ignoreId: true,
      ),
    );

    semantics.dispose();
  });
}
