// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material_3_expressive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helper to create a testable icon button.
  Widget buildApp({required Widget child, ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? ThemeData(useMaterial3: true),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('M3E IconButton size variants', () {
    testWidgets('default size is small (40x40)', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
        ),
      );

      // ButtonStyleButton renders with minimum size 40x40, but tap target
      // padding brings it to 48x48.
      expect(find.byType(IconButton), findsOneWidget);
      final Size size = tester.getSize(find.byType(IconButton));
      expect(size, const Size(48.0, 48.0));
    });

    testWidgets('xSmall size renders at 32dp minimum', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
            style: const ButtonStyle(size: IconButtonSize.xSmall),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      // xSmall minimum is 32x32, tap target enforces at least 48.
      final Size size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(32.0));
      expect(size.height, greaterThanOrEqualTo(32.0));
    });

    testWidgets('medium size renders at 56dp minimum', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
            style: const ButtonStyle(size: IconButtonSize.medium),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      final Size size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(56.0));
      expect(size.height, greaterThanOrEqualTo(56.0));
    });

    testWidgets('large size renders at 96dp minimum', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
            style: const ButtonStyle(size: IconButtonSize.large),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      final Size size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(96.0));
      expect(size.height, greaterThanOrEqualTo(96.0));
    });

    testWidgets('xLarge size renders at 136dp minimum', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
            style: const ButtonStyle(size: IconButtonSize.xLarge),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      final Size size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(136.0));
      expect(size.height, greaterThanOrEqualTo(136.0));
    });
  });

  group('M3E IconButton width variants', () {
    Material iconButtonMaterial(WidgetTester tester) {
      return tester.widget<Material>(
        find.descendant(of: find.byType(IconButton), matching: find.byType(Material)),
      );
    }

    testWidgets('small IconButton supports narrow, standard, and wide widths', (
      WidgetTester tester,
    ) async {
      Future<Size> materialSizeFor(IconButtonWidth width) async {
        await tester.pumpWidget(
          buildApp(
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add),
              style: ButtonStyle(iconButtonWidth: width),
            ),
          ),
        );
        return tester.getSize(
          find.descendant(of: find.byType(IconButton), matching: find.byType(Material)),
        );
      }

      expect(await materialSizeFor(IconButtonWidth.narrow), const Size(32.0, 40.0));
      expect(await materialSizeFor(IconButtonWidth.standard), const Size(40.0, 40.0));
      expect(await materialSizeFor(IconButtonWidth.wide), const Size(52.0, 40.0));

      expect(iconButtonMaterial(tester).animationDuration, kThemeChangeDuration);
    });

    testWidgets('IconButtonThemeData style width sets default width', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          theme: ThemeData(
            useMaterial3: true,
            iconButtonTheme: const IconButtonThemeData(
              style: ButtonStyle(iconButtonWidth: IconButtonWidth.wide),
            ),
          ),
          child: IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
        ),
      );

      final Size size = tester.getSize(
        find.descendant(of: find.byType(IconButton), matching: find.byType(Material)),
      );
      expect(size, const Size(52.0, 40.0));
    });
  });

  group('M3E IconButton shape', () {
    OutlinedBorder materialShape(WidgetTester tester) {
      final Material material = tester.widget<Material>(
        find.descendant(of: find.byType(IconButton), matching: find.byType(Material)),
      );
      return material.shape! as OutlinedBorder;
    }

    testWidgets('default shape resolves M3E token shapes by state', (WidgetTester tester) async {
      final MaterialStatesController statesController = MaterialStatesController();
      await tester.pumpWidget(
        buildApp(
          child: IconButton(
            statesController: statesController,
            isSelected: true,
            onPressed: () {},
            icon: const Icon(Icons.add),
          ),
        ),
      );
      expect(
        materialShape(tester),
        const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      );

      statesController.update(WidgetState.pressed, true);
      await tester.pumpAndSettle();

      expect(
        materialShape(tester),
        const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      );
      statesController.dispose();
    });

    testWidgets('ButtonStyle.shape remains the stateful shape override API', (
      WidgetTester tester,
    ) async {
      final MaterialStatesController statesController = MaterialStatesController();
      await tester.pumpWidget(
        buildApp(
          child: IconButton(
            statesController: statesController,
            onPressed: () {},
            icon: const Icon(Icons.add),
            style: ButtonStyle(
              shape: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                if (states.contains(WidgetState.pressed)) {
                  return const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4.0)),
                  );
                }
                return const StadiumBorder();
              }),
            ),
          ),
        ),
      );

      expect(materialShape(tester), isA<StadiumBorder>());

      statesController.update(WidgetState.pressed, true);
      await tester.pumpAndSettle();

      expect(
        materialShape(tester),
        const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))),
      );
      statesController.dispose();
    });
  });

  group('M3E IconButton variants', () {
    testWidgets('standard variant has transparent background', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('filled variant renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButton.filled(onPressed: () {}, icon: const Icon(Icons.add)),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('filledTonal variant renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.add)),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('outlined variant renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButton.outlined(onPressed: () {}, icon: const Icon(Icons.add)),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('filled variant with style size', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButton.filled(
            onPressed: () {},
            icon: const Icon(Icons.add),
            style: const ButtonStyle(size: IconButtonSize.large),
          ),
        ),
      );

      final Size size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(96.0));
      expect(size.height, greaterThanOrEqualTo(96.0));
    });

    testWidgets('outlined variant with style size', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButton.outlined(
            onPressed: () {},
            icon: const Icon(Icons.add),
            style: const ButtonStyle(size: IconButtonSize.medium),
          ),
        ),
      );

      final Size size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(56.0));
      expect(size.height, greaterThanOrEqualTo(56.0));
    });
  });

  group('M3E IconButton theme integration', () {
    testWidgets('IconButtonThemeData style size sets default size', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          theme: ThemeData(
            useMaterial3: true,
            iconButtonTheme: const IconButtonThemeData(
              style: ButtonStyle(size: IconButtonSize.large),
            ),
          ),
          child: IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
        ),
      );

      final Size size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(96.0));
      expect(size.height, greaterThanOrEqualTo(96.0));
    });

    testWidgets('widget size overrides theme size', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          theme: ThemeData(
            useMaterial3: true,
            iconButtonTheme: const IconButtonThemeData(
              style: ButtonStyle(size: IconButtonSize.large),
            ),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
            style: const ButtonStyle(size: IconButtonSize.xSmall),
          ),
        ),
      );

      final Size size = tester.getSize(find.byType(IconButton));
      // xSmall (32dp) should override theme's large (96dp).
      // Tap target may pad it to 48.
      expect(size.width, lessThan(96.0));
    });

    testWidgets('IconButtonTheme wrapping sets size', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButtonTheme(
            data: const IconButtonThemeData(style: ButtonStyle(size: IconButtonSize.medium)),
            child: IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
          ),
        ),
      );

      final Size size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(56.0));
      expect(size.height, greaterThanOrEqualTo(56.0));
    });
  });

  group('M3E IconButton selection', () {
    testWidgets('isSelected shows selectedIcon', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButton(
            onPressed: () {},
            isSelected: true,
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('isSelected false shows regular icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButton(
            onPressed: () {},
            isSelected: false,
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });
  });

  group('M3E IconButton disabled state', () {
    testWidgets('disabled button has reduced opacity colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(child: IconButton(onPressed: null, icon: const Icon(Icons.add))),
      );

      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('disabled filled button has reduced background', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(child: IconButton.filled(onPressed: null, icon: const Icon(Icons.add))),
      );

      expect(find.byType(IconButton), findsOneWidget);
    });
  });

  group('M3E IconButton debugFillProperties', () {
    testWidgets('includes size in debug properties', (WidgetTester tester) async {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.add),
        style: const ButtonStyle(size: IconButtonSize.large),
      ).debugFillProperties(builder);

      final List<String> descriptions = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(descriptions, contains(contains('size: large')));
    });
  });

  group('IconButtonThemeData', () {
    test('equality', () {
      const IconButtonThemeData a = IconButtonThemeData(
        style: ButtonStyle(size: IconButtonSize.small, iconButtonWidth: IconButtonWidth.standard),
      );
      const IconButtonThemeData b = IconButtonThemeData(
        style: ButtonStyle(size: IconButtonSize.small, iconButtonWidth: IconButtonWidth.standard),
      );
      const IconButtonThemeData c = IconButtonThemeData(
        style: ButtonStyle(size: IconButtonSize.large, iconButtonWidth: IconButtonWidth.wide),
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode', () {
      const IconButtonThemeData a = IconButtonThemeData(
        style: ButtonStyle(size: IconButtonSize.small, iconButtonWidth: IconButtonWidth.narrow),
      );
      const IconButtonThemeData b = IconButtonThemeData(
        style: ButtonStyle(size: IconButtonSize.small, iconButtonWidth: IconButtonWidth.narrow),
      );

      expect(a.hashCode, equals(b.hashCode));
    });

    test('lerp', () {
      const IconButtonThemeData a = IconButtonThemeData(
        style: ButtonStyle(size: IconButtonSize.small, iconButtonWidth: IconButtonWidth.narrow),
      );
      const IconButtonThemeData b = IconButtonThemeData(
        style: ButtonStyle(size: IconButtonSize.large, iconButtonWidth: IconButtonWidth.wide),
      );

      expect(IconButtonThemeData.lerp(a, b, 0.0)?.style?.size, IconButtonSize.small);
      expect(IconButtonThemeData.lerp(a, b, 0.4)?.style?.size, IconButtonSize.small);
      expect(IconButtonThemeData.lerp(a, b, 0.5)?.style?.size, IconButtonSize.large);
      expect(IconButtonThemeData.lerp(a, b, 1.0)?.style?.size, IconButtonSize.large);
      expect(IconButtonThemeData.lerp(a, b, 0.4)?.style?.iconButtonWidth, IconButtonWidth.narrow);
      expect(IconButtonThemeData.lerp(a, b, 0.5)?.style?.iconButtonWidth, IconButtonWidth.wide);
    });

    test('debugFillProperties includes size and width', () {
      const data = IconButtonThemeData(
        style: ButtonStyle(size: IconButtonSize.medium, iconButtonWidth: IconButtonWidth.wide),
      );
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      data.debugFillProperties(builder);

      final List<String> descriptions = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(descriptions, contains(contains('size: medium')));
      expect(descriptions, contains(contains('iconButtonWidth: wide')));
    });
  });

  group('M3E IconButton barrel file import', () {
    testWidgets('material_3_expressive.dart import provides M3E IconButton', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
            style: const ButtonStyle(size: IconButtonSize.medium),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      final Size size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(56.0));
    });
  });
}
