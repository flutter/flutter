// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is the implementation of decompression of the proposed WOFF Ultra
// Condensed file format.

#include <cassert>
#include <cstdlib>
#include <vector>

#include "third_party/brotli/dec/decode.h"

#include "opentype-sanitiser.h"
#include "ots-memory-stream.h"
#include "ots.h"
#include "woff2.h"

#define TABLE_NAME "WOFF2"

namespace {

// simple glyph flags
const uint8_t kGlyfOnCurve = 1 << 0;
const uint8_t kGlyfXShort = 1 << 1;
const uint8_t kGlyfYShort = 1 << 2;
const uint8_t kGlyfRepeat = 1 << 3;
const uint8_t kGlyfThisXIsSame = 1 << 4;
const uint8_t kGlyfThisYIsSame = 1 << 5;

// composite glyph flags
const int FLAG_ARG_1_AND_2_ARE_WORDS = 1 << 0;
const int FLAG_WE_HAVE_A_SCALE = 1 << 3;
const int FLAG_MORE_COMPONENTS = 1 << 5;
const int FLAG_WE_HAVE_AN_X_AND_Y_SCALE = 1 << 6;
const int FLAG_WE_HAVE_A_TWO_BY_TWO = 1 << 7;
const int FLAG_WE_HAVE_INSTRUCTIONS = 1 << 8;

const size_t kSfntHeaderSize = 12;
const size_t kSfntEntrySize = 16;
const size_t kCheckSumAdjustmentOffset = 8;

const size_t kEndPtsOfContoursOffset = 10;
const size_t kCompositeGlyphBegin = 10;

// Note that the byte order is big-endian, not the same as ots.cc
#define TAG(a, b, c, d) ((a << 24) | (b << 16) | (c << 8) | d)
#define CHR(t)           (t >> 24),  (t >> 16),  (t >> 8), (t >> 0)

const unsigned int kWoff2FlagsTransform = 1 << 5;

const uint32_t kKnownTags[] = {
  TAG('c', 'm', 'a', 'p'),  // 0
  TAG('h', 'e', 'a', 'd'),  // 1
  TAG('h', 'h', 'e', 'a'),  // 2
  TAG('h', 'm', 't', 'x'),  // 3
  TAG('m', 'a', 'x', 'p'),  // 4
  TAG('n', 'a', 'm', 'e'),  // 5
  TAG('O', 'S', '/', '2'),  // 6
  TAG('p', 'o', 's', 't'),  // 7
  TAG('c', 'v', 't', ' '),  // 8
  TAG('f', 'p', 'g', 'm'),  // 9
  TAG('g', 'l', 'y', 'f'),  // 10
  TAG('l', 'o', 'c', 'a'),  // 11
  TAG('p', 'r', 'e', 'p'),  // 12
  TAG('C', 'F', 'F', ' '),  // 13
  TAG('V', 'O', 'R', 'G'),  // 14
  TAG('E', 'B', 'D', 'T'),  // 15
  TAG('E', 'B', 'L', 'C'),  // 16
  TAG('g', 'a', 's', 'p'),  // 17
  TAG('h', 'd', 'm', 'x'),  // 18
  TAG('k', 'e', 'r', 'n'),  // 19
  TAG('L', 'T', 'S', 'H'),  // 20
  TAG('P', 'C', 'L', 'T'),  // 21
  TAG('V', 'D', 'M', 'X'),  // 22
  TAG('v', 'h', 'e', 'a'),  // 23
  TAG('v', 'm', 't', 'x'),  // 24
  TAG('B', 'A', 'S', 'E'),  // 25
  TAG('G', 'D', 'E', 'F'),  // 26
  TAG('G', 'P', 'O', 'S'),  // 27
  TAG('G', 'S', 'U', 'B'),  // 28
  TAG('E', 'B', 'S', 'C'),  // 29
  TAG('J', 'S', 'T', 'F'),  // 30
  TAG('M', 'A', 'T', 'H'),  // 31
  TAG('C', 'B', 'D', 'T'),  // 32
  TAG('C', 'B', 'L', 'C'),  // 33
  TAG('C', 'O', 'L', 'R'),  // 34
  TAG('C', 'P', 'A', 'L'),  // 35
  TAG('S', 'V', 'G', ' '),  // 36
  TAG('s', 'b', 'i', 'x'),  // 37
  TAG('a', 'c', 'n', 't'),  // 38
  TAG('a', 'v', 'a', 'r'),  // 39
  TAG('b', 'd', 'a', 't'),  // 40
  TAG('b', 'l', 'o', 'c'),  // 41
  TAG('b', 's', 'l', 'n'),  // 42
  TAG('c', 'v', 'a', 'r'),  // 43
  TAG('f', 'd', 's', 'c'),  // 44
  TAG('f', 'e', 'a', 't'),  // 45
  TAG('f', 'm', 't', 'x'),  // 46
  TAG('f', 'v', 'a', 'r'),  // 47
  TAG('g', 'v', 'a', 'r'),  // 48
  TAG('h', 's', 't', 'y'),  // 49
  TAG('j', 'u', 's', 't'),  // 50
  TAG('l', 'c', 'a', 'r'),  // 51
  TAG('m', 'o', 'r', 't'),  // 52
  TAG('m', 'o', 'r', 'x'),  // 53
  TAG('o', 'p', 'b', 'd'),  // 54
  TAG('p', 'r', 'o', 'p'),  // 55
  TAG('t', 'r', 'a', 'k'),  // 56
  TAG('Z', 'a', 'p', 'f'),  // 57
  TAG('S', 'i', 'l', 'f'),  // 58
  TAG('G', 'l', 'a', 't'),  // 59
  TAG('G', 'l', 'o', 'c'),  // 60
  TAG('F', 'e', 'a', 't'),  // 61
  TAG('S', 'i', 'l', 'l'),  // 62
};

struct Point {
  int16_t x;
  int16_t y;
  bool on_curve;
};

struct Table {
  uint32_t tag;
  uint32_t flags;

