// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_test/flutter_test.dart';

class FakeFrameInfo implements FrameInfo {
  FakeFrameInfo(int width, int height, this._duration) :
    _image = FakeImage(width, height);

  final Duration _duration;
  final Image _image;

  @override
  Duration get duration => _duration;

  @override
  Image get image => _image;
}

class FakeImage implements Image {
  FakeImage(this._width, this._height);

  final int _width;
  final int _height;

  @override
  int get width => _width;

  @override
  int get height => _height;

  @override
  void dispose() {}

  @override
  Future<ByteData> toByteData({ImageByteFormat format}) async {
    throw UnsupportedError('Cannot encode test image');
  }
}

class MockCodec implements Codec {

  @override
  int frameCount;

  @override
  int repetitionCount;

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

void main() {
  testWidgets('Codec future fails', (WidgetTester tester) async {
    final Completer<Codec> completer = Completer<Codec>();
    MultiFrameImageStreamCompleter(
      codec: completer.future,
      scale: 1.0,
    );
    completer.completeError('failure message');
    await tester.idle();
    expect(tester.takeException(), 'failure message');
  });

  testWidgets('First frame decoding starts when codec is ready', (WidgetTester tester) async {
    final Completer<Codec> completer = Completer<Codec>();
    final MockCodec mockCodec = MockCodec();
    mockCodec.frameCount = 1;
    MultiFrameImageStreamCompleter(
      codec: completer.future,
      scale: 1.0,
    );

    completer.complete(mockCodec);
    await tester.idle();
    expect(mockCodec.numFramesAsked, 1);
  });

   testWidgets('getNextFrame future fails', (WidgetTester tester) async {
     final MockCodec mockCodec = MockCodec();
     mockCodec.frameCount = 1;
     final Completer<Codec> codecCompleter = Completer<Codec>();

     MultiFrameImageStreamCompleter(
       codec: codecCompleter.future,
       scale: 1.0,
     );

     codecCompleter.complete(mockCodec);
     // MultiFrameImageStreamCompleter only sets an error handler for the next
     // frame future after the codec future has completed.
     // Idling here lets the MultiFrameImageStreamCompleter advance and set the
     // error handler for the nextFrame future.
     await tester.idle();

     mockCodec.failNextFrame('frame completion error');
     await tester.idle();

     expect(tester.takeException(), 'frame completion error');
   });

  testWidgets('ImageStream emits frame (static image)', (WidgetTester tester) async {
    final MockCodec mockCodec = MockCodec();
    mockCodec.frameCount = 1;
    final Completer<Codec> codecCompleter = Completer<Codec>();

    final ImageStreamCompleter imageStream = MultiFrameImageStreamCompleter(
      codec: codecCompleter.future,
      scale: 1.0,
    );

    final List<ImageInfo> emittedImages = <ImageInfo>[];
    imageStream.addListener((ImageInfo image, bool synchronousCall) {
      emittedImages.add(image);
    });

    codecCompleter.complete(mockCodec);
    await tester.idle();

    final FrameInfo frame = FakeFrameInfo(20, 10, const Duration(milliseconds: 200));
    mockCodec.completeNextFrame(frame);
    await tester.idle();

    expect(emittedImages, equals(<ImageInfo>[ImageInfo(image: frame.image)]));
  });

  testWidgets('ImageStream emits frames (animated images)', (WidgetTester tester) async {
    final MockCodec mockCodec = MockCodec();
    mockCodec.frameCount = 2;
    mockCodec.repetitionCount = -1;
    final Completer<Codec> codecCompleter = Completer<Codec>();

    final ImageStreamCompleter imageStream = MultiFrameImageStreamCompleter(
      codec: codecCompleter.future,
      scale: 1.0,
    );

    final List<ImageInfo> emittedImages = <ImageInfo>[];
    imageStream.addListener((ImageInfo image, bool synchronousCall) {
      emittedImages.add(image);
    });

    codecCompleter.complete(mockCodec);
    await tester.idle();

    final FrameInfo frame1 = FakeFrameInfo(20, 10, const Duration(milliseconds: 200));
    mockCodec.completeNextFrame(frame1);
    await tester.idle();
    // We are waiting for the next animation tick, so at this point no frames
    // should have been emitted.
    expect(emittedImages.length, 0);

    await tester.pump();
    expect(emittedImages, equals(<ImageInfo>[ImageInfo(image: frame1.image)]));

    final FrameInfo frame2 = FakeFrameInfo(200, 100, const Duration(milliseconds: 400));
    mockCodec.completeNextFrame(frame2);

    await tester.pump(const Duration(milliseconds: 100));
    // The duration for the current frame was 200ms, so we don't emit the next
    // frame yet even though it is ready.
    expect(emittedImages.length, 1);

    await tester.pump(const Duration(milliseconds: 100));
    expect(emittedImages, equals(<ImageInfo>[
      ImageInfo(image: frame1.image),
      ImageInfo(image: frame2.image),
    ]));

    // Let the pending timer for the next frame to complete so we can cleanly
    // quit the test without pending timers.
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('animation wraps back', (WidgetTester tester) async {
    final MockCodec mockCodec = MockCodec();
    mockCodec.frameCount = 2;
    mockCodec.repetitionCount = -1;
    final Completer<Codec> codecCompleter = Completer<Codec>();

    final ImageStreamCompleter imageStream = MultiFrameImageStreamCompleter(
      codec: codecCompleter.future,
      scale: 1.0,
    );

    final List<ImageInfo> emittedImages = <ImageInfo>[];
    imageStream.addListener((ImageInfo image, bool synchronousCall) {
      emittedImages.add(image);
    });

    codecCompleter.complete(mockCodec);
    await tester.idle();

    final FrameInfo frame1 = FakeFrameInfo(20, 10, const Duration(milliseconds: 200));
    final FrameInfo frame2 = FakeFrameInfo(200, 100, const Duration(milliseconds: 400));

    mockCodec.completeNextFrame(frame1);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // first animation frame shows on first app frame.
    mockCodec.completeNextFrame(frame2);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(const Duration(milliseconds: 200)); // emit 2nd frame.
    mockCodec.completeNextFrame(frame1);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(const Duration(milliseconds: 400)); // emit 3rd frame

    expect(emittedImages, equals(<ImageInfo>[
      ImageInfo(image: frame1.image),
      ImageInfo(image: frame2.image),
      ImageInfo(image: frame1.image),
    ]));

    // Let the pending timer for the next frame to complete so we can cleanly
    // quit the test without pending timers.
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('animation doesnt repeat more than specified', (WidgetTester tester) async {
    final MockCodec mockCodec = MockCodec();
    mockCodec.frameCount = 2;
    mockCodec.repetitionCount = 0;
    final Completer<Codec> codecCompleter = Completer<Codec>();

    final ImageStreamCompleter imageStream = MultiFrameImageStreamCompleter(
      codec: codecCompleter.future,
      scale: 1.0,
    );

    final List<ImageInfo> emittedImages = <ImageInfo>[];
    imageStream.addListener((ImageInfo image, bool synchronousCall) {
      emittedImages.add(image);
    });

    codecCompleter.complete(mockCodec);
    await tester.idle();

    final FrameInfo frame1 = FakeFrameInfo(20, 10, const Duration(milliseconds: 200));
    final FrameInfo frame2 = FakeFrameInfo(200, 100, const Duration(milliseconds: 400));

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

    expect(emittedImages, equals(<ImageInfo>[
      ImageInfo(image: frame1.image),
      ImageInfo(image: frame2.image),
    ]));
  });

  testWidgets('frames are only decoded when there are active listeners', (WidgetTester tester) async {
    final MockCodec mockCodec = MockCodec();
    mockCodec.frameCount = 2;
    mockCodec.repetitionCount = -1;
    final Completer<Codec> codecCompleter = Completer<Codec>();

    final ImageStreamCompleter imageStream = MultiFrameImageStreamCompleter(
      codec: codecCompleter.future,
      scale: 1.0,
    );

    final ImageListener listener = (ImageInfo image, bool synchronousCall) {};
    imageStream.addListener(listener);

    codecCompleter.complete(mockCodec);
    await tester.idle();

    final FrameInfo frame1 = FakeFrameInfo(20, 10, const Duration(milliseconds: 200));
    final FrameInfo frame2 = FakeFrameInfo(200, 100, const Duration(milliseconds: 400));

    mockCodec.completeNextFrame(frame1);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // first animation frame shows on first app frame.
    mockCodec.completeNextFrame(frame2);
    imageStream.removeListener(listener);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(const Duration(milliseconds: 400)); // emit 2nd frame.

    // Decoding of the 3rd frame should not start as there are no registered
    // listeners to the stream
    expect(mockCodec.numFramesAsked, 2);

    imageStream.addListener(listener);
    await tester.idle(); // let nextFrameFuture complete
    expect(mockCodec.numFramesAsked, 3);
  });

  testWidgets('multiple stream listeners', (WidgetTester tester) async {
    final MockCodec mockCodec = MockCodec();
    mockCodec.frameCount = 2;
    mockCodec.repetitionCount = -1;
    final Completer<Codec> codecCompleter = Completer<Codec>();

    final ImageStreamCompleter imageStream = MultiFrameImageStreamCompleter(
      codec: codecCompleter.future,
      scale: 1.0,
    );

    final List<ImageInfo> emittedImages1 = <ImageInfo>[];
    final ImageListener listener1 = (ImageInfo image, bool synchronousCall) {
      emittedImages1.add(image);
    };
    final List<ImageInfo> emittedImages2 = <ImageInfo>[];
    final ImageListener listener2 = (ImageInfo image, bool synchronousCall) {
      emittedImages2.add(image);
    };
    imageStream.addListener(listener1);
    imageStream.addListener(listener2);

    codecCompleter.complete(mockCodec);
    await tester.idle();

    final FrameInfo frame1 = FakeFrameInfo(20, 10, const Duration(milliseconds: 200));
    final FrameInfo frame2 = FakeFrameInfo(200, 100, const Duration(milliseconds: 400));

    mockCodec.completeNextFrame(frame1);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // first animation frame shows on first app frame.
    expect(emittedImages1, equals(<ImageInfo>[ImageInfo(image: frame1.image)]));
    expect(emittedImages2, equals(<ImageInfo>[ImageInfo(image: frame1.image)]));

    mockCodec.completeNextFrame(frame2);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // next app frame will schedule a timer.
    imageStream.removeListener(listener1);

    await tester.pump(const Duration(milliseconds: 400)); // emit 2nd frame.
    expect(emittedImages1, equals(<ImageInfo>[ImageInfo(image: frame1.image)]));
    expect(emittedImages2, equals(<ImageInfo>[
      ImageInfo(image: frame1.image),
      ImageInfo(image: frame2.image),
    ]));
  });

  testWidgets('timer is canceled when listeners are removed', (WidgetTester tester) async {
    final MockCodec mockCodec = MockCodec();
    mockCodec.frameCount = 2;
    mockCodec.repetitionCount = -1;
    final Completer<Codec> codecCompleter = Completer<Codec>();

    final ImageStreamCompleter imageStream = MultiFrameImageStreamCompleter(
      codec: codecCompleter.future,
      scale: 1.0,
    );

    final ImageListener listener = (ImageInfo image, bool synchronousCall) {};
    imageStream.addListener(listener);

    codecCompleter.complete(mockCodec);
    await tester.idle();

    final FrameInfo frame1 = FakeFrameInfo(20, 10, const Duration(milliseconds: 200));
    final FrameInfo frame2 = FakeFrameInfo(200, 100, const Duration(milliseconds: 400));

    mockCodec.completeNextFrame(frame1);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // first animation frame shows on first app frame.

    mockCodec.completeNextFrame(frame2);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump();

    imageStream.removeListener(listener);
    // The test framework will fail this if there are pending timers at this
    // point.
  });

  testWidgets('timeDilation affects animation frame timers', (WidgetTester tester) async {
    final MockCodec mockCodec = MockCodec();
    mockCodec.frameCount = 2;
    mockCodec.repetitionCount = -1;
    final Completer<Codec> codecCompleter = Completer<Codec>();

    final ImageStreamCompleter imageStream = MultiFrameImageStreamCompleter(
      codec: codecCompleter.future,
      scale: 1.0,
    );

    final ImageListener listener = (ImageInfo image, bool synchronousCall) {};
    imageStream.addListener(listener);

    codecCompleter.complete(mockCodec);
    await tester.idle();

    final FrameInfo frame1 = FakeFrameInfo(20, 10, const Duration(milliseconds: 200));
    final FrameInfo frame2 = FakeFrameInfo(200, 100, const Duration(milliseconds: 400));

    mockCodec.completeNextFrame(frame1);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // first animation frame shows on first app frame.

    timeDilation = 2.0;
    mockCodec.completeNextFrame(frame2);
    await tester.idle(); // let nextFrameFuture complete
    await tester.pump(); // schedule next app frame
    await tester.pump(const Duration(milliseconds: 200)); // emit 2nd frame.
    // Decoding of the 3rd frame should not start after 200 ms, as time is
    // dilated by a factor of 2.
    expect(mockCodec.numFramesAsked, 2);
    await tester.pump(const Duration(milliseconds: 200)); // emit 2nd frame.
    expect(mockCodec.numFramesAsked, 3);
  });

  testWidgets('error handlers can intercept errors', (WidgetTester tester) async {
    final MockCodec mockCodec = MockCodec();
    mockCodec.frameCount = 1;
    final Completer<Codec> codecCompleter = Completer<Codec>();

    final ImageStreamCompleter streamUnderTest = MultiFrameImageStreamCompleter(
      codec: codecCompleter.future,
      scale: 1.0,
    );

    dynamic capturedException;
    final ImageErrorListener errorListener = (dynamic exception, StackTrace stackTrace) {
      capturedException = exception;
    };

    streamUnderTest.addListener(
      (ImageInfo image, bool synchronousCall) {},
      onError: errorListener,
    );

    codecCompleter.complete(mockCodec);
    // MultiFrameImageStreamCompleter only sets an error handler for the next
    // frame future after the codec future has completed.
    // Idling here lets the MultiFrameImageStreamCompleter advance and set the
    // error handler for the nextFrame future.
    await tester.idle();

    mockCodec.failNextFrame('frame completion error');
    await tester.idle();

    // No exception is passed up.
    expect(tester.takeException(), isNull);
    expect(capturedException, 'frame completion error');
  });
}
