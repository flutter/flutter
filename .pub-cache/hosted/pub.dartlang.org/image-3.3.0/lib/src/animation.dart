import 'dart:collection';

import 'image.dart';

enum FrameType {
  /// The frames of this document are to be interpreted as animation.
  animation,

  /// The frames of this document are to be interpreted as pages of a document.
  page
}

/// Stores multiple images, most often as the frames of an animation.
///
/// Some formats, such as [TiffDecoder], support multiple images that are not
/// to be interpreted as animation, but rather multiple pages of a document.
/// The [Animation] container is still used to store the images for these files.
/// The [frameType] property is used to differentiate multi-page documents from
/// multi-frame animations, where it is set to [FrameType.page] for documents
/// and [FrameType.animation] for animated frames.
///
/// All [Decoder] classes support decoding to an [Animation], where the
/// [Animation] will only contain a single frame for single image formats
/// such as JPEG, or if the file doesn't contain any animation such as a single
/// image GIF. If you want to generically support both animated and non-animated
/// files, you can always decode to an animation and if the animation has only
/// a single frame, then it's a non-animated image.
///
/// In some cases, the frames of the animation may only provide a portion of the
/// canvas, such as the case of animations encoding only the changing pixels
/// from one frame to the next. The [width] and [height] and [backgroundColor]
/// properties of the [Animation] provide information about the canvas that
/// contains the animation, and the [Image] frames provide information about
/// how to draw the particular frame, such as the area of the canvas to draw
/// into, and if the canvas should be cleared prior to drawing the frame.
class Animation extends IterableBase<Image> {
  /// The canvas width for containing the animation.
  int width = 0;

  /// The canvas height for containing the animation.
  int height = 0;

  /// The suggested background color to clear the canvas with.
  int backgroundColor = 0xffffffff;

  /// The frames of the animation.
  List<Image> frames = [];

  /// How many times should the animation loop (0 means forever)?
  int loopCount = 0;

  /// How should the frames be interpreted?  If [FrameType.animation], the
  /// frames are part of an animated sequence. If [FrameType.page], the frames
  /// are the pages of a document.
  FrameType frameType = FrameType.animation;

  /// How many frames are in the animation?
  int get numFrames => frames.length;

  /// How many frames are in the animation?
  @override
  int get length => frames.length;

  /// Get the frame at the given [index].
  Image operator [](int index) => frames[index];

  /// Add a frame to the animation.
  void addFrame(Image image) {
    frames.add(image);
  }

  /// The first frame of the animation.
  @override
  Image get first => frames.first;

  /// The last frame of the animation.
  @override
  Image get last => frames.last;

  /// Is the animation empty (no frames)?
  @override
  bool get isEmpty => frames.isEmpty;

  /// Returns true if there is at least one frame in the animation.
  @override
  bool get isNotEmpty => frames.isNotEmpty;

  /// Get the iterator for looping over the animation. This allows the
  /// Animation to be used in for-each loops:
  /// for (AnimationFrame frame in animation) { ... }
  @override
  Iterator<Image> get iterator => frames.iterator;
}
