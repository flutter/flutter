import 'dart:math';
import 'dart:typed_data';

import '../../color/color.dart';
import '../../image/image.dart';
import '../../image/pixel.dart';
import '../../util/color_util.dart';
import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';
import '../decode_info.dart';
import 'psd_channel.dart';
import 'psd_image_resource.dart';
import 'psd_layer.dart';

enum PsdColorMode {
  bitmap,
  grayscale,
  indexed,
  rgb,
  cmyk,
  multiChannel,
  duoTone,
  lab
}

class PsdImage implements DecodeInfo {
  static const psdSignature = 0x38425053; // '8BPS'

  @override
  int width = 0;
  @override
  int height = 0;
  int? signature;
  int? version;
  late int channels;
  int? depth;
  PsdColorMode? colorMode;
  late List<PsdLayer> layers;
  late List<PsdChannel> mergeImageChannels;
  Image? mergedImage;
  final imageResources = <int, PsdImageResource>{};
  bool hasAlpha = false;

  @override
  Color? get backgroundColor => null;

  PsdImage(List<int> bytes) {
    _input = InputBuffer(bytes, bigEndian: true);

    _readHeader();
    if (!isValid) {
      return;
    }

    var len = _input!.readUint32();
    /*_colorData =*/
    _input!.readBytes(len);

    len = _input!.readUint32();
    _imageResourceData = _input!.readBytes(len);

    len = _input!.readUint32();
    _layerAndMaskData = _input!.readBytes(len);

    _imageData = _input!.readBytes(_input!.length);
  }

  bool get isValid => signature == psdSignature;

  // The number of frames that can be decoded.
  @override
  int get numFrames => 1;

  // Decode the raw psd structure without rendering the output image.
  // Use [renderImage] to render the output image.
  bool decode() {
    if (!isValid || _input == null) {
      return false;
    }

    // Color Mode Data Block:
    // Indexed and duotone images have palette data in colorData...
    _readColorModeData();

    // Image Resource Block:
    // Image resources are used to store non-pixel data associated with images,
    // such as pen tool paths.
    _readImageResources();

    _readLayerAndMaskData();

    _readMergeImageData();

    _input = null;
    //_colorData = null;
    _imageResourceData = null;
    _layerAndMaskData = null;
    _imageData = null;

    return true;
  }

  Image? decodeImage() {
    if (!decode()) {
      return null;
    }

    return renderImage();
  }

  Image renderImage() {
    if (mergedImage != null) {
      return mergedImage!;
    }

    mergedImage = Image(width: width, height: height, numChannels: 4);
    mergedImage!.clear();

    //final pixels = mergedImage!.getBytes();

    for (var li = 0; li < layers.length; ++li) {
      final layer = layers[li];
      if (!layer.isVisible()) {
        continue;
      }

      final opacity = layer.opacity / 255.0;
      final blendMode = layer.blendMode;

      //int ns = depth == 16 ? 2 : 1;
      //final srcP = layer.layerImage.getBytes();
      final src = layer.layerImage;

      for (var y = 0, sy = layer.top!; y < layer.height; ++y, ++sy) {
        //var di = (layer.top! + y) * width * 4 + layer.left! * 4;
        final dy = layer.top! + y;
        for (int? x = 0, sx = layer.left; x! < layer.width; ++x, ++sx) {
          final srcP = src.getPixel(x, y);
          final br = srcP.r.toInt();
          final bg = srcP.g.toInt();
          final bb = srcP.b.toInt();
          final ba = srcP.a.toInt();

          if (sx! >= 0 && sx < width && sy >= 0 && sy < height) {
            final dx = layer.left! + x;
            final p = mergedImage!.getPixel(dx, dy);
            final ar = p.r.toInt();
            final ag = p.g.toInt();
            final ab = p.b.toInt();
            final aa = p.a.toInt();

            _blend(ar, ag, ab, aa, br, bg, bb, ba, blendMode, opacity, p);
          }
        }
      }
    }

    return mergedImage!;
  }

