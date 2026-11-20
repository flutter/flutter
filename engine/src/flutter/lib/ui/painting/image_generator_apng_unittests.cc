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

// Appends a chunk with a declared data_length that may differ from the actual
// data bytes written. Used to test handling of malformed chunks.
void AppendChunkWithFakeLength(std::vector<uint8_t>& buf,
                               const char type[4],
                               uint32_t declared_length,
                               const std::vector<uint8_t>& actual_data) {
  WriteBE32(buf, declared_length);
  buf.insert(buf.end(), type, type + 4);
  buf.insert(buf.end(), actual_data.begin(), actual_data.end());
  WriteBE32(buf, 0);  // CRC placeholder
}

// Builds a minimal valid APNG with a malicious fdAT chunk whose
// data_length is less than 4, which would trigger an integer underflow
// in DemuxNextImage() without the bounds check fix.
std::vector<uint8_t> BuildMaliciousApng(uint32_t fdat_data_length) {
  std::vector<uint8_t> apng(APNGImageGenerator::kPngSignature.begin(),
                            APNGImageGenerator::kPngSignature.end());

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

// Appends an IHDR chunk with the given dimensions (RGBA, 8-bit).
void AppendImageHeaderChunk(std::vector<uint8_t>& apng,
                            uint32_t width,
                            uint32_t height) {
  std::vector<uint8_t> ihdr;
  WriteBE32(ihdr, width);
  WriteBE32(ihdr, height);
  ihdr.push_back(8);  // bit depth
  ihdr.push_back(6);  // color type (RGBA)
  ihdr.push_back(0);  // compression
  ihdr.push_back(0);  // filter
  ihdr.push_back(0);  // interlace
  AppendChunk(apng, "IHDR", ihdr);
}

// Appends an fcTL chunk for a frame with the given dimensions.
void AppendFrameControlChunk(std::vector<uint8_t>& apng,
                             uint32_t sequence_number,
                             uint32_t width,
                             uint32_t height) {
  std::vector<uint8_t> fctl;
  WriteBE32(fctl, sequence_number);
  WriteBE32(fctl, width);
  WriteBE32(fctl, height);
  WriteBE32(fctl, 0);   // x_offset
  WriteBE32(fctl, 0);   // y_offset
  WriteBE16(fctl, 1);   // delay_num
  WriteBE16(fctl, 10);  // delay_den
  fctl.push_back(0);    // dispose_op
  fctl.push_back(0);    // blend_op
  AppendChunk(apng, "fcTL", fctl);
}

// Appends an fdAT chunk with the given sequence number and zlib data.
void AppendFrameDataChunk(std::vector<uint8_t>& apng,
                          uint32_t sequence_number,
                          const std::vector<uint8_t>& zlib_data) {
  std::vector<uint8_t> fdat;
  WriteBE32(fdat, sequence_number);
  fdat.insert(fdat.end(), zlib_data.begin(), zlib_data.end());
  AppendChunk(apng, "fdAT", fdat);
}

// The zlib stream of a valid 1x1 RGBA image (a single transparent pixel).
std::vector<uint8_t> OnePixelZlibData() {
  return {0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01};
}

// Builds a PNG whose header declares dimensions requiring ~1 GiB of decoded
// pixel data (16383 * 16383 * 4 bytes), which exceeds
// ImageGenerator::kMaxDecodedImageBytes.
std::vector<uint8_t> BuildPngWithOversizedHeader() {
  std::vector<uint8_t> png(APNGImageGenerator::kPngSignature.begin(),
                           APNGImageGenerator::kPngSignature.end());
  AppendImageHeaderChunk(png, 16383, 16383);
  AppendChunk(png, "IDAT", {0, 0, 0, 0});
  AppendChunk(png, "IEND", {});
  return png;
}

// Builds an APNG whose default image declares dimensions requiring ~1 GiB of
// decoded pixel data. The multi-frame canvas is allocated from the default
// image dimensions, so the generator must be rejected at creation time.
std::vector<uint8_t> BuildApngWithOversizedDefaultImage() {
  std::vector<uint8_t> apng(APNGImageGenerator::kPngSignature.begin(),
                            APNGImageGenerator::kPngSignature.end());
  AppendImageHeaderChunk(apng, 16383, 16383);
  {
    std::vector<uint8_t> actl;
    WriteBE32(actl, 1);  // num_frames
    WriteBE32(actl, 0);  // num_plays (0 = infinite)
    AppendChunk(apng, "acTL", actl);
  }
  AppendChunk(apng, "IDAT", {0, 0, 0, 0});
  AppendFrameControlChunk(apng, 0, 1, 1);
  AppendFrameDataChunk(apng, 0, {0, 0, 0, 0});
  AppendChunk(apng, "IEND", {});
  return apng;
}

// Builds an APNG with a valid 1x1 default frame followed by a frame whose
// fcTL dimensions require ~1 GiB of decoded pixel data. Without a decoded
// image budget, decoding the second frame attempts a ~1 GiB allocation.
// Note: the demuxer only tracks frame info for default images demuxed from
// fcTL frames, so the first chunk after acTL must be an fcTL (no IDAT).
std::vector<uint8_t> BuildApngWithOversizedFrame() {
  std::vector<uint8_t> apng(APNGImageGenerator::kPngSignature.begin(),
                            APNGImageGenerator::kPngSignature.end());
  AppendImageHeaderChunk(apng, 1, 1);
  {
    std::vector<uint8_t> actl;
    WriteBE32(actl, 2);  // num_frames
    WriteBE32(actl, 0);  // num_plays (0 = infinite)
    AppendChunk(apng, "acTL", actl);
  }
  AppendFrameControlChunk(apng, 0, 1, 1);
  AppendFrameDataChunk(apng, 0, OnePixelZlibData());
  AppendFrameControlChunk(apng, 1, 16383, 16383);
  AppendFrameDataChunk(apng, 1, OnePixelZlibData());
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

TEST(APNGImageGeneratorTest, FdATWithOverflowDataLengthIsRejected) {
  std::vector<uint8_t> apng(APNGImageGenerator::kPngSignature.begin(),
                            APNGImageGenerator::kPngSignature.end());

  // IHDR
  {
    std::vector<uint8_t> ihdr;
    WriteBE32(ihdr, 1);
    WriteBE32(ihdr, 1);
    ihdr.push_back(8);
    ihdr.push_back(6);
    ihdr.push_back(0);
    ihdr.push_back(0);
    ihdr.push_back(0);
    AppendChunk(apng, "IHDR", ihdr);
  }
  // acTL
  {
    std::vector<uint8_t> actl;
    WriteBE32(actl, 1);
    WriteBE32(actl, 0);
    AppendChunk(apng, "acTL", actl);
  }
  // fcTL
  {
    std::vector<uint8_t> fctl;
    WriteBE32(fctl, 0);
    WriteBE32(fctl, 1);
    WriteBE32(fctl, 1);
    WriteBE32(fctl, 0);
    WriteBE32(fctl, 0);
    WriteBE16(fctl, 1);
    WriteBE16(fctl, 10);
    fctl.push_back(0);
    fctl.push_back(0);
    AppendChunk(apng, "fcTL", fctl);
  }
  // fdAT with declared data_length=0xFFFFFFFF but only 8 actual bytes
  AppendChunkWithFakeLength(apng, "fdAT", 0xFFFFFFFF, {0, 0, 0, 1, 0, 0, 0, 0});
  // IEND
  AppendChunk(apng, "IEND", {});

  auto data = SkData::MakeWithCopy(apng.data(), apng.size());
  auto generator = APNGImageGenerator::MakeFromData(data);
  // The generator should reject the malformed APNG without crashing.
  EXPECT_EQ(generator, nullptr);
}

// Verify that a PNG header declaring dimensions beyond the decoded image
// budget is rejected when the generator is created, before any allocation
// is attempted.
TEST(BuiltinSkiaCodecImageGeneratorTest, OversizedHeaderIsRejected) {
  // Constructing a registry registers the Skia codecs, which
  // SkCodec::MakeFromData relies on.
  ImageGeneratorRegistry registry;

  std::vector<uint8_t> png_bytes = BuildPngWithOversizedHeader();
  auto data = SkData::MakeWithCopy(png_bytes.data(), png_bytes.size());
  EXPECT_EQ(BuiltinSkiaCodecImageGenerator::MakeFromData(data), nullptr);
}

// Verify that an APNG default image beyond the decoded image budget is
// rejected when the generator is created.
TEST(APNGImageGeneratorTest, OversizedDefaultImageIsRejected) {
  // Constructing a registry registers the Skia codecs, which the APNG
  // demuxer relies on.
  ImageGeneratorRegistry registry;

  std::vector<uint8_t> apng_bytes = BuildApngWithOversizedDefaultImage();
  auto data = SkData::MakeWithCopy(apng_bytes.data(), apng_bytes.size());
  EXPECT_EQ(APNGImageGenerator::MakeFromData(data), nullptr);
}

// Verify that an APNG frame beyond the decoded image budget is rejected
// before its pixel buffer is allocated, while normal frames still decode.
TEST(APNGImageGeneratorTest, OversizedFrameIsRejectedWithoutAllocation) {
  // Constructing a registry registers the Skia codecs, which the APNG
  // demuxer relies on.
  ImageGeneratorRegistry registry;

  std::vector<uint8_t> apng_bytes = BuildApngWithOversizedFrame();
  auto data = SkData::MakeWithCopy(apng_bytes.data(), apng_bytes.size());
  auto generator = APNGImageGenerator::MakeFromData(data);
  ASSERT_NE(generator, nullptr);
  EXPECT_EQ(generator->GetFrameCount(), 2u);

  SkImageInfo info = SkImageInfo::MakeN32(1, 1, kPremul_SkAlphaType);
  std::vector<uint8_t> pixels(info.computeMinByteSize());

  // The first frame (1x1) decodes normally.
  EXPECT_TRUE(generator->GetPixels(info, pixels.data(), info.minRowBytes(),
                                   /*frame_index=*/0));

  // The oversized frame is rejected without attempting its pixel allocation.
  EXPECT_FALSE(generator->GetPixels(info, pixels.data(), info.minRowBytes(),
                                    /*frame_index=*/1));
}

}  // namespace testing
}  // namespace flutter
