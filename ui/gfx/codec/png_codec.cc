// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/codec/png_codec.h"

#include "base/logging.h"
#include "base/strings/string_util.h"
#include "third_party/libpng/png.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkColorPriv.h"
#include "third_party/skia/include/core/SkUnPreMultiply.h"
#include "third_party/zlib/zlib.h"
#include "ui/gfx/size.h"
#include "ui/gfx/skia_util.h"

namespace gfx {

namespace {

// Converts BGRA->RGBA and RGBA->BGRA.
void ConvertBetweenBGRAandRGBA(const unsigned char* input, int pixel_width,
                               unsigned char* output, bool* is_opaque) {
  for (int x = 0; x < pixel_width; x++) {
    const unsigned char* pixel_in = &input[x * 4];
    unsigned char* pixel_out = &output[x * 4];
    pixel_out[0] = pixel_in[2];
    pixel_out[1] = pixel_in[1];
    pixel_out[2] = pixel_in[0];
    pixel_out[3] = pixel_in[3];
  }
}

void ConvertRGBAtoRGB(const unsigned char* rgba, int pixel_width,
                      unsigned char* rgb, bool* is_opaque) {
  for (int x = 0; x < pixel_width; x++)
    memcpy(&rgb[x * 3], &rgba[x * 4], 3);
}

void ConvertSkiaToRGB(const unsigned char* skia, int pixel_width,
                      unsigned char* rgb, bool* is_opaque) {
  for (int x = 0; x < pixel_width; x++) {
    const uint32_t pixel_in = *reinterpret_cast<const uint32_t*>(&skia[x * 4]);
    unsigned char* pixel_out = &rgb[x * 3];

    int alpha = SkGetPackedA32(pixel_in);
    if (alpha != 0 && alpha != 255) {
      SkColor unmultiplied = SkUnPreMultiply::PMColorToColor(pixel_in);
      pixel_out[0] = SkColorGetR(unmultiplied);
      pixel_out[1] = SkColorGetG(unmultiplied);
      pixel_out[2] = SkColorGetB(unmultiplied);
    } else {
      pixel_out[0] = SkGetPackedR32(pixel_in);
      pixel_out[1] = SkGetPackedG32(pixel_in);
      pixel_out[2] = SkGetPackedB32(pixel_in);
    }
  }
}

void ConvertSkiaToRGBA(const unsigned char* skia, int pixel_width,
                       unsigned char* rgba, bool* is_opaque) {
  gfx::ConvertSkiaToRGBA(skia, pixel_width, rgba);
}

}  // namespace

// Decoder --------------------------------------------------------------------
//
// This code is based on WebKit libpng interface (PNGImageDecoder), which is
// in turn based on the Mozilla png decoder.

namespace {

// Gamma constants: We assume we're on Windows which uses a gamma of 2.2.
const double kMaxGamma = 21474.83;  // Maximum gamma accepted by png library.
const double kDefaultGamma = 2.2;
const double kInverseGamma = 1.0 / kDefaultGamma;

class PngDecoderState {
 public:
  // Output is a vector<unsigned char>.
  PngDecoderState(PNGCodec::ColorFormat ofmt, std::vector<unsigned char>* o)
      : output_format(ofmt),
        output_channels(0),
        bitmap(NULL),
        is_opaque(true),
        output(o),
        width(0),
        height(0),
        done(false) {
  }

  // Output is an SkBitmap.
  explicit PngDecoderState(SkBitmap* skbitmap)
      : output_format(PNGCodec::FORMAT_SkBitmap),
        output_channels(0),
        bitmap(skbitmap),
        is_opaque(true),
        output(NULL),
        width(0),
        height(0),
        done(false) {
  }

  PNGCodec::ColorFormat output_format;
  int output_channels;

  // An incoming SkBitmap to write to. If NULL, we write to output instead.
  SkBitmap* bitmap;

  // Used during the reading of an SkBitmap. Defaults to true until we see a
  // pixel with anything other than an alpha of 255.
  bool is_opaque;

