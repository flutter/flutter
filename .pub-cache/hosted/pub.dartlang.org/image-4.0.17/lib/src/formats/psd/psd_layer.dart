import '../../image/image.dart';
import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';
import 'effect/psd_bevel_effect.dart';
import 'effect/psd_drop_shadow_effect.dart';
import 'effect/psd_effect.dart';
import 'effect/psd_inner_glow_effect.dart';
import 'effect/psd_inner_shadow_effect.dart';
import 'effect/psd_outer_glow_effect.dart';
import 'effect/psd_solid_fill_effect.dart';
import 'layer_data/psd_layer_additional_data.dart';
import 'layer_data/psd_layer_section_divider.dart';
import 'psd_blending_ranges.dart';
import 'psd_channel.dart';
import 'psd_image.dart';
import 'psd_layer_data.dart';
import 'psd_mask.dart';

class PsdBlendMode {
  static const passThrough = 0x70617373; // 'pass'
  static const normal = 0x6e6f726d; // 'norm'
  static const dissolve = 0x64697373; // 'diss'
  static const darken = 0x6461726b; // 'dark'
  static const multiply = 0x6d756c20; // 'mul '
  static const colorBurn = 0x69646976; // 'idiv'
  static const linearBurn = 0x6c62726e; // 'lbrn'
  static const darkenColor = 0x646b436c; // 'dkCl'
  static const lighten = 0x6c697465; // 'lite'
  static const screen = 0x7363726e; // 'scrn'
  static const colorDodge = 0x64697620; // 'div '
  static const linearDodge = 0x6c646467; // 'lddg'
  static const lighterColor = 0x6c67436c; // 'lgCl'
  static const overlay = 0x6f766572; // 'over'
  static const softLight = 0x734c6974; // 'sLit'
  static const hardLight = 0x684c6974; // 'hLit'
  static const vividLight = 0x764c6974; // 'vLit'
  static const linearLight = 0x6c4c6974; // lLit'
  static const pinLight = 0x704c6974; // 'pLit'
  static const hardMix = 0x684d6978; // 'hMix'
  static const difference = 0x64696666; // 'diff'
  static const exclusion = 0x736d7564; // 'smud'
  static const subtract = 0x66737562; // 'fsub'
  static const divide = 0x66646976; // 'fdiv'
  static const hue = 0x68756520; // 'hue '
  static const saturation = 0x73617420; // 'sat '
  static const color = 0x636f6c72; // 'colr'
  static const luminosity = 0x6c756d20; // 'lum '

  const PsdBlendMode(this.value);
  final int value;
}

class PsdFlag {
  static const transparencyProtected = 1;
  static const hidden = 2;
  static const obsolete = 4;
  static const photoshop5 = 8;
  static const pixelDataIrrelevantToAppearance = 16;

  const PsdFlag(this.value);
  final int value;
}

class PsdLayer {
  int? top;
  int? left;
  late int bottom;
  late int right;
  late int width;
  late int height;
  int? blendMode;
  late int opacity;
  int? clipping;
  late int flags;
  int? compression;
  String? name;
  late List<PsdChannel> channels;
  PsdMask? mask;
  PsdBlendingRanges? blendingRanges;
  Map<String, PsdLayerData> additionalData = {};
  List<PsdLayer> children = [];
  PsdLayer? parent;
  late Image layerImage;
  List<PsdEffect> effects = [];

  static const signature = 0x3842494d; // '8BIM'

