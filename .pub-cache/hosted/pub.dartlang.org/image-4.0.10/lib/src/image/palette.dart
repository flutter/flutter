import 'dart:typed_data';

import '../color/format.dart';

abstract class Palette {
  /// The size of the palette data in bytes.
  int get lengthInBytes;

  /// The byte buffer storage of the palette data.
  ByteBuffer get buffer;

  /// The number of colors stored in the palette.
  final int numColors;

  /// The number of channels per color.
  final int numChannels;

  num get maxChannelValue;

  Palette(this.numColors, this.numChannels);

  /// Create a copy of the Palette.
  Palette clone();

  /// The format of the color data.
  Format get format;

  /// A Uint8List view of the palette buffer storage.
  Uint8List toUint8List() => Uint8List.view(buffer);

  /// Set the RGB color of a palette entry at [index]. If the palette has fewer
  /// channels than are set, the unsupported channels will be ignored.
  void setRgb(int index, num r, num g, num b);

  /// Set the RGBA color of a palette entry at [index]. If the palette has fewer
  /// channels than are set, the unsupported channels will be ignored.
  void setRgba(int index, num r, num g, num b, num a);

  /// Set a specific [channel] [value] of the palette entry at [index]. If the
  /// palette has fewer channels than [channel], the value will be ignored.
  void set(int index, int channel, num value);

  /// Get the the value of a specific [channel] of the palette entry at [index].
  /// If the palette has fewer colors than [index] or fewer channels than
  /// [channel], 0 will be returned.
  num get(int index, int channel);

  /// Get the red channel of the palette entry at [index]. If the palette has
  /// fewer colors or channels, 0 will be returned.
  num getRed(int index);

  /// Set the red channel of the palette entry at [index]. If the palette has
  /// fewer colors or channels, it will be ignored.
  void setRed(int index, num value);

  /// Get the green channel of the palette entry at [index]. If the palette has
  /// fewer colors or channels, 0 will be returned.
  num getGreen(int index);

  /// Set the green channel of the palette entry at [index]. If the palette has
  /// fewer colors or channels, it will be ignored.
  void setGreen(int index, num value);

  /// Get the blue channel of the palette entry at [index]. If the palette has
  /// fewer colors or channels, 0 will be returned.
  num getBlue(int index);

  /// Set the blue channel of the palette entry at [index]. If the palette has
  /// fewer colors or channels, it will be ignored.
  void setBlue(int index, num value);

  /// Get the alpha channel of the palette entry at [index]. If the palette has
  /// fewer colors or channels, 0 will be returned.
  num getAlpha(int index);

  /// Set the alpha channel of the palette entry at [index]. If the palette has
  /// fewer colors or channels, it will be ignored.
  void setAlpha(int index, num value);
}
