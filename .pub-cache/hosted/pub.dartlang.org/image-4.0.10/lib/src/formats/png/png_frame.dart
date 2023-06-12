import '../../util/_internal.dart';

enum PngDisposeMode { none, background, previous }

enum PngBlendMode { source, over }

// Decodes a frame from a PNG animation.
class PngFrame {
  int sequenceNumber;
  int width;
  int height;
  int xOffset;
  int yOffset;
  int delayNum;
  int delayDen;
  PngDisposeMode dispose;
  PngBlendMode blend;

  PngFrame(
      {this.sequenceNumber = 0,
      this.width = 0,
      this.height = 0,
      this.xOffset = 0,
      this.yOffset = 0,
      this.delayNum = 0,
      this.delayDen = 0,
      this.dispose = PngDisposeMode.none,
      this.blend = PngBlendMode.source});

  double get delay => delayNum == 0 || delayDen == 0 ? 0 : delayNum / delayDen;
}

@internal
class InternalPngFrame extends PngFrame {
  InternalPngFrame(
      {int sequenceNumber = 0,
      int width = 0,
      int height = 0,
      int xOffset = 0,
      int yOffset = 0,
      int delayNum = 0,
      int delayDen = 0,
      PngDisposeMode dispose = PngDisposeMode.none,
      PngBlendMode blend = PngBlendMode.source})
      : super(
            sequenceNumber: sequenceNumber,
            width: width,
            height: height,
            xOffset: xOffset,
            yOffset: yOffset,
            delayNum: delayNum,
            delayDen: delayDen,
            dispose: dispose,
            blend: blend);

  final fdat = <int>[];
}