  // The other way to decode output, where we write into an intermediary buffer
  // instead of directly to an SkBitmap.
  std::vector<unsigned char>* output;

  // Size of the image, set in the info callback.
  int width;
  int height;

  // Set to true when we've found the end of the data.
  bool done;

 private:
  DISALLOW_COPY_AND_ASSIGN(PngDecoderState);
};

// User transform (passed to libpng) which converts a row decoded by libpng to
// Skia format. Expects the row to have 4 channels, otherwise there won't be
// enough room in |data|.
void ConvertRGBARowToSkia(png_structp png_ptr,
                          png_row_infop row_info,
                          png_bytep data) {
  const int channels = row_info->channels;
  DCHECK_EQ(channels, 4);

  PngDecoderState* state =
      static_cast<PngDecoderState*>(png_get_user_transform_ptr(png_ptr));
  DCHECK(state) << "LibPNG user transform pointer is NULL";

  unsigned char* const end = data + row_info->rowbytes;
  for (unsigned char* p = data; p < end; p += channels) {
    uint32_t* sk_pixel = reinterpret_cast<uint32_t*>(p);
    const unsigned char alpha = p[channels - 1];
    if (alpha != 255) {
      state->is_opaque = false;
      *sk_pixel = SkPreMultiplyARGB(alpha, p[0], p[1], p[2]);
    } else {
      *sk_pixel = SkPackARGB32(alpha, p[0], p[1], p[2]);
    }
  }
}

// Called when the png header has been read. This code is based on the WebKit
// PNGImageDecoder
void DecodeInfoCallback(png_struct* png_ptr, png_info* info_ptr) {
  PngDecoderState* state = static_cast<PngDecoderState*>(
      png_get_progressive_ptr(png_ptr));

  int bit_depth, color_type, interlace_type, compression_type;
  int filter_type;
  png_uint_32 w, h;
  png_get_IHDR(png_ptr, info_ptr, &w, &h, &bit_depth, &color_type,
               &interlace_type, &compression_type, &filter_type);

  // Bounds check. When the image is unreasonably big, we'll error out and
  // end up back at the setjmp call when we set up decoding.  "Unreasonably big"
  // means "big enough that w * h * 32bpp might overflow an int"; we choose this
  // threshold to match WebKit and because a number of places in code assume
  // that an image's size (in bytes) fits in a (signed) int.
  unsigned long long total_size =
      static_cast<unsigned long long>(w) * static_cast<unsigned long long>(h);
  if (total_size > ((1 << 29) - 1))
    longjmp(png_jmpbuf(png_ptr), 1);
  state->width = static_cast<int>(w);
  state->height = static_cast<int>(h);

  // The following png_set_* calls have to be done in the order dictated by
  // the libpng docs. Please take care if you have to move any of them. This
  // is also why certain things are done outside of the switch, even though
  // they look like they belong there.

  // Expand to ensure we use 24-bit for RGB and 32-bit for RGBA.
  if (color_type == PNG_COLOR_TYPE_PALETTE ||
      (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8))
    png_set_expand(png_ptr);

  // The '!= 0' is for silencing a Windows compiler warning.
  bool input_has_alpha = ((color_type & PNG_COLOR_MASK_ALPHA) != 0);

  // Transparency for paletted images.
  if (png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS)) {
    png_set_expand(png_ptr);
    input_has_alpha = true;
  }

  // Convert 16-bit to 8-bit.
  if (bit_depth == 16)
    png_set_strip_16(png_ptr);

