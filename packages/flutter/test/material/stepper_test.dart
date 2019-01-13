// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
      (BuildContext context, {VoidCallback onStepContinue, VoidCallback onStepCancel}) {
        return Container(
          margin: const EdgeInsets.only(top: 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints.tightFor(height: 48.0),
            child: Row(
              children: <Widget>[
                FlatButton(
                  onPressed: onStepContinue,
                  color: Colors.blue,
                  textColor: Colors.white,
                  textTheme: ButtonTextTheme.normal,
                  child: const Text('Let us continue!'),
                ),
                Container(
                  margin: const EdgeInsetsDirectional.only(start: 8.0),
                  child: FlatButton(
                    onPressed: onStepCancel,
                    textColor: Colors.red,
                    textTheme: ButtonTextTheme.normal,
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
}
