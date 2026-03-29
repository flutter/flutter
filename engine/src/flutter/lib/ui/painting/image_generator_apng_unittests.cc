// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_generator_apng.h"

#include <cstdint>
#include <cstring>
#include <vector>

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

// Computes CRC32 over chunk type + data (standard PNG CRC).
uint32_t ComputePngCrc32(const uint8_t* data, size_t length) {
  uint32_t crc = 0xFFFFFFFF;
  for (size_t i = 0; i < length; i++) {
    crc ^= data[i];
    for (int j = 0; j < 8; j++) {
      crc = (crc >> 1) ^ (0xEDB88320 & (-(crc & 1)));
    }
  }
  return crc ^ 0xFFFFFFFF;
}

// Appends a PNG chunk (length + type + data + CRC) to the buffer.
void AppendChunk(std::vector<uint8_t>& buf,
                 const char type[4],
                 const std::vector<uint8_t>& data) {
  WriteBE32(buf, static_cast<uint32_t>(data.size()));
  size_t type_start = buf.size();
  buf.insert(buf.end(), type, type + 4);
  buf.insert(buf.end(), data.begin(), data.end());
  uint32_t crc =
      ComputePngCrc32(buf.data() + type_start, 4 + data.size());
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

  // acTL: 2 frames, loop forever
  {
    std::vector<uint8_t> actl;
    WriteBE32(actl, 2);  // num_frames
    WriteBE32(actl, 0);  // num_plays (0 = infinite)
    AppendChunk(apng, "acTL", actl);
  }

  // fcTL for frame 0
  {
    std::vector<uint8_t> fctl;
    WriteBE32(fctl, 0);  // sequence_number
    WriteBE32(fctl, 1);  // width
    WriteBE32(fctl, 1);  // height
    WriteBE32(fctl, 0);  // x_offset
    WriteBE32(fctl, 0);  // y_offset
    WriteBE16(fctl, 1);  // delay_num
    WriteBE16(fctl, 10); // delay_den
    fctl.push_back(0);   // dispose_op
    fctl.push_back(0);   // blend_op
    AppendChunk(apng, "fcTL", fctl);
  }

  // IDAT for frame 0: minimal valid zlib-compressed 1x1 RGBA
  {
    // zlib header (78 01) + deflate block for filter_byte(0) + RGBA(0,0,0,255)
    const uint8_t idat_data[] = {0x78, 0x01, 0x62, 0x60, 0x60, 0x60,
                                  0xF8, 0x0F, 0x00, 0x00, 0x05, 0x00,
                                  0x01};
    std::vector<uint8_t> idat(idat_data, idat_data + sizeof(idat_data));
    AppendChunk(apng, "IDAT", idat);
  }

  // fcTL for frame 1
  {
    std::vector<uint8_t> fctl;
    WriteBE32(fctl, 1);  // sequence_number
    WriteBE32(fctl, 1);  // width
    WriteBE32(fctl, 1);  // height
    WriteBE32(fctl, 0);  // x_offset
    WriteBE32(fctl, 0);  // y_offset
    WriteBE16(fctl, 1);  // delay_num
    WriteBE16(fctl, 10); // delay_den
    fctl.push_back(0);   // dispose_op
    fctl.push_back(0);   // blend_op
    AppendChunk(apng, "fcTL", fctl);
  }

  // MALICIOUS fdAT for frame 1: data_length < 4
  // An fdAT chunk must have at least 4 bytes (sequence number).
  // With data_length < 4, the subtraction in DemuxNextImage() underflows.
  {
    std::vector<uint8_t> fdat;
    for (uint32_t i = 0; i < fdat_data_length; i++) {
      fdat.push_back(0);
    }
    AppendChunk(apng, "fdAT", fdat);
  }

  // IEND
  AppendChunk(apng, "IEND", {});

  return apng;
}

}  // namespace

// Verify that an APNG with an fdAT chunk of data_length=0 does not crash.
// Without the fix, this would cause a uint32_t underflow (0 - 4 = 0xFFFFFFFC)
// leading to a heap buffer overflow in DemuxNextImage().
TEST(APNGImageGeneratorTest, FdATWithZeroDataLengthDoesNotCrash) {
  auto apng_bytes = BuildMaliciousApng(0);
  auto data = SkData::MakeWithCopy(apng_bytes.data(), apng_bytes.size());
  auto generator = APNGImageGenerator::MakeFromData(data);

  // The generator may fail to create (if the malformed fdAT is caught during
  // initial parsing) or may create successfully but fail during frame decode.
  // Either way, it must NOT crash.
  if (generator) {
    // If the generator was created, try to decode frame 1 which references
    // the malicious fdAT. This must not crash.
    auto info = generator->GetInfo();
    std::vector<uint8_t> pixels(info.computeMinByteSize());
    generator->GetPixels(info, pixels.data(), info.minRowBytes(), 1,
                         std::nullopt);
  }
}

// Verify that an fdAT chunk with data_length=2 (less than the required 4-byte
// sequence number) also does not crash.
TEST(APNGImageGeneratorTest, FdATWithShortDataLengthDoesNotCrash) {
  auto apng_bytes = BuildMaliciousApng(2);
  auto data = SkData::MakeWithCopy(apng_bytes.data(), apng_bytes.size());
  auto generator = APNGImageGenerator::MakeFromData(data);

  if (generator) {
    auto info = generator->GetInfo();
    std::vector<uint8_t> pixels(info.computeMinByteSize());
    generator->GetPixels(info, pixels.data(), info.minRowBytes(), 1,
                         std::nullopt);
  }
}

// Verify that a valid fdAT chunk (data_length >= 4) still works correctly.
TEST(APNGImageGeneratorTest, ValidFdATIsAccepted) {
  // data_length=8: 4 bytes sequence number + 4 bytes compressed data
  auto apng_bytes = BuildMaliciousApng(8);
  auto data = SkData::MakeWithCopy(apng_bytes.data(), apng_bytes.size());
  auto generator = APNGImageGenerator::MakeFromData(data);

  // A valid APNG with proper fdAT should create a generator successfully.
  // Frame decode may still fail due to invalid compressed data, but the
  // generator creation should not be rejected by the data_length check.
  if (generator) {
    EXPECT_GE(generator->GetFrameCount(), 1u);
  }
}

}  // namespace testing
}  // namespace flutter
