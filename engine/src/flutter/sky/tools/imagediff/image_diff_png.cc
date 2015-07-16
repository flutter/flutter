// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/imagediff/image_diff_png.h"

#include <stdlib.h>
#include <string.h>

#include "base/logging.h"
#include "build/build_config.h"
#include "third_party/libpng/png.h"
#include "third_party/zlib/zlib.h"

namespace image_diff_png {

// This is a duplicate of ui/gfx/codec/png_codec.cc, after removing code related
// to Skia, that we can use when running layout tests with minimal dependencies.
namespace {

enum ColorFormat {
  // 3 bytes per pixel (packed), in RGB order regardless of endianness.
  // This is the native JPEG format.
  FORMAT_RGB,

  // 4 bytes per pixel, in RGBA order in memory regardless of endianness.
  FORMAT_RGBA,

  // 4 bytes per pixel, in BGRA order in memory regardless of endianness.
  // This is the default Windows DIB order.
  FORMAT_BGRA,

  // 4 bytes per pixel, in pre-multiplied kARGB_8888_Config format. For use
  // with directly writing to a skia bitmap.
  FORMAT_SkBitmap
};

// Represents a comment in the tEXt ancillary chunk of the png.
struct Comment {
  std::string key;
  std::string text;
};

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
  for (int x = 0; x < pixel_width; x++) {
    const unsigned char* pixel_in = &rgba[x * 4];
    unsigned char* pixel_out = &rgb[x * 3];
    pixel_out[0] = pixel_in[0];
    pixel_out[1] = pixel_in[1];
    pixel_out[2] = pixel_in[2];
  }
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
  PngDecoderState(ColorFormat ofmt, std::vector<unsigned char>* o)
      : output_format(ofmt),
        output_channels(0),
        is_opaque(true),
        output(o),
        row_converter(NULL),
        width(0),
        height(0),
        done(false) {
  }

  ColorFormat output_format;
  int output_channels;

  // Used during the reading of an SkBitmap. Defaults to true until we see a
  // pixel with anything other than an alpha of 255.
  bool is_opaque;

  // An intermediary buffer for decode output.
  std::vector<unsigned char>* output;

  // Called to convert a row from the library to the correct output format.
  // When NULL, no conversion is necessary.
  void (*row_converter)(const unsigned char* in, int w, unsigned char* out,
                        bool* is_opaque);

  // Size of the image, set in the info callback.
  int width;
  int height;

  // Set to true when we've found the end of the data.
  bool done;
};

void ConvertRGBtoRGBA(const unsigned char* rgb, int pixel_width,
                      unsigned char* rgba, bool* is_opaque) {
  for (int x = 0; x < pixel_width; x++) {
    const unsigned char* pixel_in = &rgb[x * 3];
    unsigned char* pixel_out = &rgba[x * 4];
    pixel_out[0] = pixel_in[0];
    pixel_out[1] = pixel_in[1];
    pixel_out[2] = pixel_in[2];
    pixel_out[3] = 0xff;
  }
}

void ConvertRGBtoBGRA(const unsigned char* rgb, int pixel_width,
                      unsigned char* bgra, bool* is_opaque) {
  for (int x = 0; x < pixel_width; x++) {
    const unsigned char* pixel_in = &rgb[x * 3];
    unsigned char* pixel_out = &bgra[x * 4];
    pixel_out[0] = pixel_in[2];
    pixel_out[1] = pixel_in[1];
    pixel_out[2] = pixel_in[0];
    pixel_out[3] = 0xff;
  }
}

// Called when the png header has been read. This code is based on the WebKit
// PNGImageDecoder
void DecodeInfoCallback(png_struct* png_ptr, png_info* info_ptr) {
  PngDecoderState* state = static_cast<PngDecoderState*>(
      png_get_progressive_ptr(png_ptr));

  int bit_depth, color_type, interlace_type, compression_type;
  int filter_type, channels;
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

  // Expand to ensure we use 24-bit for RGB and 32-bit for RGBA.
  if (color_type == PNG_COLOR_TYPE_PALETTE ||
      (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8))
    png_set_expand(png_ptr);

  // Transparency for paletted images.
  if (png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS))
    png_set_expand(png_ptr);

  // Convert 16-bit to 8-bit.
  if (bit_depth == 16)
    png_set_strip_16(png_ptr);

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

  // Tell libpng to send us rows for interlaced pngs.
  if (interlace_type == PNG_INTERLACE_ADAM7)
    png_set_interlace_handling(png_ptr);

  // Update our info now
  png_read_update_info(png_ptr, info_ptr);
  channels = png_get_channels(png_ptr, info_ptr);

  // Pick our row format converter necessary for this data.
  if (channels == 3) {
    switch (state->output_format) {
      case FORMAT_RGB:
        state->row_converter = NULL;  // no conversion necessary
        state->output_channels = 3;
        break;
      case FORMAT_RGBA:
        state->row_converter = &ConvertRGBtoRGBA;
        state->output_channels = 4;
        break;
      case FORMAT_BGRA:
        state->row_converter = &ConvertRGBtoBGRA;
        state->output_channels = 4;
        break;
      default:
        NOTREACHED() << "Unknown output format";
        break;
    }
  } else if (channels == 4) {
    switch (state->output_format) {
      case FORMAT_RGB:
        state->row_converter = &ConvertRGBAtoRGB;
        state->output_channels = 3;
        break;
      case FORMAT_RGBA:
        state->row_converter = NULL;  // no conversion necessary
        state->output_channels = 4;
        break;
      case FORMAT_BGRA:
        state->row_converter = &ConvertBetweenBGRAandRGBA;
        state->output_channels = 4;
        break;
      default:
        NOTREACHED() << "Unknown output format";
        break;
    }
  } else {
    NOTREACHED() << "Unknown input channels";
    longjmp(png_jmpbuf(png_ptr), 1);
  }

