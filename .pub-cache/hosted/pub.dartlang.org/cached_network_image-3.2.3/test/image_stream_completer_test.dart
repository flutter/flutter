// Copyright 2020 Rene Floor. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FakeFrameInfo implements FrameInfo {
  const FakeFrameInfo(this._duration, this._image);

  final Duration _duration;
  final Image _image;

  @override
  Duration get duration => _duration;

  @override
  Image get image => _image;

  int get imageHandleCount => image.debugGetOpenHandleStackTraces()!.length;

  FakeFrameInfo clone() {
    return FakeFrameInfo(
      _duration,
      _image.clone(),
    );
  }
}

class MockCodec implements Codec {
  @override
  int frameCount = 1;

  @override
  int repetitionCount = 1;

  int numFramesAsked = 0;

  Completer<FrameInfo> _nextFrameCompleter = Completer<FrameInfo>();

  @override
  Future<FrameInfo> getNextFrame() {
    numFramesAsked += 1;
    return _nextFrameCompleter.future;
  }

  void completeNextFrame(FrameInfo frameInfo) {
    _nextFrameCompleter.complete(frameInfo);
    _nextFrameCompleter = Completer<FrameInfo>();
  }

  void failNextFrame(String err) {
    _nextFrameCompleter.completeError(err);
  }

  @override
  void dispose() {}
}

class FakeEventReportingImageStreamCompleter extends ImageStreamCompleter {
  FakeEventReportingImageStreamCompleter(
      {Stream<ImageChunkEvent>? chunkEvents}) {
    if (chunkEvents != null) {
      chunkEvents.listen(
        (ImageChunkEvent event) {
          reportImageChunkEvent(event);
        },
      );
    }
  }
}