  // Pick our row format converter necessary for this data.
  if (!input_has_alpha) {
    switch (state->output_format) {
      case PNGCodec::FORMAT_RGB:
        state->output_channels = 3;
        break;
      case PNGCodec::FORMAT_RGBA:
        state->output_channels = 4;
        png_set_add_alpha(png_ptr, 0xFF, PNG_FILLER_AFTER);
        break;
      case PNGCodec::FORMAT_BGRA:
        state->output_channels = 4;
        png_set_bgr(png_ptr);
        png_set_add_alpha(png_ptr, 0xFF, PNG_FILLER_AFTER);
        break;
      case PNGCodec::FORMAT_SkBitmap:
        state->output_channels = 4;
        png_set_add_alpha(png_ptr, 0xFF, PNG_FILLER_AFTER);
        break;
    }
  } else {
    switch (state->output_format) {
      case PNGCodec::FORMAT_RGB:
        state->output_channels = 3;
        png_set_strip_alpha(png_ptr);
        break;
      case PNGCodec::FORMAT_RGBA:
        state->output_channels = 4;
        break;
      case PNGCodec::FORMAT_BGRA:
        state->output_channels = 4;
        png_set_bgr(png_ptr);
        break;
      case PNGCodec::FORMAT_SkBitmap:
        state->output_channels = 4;
        break;
    }
  }

