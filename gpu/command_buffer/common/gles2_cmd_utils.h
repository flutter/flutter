// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is here so other GLES2 related files can have a common set of
// includes where appropriate.

#ifndef GPU_COMMAND_BUFFER_COMMON_GLES2_CMD_UTILS_H_
#define GPU_COMMAND_BUFFER_COMMON_GLES2_CMD_UTILS_H_

#include <stdint.h>

#include <limits>
#include <string>
#include <vector>

#include "base/numerics/safe_math.h"
#include "gpu/command_buffer/common/gles2_utils_export.h"

namespace gpu {
namespace gles2 {

// Does a multiply and checks for overflow.  If the multiply did not overflow
// returns true.

// Multiplies 2 32 bit unsigned numbers checking for overflow.
// If there was no overflow returns true.
inline bool SafeMultiplyUint32(uint32_t a, uint32_t b, uint32_t* dst) {
  DCHECK(dst);
  base::CheckedNumeric<uint32_t> checked = a;
  checked *= b;
  *dst = checked.ValueOrDefault(0);
  return checked.IsValid();
}

// Does an add checking for overflow.  If there was no overflow returns true.
inline bool SafeAddUint32(uint32_t a, uint32_t b, uint32_t* dst) {
  DCHECK(dst);
  base::CheckedNumeric<uint32_t> checked = a;
  checked += b;
  *dst = checked.ValueOrDefault(0);
  return checked.IsValid();
}

// Does an add checking for overflow.  If there was no overflow returns true.
inline bool SafeAddInt32(int32_t a, int32_t b, int32_t* dst) {
  DCHECK(dst);
  base::CheckedNumeric<int32_t> checked = a;
  checked += b;
  *dst = checked.ValueOrDefault(0);
  return checked.IsValid();
}

// Utilties for GLES2 support.
class GLES2_UTILS_EXPORT GLES2Util {
 public:
  static const int kNumFaces = 6;

  // Bits returned by GetChannelsForFormat
  enum ChannelBits {
    kRed = 0x1,
    kGreen = 0x2,
    kBlue = 0x4,
    kAlpha = 0x8,
    kDepth = 0x10000,
    kStencil = 0x20000,

    kRGB = kRed | kGreen | kBlue,
    kRGBA = kRGB | kAlpha
  };

  struct EnumToString {
    uint32_t value;
    const char* name;
  };

  GLES2Util()
      : num_compressed_texture_formats_(0),
        num_shader_binary_formats_(0) {
  }

  int num_compressed_texture_formats() const {
    return num_compressed_texture_formats_;
  }

  void set_num_compressed_texture_formats(int num_compressed_texture_formats) {
    num_compressed_texture_formats_ = num_compressed_texture_formats;
  }

  int num_shader_binary_formats() const {
    return num_shader_binary_formats_;
  }

  void set_num_shader_binary_formats(int num_shader_binary_formats) {
    num_shader_binary_formats_ = num_shader_binary_formats;
  }

  // Gets the number of values a particular id will return when a glGet
  // function is called. If 0 is returned the id is invalid.
  int GLGetNumValuesReturned(int id) const;

  // Computes the size of a single group of elements from a format and type pair
  static uint32_t ComputeImageGroupSize(int format, int type);

  // Computes the size of an image row including alignment padding
  static bool ComputeImagePaddedRowSize(
      int width, int format, int type, int unpack_alignment,
      uint32_t* padded_row_size);

  // Computes the size of image data for TexImage2D and TexSubImage2D.
  // Optionally the unpadded and padded row sizes can be returned. If height < 2
  // then the padded_row_size will be the same as the unpadded_row_size since
  // padding is not necessary.
  static bool ComputeImageDataSizes(
      int width, int height, int depth, int format, int type,
      int unpack_alignment, uint32_t* size, uint32_t* unpadded_row_size,
      uint32_t* padded_row_size);

  static size_t RenderbufferBytesPerPixel(int format);

  static uint32_t GetGLDataTypeSizeForUniforms(int type);

  static size_t GetGLTypeSizeForTexturesAndBuffers(uint32_t type);

  static uint32_t GLErrorToErrorBit(uint32_t gl_error);

  static uint32_t GLErrorBitToGLError(uint32_t error_bit);

  static uint32_t IndexToGLFaceTarget(int index);

  static size_t GLTargetToFaceIndex(uint32_t target);

  static uint32_t GetPreferredGLReadPixelsFormat(uint32_t internal_format);

  static uint32_t GetPreferredGLReadPixelsType(
      uint32_t internal_format, uint32_t texture_type);

  // Returns a bitmask for the channels the given format supports.
  // See ChannelBits.
  static uint32_t GetChannelsForFormat(int format);

  // Returns a bitmask for the channels the given attachment type needs.
  static uint32_t GetChannelsNeededForAttachmentType(
      int type, uint32_t max_color_attachments);

  // Return true if value is neither a power of two nor zero.
  static bool IsNPOT(uint32_t value) {
    return (value & (value - 1)) != 0;
  }

  // Return true if value is a power of two or zero.
  static bool IsPOT(uint32_t value) {
    return (value & (value - 1)) == 0;
  }

  static std::string GetStringEnum(uint32_t value);
  static std::string GetStringBool(uint32_t value);
  static std::string GetStringError(uint32_t value);

  // Parses a uniform name.
  //   array_pos: the position of the last '[' character in name.
  //   element_index: the index of the array element specifed in the name.
  //   getting_array: True if name refers to array.
  // returns true of parsing was successful. Returing true does NOT mean
  // it's a valid uniform name. On the otherhand, returning false does mean
  // it's an invalid uniform name.
  static bool ParseUniformName(
      const std::string& name,
      size_t* array_pos,
      int* element_index,
      bool* getting_array);

  static size_t CalcClearBufferivDataCount(int buffer);
  static size_t CalcClearBufferfvDataCount(int buffer);

  static void MapUint64ToTwoUint32(
      uint64_t v64, uint32_t* v32_0, uint32_t* v32_1);
  static uint64_t MapTwoUint32ToUint64(uint32_t v32_0, uint32_t v32_1);

  static uint32_t MapBufferTargetToBindingEnum(uint32_t target);

  #include "../common/gles2_cmd_utils_autogen.h"

 private:
  static std::string GetQualifiedEnumString(
      const EnumToString* table, size_t count, uint32_t value);

  static const EnumToString* const enum_to_string_table_;
  static const size_t enum_to_string_table_len_;

  int num_compressed_texture_formats_;
  int num_shader_binary_formats_;
};

struct GLES2_UTILS_EXPORT ContextCreationAttribHelper {
  ContextCreationAttribHelper();

  void Serialize(std::vector<int32_t>* attribs) const;
  bool Parse(const std::vector<int32_t>& attribs);

  // -1 if invalid or unspecified.
  int32_t alpha_size;
  int32_t blue_size;
  int32_t green_size;
  int32_t red_size;
  int32_t depth_size;
  int32_t stencil_size;
  int32_t samples;
  int32_t sample_buffers;
  bool buffer_preserved;
  bool bind_generates_resource;
  bool fail_if_major_perf_caveat;
  bool lose_context_when_out_of_memory;
  bool es3_context_required;
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_COMMON_GLES2_CMD_UTILS_H_

