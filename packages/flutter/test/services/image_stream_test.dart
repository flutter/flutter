// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFrameInfo extends FrameInfo {
  Duration _duration;
  Image _image;

  FakeFrameInfo(int width, int height, this._duration) :
    _image = new FakeImage(width, height); 

  @override
  Duration get duration => _duration;

  @override
  Image get image => _image;
}

class FakeImage extends Image {
  int _width;
  int _height;

  FakeImage(this._width, this._height);

  @override
  int get width => _width;

  @override
  int get height => _height;

  @override
  void dispose() {}
}

class MockCodec implements Codec {
  int frameCount;
  int repetitionCount;
  int numFramesAsked = 0;
  Completer<FrameInfo> _nextFrameCompleter = new Completer<FrameInfo>();

  @override
  Future<FrameInfo> getNextFrame() {
    numFramesAsked += 1;
    return _nextFrameCompleter.future;
  }

  void completeNextFrame(FrameInfo frameInfo) {
    _nextFrameCompleter.complete(frameInfo);
    _nextFrameCompleter = new Completer<FrameInfo>();
  }

  void failNextFrame(String err) {
    _nextFrameCompleter.completeError(err);
  }

  @override
  void dispose() {}

}

void main() {
  testWidgets('Codec future fails', (WidgetTester tester) async {
    Completer<Codec> completer = new Completer<Codec>();
    new MultiFrameImageStreamCompleter(
      codec: completer.future,
      scale: 1.0,
    );
    completer.completeError('failure message');
    await tester.idle();
    expect(tester.takeException(), 'failure message');
  });

  testWidgets('First frame decoding starts when codec is ready', (WidgetTester tester) async {
    Completer<Codec> completer = new Completer<Codec>();
    MockCodec mockCodec = new MockCodec();
    mockCodec.frameCount = 1;
    new MultiFrameImageStreamCompleter(
      codec: completer.future,
      scale: 1.0,
    );

    completer.complete(mockCodec);
    await tester.idle();
    expect(mockCodec.numFramesAsked, 1);
  });

   testWidgets('getNextFrame future fails', (WidgetTester tester) async {
     MockCodec mockCodec = new MockCodec();
     mockCodec.frameCount = 1;
     Completer<Codec> codecCompleter = new Completer<Codec>();

     new MultiFrameImageStreamCompleter(
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
    MockCodec mockCodec = new MockCodec();
    mockCodec.frameCount = 1;
    Completer<Codec> codecCompleter = new Completer<Codec>();

    ImageStreamCompleter imageStream = new MultiFrameImageStreamCompleter(
      codec: codecCompleter.future,
      scale: 1.0,
    );

    List<ImageInfo> emittedImages = [];
    imageStream.addListener((ImageInfo image, bool synchronousCall) {
      emittedImages.add(image);
    });

    codecCompleter.complete(mockCodec);
    await tester.idle();

    FrameInfo frame = new FakeFrameInfo(20, 10, new Duration(milliseconds: 200));
    mockCodec.completeNextFrame(frame);
    await tester.idle();

    expect(emittedImages, equals([new ImageInfo(image: frame.image)]));
  });

   testWidgets('ImageStream emits frames (animated images)', (WidgetTester tester) async {
     MockCodec mockCodec = new MockCodec();
     mockCodec.frameCount = 2;
     mockCodec.repetitionCount = -1;
     Completer<Codec> codecCompleter = new Completer<Codec>();

     ImageStreamCompleter imageStream = new MultiFrameImageStreamCompleter(
       codec: codecCompleter.future,
       scale: 1.0,
     );

     List<ImageInfo> emittedImages = [];
     imageStream.addListener((ImageInfo image, bool synchronousCall) {
       emittedImages.add(image);
     });

     codecCompleter.complete(mockCodec);
     await tester.idle();

     FrameInfo frame1 = new FakeFrameInfo(20, 10, new Duration(milliseconds: 200));
     mockCodec.completeNextFrame(frame1);
     await tester.idle();
     // We are waiting for the next animation tick, so at this point no frames
     // should have been emitted.
     expect(emittedImages.length, 0);

     await tester.pump();
     expect(emittedImages, equals([new ImageInfo(image: frame1.image)]));

     FrameInfo frame2 = new FakeFrameInfo(200, 100, new Duration(milliseconds: 400));
     mockCodec.completeNextFrame(frame2);

     await tester.pump(new Duration(milliseconds: 100));
     // The duration for the current frame was 200ms, so we don't emit the next
     // frame yet even though it is ready.
     expect(emittedImages.length, 1);

     await tester.pump(new Duration(milliseconds: 100));
     expect(emittedImages, equals([
       new ImageInfo(image: frame1.image),
       new ImageInfo(image: frame2.image),
     ]));

     // Let the pending timer for the next frame to complete so we can cleanly
     // quit the test without pending timers.
     await tester.pump(new Duration(milliseconds: 400));
   });

   testWidgets('animation wraps back', (WidgetTester tester) async {
     MockCodec mockCodec = new MockCodec();
     mockCodec.frameCount = 2;
     mockCodec.repetitionCount = -1;
     Completer<Codec> codecCompleter = new Completer<Codec>();

     ImageStreamCompleter imageStream = new MultiFrameImageStreamCompleter(
       codec: codecCompleter.future,
       scale: 1.0,
     );

     List<ImageInfo> emittedImages = [];
     imageStream.addListener((ImageInfo image, bool synchronousCall) {
       emittedImages.add(image);
     });

     codecCompleter.complete(mockCodec);
     await tester.idle();

     FrameInfo frame1 = new FakeFrameInfo(20, 10, new Duration(milliseconds: 200));
     FrameInfo frame2 = new FakeFrameInfo(200, 100, new Duration(milliseconds: 400));

     mockCodec.completeNextFrame(frame1);
     await tester.idle(); // let nextFrameFuture complete
     await tester.pump(); // first animation frame shows on first app frame.
     mockCodec.completeNextFrame(frame2);
     await tester.idle(); // let nextFrameFuture complete
     await tester.pump(new Duration(milliseconds: 200)); // emit 2nd frame.
     mockCodec.completeNextFrame(frame1);
     await tester.idle(); // let nextFrameFuture complete
     await tester.pump(new Duration(milliseconds: 400)); // emit 3rd frame

     expect(emittedImages, equals([
       new ImageInfo(image: frame1.image),
       new ImageInfo(image: frame2.image),
       new ImageInfo(image: frame1.image),
     ]));

     // Let the pending timer for the next frame to complete so we can cleanly
     // quit the test without pending timers.
     await tester.pump(new Duration(milliseconds: 200));
   });

   testWidgets('animation doesnt repeat more than specified', (WidgetTester tester) async {
     MockCodec mockCodec = new MockCodec();
     mockCodec.frameCount = 2;
     mockCodec.repetitionCount = 0;
     Completer<Codec> codecCompleter = new Completer<Codec>();

     ImageStreamCompleter imageStream = new MultiFrameImageStreamCompleter(
       codec: codecCompleter.future,
       scale: 1.0,
     );

     List<ImageInfo> emittedImages = [];
     imageStream.addListener((ImageInfo image, bool synchronousCall) {
       emittedImages.add(image);
     });

     codecCompleter.complete(mockCodec);
     await tester.idle();

     FrameInfo frame1 = new FakeFrameInfo(20, 10, new Duration(milliseconds: 200));
     FrameInfo frame2 = new FakeFrameInfo(200, 100, new Duration(milliseconds: 400));

     mockCodec.completeNextFrame(frame1);
     await tester.idle(); // let nextFrameFuture complete
     await tester.pump(); // first animation frame shows on first app frame.
     mockCodec.completeNextFrame(frame2);
     await tester.idle(); // let nextFrameFuture complete
     await tester.pump(new Duration(milliseconds: 200)); // emit 2nd frame.
     mockCodec.completeNextFrame(frame1);
     // allow another frame to complete (but we shouldn't be asking for it as
     // this animation should not repeat.
     await tester.idle();
     await tester.pump(new Duration(milliseconds: 400));

     expect(emittedImages, equals([
       new ImageInfo(image: frame1.image),
       new ImageInfo(image: frame2.image),
     ]));
   });
}