  PsdLayer([InputBuffer? input]) {
    if (input == null) {
      return;
    }

    top = input.readInt32();
    left = input.readInt32();
    bottom = input.readInt32();
    right = input.readInt32();
    width = right - left!;
    height = bottom - top!;

    channels = [];
    final numChannels = input.readUint16();
    for (var i = 0; i < numChannels; ++i) {
      final id = input.readInt16();
      final len = input.readUint32();
      channels.add(PsdChannel(id, len));
    }

    final sig = input.readUint32();
    if (sig != signature) {
      throw ImageException('Invalid PSD layer signature: '
          '${sig.toRadixString(16)}');
    }

    blendMode = input.readUint32();
    opacity = input.readByte();
    clipping = input.readByte();
    flags = input.readByte();

    final filler = input.readByte(); // should be 0
    if (filler != 0) {
      throw ImageException('Invalid PSD layer data');
    }

    var len = input.readUint32();
    final extra = input.readBytes(len);

    if (len > 0) {
      // Mask Data
      len = extra.readUint32();
      assert(len == 0 || len == 20 || len == 36);
      if (len > 0) {
        final maskData = extra.readBytes(len);
        mask = PsdMask(maskData);
      }

      // Layer Blending Ranges
      len = extra.readUint32();
      if (len > 0) {
        final data = extra.readBytes(len);
        blendingRanges = PsdBlendingRanges(data);
      }

      // Layer name
      len = extra.readByte();
      name = extra.readString(len);
      // Layer name is padded to a multiple of 4 bytes.
      final padding = (4 - (len % 4)) - 1;
      if (padding > 0) {
        extra.skip(padding);
      }

      // Additional layer sections
      while (!extra.isEOS) {
        final sig = extra.readUint32();
        if (sig != signature) {
          throw ImageException('PSD invalid signature for layer additional '
              'data: ${sig.toRadixString(16)}');
        }

        final tag = extra.readString(4);

        len = extra.readUint32();
        final data = extra.readBytes(len);
        // pad to an even byte count.
        if (len & 1 == 1) {
          extra.skip(1);
        }

        additionalData[tag] = PsdLayerData(tag, data);

        // Layer effects data
        if (tag == 'lrFX') {
          final fxData = additionalData['lrFX'] as PsdLayerAdditionalData;
          final data = InputBuffer.from(fxData.data)
            /*int version =*/
            ..readUint16();
          final numFx = data.readUint16();

          for (var j = 0; j < numFx; ++j) {
            /*var tag =*/ data.readString(4); // 8BIM
            final fxTag = data.readString(4);
            final size = data.readUint32();

            if (fxTag == 'dsdw') {
              final fx = PsdDropShadowEffect();
              effects.add(fx);
              fx
                ..version = data.readUint32()
                ..blur = data.readUint32()
                ..intensity = data.readUint32()
                ..angle = data.readUint32()
                ..distance = data.readUint32()
                ..color = [
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16()
                ]
                ..blendMode = data.readString(8)
                ..enabled = data.readByte() != 0
                ..globalAngle = data.readByte() != 0
                ..opacity = data.readByte()
                ..nativeColor = [
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16()
                ];
            } else if (fxTag == 'isdw') {
              final fx = PsdInnerShadowEffect();
              effects.add(fx);
              fx
                ..version = data.readUint32()
                ..blur = data.readUint32()
                ..intensity = data.readUint32()
                ..angle = data.readUint32()
                ..distance = data.readUint32()
                ..color = [
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16()
                ]
                ..blendMode = data.readString(8)
                ..enabled = data.readByte() != 0
                ..globalAngle = data.readByte() != 0
                ..opacity = data.readByte()
                ..nativeColor = [
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16()
                ];
            } else if (fxTag == 'oglw') {
              final fx = PsdOuterGlowEffect();
              effects.add(fx);
              fx
                ..version = data.readUint32()
                ..blur = data.readUint32()
                ..intensity = data.readUint32()
                ..color = [
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16()
                ]
                ..blendMode = data.readString(8)
                ..enabled = data.readByte() != 0
                ..opacity = data.readByte();
              if (fx.version == 2) {
                fx.nativeColor = [
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16()
                ];
              }
            } else if (fxTag == 'iglw') {
              final fx = PsdInnerGlowEffect();
              effects.add(fx);
              fx
                ..version = data.readUint32()
                ..blur = data.readUint32()
                ..intensity = data.readUint32()
                ..color = [
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16()
                ]
                ..blendMode = data.readString(8)
                ..enabled = data.readByte() != 0
                ..opacity = data.readByte();
              if (fx.version == 2) {
                fx
                  ..invert = data.readByte() != 0
                  ..nativeColor = [
                    data.readUint16(),
                    data.readUint16(),
                    data.readUint16(),
                    data.readUint16(),
                    data.readUint16()
                  ];
              }
            } else if (fxTag == 'bevl') {
              final fx = PsdBevelEffect();
              effects.add(fx);
              fx
                ..version = data.readUint32()
                ..angle = data.readUint32()
                ..strength = data.readUint32()
                ..blur = data.readUint32()
                ..highlightBlendMode = data.readString(8)
                ..shadowBlendMode = data.readString(8)
                ..highlightColor = [
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16()
                ]
                ..shadowColor = [
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16()
                ]
                ..bevelStyle = data.readByte()
                ..highlightOpacity = data.readByte()
                ..shadowOpacity = data.readByte()
                ..enabled = data.readByte() != 0
                ..globalAngle = data.readByte() != 0
                ..upOrDown = data.readByte();
              if (fx.version == 2) {
                fx
                  ..realHighlightColor = [
                    data.readUint16(),
                    data.readUint16(),
                    data.readUint16(),
                    data.readUint16(),
                    data.readUint16()
                  ]
                  ..realShadowColor = [
                    data.readUint16(),
                    data.readUint16(),
                    data.readUint16(),
                    data.readUint16(),
                    data.readUint16()
                  ];
              }
            } else if (fxTag == 'sofi') {
              final fx = PsdSolidFillEffect();
              effects.add(fx);
              fx
                ..version = data.readUint32()
                ..blendMode = data.readString(4)
                ..color = [
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16()
                ]
                ..opacity = data.readByte()
                ..enabled = data.readByte() != 0
                ..nativeColor = [
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16()
                ];
            } else {
              data.skip(size);
            }
          }
        }
      }
    }
  }

  // Is this layer visible?
  bool isVisible() => flags & PsdFlag.hidden == 0;

  // Is this layer a folder?
  int type() {
    if (additionalData.containsKey(PsdLayerSectionDivider.tagName)) {
      final section = additionalData[PsdLayerSectionDivider.tagName]
          as PsdLayerSectionDivider;
      return section.type;
    }
    return PsdLayerSectionDivider.normal;
  }

  // Get the channel for the given [id].
  // Returns null if the layer does not have the given channel.
  PsdChannel? getChannel(int id) {
    for (var i = 0; i < channels.length; ++i) {
      if (channels[i].id == id) {
        return channels[i];
      }
    }
    return null;
  }

  void readImageData(InputBuffer input, PsdImage psd) {
    for (var i = 0; i < channels.length; ++i) {
      channels[i].readPlane(input, width, height, psd.depth);
    }

    layerImage = PsdImage.createImageFromChannels(
        psd.colorMode, psd.depth, width, height, channels);
  }
}