  // Expand grayscale to RGB.
  if (color_type == PNG_COLOR_TYPE_GRAY ||
      color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
    png_set_gray_to_rgb(png_ptr);

  // Deal with gamma and keep it under our control.
  double gamma;
  if (png_get_gAMA(png_ptr, info_ptr, &gamma)) {
    if (gamma <= 0.0 || gamma > kMaxGamma) {
      gamma = kInverseGamma;
      png_set_gAMA(png_ptr, info_ptr, gamma);
    }
    png_set_gamma(png_ptr, kDefaultGamma, gamma);
  } else {
    png_set_gamma(png_ptr, kDefaultGamma, kInverseGamma);
  }

  // Setting the user transforms here (as opposed to inside the switch above)
  // because all png_set_* calls need to be done in the specific order
  // mandated by libpng.
  if (state->output_format == PNGCodec::FORMAT_SkBitmap) {
    png_set_read_user_transform_fn(png_ptr, ConvertRGBARowToSkia);
    png_set_user_transform_info(png_ptr, state, 0, 0);
  }

  // Tell libpng to send us rows for interlaced pngs.
  if (interlace_type == PNG_INTERLACE_ADAM7)
    png_set_interlace_handling(png_ptr);

  png_read_update_info(png_ptr, info_ptr);

  if (state->bitmap) {
    state->bitmap->allocN32Pixels(state->width, state->height);
  } else if (state->output) {
    state->output->resize(
        state->width * state->output_channels * state->height);
  }
}

void DecodeRowCallback(png_struct* png_ptr, png_byte* new_row,
                       png_uint_32 row_num, int pass) {
  if (!new_row)
    return;  // Interlaced image; row didn't change this pass.

  PngDecoderState* state = static_cast<PngDecoderState*>(
      png_get_progressive_ptr(png_ptr));

  if (static_cast<int>(row_num) > state->height) {
    NOTREACHED() << "Invalid row";
    return;
  }

  unsigned char* base = NULL;
  if (state->bitmap)
    base = reinterpret_cast<unsigned char*>(state->bitmap->getAddr32(0, 0));
  else if (state->output)
    base = &state->output->front();

  unsigned char* dest = &base[state->width * state->output_channels * row_num];
  png_progressive_combine_row(png_ptr, dest, new_row);
}

void DecodeEndCallback(png_struct* png_ptr, png_info* info) {
  PngDecoderState* state = static_cast<PngDecoderState*>(
      png_get_progressive_ptr(png_ptr));

  // Mark the image as complete, this will tell the Decode function that we
  // have successfully found the end of the data.
  state->done = true;
}

// Automatically destroys the given read structs on destruction to make
// cleanup and error handling code cleaner.
class PngReadStructDestroyer {
 public:
  PngReadStructDestroyer(png_struct** ps, png_info** pi) : ps_(ps), pi_(pi) {
  }
  ~PngReadStructDestroyer() {
    png_destroy_read_struct(ps_, pi_, NULL);
  }
 private:
  png_struct** ps_;
  png_info** pi_;
  DISALLOW_COPY_AND_ASSIGN(PngReadStructDestroyer);
};

// Automatically destroys the given write structs on destruction to make
// cleanup and error handling code cleaner.
class PngWriteStructDestroyer {
 public:
  explicit PngWriteStructDestroyer(png_struct** ps) : ps_(ps), pi_(0) {
  }
  ~PngWriteStructDestroyer() {
    png_destroy_write_struct(ps_, pi_);
  }
  void SetInfoStruct(png_info** pi) {
    pi_ = pi;
  }
 private:
  png_struct** ps_;
  png_info** pi_;
  DISALLOW_COPY_AND_ASSIGN(PngWriteStructDestroyer);
};

bool BuildPNGStruct(const unsigned char* input, size_t input_size,
                    png_struct** png_ptr, png_info** info_ptr) {
  if (input_size < 8)
    return false;  // Input data too small to be a png

  // Have libpng check the signature, it likes the first 8 bytes.
  if (png_sig_cmp(const_cast<unsigned char*>(input), 0, 8) != 0)
    return false;

  *png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  if (!*png_ptr)
    return false;

  *info_ptr = png_create_info_struct(*png_ptr);
  if (!*info_ptr) {
    png_destroy_read_struct(png_ptr, NULL, NULL);
    return false;
  }

  return true;
}

// Libpng user error and warning functions which allows us to print libpng
// errors and warnings using Chrome's logging facilities instead of stderr.

void LogLibPNGDecodeError(png_structp png_ptr, png_const_charp error_msg) {
  DLOG(ERROR) << "libpng decode error: " << error_msg;
  longjmp(png_jmpbuf(png_ptr), 1);
}

void LogLibPNGDecodeWarning(png_structp png_ptr, png_const_charp warning_msg) {
  DLOG(ERROR) << "libpng decode warning: " << warning_msg;
}

void LogLibPNGEncodeError(png_structp png_ptr, png_const_charp error_msg) {
  DLOG(ERROR) << "libpng encode error: " << error_msg;
  longjmp(png_jmpbuf(png_ptr), 1);
}

void LogLibPNGEncodeWarning(png_structp png_ptr, png_const_charp warning_msg) {
  DLOG(ERROR) << "libpng encode warning: " << warning_msg;
}

}  // namespace

// static
bool PNGCodec::Decode(const unsigned char* input, size_t input_size,
                      ColorFormat format, std::vector<unsigned char>* output,
                      int* w, int* h) {
  png_struct* png_ptr = NULL;
  png_info* info_ptr = NULL;
  if (!BuildPNGStruct(input, input_size, &png_ptr, &info_ptr))
    return false;

  PngReadStructDestroyer destroyer(&png_ptr, &info_ptr);
  if (setjmp(png_jmpbuf(png_ptr))) {
    // The destroyer will ensure that the structures are cleaned up in this
    // case, even though we may get here as a jump from random parts of the
    // PNG library called below.
    return false;
  }

  PngDecoderState state(format, output);

  png_set_error_fn(png_ptr, NULL, LogLibPNGDecodeError, LogLibPNGDecodeWarning);
  png_set_progressive_read_fn(png_ptr, &state, &DecodeInfoCallback,
                              &DecodeRowCallback, &DecodeEndCallback);
  png_process_data(png_ptr,
                   info_ptr,
                   const_cast<unsigned char*>(input),
                   input_size);

  if (!state.done) {
    // Fed it all the data but the library didn't think we got all the data, so
    // this file must be truncated.
    output->clear();
    return false;
  }

  *w = state.width;
  *h = state.height;
  return true;
}

// static
bool PNGCodec::Decode(const unsigned char* input, size_t input_size,
                      SkBitmap* bitmap) {
  DCHECK(bitmap);
  png_struct* png_ptr = NULL;
  png_info* info_ptr = NULL;
  if (!BuildPNGStruct(input, input_size, &png_ptr, &info_ptr))
    return false;

  PngReadStructDestroyer destroyer(&png_ptr, &info_ptr);
  if (setjmp(png_jmpbuf(png_ptr))) {
    // The destroyer will ensure that the structures are cleaned up in this
    // case, even though we may get here as a jump from random parts of the
    // PNG library called below.
    return false;
  }

  PngDecoderState state(bitmap);

  png_set_progressive_read_fn(png_ptr, &state, &DecodeInfoCallback,
                              &DecodeRowCallback, &DecodeEndCallback);
  png_process_data(png_ptr,
                   info_ptr,
                   const_cast<unsigned char*>(input),
                   input_size);

  if (!state.done) {
    return false;
  }

  // Set the bitmap's opaqueness based on what we saw.
  bitmap->setAlphaType(state.is_opaque ?
                       kOpaque_SkAlphaType : kPremul_SkAlphaType);

  return true;
}

// Encoder --------------------------------------------------------------------
//
// This section of the code is based on nsPNGEncoder.cpp in Mozilla
// (Copyright 2005 Google Inc.)

namespace {

// Passed around as the io_ptr in the png structs so our callbacks know where
// to write data.
struct PngEncoderState {
  explicit PngEncoderState(std::vector<unsigned char>* o) : out(o) {}
  std::vector<unsigned char>* out;
};

// Called by libpng to flush its internal buffer to ours.
void EncoderWriteCallback(png_structp png, png_bytep data, png_size_t size) {
  PngEncoderState* state = static_cast<PngEncoderState*>(png_get_io_ptr(png));
  DCHECK(state->out);

  size_t old_size = state->out->size();
  state->out->resize(old_size + size);
  memcpy(&(*state->out)[old_size], data, size);
}

void FakeFlushCallback(png_structp png) {
  // We don't need to perform any flushing since we aren't doing real IO, but
  // we're required to provide this function by libpng.
}

void ConvertBGRAtoRGB(const unsigned char* bgra, int pixel_width,
                      unsigned char* rgb, bool* is_opaque) {
  for (int x = 0; x < pixel_width; x++) {
    const unsigned char* pixel_in = &bgra[x * 4];
    unsigned char* pixel_out = &rgb[x * 3];
    pixel_out[0] = pixel_in[2];
    pixel_out[1] = pixel_in[1];
    pixel_out[2] = pixel_in[0];
  }
}

#ifdef PNG_TEXT_SUPPORTED
class CommentWriter {
 public:
  explicit CommentWriter(const std::vector<PNGCodec::Comment>& comments)
      : comments_(comments),
        png_text_(new png_text[comments.size()]) {
    for (size_t i = 0; i < comments.size(); ++i)
      AddComment(i, comments[i]);
  }