  state->output->resize(
      state->width * state->output_channels * state->height);
}

void DecodeRowCallback(png_struct* png_ptr, png_byte* new_row,
                       png_uint_32 row_num, int pass) {
  PngDecoderState* state = static_cast<PngDecoderState*>(
      png_get_progressive_ptr(png_ptr));

  DCHECK(pass == 0);
  if (static_cast<int>(row_num) > state->height) {
    NOTREACHED() << "Invalid row";
    return;
  }

  unsigned char* base = NULL;
  base = &state->output->front();

  unsigned char* dest = &base[state->width * state->output_channels * row_num];
  if (state->row_converter)
    state->row_converter(new_row, state->width, dest, &state->is_opaque);
  else
    memcpy(dest, new_row, state->width * state->output_channels);
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

}  // namespace

// static
bool Decode(const unsigned char* input, size_t input_size,
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

inline char* strdup(const char* str) {
#if defined(OS_WIN)
  return _strdup(str);
#else
  return ::strdup(str);
#endif
}

class CommentWriter {
 public:
  explicit CommentWriter(const std::vector<Comment>& comments)
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
  void AddComment(size_t pos, const Comment& comment) {
    png_text_[pos].compression = PNG_TEXT_COMPRESSION_NONE;
    // A PNG comment's key can only be 79 characters long.
    DCHECK(comment.key.length() < 79);
    png_text_[pos].key = strdup(comment.key.substr(0, 78).c_str());
    png_text_[pos].text = strdup(comment.text.c_str());
    png_text_[pos].text_length = comment.text.length();
#ifdef PNG_iTXt_SUPPORTED
    png_text_[pos].itxt_length = 0;
    png_text_[pos].lang = 0;
    png_text_[pos].lang_key = 0;
#endif
  }

  const std::vector<Comment> comments_;
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
                   const std::vector<Comment>& comments) {
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

}  // namespace

// static
bool EncodeWithCompressionLevel(const unsigned char* input, ColorFormat format,
                                const int width, const int height,
                                int row_byte_width,
                                bool discard_transparency,
                                const std::vector<Comment>& comments,
                                int compression_level,
                                std::vector<unsigned char>* output) {
  // Run to convert an input row into the output row format, NULL means no
  // conversion is necessary.
  FormatConverter converter = NULL;

  int input_color_components, output_color_components;
  int png_output_color_type;
  switch (format) {
    case FORMAT_RGB:
      input_color_components = 3;
      output_color_components = 3;
      png_output_color_type = PNG_COLOR_TYPE_RGB;
      discard_transparency = false;
      break;

    case FORMAT_RGBA:
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

    case FORMAT_BGRA:
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

    default:
      NOTREACHED() << "Unknown pixel format";
      return false;
  }

  // Row stride should be at least as long as the length of the data.
  DCHECK(input_color_components * width <= row_byte_width);

  png_struct* png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING,
                                                NULL, NULL, NULL);
  if (!png_ptr)
    return false;
  png_info* info_ptr = png_create_info_struct(png_ptr);
  if (!info_ptr) {
    png_destroy_write_struct(&png_ptr, NULL);
    return false;
  }

  PngEncoderState state(output);
  bool success = DoLibpngWrite(png_ptr, info_ptr, &state,
                               width, height, row_byte_width,
                               input, compression_level, png_output_color_type,
                               output_color_components, converter, comments);
  png_destroy_write_struct(&png_ptr, &info_ptr);

  return success;
}

// static
bool Encode(const unsigned char* input, ColorFormat format,
            const int width, const int height, int row_byte_width,
            bool discard_transparency,
            const std::vector<Comment>& comments,
            std::vector<unsigned char>* output) {
  return EncodeWithCompressionLevel(input, format, width, height,
                                    row_byte_width,
                                    discard_transparency,
                                    comments, Z_DEFAULT_COMPRESSION,
                                    output);
}

// Decode a PNG into an RGBA pixel array.
bool DecodePNG(const unsigned char* input, size_t input_size,
               std::vector<unsigned char>* output,
               int* width, int* height) {
  return Decode(input, input_size, FORMAT_RGBA, output, width, height);
}

// Encode an RGBA pixel array into a PNG.
bool EncodeRGBAPNG(const unsigned char* input,
                   int width,
                   int height,
                   int row_byte_width,
                   std::vector<unsigned char>* output) {
  return Encode(input, FORMAT_RGBA,
      width, height, row_byte_width, false,
      std::vector<Comment>(), output);
}

// Encode an BGRA pixel array into a PNG.
bool EncodeBGRAPNG(const unsigned char* input,
                   int width,
                   int height,
                   int row_byte_width,
                   bool discard_transparency,
                   std::vector<unsigned char>* output) {
  return Encode(input, FORMAT_BGRA,
      width, height, row_byte_width, discard_transparency,
      std::vector<Comment>(), output);
}

}  // image_diff_png
