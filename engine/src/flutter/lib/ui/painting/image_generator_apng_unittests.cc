// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_generator_apng.h"

#include <cstdint>
#include <cstring>
#include <vector>

#include "flutter/lib/ui/painting/image_generator_registry.h"
#include "flutter/testing/testing.h"
#include "third_party/skia/include/core/SkData.h"

namespace flutter {
namespace testing {

namespace {

// Writes a big-endian uint32_t to a buffer.
void WriteBE32(std::vector<uint8_t>& buf, uint32_t val) {
  buf.push_back((val >> 24) & 0xFF);
  buf.push_back((val >> 16) & 0xFF);
  buf.push_back((val >> 8) & 0xFF);
  buf.push_back(val & 0xFF);
}

// Writes a big-endian uint16_t to a buffer.
void WriteBE16(std::vector<uint8_t>& buf, uint16_t val) {
  buf.push_back((val >> 8) & 0xFF);
  buf.push_back(val & 0xFF);
}

// Appends a PNG chunk (length + type + data + CRC) to the buffer.
void AppendChunk(std::vector<uint8_t>& buf,
                 const char type[4],
                 const std::vector<uint8_t>& data) {
  FML_CHECK(data.size() <= std::numeric_limits<uint32_t>::max());
  WriteBE32(buf, static_cast<uint32_t>(data.size()));
  size_t type_start = buf.size();
  buf.insert(buf.end(), type, type + 4);
  buf.insert(buf.end(), data.begin(), data.end());
  uint32_t crc = APNGImageGenerator::ComputeCrc32(buf.data() + type_start,
                                                  4 + data.size());
  WriteBE32(buf, crc);
}

// Builds a minimal valid APNG with a malicious fdAT chunk whose
// data_length is less than 4, which would trigger an integer underflow
// in DemuxNextImage() without the bounds check fix.
std::vector<uint8_t> BuildMaliciousApng(uint32_t fdat_data_length) {
  std::vector<uint8_t> apng;

  // PNG signature
  const uint8_t sig[] = {137, 80, 78, 71, 13, 10, 26, 10};
  apng.insert(apng.end(), sig, sig + 8);

  // IHDR: 1x1 RGBA, 8-bit
  {
    std::vector<uint8_t> ihdr;
    WriteBE32(ihdr, 1);  // width
    WriteBE32(ihdr, 1);  // height
    ihdr.push_back(8);   // bit depth
    ihdr.push_back(6);   // color type (RGBA)
    ihdr.push_back(0);   // compression
    ihdr.push_back(0);   // filter
    ihdr.push_back(0);   // interlace
    AppendChunk(apng, "IHDR", ihdr);
  }

  // acTL: 1 frame, loop forever
  {
    std::vector<uint8_t> actl;
    WriteBE32(actl, 1);  // num_frames
    WriteBE32(actl, 0);  // num_plays (0 = infinite)
    AppendChunk(apng, "acTL", actl);
  }

  // fcTL for frame 0
  {
    std::vector<uint8_t> fctl;
    WriteBE32(fctl, 0);   // sequence_number
    WriteBE32(fctl, 1);   // width
    WriteBE32(fctl, 1);   // height
    WriteBE32(fctl, 0);   // x_offset
    WriteBE32(fctl, 0);   // y_offset
    WriteBE16(fctl, 1);   // delay_num
    WriteBE16(fctl, 10);  // delay_den
    fctl.push_back(0);    // dispose_op
    fctl.push_back(0);    // blend_op
    AppendChunk(apng, "fcTL", fctl);
  }

  // Malicious fdAT for frame 0: data_length < 4
  // An fdAT chunk must have at least 4 bytes (sequence number).
  // With data_length < 4, the subtraction in DemuxNextImage() underflows.
  AppendChunk(apng, "fdAT", std::vector<uint8_t>(fdat_data_length, 0));

  // IEND
  AppendChunk(apng, "IEND", {});

  return apng;
}

}  // namespace

// Verify that the APNG decoder can handle fdAT chunks whose length is shorter
// than the required 4-byte sequence number.
TEST(APNGImageGeneratorTest, FdATWithShortDataLengthDoesNotCrash) {
  ImageGeneratorRegistry registry;

  auto make_generator = [](uint32_t fdat_length) -> auto {
    auto apng_bytes = BuildMaliciousApng(fdat_length);
    auto data = SkData::MakeWithCopy(apng_bytes.data(), apng_bytes.size());
    return APNGImageGenerator::MakeFromData(data);
  };

  // The decoder should reject fdAT chunks that are less than 4 bytes long.
  EXPECT_EQ(make_generator(0), nullptr);
  EXPECT_EQ(make_generator(2), nullptr);

  // Creating the generator should succeed if the fdAT has sufficient length.
  EXPECT_NE(make_generator(4), nullptr);
}

}  // namespace testing
}  // namespace flutter
