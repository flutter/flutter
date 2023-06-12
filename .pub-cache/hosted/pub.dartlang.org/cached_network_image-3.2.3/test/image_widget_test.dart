import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_cache_manager.dart';
import 'image_data.dart';

void main() {
  late FakeCacheManager cacheManager;

  setUp(() {
    cacheManager = FakeCacheManager();
  });

  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  group('test logger', () {
    test('set log level', () {
      CachedNetworkImage.logLevel = CacheManagerLogLevel.verbose;
      expect(CachedNetworkImage.logLevel, CacheManagerLogLevel.verbose);

      CachedNetworkImage.logLevel = CacheManagerLogLevel.debug;
      expect(CachedNetworkImage.logLevel, CacheManagerLogLevel.debug);

      CachedNetworkImage.logLevel = CacheManagerLogLevel.warning;
      expect(CachedNetworkImage.logLevel, CacheManagerLogLevel.warning);

      CachedNetworkImage.logLevel = CacheManagerLogLevel.none;
      expect(CachedNetworkImage.logLevel, CacheManagerLogLevel.none);
    });
  });

  group('widget tests', () {
    testWidgets('progress indicator called when success', (tester) async {
      var imageUrl = '123';
      // Create the widget by telling the tester to build it.
      cacheManager.returns(imageUrl, kTransparentImage);
      var progressShown = false;
      var thrown = false;
      await tester.pumpWidget(MyImageWidget(
        imageUrl: imageUrl,
        cacheManager: cacheManager,
        onProgress: () => progressShown = true,
        onError: () => thrown = true,
      ));
      await tester.pump();
      expect(thrown, isFalse);
      expect(progressShown, isTrue);
    });

    testWidgets('placeholder called when fail', (tester) async {
      var imageUrl = '1234';
      // Create the widget by telling the tester to build it.
      cacheManager.throwsNotFound(imageUrl);
      var placeholderShown = false;
      var thrown = false;
      await tester.pumpWidget(MyImageWidget(
        imageUrl: imageUrl,
        cacheManager: cacheManager,
        onPlaceHolder: () => placeholderShown = true,
        onError: () => thrown = true,
      ));
      await tester.pumpAndSettle();
      expect(thrown, isTrue);
      expect(placeholderShown, isTrue);
    });

    testWidgets('errorBuilder called when image fails', (tester) async {
      var imageUrl = '12345';
      cacheManager.throwsNotFound(imageUrl);
      var thrown = false;
      await tester.pumpWidget(MyImageWidget(
        imageUrl: imageUrl,
        cacheManager: cacheManager,
        onError: () => thrown = true,
      ));
      await tester.pumpAndSettle();
      expect(thrown, isTrue);
    });

    testWidgets("errorBuilder doesn't call when image doesn't fail",
        (tester) async {
      var imageUrl = '123456';
      // Create the widget by telling the tester to build it.
      cacheManager.returns(imageUrl, kTransparentImage);
      var thrown = false;
      await tester.pumpWidget(MyImageWidget(
        imageUrl: imageUrl,
        cacheManager: cacheManager,
        onError: () => thrown = true,
      ));
      await tester.pumpAndSettle();
      expect(thrown, isFalse);
    });

    testWidgets('placeholder called when success', (tester) async {
      var imageUrl = '789';
      // Create the widget by telling the tester to build it.
      cacheManager.returns(imageUrl, kTransparentImage);
      var placeholderShown = false;
      var thrown = false;
      await tester.pumpWidget(MyImageWidget(
        imageUrl: imageUrl,
        cacheManager: cacheManager,
        onPlaceHolder: () => placeholderShown = true,
        onError: () => thrown = true,
      ));
      await tester.pumpAndSettle();
      expect(thrown, isFalse);
      expect(placeholderShown, isTrue);
    });

    testWidgets('progressIndicator called several times', (tester) async {
      var imageUrl = '7891';
      // Create the widget by telling the tester to build it.
      var delay = const Duration(milliseconds: 1);
      var expectedResult = cacheManager.returns(
        imageUrl,
        kTransparentImage,
        delayBetweenChunks: delay,
      );
      var progressIndicatorCalled = 0;
      var thrown = false;
      await tester.pumpWidget(MyImageWidget(
        imageUrl: imageUrl,
        cacheManager: cacheManager,
        onProgress: () => progressIndicatorCalled++,
        onError: () => thrown = true,
      ));
      for (var i = 0; i < expectedResult.chunks; i++) {
        await tester.pump(delay);
        await tester.idle();
      }
      expect(thrown, isFalse);
      expect(progressIndicatorCalled, expectedResult.chunks + 1);
    });
  });
}

class MyImageWidget extends StatelessWidget {
  final FakeCacheManager cacheManager;
  final ProgressIndicatorBuilder? progressBuilder;
  final PlaceholderWidgetBuilder? placeholderBuilder;
  final LoadingErrorWidgetBuilder? errorBuilder;
  final String imageUrl;

  MyImageWidget({
    Key? key,
    required this.imageUrl,
    required this.cacheManager,
    VoidCallback? onProgress,
    VoidCallback? onPlaceHolder,
    VoidCallback? onError,
  })  : progressBuilder = getProgress(onProgress),
        placeholderBuilder = getPlaceholder(onPlaceHolder),
        errorBuilder = getErrorBuilder(onError),
        super(key: key);

  static ProgressIndicatorBuilder? getProgress(VoidCallback? onProgress) {
    if (onProgress == null) return null;
    return (context, url, progress) {
      onProgress();
      return const CircularProgressIndicator();
    };
  }

  static PlaceholderWidgetBuilder? getPlaceholder(VoidCallback? onPlaceHolder) {
    if (onPlaceHolder == null) return null;
    return (context, url) {
      onPlaceHolder();
      return const Placeholder();
    };
  }

  static LoadingErrorWidgetBuilder? getErrorBuilder(VoidCallback? onError) {
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
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            cacheManager: cacheManager,
            progressIndicatorBuilder: progressBuilder,
            placeholder: placeholderBuilder,
            errorWidget: errorBuilder,
          ),
        ),
      ),
    );
  }
}