  uint32_t transform_length;

  uint32_t dst_offset;
  uint32_t dst_length;

  Table()
      : tag(0),
        flags(0),
        transform_length(0),
        dst_offset(0),
        dst_length(0) {}

  bool operator<(const Table& other) const {
    return tag < other.tag;
  }
};

// Based on section 6.1.1 of MicroType Express draft spec
bool Read255UShort(ots::Buffer* buf, uint16_t* value) {
  static const uint8_t kWordCode = 253;
  static const uint8_t kOneMoreByteCode2 = 254;
  static const uint8_t kOneMoreByteCode1 = 255;
  static const uint8_t kLowestUCode = 253;
  uint8_t code = 0;
  if (!buf->ReadU8(&code)) {
    return OTS_FAILURE();
  }
  if (code == kWordCode) {
    uint16_t result = 0;
    if (!buf->ReadU16(&result)) {
      return OTS_FAILURE();
    }
    *value = result;
    return true;
  } else if (code == kOneMoreByteCode1) {
    uint8_t result = 0;
    if (!buf->ReadU8(&result)) {
      return OTS_FAILURE();
    }
    *value = result + kLowestUCode;
    return true;
  } else if (code == kOneMoreByteCode2) {
    uint8_t result = 0;
    if (!buf->ReadU8(&result)) {
      return OTS_FAILURE();
    }
    *value = result + kLowestUCode * 2;
    return true;
  } else {
    *value = code;
    return true;
  }
}

bool ReadBase128(ots::Buffer* buf, uint32_t* value) {
  uint32_t result = 0;
  for (size_t i = 0; i < 5; ++i) {
    uint8_t code = 0;
    if (!buf->ReadU8(&code)) {
      return OTS_FAILURE();
    }
    // If any of the top seven bits are set then we're about to overflow.
    if (result & 0xfe000000U) {
      return OTS_FAILURE();
    }
    result = (result << 7) | (code & 0x7f);
    if ((code & 0x80) == 0) {
      *value = result;
      return true;
    }
  }
  // Make sure not to exceed the size bound
  return OTS_FAILURE();
}

// Caller must ensure that buffer overrun won't happen.
// TODO(ksakamaoto): Consider creating 'writer' version of the Buffer class
// and use it across the code.
size_t StoreU32(uint8_t* dst, size_t offset, uint32_t x) {
  dst[offset] = x >> 24;
  dst[offset + 1] = (x >> 16) & 0xff;
  dst[offset + 2] = (x >> 8) & 0xff;
  dst[offset + 3] = x & 0xff;
  return offset + 4;
}

size_t StoreU16(uint8_t* dst, size_t offset, uint16_t x) {
  dst[offset] = x >> 8;
  dst[offset + 1] = x & 0xff;
  return offset + 2;
}

int WithSign(int flag, int baseval) {
  assert(0 <= baseval && baseval < 65536);
  return (flag & 1) ? baseval : -baseval;
}

bool TripletDecode(const uint8_t* flags_in, const uint8_t* in, size_t in_size,
    unsigned int n_points, std::vector<Point>* result,
    size_t* in_bytes_consumed) {
  int x = 0;
  int y = 0;

  // Early return if |in| buffer is too small. Each point consumes 1-4 bytes.
  if (n_points > in_size) {
    return OTS_FAILURE();
  }
  unsigned int triplet_index = 0;

  for (unsigned int i = 0; i < n_points; ++i) {
    uint8_t flag = flags_in[i];
    bool on_curve = !(flag >> 7);
    flag &= 0x7f;
    unsigned int n_data_bytes;
    if (flag < 84) {
      n_data_bytes = 1;
    } else if (flag < 120) {
      n_data_bytes = 2;
    } else if (flag < 124) {
      n_data_bytes = 3;
    } else {
      n_data_bytes = 4;
    }
    if (triplet_index + n_data_bytes > in_size ||
        triplet_index + n_data_bytes < triplet_index) {
      return OTS_FAILURE();
    }
    int dx, dy;
    if (flag < 10) {
      dx = 0;
      dy = WithSign(flag, ((flag & 14) << 7) + in[triplet_index]);
    } else if (flag < 20) {
      dx = WithSign(flag, (((flag - 10) & 14) << 7) + in[triplet_index]);
      dy = 0;
    } else if (flag < 84) {
      int b0 = flag - 20;
      int b1 = in[triplet_index];
      dx = WithSign(flag, 1 + (b0 & 0x30) + (b1 >> 4));
      dy = WithSign(flag >> 1, 1 + ((b0 & 0x0c) << 2) + (b1 & 0x0f));
    } else if (flag < 120) {
      int b0 = flag - 84;
      dx = WithSign(flag, 1 + ((b0 / 12) << 8) + in[triplet_index]);
      dy = WithSign(flag >> 1,
                    1 + (((b0 % 12) >> 2) << 8) + in[triplet_index + 1]);
    } else if (flag < 124) {
      int b2 = in[triplet_index + 1];
      dx = WithSign(flag, (in[triplet_index] << 4) + (b2 >> 4));
      dy = WithSign(flag >> 1, ((b2 & 0x0f) << 8) + in[triplet_index + 2]);
    } else {
      dx = WithSign(flag, (in[triplet_index] << 8) + in[triplet_index + 1]);
      dy = WithSign(flag >> 1,
          (in[triplet_index + 2] << 8) + in[triplet_index + 3]);
    }
    triplet_index += n_data_bytes;
    // Possible overflow but coordinate values are not security sensitive
    x += dx;
    y += dy;
    result->push_back(Point());
    Point& back = result->back();
    back.x = static_cast<int16_t>(x);
    back.y = static_cast<int16_t>(y);
    back.on_curve = on_curve;
  }
  *in_bytes_consumed = triplet_index;
  return true;
}

// This function stores just the point data. On entry, dst points to the
// beginning of a simple glyph. Returns true on success.
bool StorePoints(const std::vector<Point>& points,
    unsigned int n_contours, unsigned int instruction_length,
    uint8_t* dst, size_t dst_size, size_t* glyph_size) {
  // I believe that n_contours < 65536, in which case this is safe. However, a
  // comment and/or an assert would be good.
  unsigned int flag_offset = kEndPtsOfContoursOffset + 2 * n_contours + 2 +
    instruction_length;
  uint8_t last_flag = 0xff;
  uint8_t repeat_count = 0;
  int last_x = 0;
  int last_y = 0;
  unsigned int x_bytes = 0;
  unsigned int y_bytes = 0;

  for (size_t i = 0; i < points.size(); ++i) {
    const Point& point = points.at(i);
    uint8_t flag = point.on_curve ? kGlyfOnCurve : 0;
    int dx = point.x - last_x;
    int dy = point.y - last_y;
    if (dx == 0) {
      flag |= kGlyfThisXIsSame;
    } else if (dx > -256 && dx < 256) {
      flag |= kGlyfXShort | (dx > 0 ? kGlyfThisXIsSame : 0);
      x_bytes += 1;
    } else {
      x_bytes += 2;
    }
    if (dy == 0) {
      flag |= kGlyfThisYIsSame;
    } else if (dy > -256 && dy < 256) {
      flag |= kGlyfYShort | (dy > 0 ? kGlyfThisYIsSame : 0);
      y_bytes += 1;
    } else {
      y_bytes += 2;
    }

    if (flag == last_flag && repeat_count != 255) {
      dst[flag_offset - 1] |= kGlyfRepeat;
      repeat_count++;
    } else {
      if (repeat_count != 0) {
        if (flag_offset >= dst_size) {
          return OTS_FAILURE();
        }
        dst[flag_offset++] = repeat_count;
      }
      if (flag_offset >= dst_size) {
        return OTS_FAILURE();
      }
      dst[flag_offset++] = flag;
      repeat_count = 0;
    }
    last_x = point.x;
    last_y = point.y;
    last_flag = flag;
  }

  if (repeat_count != 0) {
    if (flag_offset >= dst_size) {
      return OTS_FAILURE();
    }
    dst[flag_offset++] = repeat_count;
  }
  unsigned int xy_bytes = x_bytes + y_bytes;
  if (xy_bytes < x_bytes ||
      flag_offset + xy_bytes < flag_offset ||
      flag_offset + xy_bytes > dst_size) {
    return OTS_FAILURE();
  }

  int x_offset = flag_offset;
  int y_offset = flag_offset + x_bytes;
  last_x = 0;
  last_y = 0;
  for (size_t i = 0; i < points.size(); ++i) {
    int dx = points.at(i).x - last_x;
    if (dx == 0) {
      // pass
    } else if (dx > -256 && dx < 256) {
      dst[x_offset++] = static_cast<uint8_t>(std::abs(dx));
    } else {
      // will always fit for valid input, but overflow is harmless
      x_offset = StoreU16(dst, x_offset, static_cast<uint16_t>(dx));
    }
    last_x += dx;
    int dy = points.at(i).y - last_y;
    if (dy == 0) {
      // pass
    } else if (dy > -256 && dy < 256) {
      dst[y_offset++] = static_cast<uint8_t>(std::abs(dy));
    } else {
      y_offset = StoreU16(dst, y_offset, static_cast<uint16_t>(dy));
    }
    last_y += dy;
  }
  *glyph_size = y_offset;
  return true;
}

// Compute the bounding box of the coordinates, and store into a glyf buffer.
// A precondition is that there are at least 10 bytes available.
void ComputeBbox(const std::vector<Point>& points, uint8_t* dst) {
  int16_t x_min = 0;
  int16_t y_min = 0;
  int16_t x_max = 0;
  int16_t y_max = 0;

  for (size_t i = 0; i < points.size(); ++i) {
    int16_t x = points.at(i).x;
    int16_t y = points.at(i).y;
    if (i == 0 || x < x_min) x_min = x;
    if (i == 0 || x > x_max) x_max = x;
    if (i == 0 || y < y_min) y_min = y;
    if (i == 0 || y > y_max) y_max = y;
  }
  size_t offset = 2;
  offset = StoreU16(dst, offset, x_min);
  offset = StoreU16(dst, offset, y_min);
  offset = StoreU16(dst, offset, x_max);
  offset = StoreU16(dst, offset, y_max);
}

// Process entire bbox stream. This is done as a separate pass to allow for
// composite bbox computations (an optional more aggressive transform).
bool ProcessBboxStream(ots::Buffer* bbox_stream, unsigned int n_glyphs,
    const std::vector<uint32_t>& loca_values, uint8_t* glyf_buf,
    size_t glyf_buf_length) {
  const uint8_t* buf = bbox_stream->buffer();
  if (n_glyphs >= 65536 || loca_values.size() != n_glyphs + 1) {
    return OTS_FAILURE();
  }
  // Safe because n_glyphs is bounded
  unsigned int bitmap_length = ((n_glyphs + 31) >> 5) << 2;
  if (!bbox_stream->Skip(bitmap_length)) {
    return OTS_FAILURE();
  }
  for (unsigned int i = 0; i < n_glyphs; ++i) {
    if (buf[i >> 3] & (0x80 >> (i & 7))) {
      uint32_t loca_offset = loca_values.at(i);
      if (loca_values.at(i + 1) - loca_offset < kEndPtsOfContoursOffset) {
        return OTS_FAILURE();
      }
      if (glyf_buf_length < 2 + 10 ||
          loca_offset > glyf_buf_length - 2 - 10) {
        return OTS_FAILURE();
      }
      if (!bbox_stream->Read(glyf_buf + loca_offset + 2, 8)) {
        return OTS_FAILURE();
      }
    }
  }
  return true;
}

bool ProcessComposite(ots::Buffer* composite_stream, uint8_t* dst,
    size_t dst_size, size_t* glyph_size, bool* have_instructions) {
  size_t start_offset = composite_stream->offset();
  bool we_have_instructions = false;

  uint16_t flags = FLAG_MORE_COMPONENTS;
  while (flags & FLAG_MORE_COMPONENTS) {
    if (!composite_stream->ReadU16(&flags)) {
      return OTS_FAILURE();
    }
    we_have_instructions |= (flags & FLAG_WE_HAVE_INSTRUCTIONS) != 0;
    size_t arg_size = 2;  // glyph index
    if (flags & FLAG_ARG_1_AND_2_ARE_WORDS) {
      arg_size += 4;
    } else {
      arg_size += 2;
    }
    if (flags & FLAG_WE_HAVE_A_SCALE) {
      arg_size += 2;
    } else if (flags & FLAG_WE_HAVE_AN_X_AND_Y_SCALE) {
      arg_size += 4;
    } else if (flags & FLAG_WE_HAVE_A_TWO_BY_TWO) {
      arg_size += 8;
    }
    if (!composite_stream->Skip(arg_size)) {
      return OTS_FAILURE();
    }
  }
  size_t composite_glyph_size = composite_stream->offset() - start_offset;
  if (composite_glyph_size + kCompositeGlyphBegin > dst_size) {
    return OTS_FAILURE();
  }
  StoreU16(dst, 0, 0xffff);  // nContours = -1 for composite glyph
  std::memcpy(dst + kCompositeGlyphBegin,
      composite_stream->buffer() + start_offset,
      composite_glyph_size);
  *glyph_size = kCompositeGlyphBegin + composite_glyph_size;
  *have_instructions = we_have_instructions;
  return true;
}

// Build TrueType loca table
bool StoreLoca(const std::vector<uint32_t>& loca_values, int index_format,
    uint8_t* dst, size_t dst_size) {
  const uint64_t loca_size = loca_values.size();
  const uint64_t offset_size = index_format ? 4 : 2;
  if ((loca_size << 2) >> 2 != loca_size) {
    return OTS_FAILURE();
  }
  // No integer overflow here (loca_size <= 2^16).
  if (offset_size * loca_size > dst_size) {
    return OTS_FAILURE();
  }
  size_t offset = 0;
  for (size_t i = 0; i < loca_values.size(); ++i) {
    uint32_t value = loca_values.at(i);
    if (index_format) {
      offset = StoreU32(dst, offset, value);
    } else {
      offset = StoreU16(dst, offset, static_cast<uint16_t>(value >> 1));
    }
  }
  return true;
}

// Reconstruct entire glyf table based on transformed original
bool ReconstructGlyf(ots::OpenTypeFile* file,
    const uint8_t* data, size_t data_size,
    uint8_t* dst, size_t dst_size,
    uint8_t* loca_buf, size_t loca_size) {
  static const int kNumSubStreams = 7;
  ots::Buffer buffer(data, data_size);
  uint32_t version;
  std::vector<std::pair<const uint8_t*, size_t> > substreams(kNumSubStreams);

  if (!buffer.ReadU32(&version)) {
    return OTS_FAILURE_MSG("Failed to read 'version' of transformed 'glyf' table");
  }
  uint16_t num_glyphs;
  if (!buffer.ReadU16(&num_glyphs)) {
    return OTS_FAILURE_MSG("Failed to read 'numGlyphs' from transformed 'glyf' table");
  }
  uint16_t index_format;
  if (!buffer.ReadU16(&index_format)) {
    return OTS_FAILURE_MSG("Failed to read 'indexFormat' from transformed 'glyf' table");
  }
  unsigned int offset = (2 + kNumSubStreams) * 4;
  if (offset > data_size) {
    return OTS_FAILURE_MSG("Size of transformed 'glyf' table is too small to fit its data");
  }
  // Invariant from here on: data_size >= offset
  for (int i = 0; i < kNumSubStreams; ++i) {
    uint32_t substream_size;
    if (!buffer.ReadU32(&substream_size)) {
      return OTS_FAILURE_MSG("Failed to read substream size %d of transformed 'glyf' table", i);
    }
    if (substream_size > data_size - offset) {
      return OTS_FAILURE_MSG("Size of substream %d of transformed 'glyf' table does not fit in table size");
    }
    substreams.at(i) = std::make_pair(data + offset, substream_size);
    offset += substream_size;
  }
  ots::Buffer n_contour_stream(substreams.at(0).first, substreams.at(0).second);
  ots::Buffer n_points_stream(substreams.at(1).first, substreams.at(1).second);
  ots::Buffer flag_stream(substreams.at(2).first, substreams.at(2).second);
  ots::Buffer glyph_stream(substreams.at(3).first, substreams.at(3).second);
  ots::Buffer composite_stream(substreams.at(4).first, substreams.at(4).second);
  ots::Buffer bbox_stream(substreams.at(5).first, substreams.at(5).second);
  ots::Buffer instruction_stream(substreams.at(6).first,
                                 substreams.at(6).second);

  std::vector<uint32_t> loca_values;
  loca_values.reserve(num_glyphs + 1);
  std::vector<uint16_t> n_points_vec;
  std::vector<Point> points;
  uint32_t loca_offset = 0;
  for (unsigned int i = 0; i < num_glyphs; ++i) {
    size_t glyph_size = 0;
    uint16_t n_contours = 0;
    if (!n_contour_stream.ReadU16(&n_contours)) {
      return OTS_FAILURE_MSG("Filed to read 'numberOfContours' of glyph %d from transformed 'glyf' table", i);
    }
    uint8_t* glyf_dst = dst + loca_offset;
    size_t glyf_dst_size = dst_size - loca_offset;
    if (n_contours == 0xffff) {
      // composite glyph
      bool have_instructions = false;
      uint16_t instruction_size = 0;
      if (!ProcessComposite(&composite_stream, glyf_dst, glyf_dst_size,
            &glyph_size, &have_instructions)) {
        return OTS_FAILURE_MSG("Filed to process composite glyph %d from transformed 'glyf' table", i);
      }
      if (have_instructions) {
        if (!Read255UShort(&glyph_stream, &instruction_size)) {
          return OTS_FAILURE_MSG("Failed to read 'instructionLength' of glyph %d from transformed 'glyf' table", i);
        }
        // No integer overflow here (instruction_size < 2^16).
        if (instruction_size + 2U > glyf_dst_size - glyph_size) {
          return OTS_FAILURE_MSG("'instructionLength' of glyph %d from transformed 'glyf' table does not fit in the destination glyph size", i);
        }
        StoreU16(glyf_dst, glyph_size, instruction_size);
        if (!instruction_stream.Read(glyf_dst + glyph_size + 2,
              instruction_size)) {
          return OTS_FAILURE_MSG("Filed to read instructions of glyph %d from transformed 'glyf' table", i);
        }
        glyph_size += instruction_size + 2;
      }
    } else if (n_contours > 0) {
      // simple glyph
      n_points_vec.clear();
      points.clear();
      uint32_t total_n_points = 0;
      uint16_t n_points_contour;
      for (uint32_t j = 0; j < n_contours; ++j) {
        if (!Read255UShort(&n_points_stream, &n_points_contour)) {
          return OTS_FAILURE_MSG("Filed to read number of points of contour %d of glyph %d from transformed 'glyf' table", j, i);
        }
        n_points_vec.push_back(n_points_contour);
        if (total_n_points + n_points_contour < total_n_points) {
          return OTS_FAILURE_MSG("Negative number of points of contour %d of glyph %d from transformed 'glyf' table", j, i);
        }
        total_n_points += n_points_contour;
      }
      uint32_t flag_size = total_n_points;
      if (flag_size > flag_stream.length() - flag_stream.offset()) {
        return OTS_FAILURE();
      }
      const uint8_t* flags_buf = flag_stream.buffer() + flag_stream.offset();
      const uint8_t* triplet_buf = glyph_stream.buffer() +
        glyph_stream.offset();
      size_t triplet_size = glyph_stream.length() - glyph_stream.offset();
      size_t triplet_bytes_consumed = 0;
      if (!TripletDecode(flags_buf, triplet_buf, triplet_size, total_n_points,
            &points, &triplet_bytes_consumed)) {
        return OTS_FAILURE();
      }
      const uint32_t header_and_endpts_contours_size =
          kEndPtsOfContoursOffset + 2 * n_contours;
      if (glyf_dst_size < header_and_endpts_contours_size) {
        return OTS_FAILURE();
      }
      StoreU16(glyf_dst, 0, n_contours);
      ComputeBbox(points, glyf_dst);
      size_t endpts_offset = kEndPtsOfContoursOffset;
      int end_point = -1;
      for (unsigned int contour_ix = 0; contour_ix < n_contours; ++contour_ix) {
        end_point += n_points_vec.at(contour_ix);
        if (end_point >= 65536) {
          return OTS_FAILURE();
        }
        endpts_offset = StoreU16(glyf_dst, endpts_offset, static_cast<uint16_t>(end_point));
      }
      if (!flag_stream.Skip(flag_size)) {
        return OTS_FAILURE();
      }
      if (!glyph_stream.Skip(triplet_bytes_consumed)) {
        return OTS_FAILURE();
      }
      uint16_t instruction_size;
      if (!Read255UShort(&glyph_stream, &instruction_size)) {
        return OTS_FAILURE();
      }
      // No integer overflow here (instruction_size < 2^16).
      if (glyf_dst_size - header_and_endpts_contours_size <
          instruction_size + 2U) {
        return OTS_FAILURE();
      }
      uint8_t* instruction_dst = glyf_dst + header_and_endpts_contours_size;
      StoreU16(instruction_dst, 0, instruction_size);
      if (!instruction_stream.Read(instruction_dst + 2, instruction_size)) {
        return OTS_FAILURE();
      }
      if (!StorePoints(points, n_contours, instruction_size,
            glyf_dst, glyf_dst_size, &glyph_size)) {
        return OTS_FAILURE_MSG("Failed to store points of glyph %d from the transformed 'glyf' table", i);
      }
    } else {
      glyph_size = 0;
    }
    loca_values.push_back(loca_offset);
    if (glyph_size + 3 < glyph_size) {
      return OTS_FAILURE();
    }
    glyph_size = ots::Round2(glyph_size);
    if (glyph_size > dst_size - loca_offset) {
      // This shouldn't happen, but this test defensively maintains the
      // invariant that loca_offset <= dst_size.
      return OTS_FAILURE();
    }
    loca_offset += glyph_size;
  }
  loca_values.push_back(loca_offset);
  assert(loca_values.size() == static_cast<size_t>(num_glyphs + 1));
  if (!ProcessBboxStream(&bbox_stream, num_glyphs, loca_values,
          dst, dst_size)) {
    return OTS_FAILURE_MSG("Filed to process 'bboxStream' from the transformed 'glyf' table");
  }
  return StoreLoca(loca_values, index_format, loca_buf, loca_size);
}

// This is linear search, but could be changed to binary because we
// do have a guarantee that the tables are sorted by tag. But the total
// cpu time is expected to be very small in any case.
const Table* FindTable(const std::vector<Table>& tables, uint32_t tag) {
  size_t n_tables = tables.size();
  for (size_t i = 0; i < n_tables; ++i) {
    if (tables.at(i).tag == tag) {
      return &tables.at(i);
    }
  }
  return NULL;
}

bool ReconstructTransformed(ots::OpenTypeFile* file,
    const std::vector<Table>& tables, uint32_t tag,
    const uint8_t* transformed_buf, size_t transformed_size,
    uint8_t* dst, size_t dst_length) {
  if (tag == TAG('g', 'l', 'y', 'f')) {
    const Table* glyf_table = FindTable(tables, tag);
    const Table* loca_table = FindTable(tables, TAG('l', 'o', 'c', 'a'));
    if (glyf_table == NULL || loca_table == NULL) {
      return OTS_FAILURE();
    }
    if (static_cast<uint64_t>(glyf_table->dst_offset) + glyf_table->dst_length >
        dst_length) {
      return OTS_FAILURE();
    }
    if (static_cast<uint64_t>(loca_table->dst_offset) + loca_table->dst_length >
        dst_length) {
      return OTS_FAILURE();
    }
    return ReconstructGlyf(file, transformed_buf, transformed_size,
        dst + glyf_table->dst_offset, glyf_table->dst_length,
        dst + loca_table->dst_offset, loca_table->dst_length);
  } else if (tag == TAG('l', 'o', 'c', 'a')) {
    // processing was already done by glyf table, but validate
    if (!FindTable(tables, TAG('g', 'l', 'y', 'f'))) {
      return OTS_FAILURE();
    }
  } else {
    // transform for the tag is not known
    return OTS_FAILURE();
  }
  return true;
}

uint32_t ComputeChecksum(const uint8_t* buf, size_t size) {
  uint32_t checksum = 0;
  for (size_t i = 0; i < size; i += 4) {
    // We assume the addition is mod 2^32, which is valid because unsigned
    checksum += (buf[i] << 24) | (buf[i + 1] << 16) |
      (buf[i + 2] << 8) | buf[i + 3];
  }
  return checksum;
}

bool FixChecksums(const std::vector<Table>& tables, uint8_t* dst) {
  const Table* head_table = FindTable(tables, TAG('h', 'e', 'a', 'd'));
  if (head_table == NULL ||
      head_table->dst_length < kCheckSumAdjustmentOffset + 4) {
    return OTS_FAILURE();
  }
  size_t adjustment_offset = head_table->dst_offset + kCheckSumAdjustmentOffset;
  if (adjustment_offset < head_table->dst_offset) {
    return OTS_FAILURE();
  }
  StoreU32(dst, adjustment_offset, 0);
  size_t n_tables = tables.size();
  uint32_t file_checksum = 0;
  for (size_t i = 0; i < n_tables; ++i) {
    const Table* table = &tables.at(i);
    size_t table_length = table->dst_length;
    uint8_t* table_data = dst + table->dst_offset;
    uint32_t checksum = ComputeChecksum(table_data, table_length);
    StoreU32(dst, kSfntHeaderSize + i * kSfntEntrySize + 4, checksum);
    file_checksum += checksum;  // The addition is mod 2^32
  }
  file_checksum += ComputeChecksum(dst,
      kSfntHeaderSize + kSfntEntrySize * n_tables);
  uint32_t checksum_adjustment = 0xb1b0afba - file_checksum;
  StoreU32(dst, adjustment_offset, checksum_adjustment);
  return true;
}

bool Woff2Uncompress(uint8_t* dst_buf, size_t dst_size,
    const uint8_t* src_buf, size_t src_size) {
  size_t uncompressed_size = dst_size;
  int ok = BrotliDecompressBuffer(src_size, src_buf,
                                  &uncompressed_size, dst_buf);
  if (!ok || uncompressed_size != dst_size) {
    return OTS_FAILURE();
  }
  return true;
}

bool ReadTableDirectory(ots::OpenTypeFile* file,
    ots::Buffer* buffer, std::vector<Table>* tables,
    size_t num_tables) {
  for (size_t i = 0; i < num_tables; ++i) {
    Table* table = &tables->at(i);
    uint8_t flag_byte;
    if (!buffer->ReadU8(&flag_byte)) {
      return OTS_FAILURE_MSG("Failed to read the flags of table directory entry %d", i);
    }
    uint32_t tag;
    if ((flag_byte & 0x3f) == 0x3f) {
      if (!buffer->ReadU32(&tag)) {
        return OTS_FAILURE_MSG("Failed to read the tag of table directory entry %d", i);
      }
    } else {
      tag = kKnownTags[flag_byte & 0x3f];
    }
    // Bits 6 and 7 are reserved and must be 0.
    if ((flag_byte & 0xc0) != 0) {
      return OTS_FAILURE_MSG("Bits 6 and 7 are not 0 for table directory entry %d", i);
    }
    uint32_t flags = 0;
    // Always transform the glyf and loca tables
    if (tag == TAG('g', 'l', 'y', 'f') ||
        tag == TAG('l', 'o', 'c', 'a')) {
      flags |= kWoff2FlagsTransform;
    }
    uint32_t dst_length;
    if (!ReadBase128(buffer, &dst_length)) {
      return OTS_FAILURE_MSG("Failed to read 'origLength' for table '%c%c%c%c'", CHR(tag));
    }
    uint32_t transform_length = dst_length;
    if ((flags & kWoff2FlagsTransform) != 0) {
      if (!ReadBase128(buffer, &transform_length)) {
        return OTS_FAILURE_MSG("Failed to read 'transformLength' for table '%c%c%c%c'", CHR(tag));
      }
    }
    // Disallow huge numbers (> 1GB) for sanity.
    if (transform_length > 1024 * 1024 * 1024 ||
        dst_length > 1024 * 1024 * 1024) {
      return OTS_FAILURE_MSG("'origLength' or 'transformLength' > 1GB");
    }
    table->tag = tag;
    table->flags = flags;
    table->transform_length = transform_length;
    table->dst_length = dst_length;
  }
  return true;
}

}  // namespace

