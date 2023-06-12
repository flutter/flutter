import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octo_image/octo_image.dart';

import 'helpers/mock_image_provider.dart';

void main() {
  testWidgets('errorBuilder called when image fails', (tester) async {
    // Create the widget by telling the tester to build it.
    var thrown = false;
    await tester.pumpWidget(MyWidget(
      useCase: TestUseCase.loadAndFail,
      onError: () => thrown = true,
    ));
    await tester.pumpAndSettle();
    expect(thrown, isTrue);
  });

  testWidgets("errorBuilder doesn't call when image doesn't fail",
      (tester) async {
    // Create the widget by telling the tester to build it.
    var thrown = false;
    await tester.pumpWidget(MyWidget(
      useCase: TestUseCase.loadAndSuccess,
      onError: () => thrown = true,
    ));
    await tester.pumpAndSettle();
    expect(thrown, isFalse);
  });

  testWidgets('placeholder called when fail', (tester) async {
    // Create the widget by telling the tester to build it.
    var placeholderShown = false;
    var thrown = false;
    await tester.pumpWidget(MyWidget(
      useCase: TestUseCase.loadAndFail,
      onPlaceHolder: () => placeholderShown = true,
      onError: () => thrown = true,
    ));
    await tester.pumpAndSettle();
    expect(thrown, isTrue);
    expect(placeholderShown, isTrue);
  });

  testWidgets('placeholder called when success', (tester) async {
    // Create the widget by telling the tester to build it.
    var placeholderShown = false;
    var thrown = false;
    await tester.pumpWidget(MyWidget(
      useCase: TestUseCase.loadAndSuccess,
      onPlaceHolder: () => placeholderShown = true,
      onError: () => thrown = true,
    ));
    await tester.pumpAndSettle();
    expect(thrown, isFalse);
    expect(placeholderShown, isTrue);
  });

  testWidgets('placeholder called when success', (tester) async {
    // Create the widget by telling the tester to build it.
    var placeholderShown = false;
    var thrown = false;
    await tester.pumpWidget(MyWidget(
      useCase: TestUseCase.loadAndSuccess,
      onPlaceHolder: () => placeholderShown = true,
      onError: () => thrown = true,
    ));
    await tester.pumpAndSettle();
    expect(thrown, isFalse);
    expect(placeholderShown, isTrue);
  });

  testWidgets('progressIndicator called several times', (tester) async {
    // Create the widget by telling the tester to build it.
    var progressIndicatorCalled = 0;
    var thrown = false;
    await tester.pumpWidget(MyWidget(
      useCase: TestUseCase.loadAndSuccess,
      onProgress: () => progressIndicatorCalled++,
      onError: () => thrown = true,
    ));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(thrown, isFalse);
    expect(progressIndicatorCalled, 11);
  });
}

class MyWidget extends StatelessWidget {
  final TestUseCase useCase;
  final OctoProgressIndicatorBuilder? progressBuilder;
  final OctoPlaceholderBuilder? placeholderBuilder;
  final OctoErrorBuilder? errorBuilder;

  MyWidget({
    Key? key,
    required this.useCase,
    VoidCallback? onProgress,
    VoidCallback? onPlaceHolder,
    VoidCallback? onError,
  })  : progressBuilder = getProgress(onProgress),
        placeholderBuilder = getPlaceholder(onPlaceHolder),
        errorBuilder = getErrorBuilder(onError),
        super(key: key);

  static OctoProgressIndicatorBuilder? getProgress(VoidCallback? onProgress) {
    if (onProgress == null) return null;
    return (context, progress) {
      onProgress();
      return const CircularProgressIndicator();
    };
  }

  static OctoPlaceholderBuilder? getPlaceholder(VoidCallback? onPlaceHolder) {
    if (onPlaceHolder == null) return null;
    return (context) {
      onPlaceHolder();
      return const Placeholder();
    };
  }

  static OctoErrorBuilder? getErrorBuilder(VoidCallback? onError) {
    if (onError == null) return null;
    return (context, error, stacktrace) {
      onError();
      return const Icon(Icons.error);
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        body: Center(
          child: OctoImage(
            image: MockImageProvider(useCase: useCase),
            progressIndicatorBuilder: progressBuilder,
            placeholderBuilder: placeholderBuilder,
            errorBuilder: errorBuilder,
          ),
        ),
      ),
    );
  }
}
