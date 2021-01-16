// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "third_party/zlib/google/compression_utils.h"

#include "base/bit_cast.h"
#include "base/check_op.h"
#include "base/process/memory.h"
#include "base/sys_byteorder.h"

#include "third_party/zlib/google/compression_utils_portable.h"

namespace compression {

bool GzipCompress(base::span<const char> input,
                  char* output_buffer,
                  size_t output_buffer_size,
                  size_t* compressed_size,
                  void* (*malloc_fn)(size_t),
                  void (*free_fn)(void*)) {
  static_assert(sizeof(Bytef) == 1, "");

  // uLongf can be larger than size_t.
  uLongf compressed_size_long = static_cast<uLongf>(output_buffer_size);
  if (zlib_internal::GzipCompressHelper(
          bit_cast<Bytef*>(output_buffer), &compressed_size_long,
          bit_cast<const Bytef*>(input.data()),
          static_cast<uLongf>(input.size()), malloc_fn, free_fn) != Z_OK) {
    return false;
  }
  // No overflow, as compressed_size_long <= output.size() which is a size_t.
  *compressed_size = static_cast<size_t>(compressed_size_long);
  return true;
}

bool GzipCompress(base::span<const char> input, std::string* output) {
  return GzipCompress(base::as_bytes(input), output);
}

bool GzipCompress(base::span<const uint8_t> input, std::string* output) {
  // Not using std::vector<> because allocation failures are recoverable,
  // which is hidden by std::vector<>.
  static_assert(sizeof(Bytef) == 1, "");
  const uLongf input_size = static_cast<uLongf>(input.size());

  uLongf compressed_data_size =
      zlib_internal::GzipExpectedCompressedSize(input_size);

  Bytef* compressed_data;
  if (!base::UncheckedMalloc(compressed_data_size,
                             reinterpret_cast<void**>(&compressed_data))) {
    return false;
  }

  if (zlib_internal::GzipCompressHelper(compressed_data, &compressed_data_size,
                                        bit_cast<const Bytef*>(input.data()),
                                        input_size, nullptr, nullptr) != Z_OK) {
    free(compressed_data);
    return false;
  }

  Bytef* resized_data =
      reinterpret_cast<Bytef*>(realloc(compressed_data, compressed_data_size));
  if (!resized_data) {
    free(compressed_data);
    return false;
  }
  output->assign(resized_data, resized_data + compressed_data_size);
  DCHECK_EQ(input_size, GetUncompressedSize(*output));

  free(resized_data);
  return true;
}

bool GzipUncompress(const std::string& input, std::string* output) {
  std::string uncompressed_output;
  uLongf uncompressed_size = static_cast<uLongf>(GetUncompressedSize(input));
  if (uncompressed_size > uncompressed_output.max_size())
    return false;

  uncompressed_output.resize(uncompressed_size);
  if (zlib_internal::GzipUncompressHelper(
          bit_cast<Bytef*>(uncompressed_output.data()), &uncompressed_size,
          bit_cast<const Bytef*>(input.data()),
          static_cast<uLongf>(input.length())) == Z_OK) {
    output->swap(uncompressed_output);
    return true;
  }
  return false;
}

bool GzipUncompress(base::span<const char> input,
                    base::span<const char> output) {
  return GzipUncompress(base::as_bytes(input), base::as_bytes(output));
}

bool GzipUncompress(base::span<const uint8_t> input,
                    base::span<const uint8_t> output) {
  uLongf uncompressed_size = GetUncompressedSize(input);
  if (uncompressed_size > output.size())
    return false;
  return zlib_internal::GzipUncompressHelper(
             bit_cast<Bytef*>(output.data()), &uncompressed_size,
             bit_cast<const Bytef*>(input.data()),
             static_cast<uLongf>(input.size())) == Z_OK;
}

bool GzipUncompress(base::span<const char> input, std::string* output) {
  return GzipUncompress(base::as_bytes(input), output);
}

bool GzipUncompress(base::span<const uint8_t> input, std::string* output) {
  // Disallow in-place usage, i.e., |input| using |*output| as underlying data.
  DCHECK_NE(reinterpret_cast<const char*>(input.data()), output->data());
  uLongf uncompressed_size = GetUncompressedSize(input);
  output->resize(uncompressed_size);
  return zlib_internal::GzipUncompressHelper(
             bit_cast<Bytef*>(output->data()), &uncompressed_size,
             bit_cast<const Bytef*>(input.data()),
             static_cast<uLongf>(input.size())) == Z_OK;
}

uint32_t GetUncompressedSize(base::span<const char> compressed_data) {
  return GetUncompressedSize(base::as_bytes(compressed_data));
}

uint32_t GetUncompressedSize(base::span<const uint8_t> compressed_data) {
  return zlib_internal::GetGzipUncompressedSize(
      bit_cast<Bytef*>(compressed_data.data()), compressed_data.size());
}

}  // namespace compression
