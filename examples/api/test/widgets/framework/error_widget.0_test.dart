import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/framework/error_widget.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorWidgetExampleApp', () {
    group('Debug Mode', () {
      setUp(() {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return ErrorWidget(details.exception);
        };
      });

      testWidgets('Shows debug error widget in debug mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(const example.ErrorWidgetExampleApp());

        expect(find.widgetWithText(AppBar, 'ErrorWidget Sample'), findsOne);

        await tester.tap(find.widgetWithText(TextButton, 'Error Prone'));
        await tester.pump();

        expectLater(tester.takeException(), isInstanceOf<Exception>());

        final Finder errorWidget = find.byType(ErrorWidget);
        expect(errorWidget, findsOneWidget);
        final ErrorWidget error = tester.firstWidget(errorWidget);
        expect(error.message, 'Exception: oh no, an error');
      });

      group(
        'Release Mode',
        () {
          setUp(() {
            ErrorWidget.builder = (FlutterErrorDetails details) {
              return Container(
                alignment: Alignment.center,
                child: Text(
                  'Error!\n${details.exception}',
                  style: const TextStyle(color: Colors.yellow),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                ),
              );
            };
          });

          testWidgets(
            'Shows error widget in release mode',
            (WidgetTester tester) async {
              await tester.pumpWidget(const example.ErrorWidgetExampleApp());

              expect(
                  find.widgetWithText(AppBar, 'ErrorWidget Sample'), findsOne);

              await tester.tap(find.widgetWithText(TextButton, 'Error Prone'));
              await tester.pump();

              expectLater(tester.takeException(), isInstanceOf<Exception>());

              final Finder errorTextFinder =
                  find.textContaining('Error!\nException: oh no, an error');

              expect(errorTextFinder, findsOneWidget);

              final Text errorText = tester.firstWidget(errorTextFinder);
              expect(errorText.style?.color, Colors.yellow);
            },
          );
        },
      );
    });
  });
}