void main() {
  late Image image20x10;
  late Image image200x100;
  late Image image300x100;
  setUp(() async {
    image20x10 = await createTestImage(width: 20, height: 10);
    image200x100 = await createTestImage(width: 200, height: 100);
    image300x100 = await createTestImage(width: 300, height: 100);
  });

  testWidgets('Codec future fails', (WidgetTester tester) async {
    final codecStream = StreamController<Codec>();
    MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );
    codecStream.addError('failure message');
    await tester.idle();
    expect(tester.takeException(), 'failure message');
  });

  test('Completer unsubscribes to chunk events when disposed', () async {
    final codecStream = StreamController<Codec>();
    final chunkStream = StreamController<ImageChunkEvent>();

    final MultiImageStreamCompleter completer = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
      chunkEvents: chunkStream.stream,
    );

    expect(chunkStream.hasListener, true);

    chunkStream.add(
        const ImageChunkEvent(cumulativeBytesLoaded: 1, expectedTotalBytes: 3));

    final ImageStreamListener listener =
        ImageStreamListener((ImageInfo info, bool syncCall) {});
    // Cause the completer to dispose.
    completer.addListener(listener);
    completer.removeListener(listener);

    expect(chunkStream.hasListener, false);

    // The above expectation should cover this, but the point of this test is to
    // make sure the completer does not assert that it's disposed and still
    // receiving chunk events. Streams from the network can keep sending data
    // even after evicting an image from the cache, for example.
    chunkStream.add(
        const ImageChunkEvent(cumulativeBytesLoaded: 2, expectedTotalBytes: 3));
  });

  testWidgets('Decoding starts when a listener is added after codec is ready',
      (WidgetTester tester) async {
    final codecStream = StreamController<Codec>();
    final mockCodec = MockCodec();
    mockCodec.frameCount = 1;
    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    codecStream.add(mockCodec);
    await tester.idle();
    expect(mockCodec.numFramesAsked, 0);

    listener(ImageInfo image, bool synchronousCall) {}
    imageStream.addListener(ImageStreamListener(listener));
    await tester.idle();
    expect(mockCodec.numFramesAsked, 1);
  });

  testWidgets('Decoding starts when a codec is ready after a listener is added',
      (WidgetTester tester) async {
    final codecStream = StreamController<Codec>();
    final mockCodec = MockCodec();
    mockCodec.frameCount = 1;
    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    listener(ImageInfo image, bool synchronousCall) {}
    imageStream.addListener(ImageStreamListener(listener));
    await tester.idle();
    expect(mockCodec.numFramesAsked, 0);

    codecStream.add(mockCodec);
    await tester.idle();
    expect(mockCodec.numFramesAsked, 1);
  });

  testWidgets('Adding a second codec triggers start decoding',
      (WidgetTester tester) async {
    final codecStream = StreamController<Codec>();
    final firstCodec = MockCodec();
    final secondCodec = MockCodec();
    firstCodec.frameCount = 1;
    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    listener(ImageInfo image, bool synchronousCall) {}
    imageStream.addListener(ImageStreamListener(listener));
    await tester.idle();
    expect(firstCodec.numFramesAsked, 0);

    codecStream.add(firstCodec);
    await tester.idle();
    expect(firstCodec.numFramesAsked, 1);

    expect(secondCodec.numFramesAsked, 0);

    codecStream.add(secondCodec);
    await tester.idle();
    expect(secondCodec.numFramesAsked, 1);
  });

  testWidgets('Decoding does not crash when disposed',
      (WidgetTester tester) async {
    final codecStream = StreamController<Codec>();
    final mockCodec = MockCodec();
    mockCodec.frameCount = 1;
    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    codecStream.add(mockCodec);
    await tester.idle();
    expect(mockCodec.numFramesAsked, 0);

    listener(ImageInfo image, bool synchronousCall) {}
    final streamListener = ImageStreamListener(listener);
    imageStream.addListener(streamListener);
    await tester.idle();
    expect(mockCodec.numFramesAsked, 1);

    final FrameInfo frame =
        FakeFrameInfo(const Duration(milliseconds: 200), image20x10);
    mockCodec.completeNextFrame(frame);
    imageStream.removeListener(streamListener);
    await tester.idle();
  });

  testWidgets('Chunk events of base ImageStreamCompleter are delivered',
      (WidgetTester tester) async {
    final chunkEvents = <ImageChunkEvent>[];
    final streamController = StreamController<ImageChunkEvent>();
    final ImageStreamCompleter imageStream =
        FakeEventReportingImageStreamCompleter(
      chunkEvents: streamController.stream,
    );

    imageStream.addListener(ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {},
      onChunk: (ImageChunkEvent event) {
        chunkEvents.add(event);
      },
    ));
    streamController.add(
        const ImageChunkEvent(cumulativeBytesLoaded: 1, expectedTotalBytes: 3));
    streamController.add(
        const ImageChunkEvent(cumulativeBytesLoaded: 2, expectedTotalBytes: 3));
    await tester.idle();

    expect(chunkEvents.length, 2);
    expect(chunkEvents[0].cumulativeBytesLoaded, 1);
    expect(chunkEvents[0].expectedTotalBytes, 3);
    expect(chunkEvents[1].cumulativeBytesLoaded, 2);
    expect(chunkEvents[1].expectedTotalBytes, 3);
  });

  testWidgets(
      'Chunk events of base ImageStreamCompleter are not buffered before listener registration',
      (WidgetTester tester) async {
    final chunkEvents = <ImageChunkEvent>[];
    final streamController = StreamController<ImageChunkEvent>();
    final ImageStreamCompleter imageStream =
        FakeEventReportingImageStreamCompleter(
      chunkEvents: streamController.stream,
    );

    streamController.add(
        const ImageChunkEvent(cumulativeBytesLoaded: 1, expectedTotalBytes: 3));
    await tester.idle();
    imageStream.addListener(ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {},
      onChunk: (ImageChunkEvent event) {
        chunkEvents.add(event);
      },
    ));
    streamController.add(
        const ImageChunkEvent(cumulativeBytesLoaded: 2, expectedTotalBytes: 3));
    await tester.idle();

    expect(chunkEvents.length, 1);
    expect(chunkEvents[0].cumulativeBytesLoaded, 2);
    expect(chunkEvents[0].expectedTotalBytes, 3);
  });

  testWidgets('Chunk events of MultiImageStreamCompleter are delivered',
      (WidgetTester tester) async {
    final chunkEvents = <ImageChunkEvent>[];
    final codecStream = StreamController<Codec>();
    final streamController = StreamController<ImageChunkEvent>();
    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      chunkEvents: streamController.stream,
      scale: 1.0,
    );

    imageStream.addListener(ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {},
      onChunk: (ImageChunkEvent event) {
        chunkEvents.add(event);
      },
    ));
    streamController.add(
        const ImageChunkEvent(cumulativeBytesLoaded: 1, expectedTotalBytes: 3));
    streamController.add(
        const ImageChunkEvent(cumulativeBytesLoaded: 2, expectedTotalBytes: 3));
    await tester.idle();

    expect(chunkEvents.length, 2);
    expect(chunkEvents[0].cumulativeBytesLoaded, 1);
    expect(chunkEvents[0].expectedTotalBytes, 3);
    expect(chunkEvents[1].cumulativeBytesLoaded, 2);
    expect(chunkEvents[1].expectedTotalBytes, 3);
  });

  testWidgets(
      'Chunk events of MultiImageStreamCompleter are not buffered before listener registration',
      (WidgetTester tester) async {
    final chunkEvents = <ImageChunkEvent>[];
    final codecStream = StreamController<Codec>();
    final streamController = StreamController<ImageChunkEvent>();
    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      chunkEvents: streamController.stream,
      scale: 1.0,
    );

    streamController.add(
        const ImageChunkEvent(cumulativeBytesLoaded: 1, expectedTotalBytes: 3));
    await tester.idle();
    imageStream.addListener(ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {},
      onChunk: (ImageChunkEvent event) {
        chunkEvents.add(event);
      },
    ));
    streamController.add(
        const ImageChunkEvent(cumulativeBytesLoaded: 2, expectedTotalBytes: 3));
    await tester.idle();

    expect(chunkEvents.length, 1);
    expect(chunkEvents[0].cumulativeBytesLoaded, 2);
    expect(chunkEvents[0].expectedTotalBytes, 3);
  });

  testWidgets('Chunk errors are reported', (WidgetTester tester) async {
    final chunkEvents = <ImageChunkEvent>[];
    final codecStream = StreamController<Codec>();
    final streamController = StreamController<ImageChunkEvent>();
    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      chunkEvents: streamController.stream,
      scale: 1.0,
    );

    imageStream.addListener(ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {},
      onChunk: (ImageChunkEvent event) {
        chunkEvents.add(event);
      },
    ));
    streamController.addError(Error());
    streamController.add(
        const ImageChunkEvent(cumulativeBytesLoaded: 2, expectedTotalBytes: 3));
    await tester.idle();

    expect(tester.takeException(), isNotNull);
    expect(chunkEvents.length, 1);
    expect(chunkEvents[0].cumulativeBytesLoaded, 2);
    expect(chunkEvents[0].expectedTotalBytes, 3);
  });

  testWidgets('getNextFrame future fails', (WidgetTester tester) async {
    final mockCodec = MockCodec();
    mockCodec.frameCount = 1;
    final codecStream = StreamController<Codec>();

    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    listener(ImageInfo image, bool synchronousCall) {}
    imageStream.addListener(ImageStreamListener(listener));
    codecStream.add(mockCodec);
    // MultiImageStreamCompleter only sets an error handler for the next
    // frame future after the codec future has completed.
    // Idling here lets the MultiImageStreamCompleter advance and set the
    // error handler for the nextFrame future.
    await tester.idle();

    mockCodec.failNextFrame('frame completion error');
    await tester.idle();

    expect(tester.takeException(), 'frame completion error');
  });

  testWidgets('ImageStream emits frame (static image)',
      (WidgetTester tester) async {
    final mockCodec = MockCodec();
    mockCodec.frameCount = 1;
    final codecStream = StreamController<Codec>();

    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    final emittedImages = <ImageInfo>[];
    imageStream.addListener(
        ImageStreamListener((ImageInfo image, bool synchronousCall) {
      emittedImages.add(image);
    }));

    codecStream.add(mockCodec);
    await tester.idle();

    final FrameInfo frame =
        FakeFrameInfo(const Duration(milliseconds: 200), image20x10);
    mockCodec.completeNextFrame(frame);
    await tester.idle();

    expect(
        emittedImages
            .every((ImageInfo info) => info.image.isCloneOf(frame.image)),
        true);
  });

  testWidgets('ImageStream emits frames (animated images)',
      (WidgetTester tester) async {
    final mockCodec = MockCodec();
    mockCodec.frameCount = 2;
    mockCodec.repetitionCount = -1;
    final codecStream = StreamController<Codec>();

    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    final emittedImages = <ImageInfo>[];
    imageStream.addListener(
        ImageStreamListener((ImageInfo image, bool synchronousCall) {
      emittedImages.add(image);
    }));

    codecStream.add(mockCodec);
    await tester.idle();

    final FrameInfo frame1 =
        FakeFrameInfo(const Duration(milliseconds: 200), image20x10);
    mockCodec.completeNextFrame(frame1);
    await tester.idle();
    // We are waiting for the next animation tick, so at this point no frames
    // should have been emitted.
    expect(emittedImages.length, 0);

    await tester.pump();
    expect(emittedImages.single.image.isCloneOf(frame1.image), true);

    final FrameInfo frame2 =
        FakeFrameInfo(const Duration(milliseconds: 400), image200x100);
    mockCodec.completeNextFrame(frame2);

    await tester.pump(const Duration(milliseconds: 100));
    // The duration for the current frame was 200ms, so we don't emit the next
    // frame yet even though it is ready.
    expect(emittedImages.length, 1);

    await tester.pump(const Duration(milliseconds: 100));
    expect(emittedImages[0].image.isCloneOf(frame1.image), true);
    expect(emittedImages[1].image.isCloneOf(frame2.image), true);

    // Let the pending timer for the next frame to complete so we can cleanly
    // quit the test without pending timers.
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('animation wraps back', (WidgetTester tester) async {
    final mockCodec = MockCodec();
    mockCodec.frameCount = 2;
    mockCodec.repetitionCount = -1;
    final codecStream = StreamController<Codec>();

    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    final emittedImages = <ImageInfo>[];
    imageStream.addListener(
        ImageStreamListener((ImageInfo image, bool synchronousCall) {
      emittedImages.add(image);
    }));

    codecStream.add(mockCodec);
    await tester.idle();

    final frame1 = FakeFrameInfo(const Duration(milliseconds: 200), image20x10);
    final frame2 =
        FakeFrameInfo(const Duration(milliseconds: 400), image200x100);

    mockCodec.completeNextFrame(frame1.clone());
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // first animation frame shows on first app frame.
    mockCodec.completeNextFrame(frame2.clone());
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(const Duration(milliseconds: 200)); // emit 2nd frame.
    mockCodec.completeNextFrame(frame1.clone());
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(const Duration(milliseconds: 400)); // emit 3rd frame

    expect(emittedImages[0].image.isCloneOf(frame1.image), true);
    expect(emittedImages[1].image.isCloneOf(frame2.image), true);
    expect(emittedImages[2].image.isCloneOf(frame1.image), true);

    // Let the pending timer for the next frame to complete so we can cleanly
    // quit the test without pending timers.
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('animation doesnt repeat more than specified',
      (WidgetTester tester) async {
    final mockCodec = MockCodec();
    mockCodec.frameCount = 2;
    mockCodec.repetitionCount = 0;
    final codecStream = StreamController<Codec>();

    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    final emittedImages = <ImageInfo>[];
    imageStream.addListener(
        ImageStreamListener((ImageInfo image, bool synchronousCall) {
      emittedImages.add(image);
    }));

    codecStream.add(mockCodec);
    await tester.idle();

    final FrameInfo frame1 =
        FakeFrameInfo(const Duration(milliseconds: 200), image20x10);
    final FrameInfo frame2 =
        FakeFrameInfo(const Duration(milliseconds: 400), image200x100);

    mockCodec.completeNextFrame(frame1);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // first animation frame shows on first app frame.
    mockCodec.completeNextFrame(frame2);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(const Duration(milliseconds: 200)); // emit 2nd frame.
    mockCodec.completeNextFrame(frame1);
    // allow another frame to complete (but we shouldn't be asking for it as
    // this animation should not repeat.
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(emittedImages[0].image.isCloneOf(frame1.image), true);
    expect(emittedImages[1].image.isCloneOf(frame2.image), true);
  });

  testWidgets('frames are only decoded when there are listeners',
      (WidgetTester tester) async {
    final mockCodec = MockCodec();
    mockCodec.frameCount = 2;
    mockCodec.repetitionCount = -1;
    final codecStream = StreamController<Codec>();

    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    listener(ImageInfo image, bool synchronousCall) {}
    imageStream.addListener(ImageStreamListener(listener));
    final handle = imageStream.keepAlive();

    codecStream.add(mockCodec);
    await tester.idle();

    final FrameInfo frame1 =
        FakeFrameInfo(const Duration(milliseconds: 200), image20x10);
    final FrameInfo frame2 =
        FakeFrameInfo(const Duration(milliseconds: 400), image200x100);

    mockCodec.completeNextFrame(frame1);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // first animation frame shows on first app frame.
    mockCodec.completeNextFrame(frame2);
    imageStream.removeListener(ImageStreamListener(listener));
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(const Duration(milliseconds: 400)); // emit 2nd frame.

    // Decoding of the 3rd frame should not start as there are no registered
    // listeners to the stream
    expect(mockCodec.numFramesAsked, 2);

    imageStream.addListener(ImageStreamListener(listener));
    await tester.idle(); // let nextFrameFuture complete
    expect(mockCodec.numFramesAsked, 3);

    handle.dispose();
  });

  testWidgets('multiple stream listeners', (WidgetTester tester) async {
    final mockCodec = MockCodec();
    mockCodec.frameCount = 2;
    mockCodec.repetitionCount = -1;
    final codecStream = StreamController<Codec>();

    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    final emittedImages1 = <ImageInfo>[];
    listener1(ImageInfo image, bool synchronousCall) {
      emittedImages1.add(image);
    }

    final emittedImages2 = <ImageInfo>[];
    listener2(ImageInfo image, bool synchronousCall) {
      emittedImages2.add(image);
    }

    imageStream.addListener(ImageStreamListener(listener1));
    imageStream.addListener(ImageStreamListener(listener2));

    codecStream.add(mockCodec);
    await tester.idle();

    final FrameInfo frame1 =
        FakeFrameInfo(const Duration(milliseconds: 200), image20x10);
    final FrameInfo frame2 =
        FakeFrameInfo(const Duration(milliseconds: 400), image200x100);

    mockCodec.completeNextFrame(frame1);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // first animation frame shows on first app frame.

    expect(emittedImages1.single.image.isCloneOf(frame1.image), true);
    expect(emittedImages2.single.image.isCloneOf(frame1.image), true);

    mockCodec.completeNextFrame(frame2);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // next app frame will schedule a timer.
    imageStream.removeListener(ImageStreamListener(listener1));

    await tester.pump(const Duration(milliseconds: 400)); // emit 2nd frame.
    expect(emittedImages1.single.image.isCloneOf(frame1.image), true);
    expect(emittedImages2[0].image.isCloneOf(frame1.image), true);
    expect(emittedImages2[1].image.isCloneOf(frame2.image), true);
  });

  testWidgets('timer is canceled when listeners are removed',
      (WidgetTester tester) async {
    final mockCodec = MockCodec();
    mockCodec.frameCount = 2;
    mockCodec.repetitionCount = -1;
    final codecStream = StreamController<Codec>();

    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    listener(ImageInfo image, bool synchronousCall) {}
    imageStream.addListener(ImageStreamListener(listener));

    codecStream.add(mockCodec);
    await tester.idle();

    final FrameInfo frame1 =
        FakeFrameInfo(const Duration(milliseconds: 200), image20x10);
    final FrameInfo frame2 =
        FakeFrameInfo(const Duration(milliseconds: 400), image200x100);

    mockCodec.completeNextFrame(frame1);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // first animation frame shows on first app frame.

    mockCodec.completeNextFrame(frame2);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump();

    imageStream.removeListener(ImageStreamListener(listener));
    // The test framework will fail this if there are pending timers at this
    // point.
  });

  testWidgets('error handlers can intercept errors',
      (WidgetTester tester) async {
    final mockCodec = MockCodec();
    mockCodec.frameCount = 1;
    final codecStream = StreamController<Codec>();

    final ImageStreamCompleter streamUnderTest = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    dynamic capturedException;
    errorListener(dynamic exception, StackTrace? stackTrace) {
      capturedException = exception;
    }

    streamUnderTest.addListener(ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {},
      onError: errorListener,
    ));

    codecStream.add(mockCodec);
    // MultiImageStreamCompleter only sets an error handler for the next
    // frame future after the codec future has completed.
    // Idling here lets the MultiImageStreamCompleter advance and set the
    // error handler for the nextFrame future.
    await tester.idle();

    mockCodec.failNextFrame('frame completion error');
    await tester.idle();

    // No exception is passed up.
    expect(tester.takeException(), isNull);
    expect(capturedException, 'frame completion error');
  });

  testWidgets('remove and add listener ', (WidgetTester tester) async {
    final mockCodec = MockCodec();
    mockCodec.frameCount = 3;
    mockCodec.repetitionCount = 0;
    final codecStream = StreamController<Codec>();

    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    listener(ImageInfo image, bool synchronousCall) {}
    imageStream.addListener(ImageStreamListener(listener));

    codecStream.add(mockCodec);

    await tester.idle(); // let nextFrameFuture complete

    imageStream.addListener(ImageStreamListener(listener));
    imageStream.removeListener(ImageStreamListener(listener));

    final FrameInfo frame1 =
        FakeFrameInfo(const Duration(milliseconds: 200), image20x10);

    mockCodec.completeNextFrame(frame1);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // first animation frame shows on first app frame.

    await tester.pump(const Duration(milliseconds: 200)); // emit 2nd frame.
  });

  testWidgets(
      'Keep alive handles do not drive frames or prevent last listener callbacks',
      (WidgetTester tester) async {
    final image10x10 =
        (await tester.runAsync(() => createTestImage(width: 10, height: 10)));
    final mockCodec = MockCodec();
    mockCodec.frameCount = 2;
    mockCodec.repetitionCount = -1;
    final codecStream = StreamController<Codec>();

    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    var onImageCount = 0;
    activeListener(ImageInfo image, bool synchronousCall) {
      onImageCount += 1;
    }

    var lastListenerDropped = false;
    imageStream.addOnLastListenerRemovedCallback(() {
      lastListenerDropped = true;
    });

    expect(lastListenerDropped, false);
    final handle = imageStream.keepAlive();
    expect(lastListenerDropped, false);
    SchedulerBinding.instance
        .debugAssertNoTransientCallbacks('Only passive listeners');

    codecStream.add(mockCodec);
    await tester.idle();

    expect(onImageCount, 0);

    final frame1 = FakeFrameInfo(Duration.zero, image20x10);
    mockCodec.completeNextFrame(frame1);
    await tester.idle();
    SchedulerBinding.instance
        .debugAssertNoTransientCallbacks('Only passive listeners');
    await tester.pump();
    expect(onImageCount, 0);

    imageStream.addListener(ImageStreamListener(activeListener));

    final frame2 = FakeFrameInfo(Duration.zero, image10x10!);
    mockCodec.completeNextFrame(frame2);
    await tester.idle();
    expect(SchedulerBinding.instance.transientCallbackCount, 1);
    await tester.pump();

    expect(onImageCount, 1);

    imageStream.removeListener(ImageStreamListener(activeListener));
    expect(lastListenerDropped, true);

    mockCodec.completeNextFrame(frame1);
    await tester.idle();
    expect(SchedulerBinding.instance.transientCallbackCount, 1);
    await tester.pump();

    expect(onImageCount, 1);

    SchedulerBinding.instance
        .debugAssertNoTransientCallbacks('Only passive listeners');

    mockCodec.completeNextFrame(frame2);
    await tester.idle();
    SchedulerBinding.instance
        .debugAssertNoTransientCallbacks('Only passive listeners');
    await tester.pump();

    expect(onImageCount, 1);

    handle.dispose();
  });

  testWidgets('Multiframe image is completed before next image is shown',
      (WidgetTester tester) async {
    final firstCodec = MockCodec();
    firstCodec.frameCount = 3;
    firstCodec.repetitionCount = -1;
    final secondCodec = MockCodec();

    final codecStream = StreamController<Codec>();

    final ImageStreamCompleter imageStream = MultiImageStreamCompleter(
      codec: codecStream.stream,
      scale: 1.0,
    );

    listener(ImageInfo image, bool synchronousCall) {}
    imageStream.addListener(ImageStreamListener(listener));

    codecStream.add(firstCodec);
    await tester.idle();

    final FrameInfo frame1 =
        FakeFrameInfo(const Duration(milliseconds: 200), image20x10);
    final FrameInfo frame2 =
        FakeFrameInfo(const Duration(milliseconds: 400), image200x100);
    final FrameInfo frame3 =
        FakeFrameInfo(const Duration(milliseconds: 200), image300x100);

    firstCodec.completeNextFrame(frame1);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // first animation frame shows on first app frame.

    firstCodec.completeNextFrame(frame2);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(const Duration(milliseconds: 100)); // second frame is
    // not yet shown, but ready.

    codecStream.add(secondCodec);
    await tester.idle(); // let nextFrameFuture complete

    await tester.pump(const Duration(milliseconds: 300)); // emit 2nd frame.
    firstCodec.completeNextFrame(frame3);
    await tester.idle(); // let nextFrameFuture complete
    expect(secondCodec.numFramesAsked, 0);
    await tester.pump(const Duration(milliseconds: 200)); // emit 3rd frame.
    await tester.idle();

    // emit 1st frame 2nd image
    await tester.pump(const Duration(milliseconds: 200));

    // Decoding of the 3rd frame should not start as we switched images
    expect(firstCodec.numFramesAsked, 3);
    expect(secondCodec.numFramesAsked, 1);
  });
}