  void _blend(int ar, int ag, int ab, int aa, int br, int bg, int bb, int ba,
      int? blendMode, double opacity, Pixel p) {
    var r = br;
    var g = bg;
    var b = bb;
    var a = ba;
    final da = (ba / 255.0) * opacity;

    switch (blendMode) {
      case PsdBlendMode.passThrough:
        r = ar;
        g = ag;
        b = ab;
        a = aa;
        break;
      case PsdBlendMode.normal:
        break;
      case PsdBlendMode.dissolve:
        break;
      case PsdBlendMode.darken:
        r = _blendDarken(ar, br);
        g = _blendDarken(ag, bg);
        b = _blendDarken(ab, bb);
        break;
      case PsdBlendMode.multiply:
        r = _blendMultiply(ar, br);
        g = _blendMultiply(ag, bg);
        b = _blendMultiply(ab, bb);
        break;
      case PsdBlendMode.colorBurn:
        r = _blendColorBurn(ar, br);
        g = _blendColorBurn(ag, bg);
        b = _blendColorBurn(ab, bb);
        break;
      case PsdBlendMode.linearBurn:
        r = _blendLinearBurn(ar, br);
        g = _blendLinearBurn(ag, bg);
        b = _blendLinearBurn(ab, bb);
        break;
      case PsdBlendMode.darkenColor:
        break;
      case PsdBlendMode.lighten:
        r = _blendLighten(ar, br);
        g = _blendLighten(ag, bg);
        b = _blendLighten(ab, bb);
        break;
      case PsdBlendMode.screen:
        r = _blendScreen(ar, br);
        g = _blendScreen(ag, bg);
        b = _blendScreen(ab, bb);
        break;
      case PsdBlendMode.colorDodge:
        r = _blendColorDodge(ar, br);
        g = _blendColorDodge(ag, bg);
        b = _blendColorDodge(ab, bb);
        break;
      case PsdBlendMode.linearDodge:
        r = _blendLinearDodge(ar, br);
        g = _blendLinearDodge(ag, bg);
        b = _blendLinearDodge(ab, bb);
        break;
      case PsdBlendMode.lighterColor:
        break;
      case PsdBlendMode.overlay:
        r = _blendOverlay(ar, br, aa, ba);
        g = _blendOverlay(ag, bg, aa, ba);
        b = _blendOverlay(ab, bb, aa, ba);
        break;
      case PsdBlendMode.softLight:
        r = _blendSoftLight(ar, br);
        g = _blendSoftLight(ag, bg);
        b = _blendSoftLight(ab, bb);
        break;
      case PsdBlendMode.hardLight:
        r = _blendHardLight(ar, br);
        g = _blendHardLight(ag, bg);
        b = _blendHardLight(ab, bb);
        break;
      case PsdBlendMode.vividLight:
        r = _blendVividLight(ar, br);
        g = _blendVividLight(ag, bg);
        b = _blendVividLight(ab, bb);
        break;
      case PsdBlendMode.linearLight:
        r = _blendLinearLight(ar, br);
        g = _blendLinearLight(ag, bg);
        b = _blendLinearLight(ab, bb);
        break;
      case PsdBlendMode.pinLight:
        r = _blendPinLight(ar, br);
        g = _blendPinLight(ag, bg);
        b = _blendPinLight(ab, bb);
        break;
      case PsdBlendMode.hardMix:
        r = _blendHardMix(ar, br);
        g = _blendHardMix(ag, bg);
        b = _blendHardMix(ab, bb);
        break;
      case PsdBlendMode.difference:
        r = _blendDifference(ar, br);
        g = _blendDifference(ag, bg);
        b = _blendDifference(ab, bb);
        break;
      case PsdBlendMode.exclusion:
        r = _blendExclusion(ar, br);
        g = _blendExclusion(ag, bg);
        b = _blendExclusion(ab, bb);
        break;
      case PsdBlendMode.subtract:
        break;
      case PsdBlendMode.divide:
        break;
      case PsdBlendMode.hue:
        break;
      case PsdBlendMode.saturation:
        break;
      case PsdBlendMode.color:
        break;
      case PsdBlendMode.luminosity:
        break;
    }

    p
      ..r = ((ar * (1.0 - da)) + (r * da)).toInt()
      ..g = ((ag * (1.0 - da)) + (g * da)).toInt()
      ..b = ((ab * (1.0 - da)) + (b * da)).toInt()
      ..a = ((aa * (1.0 - da)) + (a * da)).toInt();
  }

  static int _blendLighten(int a, int b) => max(a, b);

  static int _blendDarken(int a, int b) => min(a, b);

  static int _blendMultiply(int a, int b) => (a * b) >> 8;

  static int _blendOverlay(int a, int b, int aAlpha, int bAlpha) {
    final x = a / 255.0;
    final y = b / 255.0;
    final aa = aAlpha / 255.0;
    final ba = bAlpha / 255.0;

    double z;
    if (2.0 * x < aa) {
      z = 2.0 * y * x + y * (1.0 - aa) + x * (1.0 - ba);
    } else {
      z = ba * aa - 2.0 * (aa - x) * (ba - y) + y * (1.0 - aa) + x * (1.0 - ba);
    }

    return (z * 255.0).clamp(0, 255).toInt();
  }

