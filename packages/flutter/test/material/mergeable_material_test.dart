  // Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

enum RadiusType {
  Sharp,
  Shifting,
  Round
}

void matches(BorderRadius borderRadius, RadiusType top, RadiusType bottom) {
  final Radius cardRadius = kMaterialEdges[MaterialType.card].topLeft;

  if (top == RadiusType.Sharp) {
    expect(borderRadius.topLeft, equals(Radius.zero));
    expect(borderRadius.topRight, equals(Radius.zero));
  } else if (top == RadiusType.Shifting) {
    expect(borderRadius.topLeft.x, greaterThan(0.0));
    expect(borderRadius.topLeft.x, lessThan(cardRadius.x));
    expect(borderRadius.topLeft.y, greaterThan(0.0));
    expect(borderRadius.topLeft.y, lessThan(cardRadius.y));
    expect(borderRadius.topRight.x, greaterThan(0.0));
    expect(borderRadius.topRight.x, lessThan(cardRadius.x));
    expect(borderRadius.topRight.y, greaterThan(0.0));
    expect(borderRadius.topRight.y, lessThan(cardRadius.y));
  } else {
    expect(borderRadius.topLeft, equals(cardRadius));
    expect(borderRadius.topRight, equals(cardRadius));
  }

  if (bottom == RadiusType.Sharp) {
    expect(borderRadius.bottomLeft, equals(Radius.zero));
    expect(borderRadius.bottomRight, equals(Radius.zero));
  } else if (bottom == RadiusType.Shifting) {
    expect(borderRadius.bottomLeft.x, greaterThan(0.0));
    expect(borderRadius.bottomLeft.x, lessThan(cardRadius.x));
    expect(borderRadius.bottomLeft.y, greaterThan(0.0));
    expect(borderRadius.bottomLeft.y, lessThan(cardRadius.y));
    expect(borderRadius.bottomRight.x, greaterThan(0.0));
    expect(borderRadius.bottomRight.x, lessThan(cardRadius.x));
    expect(borderRadius.bottomRight.y, greaterThan(0.0));
    expect(borderRadius.bottomRight.y, lessThan(cardRadius.y));
  } else {
    expect(borderRadius.bottomLeft, equals(cardRadius));
    expect(borderRadius.bottomRight, equals(cardRadius));
  }
}

// Returns the border radius decoration of an item within a MergeableMaterial.
// This depends on the exact structure of objects built by the Material and
// MergeableMaterial widgets.
BorderRadius getBorderRadius(WidgetTester tester, int index) {
  final List<Element> containers = tester.elementList(find.byType(Container))
                                   .toList();

  final Container container = containers[index].widget;
  final BoxDecoration boxDecoration = container.decoration;

  return boxDecoration.borderRadius;
}