  ~CommentWriter() {
    for (size_t i = 0; i < comments_.size(); ++i) {
      free(png_text_[i].key);
      free(png_text_[i].text);
    }
    delete [] png_text_;
  }

  bool HasComments() {
    return !comments_.empty();
  }

  png_text* get_png_text() {
    return png_text_;
  }

  int size() {
    return static_cast<int>(comments_.size());
  }

 private:
  void AddComment(size_t pos, const PNGCodec::Comment& comment) {
    png_text_[pos].compression = PNG_TEXT_COMPRESSION_NONE;
    // A PNG comment's key can only be 79 characters long.
    DCHECK(comment.key.length() < 79);
    png_text_[pos].key = base::strdup(comment.key.substr(0, 78).c_str());
    png_text_[pos].text = base::strdup(comment.text.c_str());
    png_text_[pos].text_length = comment.text.length();
#ifdef PNG_iTXt_SUPPORTED
    png_text_[pos].itxt_length = 0;
    png_text_[pos].lang = 0;
    png_text_[pos].lang_key = 0;
#endif
  }

  DISALLOW_COPY_AND_ASSIGN(CommentWriter);

  const std::vector<PNGCodec::Comment> comments_;
  png_text* png_text_;
};
#endif  // PNG_TEXT_SUPPORTED

// The type of functions usable for converting between pixel formats.
typedef void (*FormatConverter)(const unsigned char* in, int w,
                                unsigned char* out, bool* is_opaque);

// libpng uses a wacky setjmp-based API, which makes the compiler nervous.
// We constrain all of the calls we make to libpng where the setjmp() is in
// place to this function.
// Returns true on success.
bool DoLibpngWrite(png_struct* png_ptr, png_info* info_ptr,
                   PngEncoderState* state,
                   int width, int height, int row_byte_width,
                   const unsigned char* input, int compression_level,
                   int png_output_color_type, int output_color_components,
                   FormatConverter converter,
                   const std::vector<PNGCodec::Comment>& comments) {
#ifdef PNG_TEXT_SUPPORTED
  CommentWriter comment_writer(comments);
#endif
  unsigned char* row_buffer = NULL;

  // Make sure to not declare any locals here -- locals in the presence
  // of setjmp() in C++ code makes gcc complain.

  if (setjmp(png_jmpbuf(png_ptr))) {
    delete[] row_buffer;
    return false;
  }

  png_set_compression_level(png_ptr, compression_level);

  // Set our callback for libpng to give us the data.
  png_set_write_fn(png_ptr, state, EncoderWriteCallback, FakeFlushCallback);
  png_set_error_fn(png_ptr, NULL, LogLibPNGEncodeError, LogLibPNGEncodeWarning);

  png_set_IHDR(png_ptr, info_ptr, width, height, 8, png_output_color_type,
               PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT,
               PNG_FILTER_TYPE_DEFAULT);

#ifdef PNG_TEXT_SUPPORTED
  if (comment_writer.HasComments()) {
    png_set_text(png_ptr, info_ptr, comment_writer.get_png_text(),
                 comment_writer.size());
  }
#endif

  png_write_info(png_ptr, info_ptr);

  if (!converter) {
    // No conversion needed, give the data directly to libpng.
    for (int y = 0; y < height; y ++) {
      png_write_row(png_ptr,
                    const_cast<unsigned char*>(&input[y * row_byte_width]));
    }
  } else {
    // Needs conversion using a separate buffer.
    row_buffer = new unsigned char[width * output_color_components];
    for (int y = 0; y < height; y ++) {
      converter(&input[y * row_byte_width], width, row_buffer, NULL);
      png_write_row(png_ptr, row_buffer);
    }
    delete[] row_buffer;
  }

  png_write_end(png_ptr, info_ptr);
  return true;
}

bool EncodeWithCompressionLevel(const unsigned char* input,
                                PNGCodec::ColorFormat format,
                                const Size& size,
                                int row_byte_width,
                                bool discard_transparency,
                                const std::vector<PNGCodec::Comment>& comments,
                                int compression_level,
                                std::vector<unsigned char>* output) {
  // Run to convert an input row into the output row format, NULL means no
  // conversion is necessary.
  FormatConverter converter = NULL;

  int input_color_components, output_color_components;
  int png_output_color_type;
  switch (format) {
    case PNGCodec::FORMAT_RGB:
      input_color_components = 3;
      output_color_components = 3;
      png_output_color_type = PNG_COLOR_TYPE_RGB;
      break;

    case PNGCodec::FORMAT_RGBA:
      input_color_components = 4;
      if (discard_transparency) {
        output_color_components = 3;
        png_output_color_type = PNG_COLOR_TYPE_RGB;
        converter = ConvertRGBAtoRGB;
      } else {
        output_color_components = 4;
        png_output_color_type = PNG_COLOR_TYPE_RGB_ALPHA;
        converter = NULL;
      }
      break;

    case PNGCodec::FORMAT_BGRA:
      input_color_components = 4;
      if (discard_transparency) {
        output_color_components = 3;
        png_output_color_type = PNG_COLOR_TYPE_RGB;
        converter = ConvertBGRAtoRGB;
      } else {
        output_color_components = 4;
        png_output_color_type = PNG_COLOR_TYPE_RGB_ALPHA;
        converter = ConvertBetweenBGRAandRGBA;
      }
      break;

    case PNGCodec::FORMAT_SkBitmap:
      // Compare row_byte_width and size.width() to detect the format of
      // SkBitmap. kA8_Config (1bpp) and kARGB_8888_Config (4bpp) are the two
      // supported formats.
      if (row_byte_width < 4 * size.width()) {
        // Not 4bpp, so must be 1bpp.
        // Ignore discard_transparency - it doesn't make sense in this context,
        // since alpha is the only thing we have and it needs to be used for
        // color intensity.
        input_color_components = 1;
        output_color_components = 1;
        png_output_color_type = PNG_COLOR_TYPE_GRAY;
        // |converter| is left as null
      } else {
        input_color_components = 4;
        if (discard_transparency) {
          output_color_components = 3;
          png_output_color_type = PNG_COLOR_TYPE_RGB;
          converter = ConvertSkiaToRGB;
        } else {
          output_color_components = 4;
          png_output_color_type = PNG_COLOR_TYPE_RGB_ALPHA;
          converter = ConvertSkiaToRGBA;
        }
      }
      break;

    default:
      NOTREACHED() << "Unknown pixel format";
      return false;
  }

  // Row stride should be at least as long as the length of the data.
  DCHECK(input_color_components * size.width() <= row_byte_width);

  png_struct* png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING,
                                                NULL, NULL, NULL);
  if (!png_ptr)
    return false;
  PngWriteStructDestroyer destroyer(&png_ptr);
  png_info* info_ptr = png_create_info_struct(png_ptr);
  if (!info_ptr)
    return false;
  destroyer.SetInfoStruct(&info_ptr);