  static int _blendColorBurn(int a, int b) {
    if (b == 0) {
      return 0; // We don't want to divide by zero
    }
    final c = (255.0 * (1.0 - (1.0 - (a / 255.0)) / (b / 255.0))).toInt();
    return c.clamp(0, 255).toInt();
  }

  static int _blendLinearBurn(int a, int b) =>
      (a + b - 255).clamp(0, 255).toInt();

  static int _blendScreen(int a, int b) =>
      (255 - ((255 - b) * (255 - a))).clamp(0, 255).toInt();

  static int _blendColorDodge(int a, int b) {
    if (b == 255) {
      return 255;
    }
    return (((a / 255) / (1.0 - (b / 255.0))) * 255.0).clamp(0, 255).toInt();
  }

  static int _blendLinearDodge(int a, int b) => (b + a > 255) ? 0xff : a + b;

  static int _blendSoftLight(int a, int b) {
    final aa = a / 255.0;
    final bb = b / 255.0;
    return (255.0 *
            ((1.0 - bb) * bb * aa + bb * (1.0 - (1.0 - bb) * (1.0 - aa))))
        .round();
  }

  static int _blendHardLight(int bottom, int top) {
    final a = top / 255.0;
    final b = bottom / 255.0;
    if (b < 0.5) {
      return (255.0 * 2.0 * a * b).round();
    } else {
      return (255.0 * (1.0 - 2.0 * (1.0 - a) * (1.0 - b))).round();
    }
  }

  static int _blendVividLight(int bottom, int top) {
    if (top < 128) {
      return _blendColorBurn(bottom, 2 * top);
    } else {
      return _blendColorDodge(bottom, 2 * (top - 128));
    }
  }

  static int _blendLinearLight(int bottom, int top) {
    if (top < 128) {
      return _blendLinearBurn(bottom, 2 * top);
    } else {
      return _blendLinearDodge(bottom, 2 * (top - 128));
    }
  }

  static int _blendPinLight(int bottom, int top) => (top < 128)
      ? _blendDarken(bottom, 2 * top)
      : _blendLighten(bottom, 2 * (top - 128));

  static int _blendHardMix(int bottom, int top) =>
      (top < 255 - bottom) ? 0 : 255;

  static int _blendDifference(int bottom, int top) => (top - bottom).abs();

  static int _blendExclusion(int bottom, int top) =>
      (top + bottom - 2 * top * bottom / 255.0).round();

  void _readHeader() {
    signature = _input!.readUint32();
    version = _input!.readUint16();

    // version should be 1 (2 for PSB files).
    if (version != 1) {
      signature = 0;
      return;
    }

    // padding should be all 0's
    final padding = _input!.readBytes(6);
    for (var i = 0; i < 6; ++i) {
      if (padding[i] != 0) {
        signature = 0;
        return;
      }
    }

    channels = _input!.readUint16();
    height = _input!.readUint32();
    width = _input!.readUint32();
    depth = _input!.readUint16();
    colorMode = PsdColorMode.values[_input!.readUint16()];
  }

  void _readColorModeData() {
    // TODO support indexed and duotone images.
  }

  void _readImageResources() {
    _imageResourceData!.rewind();
    while (!_imageResourceData!.isEOS) {
      final blockSignature = _imageResourceData!.readUint32();
      final blockId = _imageResourceData!.readUint16();

      var len = _imageResourceData!.readByte();
      final blockName = _imageResourceData!.readString(len);
      // name string is padded to an even size
      if (len & 1 == 0) {
        _imageResourceData!.skip(1);
      }

      len = _imageResourceData!.readUint32();
      final blockData = _imageResourceData!.readBytes(len);
      // blocks are padded to an even length.
      if (len & 1 == 1) {
        _imageResourceData!.skip(1);
      }

      if (blockSignature == resourceBlockSignature) {
        imageResources[blockId] =
            PsdImageResource(blockId, blockName, blockData);
      }
    }
  }

  void _readLayerAndMaskData() {
    _layerAndMaskData!.rewind();
    var len = _layerAndMaskData!.readUint32();
    if ((len & 1) != 0) {
      len++;
    }

    final layerData = _layerAndMaskData!.readBytes(len);

    layers = [];
    if (len > 0) {
      var count = layerData.readInt16();
      // If it is a negative number, its absolute value is the number of
      // layers and the first alpha channel contains the transparency data for
      // the merged result.
      if (count < 0) {
        hasAlpha = true;
        count = -count;
      }

      for (var i = 0; i < count; ++i) {
        final layer = PsdLayer(layerData);
        layers.add(layer);
      }
    }

    for (var i = 0; i < layers.length; ++i) {
      layers[i].readImageData(layerData, this);
    }

    // Global layer mask info
    len = _layerAndMaskData!.readUint32();
    final maskData = _layerAndMaskData!.readBytes(len);
    if (len > 0) {
      /*int colorSpace =*/ maskData
        ..readUint16()
        /*int rc =*/
        ..readUint16()
        /*int gc =*/
        ..readUint16()
        /*int bc =*/
        ..readUint16()
        /*int ac =*/
        ..readUint16()
        /*int opacity =*/
        ..readUint16() // 0-100
        /*int kind =*/
        ..readByte();
    }
  }

