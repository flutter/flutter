import 'package:photo_view/photo_view.dart';
import 'package:test/test.dart';

void main() {
  late PhotoViewScaleStateController controller;
  setUp(() {
    controller = PhotoViewScaleStateController();
  });

  test('controller constructor', () {
    expect(controller.prevScaleState, PhotoViewScaleState.initial);
    expect(controller.scaleState, PhotoViewScaleState.initial);
  });

  test('controller change values', () {
    controller.scaleState = PhotoViewScaleState.covering;
    expect(controller.prevScaleState, PhotoViewScaleState.initial);
    expect(controller.scaleState, PhotoViewScaleState.covering);
    controller.scaleState = PhotoViewScaleState.originalSize;
    expect(controller.prevScaleState, PhotoViewScaleState.covering);
    expect(controller.scaleState, PhotoViewScaleState.originalSize);
    controller.setInvisibly(PhotoViewScaleState.zoomedOut);
    expect(controller.prevScaleState, PhotoViewScaleState.originalSize);
    expect(controller.scaleState, PhotoViewScaleState.zoomedOut);
  });

  test('controller reset', () {
    controller.scaleState = PhotoViewScaleState.covering;
    controller.reset();
    expect(controller.prevScaleState, PhotoViewScaleState.covering);
    expect(controller.scaleState, PhotoViewScaleState.initial);
  });

  test('controller stream mutation', () {
    const PhotoViewScaleState value1 = PhotoViewScaleState.covering;
    const PhotoViewScaleState value2 = PhotoViewScaleState.originalSize;
    const PhotoViewScaleState value3 = PhotoViewScaleState.initial;
    const PhotoViewScaleState value4 = PhotoViewScaleState.zoomedOut;

    expect(controller.outputScaleStateStream,
        emitsInOrder([value1, value2, value3, value4]));
    controller.scaleState = PhotoViewScaleState.covering;
    controller.scaleState = PhotoViewScaleState.originalSize;
    controller.reset();
    controller.scaleState = PhotoViewScaleState.initial;
    controller.setInvisibly(PhotoViewScaleState.zoomedOut);
  });

  test('controller invisible update', () {
    int count = 0;
    final void Function() callback = () {
      count++;
    };

    controller.addIgnorableListener(callback);

    expect(count, 0);

    controller.scaleState = PhotoViewScaleState.zoomedOut;
    expect(count, 1);
    controller.setInvisibly(PhotoViewScaleState.zoomedOut);
    expect(count, 1);
    controller.reset();
    expect(count, 2);
  });
}
