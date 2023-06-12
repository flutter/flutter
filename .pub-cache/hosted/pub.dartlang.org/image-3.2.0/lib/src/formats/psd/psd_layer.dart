import '../../image.dart';
import '../../image_exception.dart';
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

  static const SIGNATURE = 0x3842494d; // '8BIM'

  static const BLEND_PASSTHROUGH = 0x70617373; // 'pass'
  static const BLEND_NORMAL = 0x6e6f726d; // 'norm'
  static const BLEND_DISSOLVE = 0x64697373; // 'diss'
  static const BLEND_DARKEN = 0x6461726b; // 'dark'
  static const BLEND_MULTIPLY = 0x6d756c20; // 'mul '
  static const BLEND_COLOR_BURN = 0x69646976; // 'idiv'
  static const BLEND_LINEAR_BURN = 0x6c62726e; // 'lbrn'
  static const BLEND_DARKEN_COLOR = 0x646b436c; // 'dkCl'
  static const BLEND_LIGHTEN = 0x6c697465; // 'lite'
  static const BLEND_SCREEN = 0x7363726e; // 'scrn'
  static const BLEND_COLOR_DODGE = 0x64697620; // 'div '
  static const BLEND_LINEAR_DODGE = 0x6c646467; // 'lddg'
  static const BLEND_LIGHTER_COLOR = 0x6c67436c; // 'lgCl'
  static const BLEND_OVERLAY = 0x6f766572; // 'over'
  static const BLEND_SOFT_LIGHT = 0x734c6974; // 'sLit'
  static const BLEND_HARD_LIGHT = 0x684c6974; // 'hLit'
  static const BLEND_VIVID_LIGHT = 0x764c6974; // 'vLit'
  static const BLEND_LINEAR_LIGHT = 0x6c4c6974; // lLit'
  static const BLEND_PIN_LIGHT = 0x704c6974; // 'pLit'
  static const BLEND_HARD_MIX = 0x684d6978; // 'hMix'
  static const BLEND_DIFFERENCE = 0x64696666; // 'diff'
  static const BLEND_EXCLUSION = 0x736d7564; // 'smud'
  static const BLEND_SUBTRACT = 0x66737562; // 'fsub'
  static const BLEND_DIVIDE = 0x66646976; // 'fdiv'
  static const BLEND_HUE = 0x68756520; // 'hue '
  static const BLEND_SATURATION = 0x73617420; // 'sat '
  static const BLEND_COLOR = 0x636f6c72; // 'colr'
  static const BLEND_LUMINOSITY = 0x6c756d20; // 'lum '

  static const FLAG_TRANSPARENCY_PROTECTED = 1;
  static const FLAG_HIDDEN = 2;
  static const FLAG_OBSOLETE = 4;
  static const FLAG_PHOTOSHOP_5 = 8;
  static const FLAG_PIXEL_DATA_IRRELEVANT_TO_APPEARANCE = 16;

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
    if (sig != SIGNATURE) {
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
        if (sig != SIGNATURE) {
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
          final fxData = (additionalData['lrFX'] as PsdLayerAdditionalData);
          final data = InputBuffer.from(fxData.data);
          /*int version =*/
          data.readUint16();
          final numFx = data.readUint16();

          for (var j = 0; j < numFx; ++j) {
            /*var tag =*/ data.readString(4); // 8BIM
            final fxTag = data.readString(4);
            final size = data.readUint32();

            if (fxTag == 'dsdw') {
              final fx = PsdDropShadowEffect();
              effects.add(fx);
              fx.version = data.readUint32();
              fx.blur = data.readUint32();
              fx.intensity = data.readUint32();
              fx.angle = data.readUint32();
              fx.distance = data.readUint32();
              fx.color = [
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16()
              ];
              fx.blendMode = data.readString(8);
              fx.enabled = data.readByte() != 0;
              fx.globalAngle = data.readByte() != 0;
              fx.opacity = data.readByte();
              fx.nativeColor = [
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16()
              ];
            } else if (fxTag == 'isdw') {
              final fx = PsdInnerShadowEffect();
              effects.add(fx);
              fx.version = data.readUint32();
              fx.blur = data.readUint32();
              fx.intensity = data.readUint32();
              fx.angle = data.readUint32();
              fx.distance = data.readUint32();
              fx.color = [
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16()
              ];
              fx.blendMode = data.readString(8);
              fx.enabled = data.readByte() != 0;
              fx.globalAngle = data.readByte() != 0;
              fx.opacity = data.readByte();
              fx.nativeColor = [
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16()
              ];
            } else if (fxTag == 'oglw') {
              final fx = PsdOuterGlowEffect();
              effects.add(fx);
              fx.version = data.readUint32();
              fx.blur = data.readUint32();
              fx.intensity = data.readUint32();
              fx.color = [
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16()
              ];
              fx.blendMode = data.readString(8);
              fx.enabled = data.readByte() != 0;
              fx.opacity = data.readByte();
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
              fx.version = data.readUint32();
              fx.blur = data.readUint32();
              fx.intensity = data.readUint32();
              fx.color = [
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16()
              ];
              fx.blendMode = data.readString(8);
              fx.enabled = data.readByte() != 0;
              fx.opacity = data.readByte();
              if (fx.version == 2) {
                fx.invert = data.readByte() != 0;
                fx.nativeColor = [
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
              fx.version = data.readUint32();
              fx.angle = data.readUint32();
              fx.strength = data.readUint32();
              fx.blur = data.readUint32();
              fx.highlightBlendMode = data.readString(8);
              fx.shadowBlendMode = data.readString(8);
              fx.highlightColor = [
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16()
              ];
              fx.shadowColor = [
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16()
              ];
              fx.bevelStyle = data.readByte();
              fx.highlightOpacity = data.readByte();
              fx.shadowOpacity = data.readByte();
              fx.enabled = data.readByte() != 0;
              fx.globalAngle = data.readByte() != 0;
              fx.upOrDown = data.readByte();
              if (fx.version == 2) {
                fx.realHighlightColor = [
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16(),
                  data.readUint16()
                ];
                fx.realShadowColor = [
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
              fx.version = data.readUint32();
              fx.blendMode = data.readString(4);
              fx.color = [
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16(),
                data.readUint16()
              ];
              fx.opacity = data.readByte();
              fx.enabled = data.readByte() != 0;
              fx.nativeColor = [
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
  bool isVisible() => flags & FLAG_HIDDEN == 0;

  // Is this layer a folder?
  int type() {
    if (additionalData.containsKey(PsdLayerSectionDivider.TAG)) {
      final section =
          additionalData[PsdLayerSectionDivider.TAG] as PsdLayerSectionDivider;
      return section.type;
    }
    return PsdLayerSectionDivider.NORMAL;
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