  void _readMergeImageData() {
    _imageData!.rewind();
    final compression = _imageData!.readUint16();

    Uint16List? lineLengths;
    if (compression == PsdChannel.compressRle) {
      final numLines = height * channels;
      lineLengths = Uint16List(numLines);
      for (var i = 0; i < numLines; ++i) {
        lineLengths[i] = _imageData!.readUint16();
      }
    }

    mergeImageChannels = [];
    for (var i = 0; i < channels; ++i) {
      mergeImageChannels.add(PsdChannel.read(_imageData!, i == 3 ? -1 : i,
          width, height, depth, compression, lineLengths, i));
    }

    mergedImage = createImageFromChannels(
        colorMode, depth, width, height, mergeImageChannels);
  }

  static int _ch(List<int> data, int si, int ns) =>
      ns == 1 ? data[si] : ((data[si] << 8) | data[si + 1]) >> 8;

  static Image createImageFromChannels(PsdColorMode? colorMode, int? bitDepth,
      int width, int height, List<PsdChannel> channelList) {
    final channels = <int, PsdChannel>{};
    for (var ch in channelList) {
      channels[ch.id] = ch;
    }

    final numChannels = channelList.length;
    final ns = (bitDepth == 8)
        ? 1
        : (bitDepth == 16)
            ? 2
            : -1;

    final output =
        Image(width: width, height: height, numChannels: numChannels);

    if (ns == -1) {
      throw ImageException('PSD: unsupported bit depth: $bitDepth');
    }

    final channel0 = channels[0];
    final channel1 = channels[1];
    final channel2 = channels[2];
    final channel_1 = channels[-1];

    var si = -ns;
    for (final p in output) {
      si += ns;
      switch (colorMode) {
        case PsdColorMode.rgb:
          p.r = _ch(channel0!.data, si, ns);
          p.g = _ch(channel1!.data, si, ns);
          p.b = _ch(channel2!.data, si, ns);
          p.a = numChannels >= 4 ? _ch(channel_1!.data, si, ns) : 255;

          if (p.a != 0) {
            // Photoshop/Gimp blend the image against white (argh!),
            // which is not what we want for compositing. Invert the blend
            // operation to try and undo the damage.
            p
              ..r = (((p.r + p.a) - 255) * 255) / p.a
              ..g = (((p.g + p.a) - 255) * 255) / p.a
              ..b = (((p.b + p.a) - 255) * 255) / p.a;
          }
          break;
        case PsdColorMode.lab:
          final L = _ch(channel0!.data, si, ns) * 100 >> 8;
          final a = _ch(channel1!.data, si, ns) - 128;
          final b = _ch(channel2!.data, si, ns) - 128;
          final alpha = numChannels >= 4 ? _ch(channel_1!.data, si, ns) : 255;
          final rgb = labToRgb(L, a, b);
          p.r = rgb[0];
          p.g = rgb[1];
          p.b = rgb[2];
          p.a = alpha;
          break;
        case PsdColorMode.grayscale:
          final gray = _ch(channel0!.data, si, ns);
          final alpha = numChannels >= 2 ? _ch(channel_1!.data, si, ns) : 255;
          p.r = gray;
          p.g = gray;
          p.b = gray;
          p.a = alpha;
          break;
        case PsdColorMode.cmyk:
          final c = _ch(channel0!.data, si, ns);
          final m = _ch(channel1!.data, si, ns);
          final y = _ch(channel2!.data, si, ns);
          final k = _ch(channels[numChannels == 4 ? -1 : 3]!.data, si, ns);
          final alpha = numChannels >= 5 ? _ch(channel_1!.data, si, ns) : 255;
          final rgb = cmykToRgb(255 - c, 255 - m, 255 - y, 255 - k);
          p.r = rgb[0];
          p.g = rgb[1];
          p.b = rgb[2];
          p.a = alpha;
          break;
        default:
          throw ImageException('Unhandled color mode: $colorMode');
      }
    }

    return output;
  }

  static const resourceBlockSignature = 0x3842494d; // '8BIM'

  late InputBuffer? _input;

  //InputBuffer _colorData;
  late InputBuffer? _imageResourceData;
  late InputBuffer? _layerAndMaskData;
  late InputBuffer? _imageData;
}
