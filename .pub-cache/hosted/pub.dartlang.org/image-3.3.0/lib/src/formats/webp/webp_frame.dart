import '../../internal/internal.dart';
import '../../util/input_buffer.dart';

// Decodes a frame from a WebP animation.
class WebPFrame {
  // The x coordinate of the upper left corner of the frame.
  int x;

  // The y coordinate of the upper left corner of the frame.
  int y;

  // The width of the frame.
  int width;

  // The height of the frame.
  int height;

  // How long the frame should be displayed, in milliseconds.
  int duration;

  // Indicates how the current frame is to be treated after it has been
  // displayed (before rendering the next frame) on the canvas.
  // If true, the frame is cleared to the background color. If false,
  // frame is left and the next frame drawn over it.
  late bool clearFrame;

  WebPFrame(InputBuffer input, int size)
      : x = input.readUint24() * 2,
        y = input.readUint24() * 2,
        width = input.readUint24() + 1,
        height = input.readUint24() + 1,
        duration = input.readUint24() {
    final b = input.readByte();
    _reserved = (b & 0x7F) >> 7;
    clearFrame = (b & 0x1) != 0;

    _framePosition = input.position;
    _frameSize = size - _ANIMF_HEADER_SIZE;
  }

  bool get isValid => _reserved == 0;

  int _reserved = 1;
  late int _framePosition;
  late int _frameSize;

  // Size of an animation frame header.
  static const _ANIMF_HEADER_SIZE = 16;
}

@internal
class InternalWebPFrame extends WebPFrame {
  InternalWebPFrame(InputBuffer input, int size) : super(input, size);

  int get framePosition => _framePosition;
  int get frameSize => _frameSize;
}
