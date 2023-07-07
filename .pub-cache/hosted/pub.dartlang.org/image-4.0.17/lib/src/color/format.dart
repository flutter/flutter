/// The format of a color or image.
enum Format {
  uint1,
  uint2,
  uint4,
  uint8,
  uint16,
  uint32,
  int8,
  int16,
  int32,
  float16,
  float32,
  float64
}

enum FormatType { uint, int, float }

const formatToFormatType = <Format, FormatType>{
  Format.uint1: FormatType.uint,
  Format.uint2: FormatType.uint,
  Format.uint4: FormatType.uint,
  Format.uint8: FormatType.uint,
  Format.uint16: FormatType.uint,
  Format.uint32: FormatType.uint,
  Format.int8: FormatType.int,
  Format.int16: FormatType.int,
  Format.int32: FormatType.int,
  Format.float16: FormatType.float,
  Format.float32: FormatType.float,
  Format.float64: FormatType.float
};

const formatSize = <Format, int>{
  Format.uint1: 1,
  Format.uint2: 1,
  Format.uint4: 1,
  Format.uint8: 1,
  Format.uint16: 2,
  Format.uint32: 4,
  Format.int8: 1,
  Format.int16: 2,
  Format.int32: 4,
  Format.float16: 2,
  Format.float32: 4,
  Format.float64: 8
};

const formatMaxValue = <Format, int>{
  Format.uint1: 0x1,
  Format.uint2: 0x3,
  Format.uint4: 0xf,
  Format.uint8: 0xff,
  Format.uint16: 0xffff,
  Format.uint32: 0xffffffff,
  Format.int8: 0x7f,
  Format.int16: 0x7fff,
  Format.int32: 0x7fffffff,
  Format.float16: 1,
  Format.float32: 1,
  Format.float64: 1
};

int getRowStride(int width, int numChannels, Format format) =>
    (format == Format.uint1)
        ? ((width * numChannels) / 8).ceil()
        : (format == Format.uint2)
            ? ((width * numChannels) / 4).ceil()
            : (format == Format.uint4)
                ? ((width * numChannels) / 2).ceil()
                : width * numChannels * formatSize[format]!;