void main() {
  testWidgets('MergeableMaterial empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial()
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(MergeableMaterial));
    expect(box.size.height, equals(0));
  });

  testWidgets('MergeableMaterial update slice', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    RenderBox box = tester.renderObject(find.byType(MergeableMaterial));
    expect(box.size.height, equals(100.0));

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 200.0
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    box = tester.renderObject(find.byType(MergeableMaterial));
    expect(box.size.height, equals(200.0));
  });

  testWidgets('MergeableMaterial swap slices', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    RenderBox box = tester.renderObject(find.byType(MergeableMaterial));
    expect(box.size.height, equals(200.0));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    box = tester.renderObject(find.byType(MergeableMaterial));
    expect(box.size.height, equals(200.0));

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, equals(200.0));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);
  });

  testWidgets('MergeableMaterial paints shadows', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final BoxShadow boxShadow = kElevationToShadow[2][0];
    final RRect rrect = kMaterialEdges[MaterialType.card].toRRect(
      new Rect.fromLTRB(0.0, 0.0, 800.0, 100.0)
    );
    expect(
      find.byType(MergeableMaterial),
      paints..rrect(rrect: rrect, color: boxShadow.color, hasMaskFilter: true),
    );
  });

  testWidgets('MergeableMaterial merge gap', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('x')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(MergeableMaterial));
    expect(box.size.height, equals(216));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);
    matches(getBorderRadius(tester, 1), RadiusType.Round, RadiusType.Round);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, lessThan(216));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Shifting);
    matches(getBorderRadius(tester, 1), RadiusType.Shifting, RadiusType.Round);

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, equals(200));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Sharp);
    matches(getBorderRadius(tester, 1), RadiusType.Sharp, RadiusType.Round);
  });

  testWidgets('MergeableMaterial separate slices', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(MergeableMaterial));
    expect(box.size.height, equals(200));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('x')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, lessThan(216));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Shifting);
    matches(getBorderRadius(tester, 1), RadiusType.Shifting, RadiusType.Round);

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, equals(216));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);
    matches(getBorderRadius(tester, 1), RadiusType.Round, RadiusType.Round);
  });

  testWidgets('MergeableMaterial separate merge separate', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    final RenderBox box = tester.renderObject(find.byType(MergeableMaterial));
    expect(box.size.height, equals(200));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('x')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, lessThan(216));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Shifting);
    matches(getBorderRadius(tester, 1), RadiusType.Shifting, RadiusType.Round);

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, equals(216));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);
    matches(getBorderRadius(tester, 1), RadiusType.Round, RadiusType.Round);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, lessThan(216));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Shifting);
    matches(getBorderRadius(tester, 1), RadiusType.Shifting, RadiusType.Round);

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, equals(200));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Sharp);
    matches(getBorderRadius(tester, 1), RadiusType.Sharp, RadiusType.Round);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('x')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, lessThan(216));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Shifting);
    matches(getBorderRadius(tester, 1), RadiusType.Shifting, RadiusType.Round);

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, equals(216));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);
    matches(getBorderRadius(tester, 1), RadiusType.Round, RadiusType.Round);
  });

  testWidgets('MergeableMaterial insert slice', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('C'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    final RenderBox box = tester.renderObject(find.byType(MergeableMaterial));
    expect(box.size.height, equals(200));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('C'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    expect(box.size.height, equals(300));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);
  });

  testWidgets('MergeableMaterial remove slice', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('C'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    final RenderBox box = tester.renderObject(find.byType(MergeableMaterial));
    expect(box.size.height, equals(300));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('C'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    await tester.pump();
    expect(box.size.height, equals(200));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);
  });

  testWidgets('MergeableMaterial insert chunk', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('C'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    final RenderBox box = tester.renderObject(find.byType(MergeableMaterial));
    expect(box.size.height, equals(200));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('x')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('y')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('C'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, lessThan(332));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Shifting);
    matches(getBorderRadius(tester, 1), RadiusType.Shifting, RadiusType.Shifting);
    matches(getBorderRadius(tester, 2), RadiusType.Shifting, RadiusType.Round);

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, equals(332));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);
    matches(getBorderRadius(tester, 1), RadiusType.Round, RadiusType.Round);
    matches(getBorderRadius(tester, 2), RadiusType.Round, RadiusType.Round);
  });

  testWidgets('MergeableMaterial remove chunk', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('x')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('y')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('C'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    final RenderBox box = tester.renderObject(find.byType(MergeableMaterial));
    expect(box.size.height, equals(332));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);
    matches(getBorderRadius(tester, 1), RadiusType.Round, RadiusType.Round);
    matches(getBorderRadius(tester, 2), RadiusType.Round, RadiusType.Round);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('C'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, lessThan(332));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Shifting);
    matches(getBorderRadius(tester, 1), RadiusType.Shifting, RadiusType.Round);

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, equals(200));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Sharp);
    matches(getBorderRadius(tester, 1), RadiusType.Sharp, RadiusType.Round);
  });

  testWidgets('MergeableMaterial replace gap with chunk', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('x')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('C'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    final RenderBox box = tester.renderObject(find.byType(MergeableMaterial));
    expect(box.size.height, equals(216));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);
    matches(getBorderRadius(tester, 1), RadiusType.Round, RadiusType.Round);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('y')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('z')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('C'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, lessThan(332));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Shifting);
    matches(getBorderRadius(tester, 1), RadiusType.Shifting, RadiusType.Shifting);
    matches(getBorderRadius(tester, 2), RadiusType.Shifting, RadiusType.Round);

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, equals(332));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);
    matches(getBorderRadius(tester, 1), RadiusType.Round, RadiusType.Round);
    matches(getBorderRadius(tester, 2), RadiusType.Round, RadiusType.Round);
  });

  testWidgets('MergeableMaterial replace chunk with gap', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('x')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('y')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('C'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    final RenderBox box = tester.renderObject(find.byType(MergeableMaterial));
    expect(box.size.height, equals(332));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);
    matches(getBorderRadius(tester, 1), RadiusType.Round, RadiusType.Round);
    matches(getBorderRadius(tester, 2), RadiusType.Round, RadiusType.Round);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('z')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('C'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, lessThan(332));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Shifting);
    matches(getBorderRadius(tester, 1), RadiusType.Shifting, RadiusType.Round);

    await tester.pump(const Duration(milliseconds: 100));
    expect(box.size.height, equals(216));

    matches(getBorderRadius(tester, 0), RadiusType.Round, RadiusType.Round);
    matches(getBorderRadius(tester, 1), RadiusType.Round, RadiusType.Round);
  });

  bool isDivider(Widget widget, bool top, bool bottom) {
    final DecoratedBox box = widget;
    const BorderSide side = const BorderSide(color: const Color(0x1F000000), width: 0.5);

    return box.decoration == new BoxDecoration(
      border: new Border(
        top: top ? side : BorderSide.none,
        bottom: bottom ? side : BorderSide.none
      )
    );
  }

  testWidgets('MergeableMaterial dividers', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              hasDividers: true,
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('C'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('D'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    List<Widget> boxes = tester.widgetList(find.byType(DecoratedBox)).toList();
    int offset = 1;

    expect(isDivider(boxes[offset], false, true), isTrue);
    expect(isDivider(boxes[offset + 1], true, true), isTrue);
    expect(isDivider(boxes[offset + 2], true, true), isTrue);
    expect(isDivider(boxes[offset + 3], true, false), isTrue);

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: const MergeableMaterial(
              hasDividers: true,
              children: const <MergeableMaterialItem>[
                const MaterialSlice(
                  key: const ValueKey<String>('A'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('B'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialGap(
                  key: const ValueKey<String>('x')
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('C'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                ),
                const MaterialSlice(
                  key: const ValueKey<String>('D'),
                  child: const SizedBox(
                    width: 100.0,
                    height: 100.0
                  )
                )
              ]
            )
          )
        )
      )
    );

    // Wait for dividers to shrink.
    await tester.pump(const Duration(milliseconds: 200));

    boxes = tester.widgetList(find.byType(DecoratedBox)).toList();
    offset = 1;

    expect(isDivider(boxes[offset], false, true), isTrue);
    expect(isDivider(boxes[offset + 1], true, false), isTrue);
    // offset + 2 is gap
    expect(isDivider(boxes[offset + 3], false, true), isTrue);
    expect(isDivider(boxes[offset + 4], true, false), isTrue);
  });
}
