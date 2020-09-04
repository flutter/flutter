// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Stepper tap callback test', (WidgetTester tester) async {
    int index = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            onStepTapped: (int i) {
              index = i;
            },
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
              Step(
                title: Text('Step 2'),
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Step 2'));
    expect(index, 1);
  });

  testWidgets('Stepper expansion test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: Stepper(
              steps: const <Step>[
                Step(
                  title: Text('Step 1'),
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
                Step(
                  title: Text('Step 2'),
                  content: SizedBox(
                    width: 200.0,
                    height: 200.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    RenderBox box = tester.renderObject(find.byType(Stepper));
    expect(box.size.height, 332.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: Stepper(
              currentStep: 1,
              steps: const <Step>[
                Step(
                  title: Text('Step 1'),
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
                Step(
                  title: Text('Step 2'),
                  content: SizedBox(
                    width: 200.0,
                    height: 200.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    box = tester.renderObject(find.byType(Stepper));
    expect(box.size.height, greaterThan(332.0));
    await tester.pump(const Duration(milliseconds: 100));
    box = tester.renderObject(find.byType(Stepper));
    expect(box.size.height, 432.0);
  });

  testWidgets('Stepper horizontal size test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: Stepper(
              type: StepperType.horizontal,
              steps: const <Step>[
                Step(
                  title: Text('Step 1'),
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(Stepper));
    expect(box.size.height, 600.0);
  });

  testWidgets('Stepper visibility test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            type: StepperType.horizontal,
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: Text('A'),
              ),
              Step(
                title: Text('Step 2'),
                content: Text('B'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            currentStep: 1,
            type: StepperType.horizontal,
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: Text('A'),
              ),
              Step(
                title: Text('Step 2'),
                content: Text('B'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('Stepper button test', (WidgetTester tester) async {
    bool continuePressed = false;
    bool cancelPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            type: StepperType.horizontal,
            onStepContinue: () {
              continuePressed = true;
            },
            onStepCancel: () {
              cancelPressed = true;
            },
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
              Step(
                title: Text('Step 2'),
                content: SizedBox(
                  width: 200.0,
                  height: 200.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('CONTINUE'));
    await tester.tap(find.text('CANCEL'));

    expect(continuePressed, isTrue);
    expect(cancelPressed, isTrue);
  });

  testWidgets('Stepper disabled step test', (WidgetTester tester) async {
    int index = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            onStepTapped: (int i) {
              index = i;
            },
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
              Step(
                title: Text('Step 2'),
                state: StepState.disabled,
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Step 2'));
    expect(index, 0);
  });

  testWidgets('Stepper scroll test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: SizedBox(
                  width: 100.0,
                  height: 300.0,
                ),
              ),
              Step(
                title: Text('Step 2'),
                content: SizedBox(
                  width: 100.0,
                  height: 300.0,
                ),
              ),
              Step(
                title: Text('Step 3'),
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final ScrollableState scrollableState = tester.firstState(find.byType(Scrollable));
    expect(scrollableState.position.pixels, 0.0);

    await tester.tap(find.text('Step 3'));
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            currentStep: 2,
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: SizedBox(
                  width: 100.0,
                  height: 300.0,
                ),
              ),
              Step(
                title: Text('Step 2'),
                content: SizedBox(
                  width: 100.0,
                  height: 300.0,
                ),
              ),
              Step(
                title: Text('Step 3'),
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(scrollableState.position.pixels, greaterThan(0.0));
  });

  testWidgets('Stepper index test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: Stepper(
              steps: const <Step>[
                Step(
                  title: Text('A'),
                  state: StepState.complete,
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
                Step(
                  title: Text('B'),
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Stepper custom controls test', (WidgetTester tester) async {
    bool continuePressed = false;
    void setContinue() {
      continuePressed = true;
    }

    bool canceledPressed = false;
    void setCanceled() {
      canceledPressed = true;
    }

    final ControlsWidgetBuilder builder =
      (BuildContext context, { VoidCallback onStepContinue, VoidCallback onStepCancel }) {
        return Container(
          margin: const EdgeInsets.only(top: 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints.tightFor(height: 48.0),
            child: Row(
              children: <Widget>[
                TextButton(
                  onPressed: onStepContinue,
                  child: const Text('Let us continue!'),
                ),
                Container(
                  margin: const EdgeInsetsDirectional.only(start: 8.0),
                  child: TextButton(
                    onPressed: onStepCancel,
                    child: const Text('Cancel This!'),
                  ),
                ),
              ],
            ),
          ),
        );
      };

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: Stepper(
              controlsBuilder: builder,
              onStepCancel: setCanceled,
              onStepContinue: setContinue,
              steps: const <Step>[
                Step(
                  title: Text('A'),
                  state: StepState.complete,
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
                Step(
                  title: Text('B'),
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 2 because stepper creates a set of controls for each step
    expect(find.text('Let us continue!'), findsNWidgets(2));
    expect(find.text('Cancel This!'), findsNWidgets(2));

    await tester.tap(find.text('Cancel This!').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Let us continue!').first);
    await tester.pumpAndSettle();

    expect(canceledPressed, isTrue);
    expect(continuePressed, isTrue);
  });

  testWidgets('Stepper error test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: Stepper(
              steps: const <Step>[
                Step(
                  title: Text('A'),
                  state: StepState.error,
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('!'), findsOneWidget);
  });

  testWidgets('Nested stepper error test', (WidgetTester tester) async {
    FlutterErrorDetails errorDetails;
    final FlutterExceptionHandler oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      errorDetails = details;
    };
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Stepper(
              type: StepperType.horizontal,
              steps: <Step>[
                Step(
                  title: const Text('Step 2'),
                  content:  Stepper(
                    type: StepperType.vertical,
                    steps: const <Step>[
                      Step(
                        title: Text('Nested step 1'),
                        content: Text('A'),
                      ),
                      Step(
                        title: Text('Nested step 2'),
                        content: Text('A'),
                      ),
                    ],
                  ),
                ),
                const Step(
                  title: Text('Step 1'),
                  content: Text('A'),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      FlutterError.onError = oldHandler;
    }

    expect(errorDetails, isNotNull);
    expect(errorDetails.stack, isNotNull);
    // Check the ErrorDetails without the stack trace
    final String fullErrorMessage = errorDetails.toString();
    final List<String> lines = fullErrorMessage.split('\n');
    // The lines in the middle of the error message contain the stack trace
    // which will change depending on where the test is run.
    final String errorMessage = lines.takeWhile(
      (String line) => line != '',
    ).join('\n');
    expect(errorMessage.length, lessThan(fullErrorMessage.length));
    expect(errorMessage, startsWith(
      '══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞════════════════════════\n'
      'The following assertion was thrown building Stepper('
    ));
    // The description string of the stepper looks slightly different depending
    // on the platform and is omitted here.
    expect(errorMessage, endsWith(
      '):\n'
      'Steppers must not be nested.\n'
      'The material specification advises that one should avoid\n'
      'embedding steppers within steppers.\n'
      'https://material.io/archive/guidelines/components/steppers.html#steppers-usage'
    ));
  });

  ///https://github.com/flutter/flutter/issues/16920
  testWidgets('Stepper icons size test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            steps: const <Step>[
              Step(
                title: Text('A'),
                state: StepState.editing,
                content: SizedBox(width: 100.0, height: 100.0),
              ),
              Step(
                title: Text('B'),
                state: StepState.complete,
                content: SizedBox(width: 100.0, height: 100.0),
              ),
            ],
          ),
        ),
      ),
    );

    RenderBox renderObject = tester.renderObject(find.byIcon(Icons.edit));
    expect(renderObject.size, equals(const Size.square(18.0)));

    renderObject = tester.renderObject(find.byIcon(Icons.check));
    expect(renderObject.size, equals(const Size.square(18.0)));
  });

  testWidgets('Stepper physics scroll error test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              Stepper(
                steps: const <Step>[
                  Step(title: Text('Step 1'), content: Text('Text 1')),
                  Step(title: Text('Step 2'), content: Text('Text 2')),
                  Step(title: Text('Step 3'), content: Text('Text 3')),
                  Step(title: Text('Step 4'), content: Text('Text 4')),
                  Step(title: Text('Step 5'), content: Text('Text 5')),
                  Step(title: Text('Step 6'), content: Text('Text 6')),
                  Step(title: Text('Step 7'), content: Text('Text 7')),
                  Step(title: Text('Step 8'), content: Text('Text 8')),
                  Step(title: Text('Step 9'), content: Text('Text 9')),
                  Step(title: Text('Step 10'), content: Text('Text 10')),
                ],
              ),
              const Text('Text After Stepper'),
            ],
          ),
        ),
      ),
    );

    await tester.fling(find.byType(Stepper), const Offset(0.0, -100.0), 1000.0);
    await tester.pumpAndSettle();

    expect(find.text('Text After Stepper'), findsNothing);
  });

  testWidgets("Vertical Stepper can't be focused when disabled.", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            currentStep: 0,
            type: StepperType.vertical,
            steps: const <Step>[
              Step(
                title: Text('Step 0'),
                state: StepState.disabled,
                content: Text('Text 0'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final FocusNode disabledNode = Focus.of(tester.element(find.text('Step 0')), nullOk: true, scopeOk: true);
    disabledNode.requestFocus();
    await tester.pump();
    expect(disabledNode.hasPrimaryFocus, isFalse);
  });

  testWidgets("Horizontal Stepper can't be focused when disabled.", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            currentStep: 0,
            type: StepperType.horizontal,
            steps: const <Step>[
              Step(
                title: Text('Step 0'),
                state: StepState.disabled,
                content: Text('Text 0'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final FocusNode disabledNode = Focus.of(tester.element(find.text('Step 0')), nullOk: true, scopeOk: true);
    disabledNode.requestFocus();
    await tester.pump();
    expect(disabledNode.hasPrimaryFocus, isFalse);
  });

  testWidgets('Stepper header title should not overflow', (WidgetTester tester) async {
    const String longText =
        'A long long long long long long long long long long long long text';

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              Stepper(
                steps: const <Step>[
                  Step(
                    title: Text(longText),
                    content: Text('Text content')
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Stepper header subtitle should not overflow', (WidgetTester tester) async {
    const String longText =
        'A long long long long long long long long long long long long text';

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              Stepper(
                steps: const <Step>[
                  Step(
                    title: Text('Regular title'),
                    subtitle: Text(longText),
                    content: Text('Text content')
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Stepper enabled button styles', (WidgetTester tester) async {
    Widget buildFrame(ThemeData theme) {
      return MaterialApp(
        theme: theme,
        home: Material(
          child: Stepper(
            type: StepperType.horizontal,
            onStepCancel: () { },
            onStepContinue: () { },
            steps: const <Step>[
              Step(
                title: Text('step1'),
                content: SizedBox(width: 100, height: 100),
              ),
            ],
          ),
        ),
      );
    }

    Material buttonMaterial(String label) {
      return tester.widget<Material>(
        find.descendant(of: find.widgetWithText(TextButton, label), matching: find.byType(Material))
      );
    }

    // The checks that follow verify that the layout and appearance of
    // the default enabled Stepper buttons have not changed even
    // though the FlatButtons have been replaced by TextButtons.

    const OutlinedBorder buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2)));
    const Rect continueButtonRect = Rect.fromLTRB(24.0, 212.0, 168.0, 260.0);
    const Rect cancelButtonRect = Rect.fromLTRB(176.0, 212.0, 292.0, 260.0);

    await tester.pumpWidget(buildFrame(ThemeData.light()));

    expect(buttonMaterial('CONTINUE').color.value, 0xff2196f3);
    expect(buttonMaterial('CONTINUE').textStyle.color.value, 0xffffffff);
    expect(buttonMaterial('CONTINUE').shape, buttonShape);
    expect(tester.getRect(find.widgetWithText(TextButton, 'CONTINUE')), continueButtonRect);

    expect(buttonMaterial('CANCEL').color.value, 0);
    expect(buttonMaterial('CANCEL').textStyle.color.value, 0x8a000000);
    expect(buttonMaterial('CANCEL').shape, buttonShape);
    expect(tester.getRect(find.widgetWithText(TextButton, 'CANCEL')), cancelButtonRect);

    await tester.pumpWidget(buildFrame(ThemeData.dark()));
    await tester.pumpAndSettle(); // Complete the theme animation.

    expect(buttonMaterial('CONTINUE').color.value, 0);
    expect(buttonMaterial('CONTINUE').textStyle.color.value,  0xffffffff);
    expect(buttonMaterial('CONTINUE').shape, buttonShape);
    expect(tester.getRect(find.widgetWithText(TextButton, 'CONTINUE')), continueButtonRect);

    expect(buttonMaterial('CANCEL').color.value, 0);
    expect(buttonMaterial('CANCEL').textStyle.color.value, 0xb3ffffff);
    expect(buttonMaterial('CANCEL').shape, buttonShape);
    expect(tester.getRect(find.widgetWithText(TextButton, 'CANCEL')), cancelButtonRect);
  });

  testWidgets('Stepper disabled button styles', (WidgetTester tester) async {
    Widget buildFrame(ThemeData theme) {
      return MaterialApp(
        theme: theme,
        home: Material(
          child: Stepper(
            type: StepperType.horizontal,
            steps: const <Step>[
              Step(
                title: Text('step1'),
                content: SizedBox(width: 100, height: 100),
              ),
            ],
          ),
        ),
      );
    }

    Material buttonMaterial(String label) {
      return tester.widget<Material>(
        find.descendant(of: find.widgetWithText(TextButton, label), matching: find.byType(Material))
      );
    }

    // The checks that follow verify that the appearance of the
    // default disabled Stepper buttons have not changed even though
    // the FlatButtons have been replaced by TextButtons.

    await tester.pumpWidget(buildFrame(ThemeData.light()));

    expect(buttonMaterial('CONTINUE').color.value, 0);
    expect(buttonMaterial('CONTINUE').textStyle.color.value, 0x61000000);

    expect(buttonMaterial('CANCEL').color.value, 0);
    expect(buttonMaterial('CANCEL').textStyle.color.value, 0x61000000);

    await tester.pumpWidget(buildFrame(ThemeData.dark()));
    await tester.pumpAndSettle(); // Complete the theme animation.

    expect(buttonMaterial('CONTINUE').color.value, 0);
    expect(buttonMaterial('CONTINUE').textStyle.color.value, 0x61ffffff);

    expect(buttonMaterial('CANCEL').color.value, 0);
    expect(buttonMaterial('CANCEL').textStyle.color.value, 0x61ffffff);
  });

  testWidgets('Vertical and Horizontal Stepper physics test', (WidgetTester tester) async {
    const ScrollPhysics physics = NeverScrollableScrollPhysics();

    for(final StepperType type in StepperType.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Stepper(
              physics: physics,
              type: type,
              steps: const <Step>[
                Step(
                  title: Text('Step 1'),
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final ListView listView = tester.widget<ListView>(find.descendant(of: find.byType(Stepper), matching: find.byType(ListView)));
      expect(listView.physics, physics);
    }
  });
}