  output->clear();

  PngEncoderState state(output);
  bool success = DoLibpngWrite(png_ptr, info_ptr, &state,
                               size.width(), size.height(), row_byte_width,
                               input, compression_level, png_output_color_type,
                               output_color_components, converter, comments);

  return success;
}

bool InternalEncodeSkBitmap(const SkBitmap& input,
                            bool discard_transparency,
                            int compression_level,
                            std::vector<unsigned char>* output) {
  if (input.empty() || input.isNull())
    return false;
  int bpp = input.bytesPerPixel();
  DCHECK(bpp == 1 || bpp == 4);  // We support kA8_Config and kARGB_8888_Config.

  SkAutoLockPixels lock_input(input);
  unsigned char* inputAddr = bpp == 1 ?
      reinterpret_cast<unsigned char*>(input.getAddr8(0, 0)) :
      reinterpret_cast<unsigned char*>(input.getAddr32(0, 0));    // bpp = 4
  return EncodeWithCompressionLevel(
      inputAddr,
      PNGCodec::FORMAT_SkBitmap,
      Size(input.width(), input.height()),
      static_cast<int>(input.rowBytes()),
      discard_transparency,
      std::vector<PNGCodec::Comment>(),
      compression_level,
      output);
}


}  // namespace

// static
bool PNGCodec::Encode(const unsigned char* input,
                      ColorFormat format,
                      const Size& size,
                      int row_byte_width,
                      bool discard_transparency,
                      const std::vector<Comment>& comments,
                      std::vector<unsigned char>* output) {
  return EncodeWithCompressionLevel(input,
                                    format,
                                    size,
                                    row_byte_width,
                                    discard_transparency,
                                    comments,
                                    Z_DEFAULT_COMPRESSION,
                                    output);
}

// static
bool PNGCodec::EncodeBGRASkBitmap(const SkBitmap& input,
                                  bool discard_transparency,
                                  std::vector<unsigned char>* output) {
  return InternalEncodeSkBitmap(input,
                                discard_transparency,
                                Z_DEFAULT_COMPRESSION,
                                output);
}

// static
bool PNGCodec::EncodeA8SkBitmap(const SkBitmap& input,
                                std::vector<unsigned char>* output) {
  return InternalEncodeSkBitmap(input,
                                false,
                                Z_DEFAULT_COMPRESSION,
                                output);
}

// static
bool PNGCodec::FastEncodeBGRASkBitmap(const SkBitmap& input,
                                      bool discard_transparency,
                                      std::vector<unsigned char>* output) {
  return InternalEncodeSkBitmap(input,
                                discard_transparency,
                                Z_BEST_SPEED,
                                output);
}

PNGCodec::Comment::Comment(const std::string& k, const std::string& t)
    : key(k), text(t) {
}

PNGCodec::Comment::~Comment() {
}

}  // namespace gfx
