import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_image/octo_image.dart';

List<OctoPlaceholderBuilder> placeholderBuilders = [
  OctoPlaceholder.blurHash('LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
  OctoPlaceholder.circularProgressIndicator(),
  OctoPlaceholder.circleAvatar(
    backgroundColor: Colors.blue,
    text: const Text('T'),
  ),
  OctoPlaceholder.frame(),
];

List<OctoErrorBuilder> errorBuilders = [
  OctoError.circleAvatar(
    backgroundColor: Colors.blue,
    text: const Text('T'),
  ),
  OctoError.icon(),
];

List<OctoProgressIndicatorBuilder> progressIndicators = [
  OctoProgressIndicator.circularProgressIndicator(),
];

void main() {
  group('Placeholder tests', () {
    testWidgets('All placeholders return a widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                var list = <Widget>[];
                for (var element in placeholderBuilders) {
                  var placeholder = element(context);
                  expect(placeholder, isNotNull);
                  list.add(SizedBox(
                    height: 100,
                    child: placeholder,
                  ));
                }
                return ListView(
                  children: list,
                );
              },
            ),
          ),
        ),
      );
    });
  });

  group('ErrorBuilder tests', () {
    testWidgets('All errorBuilders return a widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                var list = <Widget>[];
                for (var element in errorBuilders) {
                  var errorWidget = element(context, Exception(), null);
                  expect(errorWidget, isNotNull);
                  list.add(SizedBox(
                    height: 100,
                    child: errorWidget,
                  ));
                }
                return ListView(
                  children: list,
                );
              },
            ),
          ),
        ),
      );
    });
  });

  group('Progress indicator tests', () {
    testWidgets('ProgressIndicators handle known progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                var list = <Widget>[];
                for (var element in progressIndicators) {
                  var knownProgress = element(
                    context,
                    const ImageChunkEvent(
                      cumulativeBytesLoaded: 5,
                      expectedTotalBytes: 10,
                    ),
                  );
                  expect(knownProgress, isNotNull);
                  list.add(SizedBox(
                    height: 100,
                    child: knownProgress,
                  ));
                }
                return ListView(
                  children: list,
                );
              },
            ),
          ),
        ),
      );
    });

    testWidgets('ProgressIndicators handle unknown progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                var list = <Widget>[];
                for (var element in progressIndicators) {
                  var unknownProgress = element(context, null);
                  expect(unknownProgress, isNotNull);
                  list.add(SizedBox(
                    height: 100,
                    child: unknownProgress,
                  ));
                }
                return ListView(
                  children: list,
                );
              },
            ),
          ),
        ),
      );
    });

    testWidgets('ProgressIndicators handle unknown size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                var list = <Widget>[];
                for (var element in progressIndicators) {
                  var unknownSize = element(
                    context,
                    const ImageChunkEvent(
                      cumulativeBytesLoaded: 5,
                      expectedTotalBytes: null,
                    ),
                  );
                  expect(unknownSize, isNotNull);
                  list.add(SizedBox(
                    height: 100,
                    child: unknownSize,
                  ));
                }
                return ListView(
                  children: list,
                );
              },
            ),
          ),
        ),
      );
    });
  });
}