namespace ots {

size_t ComputeWOFF2FinalSize(const uint8_t* data, size_t length) {
  ots::Buffer file(data, length);
  uint32_t total_length;

  if (!file.Skip(16) ||
      !file.ReadU32(&total_length)) {
    return 0;
  }
  return total_length;
}

bool ConvertWOFF2ToSFNT(ots::OpenTypeFile* file,
                        uint8_t* result, size_t result_length,
                        const uint8_t* data, size_t length) {
  static const uint32_t kWoff2Signature = 0x774f4632;  // "wOF2"
  ots::Buffer buffer(data, length);

  uint32_t signature;
  uint32_t flavor = 0;
  if (!buffer.ReadU32(&signature) || signature != kWoff2Signature ||
      !buffer.ReadU32(&flavor)) {
    return OTS_FAILURE_MSG("Failed to read 'signature' or 'flavor', or not WOFF2 signature");
  }

  if (!IsValidVersionTag(ntohl(flavor))) {
    return OTS_FAILURE_MSG("Invalid 'flavor'");
  }

  uint32_t reported_length;
  if (!buffer.ReadU32(&reported_length) || length != reported_length) {
    return OTS_FAILURE_MSG("Failed to read 'length' or it does not match the actual file size");
  }
  uint16_t num_tables;
  if (!buffer.ReadU16(&num_tables) || !num_tables) {
    return OTS_FAILURE_MSG("Failed to read 'numTables'");
  }

  uint16_t reserved_value;
  if (!buffer.ReadU16(&reserved_value)) {
    return OTS_FAILURE_MSG("Failed to read 'reserved' field");
  }

  // We don't care about these fields of the header:
  //   uint32_t total_sfnt_size, the caller already passes it as result_length
  if (!buffer.Skip(4)) {
    return OTS_FAILURE_MSG("Failed to read 'totalSfntSize'");
  }
  uint32_t compressed_length;
  if (!buffer.ReadU32(&compressed_length)) {
    return OTS_FAILURE_MSG("Failed to read 'totalCompressedSize'");
  }
  if (compressed_length > std::numeric_limits<uint32_t>::max()) {
    return OTS_FAILURE();
  }

  // We don't care about these fields of the header:
  //   uint16_t major_version, minor_version
  if (!buffer.Skip(2 * 2)) {
    return OTS_FAILURE_MSG("Failed to read 'majorVersion' or 'minorVersion'");
  }

  // Checks metadata block size.
  uint32_t meta_offset;
  uint32_t meta_length;
  uint32_t meta_length_orig;
  if (!buffer.ReadU32(&meta_offset) ||
      !buffer.ReadU32(&meta_length) ||
      !buffer.ReadU32(&meta_length_orig)) {
    return OTS_FAILURE_MSG("Failed to read header metadata block fields");
  }
  if (meta_offset) {
    if (meta_offset >= length || length - meta_offset < meta_length) {
      return OTS_FAILURE_MSG("Invalid metadata block offset or length");
    }
  }

  // Checks private data block size.
  uint32_t priv_offset;
  uint32_t priv_length;
  if (!buffer.ReadU32(&priv_offset) ||
      !buffer.ReadU32(&priv_length)) {
    return OTS_FAILURE_MSG("Failed to read header private block fields");
  }
  if (priv_offset) {
    if (priv_offset >= length || length - priv_offset < priv_length) {
      return OTS_FAILURE_MSG("Invalid private block offset or length");
    }
  }

  std::vector<Table> tables(num_tables);
  if (!ReadTableDirectory(file, &buffer, &tables, num_tables)) {
    return OTS_FAILURE_MSG("Failed to read table directory");
  }
  uint64_t compressed_offset = buffer.offset();
  if (compressed_offset > std::numeric_limits<uint32_t>::max()) {
    return OTS_FAILURE();
  }
  uint64_t dst_offset = kSfntHeaderSize +
      kSfntEntrySize * static_cast<uint64_t>(num_tables);
  for (uint16_t i = 0; i < num_tables; ++i) {
    Table* table = &tables.at(i);
    table->dst_offset = static_cast<uint32_t>(dst_offset);
    dst_offset += table->dst_length;
    if (dst_offset > std::numeric_limits<uint32_t>::max()) {
      return OTS_FAILURE();
    }
    dst_offset = ots::Round4(dst_offset);
  }

  uint64_t block_end = ots::Round4(compressed_offset + compressed_length);
  if (block_end > length || dst_offset != result_length) {
    return OTS_FAILURE_MSG("Uncompressed sfnt size mismatch");
  }

  const uint32_t sfnt_header_and_table_directory_size = 12 + 16 * num_tables;
  if (sfnt_header_and_table_directory_size > result_length) {
    return OTS_FAILURE();
  }

  if (meta_offset) {
    if (block_end != meta_offset) {
      return OTS_FAILURE_MSG("Invalid metadata block offset");
    }
    block_end = ots::Round4(static_cast<uint64_t>(meta_offset) +
                            static_cast<uint64_t>(meta_length));
    if (block_end > std::numeric_limits<uint32_t>::max()) {
      return OTS_FAILURE_MSG("Invalid metadata block length");
    }
  }

  if (priv_offset) {
    if (block_end != priv_offset) {
      return OTS_FAILURE_MSG("Invalid private block offset");
    }
    block_end = ots::Round4(static_cast<uint64_t>(priv_offset) +
                            static_cast<uint64_t>(priv_length));
    if (block_end > std::numeric_limits<uint32_t>::max()) {
      return OTS_FAILURE_MSG("Invalid private block length");
    }
  }

  if (block_end != ots::Round4(length)) {
    return OTS_FAILURE_MSG("File length mismatch (trailing junk?)");
  }

  // Start building the font
  size_t offset = 0;
  offset = StoreU32(result, offset, flavor);
  offset = StoreU16(result, offset, num_tables);
  uint8_t max_pow2 = 0;
  while (1u << (max_pow2 + 1) <= num_tables) {
    max_pow2++;
  }
  const uint16_t output_search_range = (1u << max_pow2) << 4;
  offset = StoreU16(result, offset, output_search_range);
  offset = StoreU16(result, offset, max_pow2);
  offset = StoreU16(result, offset, (num_tables << 4) - output_search_range);

  // sort tags in the table directory in ascending alphabetical order
  std::vector<Table> sorted_tables(tables);
  std::sort(sorted_tables.begin(), sorted_tables.end());

  for (uint16_t i = 0; i < num_tables; ++i) {
    const Table* table = &sorted_tables.at(i);
    offset = StoreU32(result, offset, table->tag);
    offset = StoreU32(result, offset, 0);  // checksum, to fill in later
    offset = StoreU32(result, offset, table->dst_offset);
    offset = StoreU32(result, offset, table->dst_length);
  }
  std::vector<uint8_t> uncompressed_buf;
  const uint8_t* transform_buf = NULL;
  uint64_t total_size = 0;

  for (uint16_t i = 0; i < num_tables; ++i) {
    total_size += tables.at(i).transform_length;
    if (total_size > std::numeric_limits<uint32_t>::max()) {
      return OTS_FAILURE();
    }
  }
  // Enforce same 30M limit on uncompressed tables as OTS
  if (total_size > 30 * 1024 * 1024) {
    return OTS_FAILURE();
  }
  const size_t total_size_size_t = static_cast<size_t>(total_size);
  uncompressed_buf.resize(total_size_size_t);
  const uint8_t* src_buf = data + compressed_offset;
  if (!Woff2Uncompress(&uncompressed_buf[0], total_size_size_t,
      src_buf, compressed_length)) {
    return OTS_FAILURE_MSG("Failed to uncompress font data");
  }
  transform_buf = &uncompressed_buf[0];

  for (uint16_t i = 0; i < num_tables; ++i) {
    const Table* table = &tables.at(i);
    uint32_t flags = table->flags;
    size_t transform_length = table->transform_length;

    if ((flags & kWoff2FlagsTransform) == 0) {
      if (transform_length != table->dst_length) {
        return OTS_FAILURE();
      }
      if (static_cast<uint64_t>(table->dst_offset) + transform_length >
          result_length) {
        return OTS_FAILURE();
      }
      std::memcpy(result + table->dst_offset, transform_buf,
          transform_length);
    } else {
      if (!ReconstructTransformed(file, tables, table->tag,
            transform_buf, transform_length, result, result_length)) {
        return OTS_FAILURE_MSG("Failed to reconstruct '%c%c%c%c' table", CHR(table->tag));
      }
    }

    transform_buf += transform_length;
    if (transform_buf > &uncompressed_buf[0] + uncompressed_buf.size()) {
      return OTS_FAILURE();
    }
  }

  return FixChecksums(sorted_tables, result);
}

}  // namespace ots

#undef TABLE_NAME