/// Convert a value from the [from] [Format] to the [to] Format.
num convertFormatValue(num value, Format from, Format to) {
  if (from == to) {
    return value;
  }

  switch (from) {
    case Format.uint1:
      return value == 0 ? 0 : formatMaxValue[to]!;
    case Format.uint2:
      switch (to) {
        case Format.uint1:
          return value == 0 ? 0 : 1;
        case Format.uint2:
          return value;
        case Format.uint4:
          return value * 5;
        case Format.uint8:
          return value * 75;
        case Format.uint16:
          return value * 21845;
        case Format.uint32:
          return value * 1431655765;
        case Format.int8:
          return value * 42;
        case Format.int16:
          return value * 10922;
        case Format.int32:
          return value * 715827882;
        case Format.float16:
        case Format.float32:
        case Format.float64:
          return value / 3;
      }
    case Format.uint4:
      switch (to) {
        case Format.uint1:
          return value == 0 ? 0 : 1;
        case Format.uint2:
          return (value as int) >> 1;
        case Format.uint4:
          return value;
        case Format.uint8:
          return value * 17;
        case Format.uint16:
          return value * 4369;
        case Format.uint32:
          return value * 286331153;
        case Format.int8:
          return value * 8;
        case Format.int16:
          return value * 2184;
        case Format.int32:
          return value * 143165576;
        case Format.float16:
        case Format.float32:
        case Format.float64:
          return value / 3;
      }
    case Format.uint8:
      switch (to) {
        case Format.uint1:
          return value == 0 ? 0 : 1;
        case Format.uint2:
          return (value as int) >> 6;
        case Format.uint4:
          return (value as int) >> 4;
        case Format.uint8:
          return value;
        case Format.uint16:
          return value * 257;
        case Format.uint32:
          return value * 16843009;
        case Format.int8:
          return (value as int) >> 1;
        case Format.int16:
          return value * 128;
        case Format.int32:
          return value * 8421504;
        case Format.float16:
        case Format.float32:
        case Format.float64:
          return value / 255;
      }
    case Format.uint16:
      switch (to) {
        case Format.uint1:
          return value == 0 ? 0 : 1;
        case Format.uint2:
          return (value as int) >> 14;
        case Format.uint4:
          return (value as int) >> 12;
        case Format.uint8:
          return (value as int) >> 8;
        case Format.uint16:
          return value;
        case Format.uint32:
          return (value as int) << 8;
        case Format.int8:
          return (value as int) >> 9;
        case Format.int16:
          return (value as int) >> 1;
        case Format.int32:
          return value * 524296;
        case Format.float16:
        case Format.float32:
        case Format.float64:
          return value / 0xffff;
      }
    case Format.uint32:
      switch (to) {
        case Format.uint1:
          return value == 0 ? 0 : 1;
        case Format.uint2:
          return (value as int) >> 30;
        case Format.uint4:
          return (value as int) >> 28;
        case Format.uint8:
          return (value as int) >> 24;
        case Format.uint16:
          return (value as int) >> 16;
        case Format.uint32:
          return value;
        case Format.int8:
          return (value as int) >> 25;
        case Format.int16:
          return (value as int) >> 17;
        case Format.int32:
          return (value as int) >> 1;
        case Format.float16:
        case Format.float32:
        case Format.float64:
          return value / 0xffffffff;
      }
    case Format.int8:
      switch (to) {
        case Format.uint1:
          return value == 0 ? 0 : 1;
        case Format.uint2:
          return value <= 0 ? 0 : (value as int) >> 5;
        case Format.uint4:
          return value <= 0 ? 0 : (value as int) >> 3;
        case Format.uint8:
          return value <= 0 ? 0 : (value as int) << 1;
        case Format.uint16:
          return value <= 0 ? 0 : (value as int) * 516;
        case Format.uint32:
          return value <= 0 ? 0 : (value as int) * 33818640;
        case Format.int8:
          return value;
        case Format.int16:
          return value * 258;
        case Format.int32:
          return value * 16909320;
        case Format.float16:
        case Format.float32:
        case Format.float64:
          return value / 127;
      }
    case Format.int16:
      switch (to) {
        case Format.uint1:
          return value == 0 ? 0 : 1;
        case Format.uint2:
          return value <= 0 ? 0 : (value as int) >> 15;
        case Format.uint4:
          return value <= 0 ? 0 : (value as int) >> 11;
        case Format.uint8:
          return value <= 0 ? 0 : (value as int) >> 7;
        case Format.uint16:
          return value <= 0 ? 0 : (value as int) << 1;
        case Format.uint32:
          return value <= 0 ? 0 : (value as int) * 131076;
        case Format.int8:
          return (value as int) >> 8;
        case Format.int16:
          return value;
        case Format.int32:
          return (value as int) * 65538;
        case Format.float16:
        case Format.float32:
        case Format.float64:
          return value / 0x7fff;
      }
    case Format.int32:
      switch (to) {
        case Format.uint1:
          return value == 0 ? 0 : 1;
        case Format.uint2:
          return value <= 0 ? 0 : (value as int) >> 29;
        case Format.uint4:
          return value <= 0 ? 0 : (value as int) >> 27;
        case Format.uint8:
          return value <= 0 ? 0 : (value as int) >> 23;
        case Format.uint16:
          return value <= 0 ? 0 : (value as int) >> 16;
        case Format.uint32:
          return value <= 0 ? 0 : (value as int) << 1;
        case Format.int8:
          return (value as int) >> 24;
        case Format.int16:
          return (value as int) >> 16;
        case Format.int32:
          return value;
        case Format.float16:
        case Format.float32:
        case Format.float64:
          return value / 0x7fffffff;
      }
    case Format.float16:
    case Format.float32:
    case Format.float64:
      switch (to) {
        case Format.uint1:
          return value == 0 ? 0 : 1;
        case Format.uint2:
          return (value.clamp(0, 1) * 3).toInt();
        case Format.uint4:
          return (value.clamp(0, 1) * 15).toInt();
        case Format.uint8:
          return (value.clamp(0, 1) * 255).toInt();
        case Format.uint16:
          return (value.clamp(0, 1) * 0xffff).toInt();
        case Format.uint32:
          return (value.clamp(0, 1) * 0xffffffff).toInt();
        case Format.int8:
          return (value < 0
                  ? value.clamp(-1, 1) * 128
                  : value.clamp(-1, 1) * 127)
              .toInt();
        case Format.int16:
          return (value < 0
                  ? value.clamp(-1, 1) * 32768
                  : value.clamp(-1, 1) * 32767)
              .toInt();
        case Format.int32:
          return (value < 0
                  ? value.clamp(-1, 1) * 2147483648
                  : value.clamp(-1, 1) * 2147483647)
              .toInt();
        case Format.float16:
        case Format.float32:
        case Format.float64:
          return value;
      }
  }
}
