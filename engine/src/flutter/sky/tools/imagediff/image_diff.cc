// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file input format is based loosely on
// Tools/DumpRenderTree/ImageDiff.m

// The exact format of this tool's output to stdout is important, to match
// what the run-webkit-tests script expects.

#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

#include "base/basictypes.h"
#include "base/command_line.h"
#include "base/containers/hash_tables.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/numerics/safe_conversions.h"
#include "base/process/memory.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"
#include "sky/tools/imagediff/image_diff_png.h"

#if defined(OS_WIN)
#include "windows.h"
#endif

// Causes the app to remain open, waiting for pairs of filenames on stdin.
// The caller is then responsible for terminating this app.
static const char kOptionPollStdin[] = "use-stdin";
// Causes the app to additionally calculate a diff of the color histograms
// (which is resistant to shifts in layout).
static const char kOptionCompareHistograms[] = "histogram";
// Causes the app to output an image that visualizes the difference.
static const char kOptionGenerateDiff[] = "diff";

// Return codes used by this utility.
static const int kStatusSame = 0;
static const int kStatusDifferent = 1;
static const int kStatusError = 2;

// Color codes.
static const uint32 RGBA_RED = 0x000000ff;
static const uint32 RGBA_ALPHA = 0xff000000;

class Image {
 public:
  Image() : w_(0), h_(0) {
  }

  Image(const Image& image)
      : w_(image.w_),
        h_(image.h_),
        data_(image.data_) {
  }

  bool has_image() const {
    return w_ > 0 && h_ > 0;
  }

  int w() const {
    return w_;
  }

  int h() const {
    return h_;
  }

  const unsigned char* data() const {
    return &data_.front();
  }

  // Creates the image from stdin with the given data length. On success, it
  // will return true. On failure, no other methods should be accessed.
  bool CreateFromStdin(size_t byte_length) {
    if (byte_length == 0)
      return false;

    scoped_ptr<unsigned char[]> source(new unsigned char[byte_length]);
    if (fread(source.get(), 1, byte_length, stdin) != byte_length)
      return false;

    if (!image_diff_png::DecodePNG(source.get(), byte_length,
                                   &data_, &w_, &h_)) {
      Clear();
      return false;
    }
    return true;
  }

  // Creates the image from the given filename on disk, and returns true on
  // success.
  bool CreateFromFilename(const base::FilePath& path) {
    FILE* f = base::OpenFile(path, "rb");
    if (!f)
      return false;

    std::vector<unsigned char> compressed;
    const int buf_size = 1024;
    unsigned char buf[buf_size];
    size_t num_read = 0;
    while ((num_read = fread(buf, 1, buf_size, f)) > 0) {
      compressed.insert(compressed.end(), buf, buf + num_read);
    }

    base::CloseFile(f);

    if (!image_diff_png::DecodePNG(&compressed[0], compressed.size(),
                                   &data_, &w_, &h_)) {
      Clear();
      return false;
    }
    return true;
  }

  void Clear() {
    w_ = h_ = 0;
    data_.clear();
  }

  // Returns the RGBA value of the pixel at the given location
  uint32 pixel_at(int x, int y) const {
    DCHECK(x >= 0 && x < w_);
    DCHECK(y >= 0 && y < h_);
    return *reinterpret_cast<const uint32*>(&(data_[(y * w_ + x) * 4]));
  }

  void set_pixel_at(int x, int y, uint32 color) const {
    DCHECK(x >= 0 && x < w_);
    DCHECK(y >= 0 && y < h_);
    void* addr = &const_cast<unsigned char*>(&data_.front())[(y * w_ + x) * 4];
    *reinterpret_cast<uint32*>(addr) = color;
  }

 private:
  // pixel dimensions of the image
  int w_, h_;

  std::vector<unsigned char> data_;
};

float PercentageDifferent(const Image& baseline, const Image& actual) {
  int w = std::min(baseline.w(), actual.w());
  int h = std::min(baseline.h(), actual.h());

  // Compute pixels different in the overlap.
  int pixels_different = 0;
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      if (baseline.pixel_at(x, y) != actual.pixel_at(x, y))
        pixels_different++;
    }
  }

  // Count pixels that are a difference in size as also being different.
  int max_w = std::max(baseline.w(), actual.w());
  int max_h = std::max(baseline.h(), actual.h());
  // These pixels are off the right side, not including the lower right corner.
  pixels_different += (max_w - w) * h;
  // These pixels are along the bottom, including the lower right corner.
  pixels_different += (max_h - h) * max_w;

  // Like the WebKit ImageDiff tool, we define percentage different in terms
  // of the size of the 'actual' bitmap.
  float total_pixels = static_cast<float>(actual.w()) *
                       static_cast<float>(actual.h());
  if (total_pixels == 0) {
    // When the bitmap is empty, they are 100% different.
    return 100.0f;
  }
  return 100.0f * pixels_different / total_pixels;
}

typedef base::hash_map<uint32, int32> RgbaToCountMap;

float HistogramPercentageDifferent(const Image& baseline, const Image& actual) {
  // TODO(johnme): Consider using a joint histogram instead, as described in
  // "Comparing Images Using Joint Histograms" by Pass & Zabih
  // http://www.cs.cornell.edu/~rdz/papers/pz-jms99.pdf

  int w = std::min(baseline.w(), actual.w());
  int h = std::min(baseline.h(), actual.h());

  // Count occurences of each RGBA pixel value of baseline in the overlap.
  RgbaToCountMap baseline_histogram;
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      // hash_map operator[] inserts a 0 (default constructor) if key not found.
      baseline_histogram[baseline.pixel_at(x, y)]++;
    }
  }

  // Compute pixels different in the histogram of the overlap.
  int pixels_different = 0;
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      uint32 actual_rgba = actual.pixel_at(x, y);
      RgbaToCountMap::iterator it = baseline_histogram.find(actual_rgba);
      if (it != baseline_histogram.end() && it->second > 0)
        it->second--;
      else
        pixels_different++;
    }
  }

  // Count pixels that are a difference in size as also being different.
  int max_w = std::max(baseline.w(), actual.w());
  int max_h = std::max(baseline.h(), actual.h());
  // These pixels are off the right side, not including the lower right corner.
  pixels_different += (max_w - w) * h;
  // These pixels are along the bottom, including the lower right corner.
  pixels_different += (max_h - h) * max_w;

  // Like the WebKit ImageDiff tool, we define percentage different in terms
  // of the size of the 'actual' bitmap.
  float total_pixels = static_cast<float>(actual.w()) *
                       static_cast<float>(actual.h());
  if (total_pixels == 0) {
    // When the bitmap is empty, they are 100% different.
    return 100.0f;
  }
  return 100.0f * pixels_different / total_pixels;
}

void PrintHelp() {
  fprintf(stderr,
    "Usage:\n"
    "  image_diff [--histogram] <compare file> <reference file>\n"
    "    Compares two files on disk, returning 0 when they are the same;\n"
    "    passing \"--histogram\" additionally calculates a diff of the\n"
    "    RGBA value histograms (which is resistant to shifts in layout)\n"
    "  image_diff --use-stdin\n"
    "    Stays open reading pairs of filenames from stdin, comparing them,\n"
    "    and sending 0 to stdout when they are the same\n"
    "  image_diff --diff <compare file> <reference file> <output file>\n"
    "    Compares two files on disk, outputs an image that visualizes the\n"
    "    difference to <output file>\n");
  /* For unfinished webkit-like-mode (see below)
    "\n"
    "  image_diff -s\n"
    "    Reads stream input from stdin, should be EXACTLY of the format\n"
    "    \"Content-length: <byte length> <data>Content-length: ...\n"
    "    it will take as many file pairs as given, and will compare them as\n"
    "    (cmp_file, reference_file) pairs\n");
  */
}

int CompareImages(const base::FilePath& file1,
                  const base::FilePath& file2,
                  bool compare_histograms) {
  Image actual_image;
  Image baseline_image;

  if (!actual_image.CreateFromFilename(file1)) {
    fprintf(stderr, "image_diff: Unable to open file \"%" PRFilePath "\"\n",
            file1.value().c_str());
    return kStatusError;
  }
  if (!baseline_image.CreateFromFilename(file2)) {
    fprintf(stderr, "image_diff: Unable to open file \"%" PRFilePath "\"\n",
            file2.value().c_str());
    return kStatusError;
  }

  if (compare_histograms) {
    float percent = HistogramPercentageDifferent(actual_image, baseline_image);
    const char* passed = percent > 0.0 ? "failed" : "passed";
    printf("histogram diff: %01.2f%% %s\n", percent, passed);
  }

  const char* diff_name = compare_histograms ? "exact diff" : "diff";
  float percent = PercentageDifferent(actual_image, baseline_image);
  const char* passed = percent > 0.0 ? "failed" : "passed";
  printf("%s: %01.2f%% %s\n", diff_name, percent, passed);
  if (percent > 0.0) {
    // failure: The WebKit version also writes the difference image to
    // stdout, which seems excessive for our needs.
    return kStatusDifferent;
  }
  // success
  return kStatusSame;

/* Untested mode that acts like WebKit's image comparator. I wrote this but
   decided it's too complicated. We may use it in the future if it looks useful

  char buffer[2048];
  while (fgets(buffer, sizeof(buffer), stdin)) {

    if (strncmp("Content-length: ", buffer, 16) == 0) {
      char* context;
      strtok_s(buffer, " ", &context);
      int image_size = strtol(strtok_s(NULL, " ", &context), NULL, 10);

      bool success = false;
      if (image_size > 0 && actual_image.has_image() == 0) {
        if (!actual_image.CreateFromStdin(image_size)) {
          fputs("Error, input image can't be decoded.\n", stderr);
          return 1;
        }
      } else if (image_size > 0 && baseline_image.has_image() == 0) {
        if (!baseline_image.CreateFromStdin(image_size)) {
          fputs("Error, baseline image can't be decoded.\n", stderr);
          return 1;
        }
      } else {
        fputs("Error, image size must be specified.\n", stderr);
        return 1;
      }
    }

    if (actual_image.has_image() && baseline_image.has_image()) {
      float percent = PercentageDifferent(actual_image, baseline_image);
      if (percent > 0.0) {
        // failure: The WebKit version also writes the difference image to
        // stdout, which seems excessive for our needs.
        printf("diff: %01.2f%% failed\n", percent);
      } else {
        // success
        printf("diff: %01.2f%% passed\n", percent);
      }
      actual_image.Clear();
      baseline_image.Clear();
    }

    fflush(stdout);
  }
*/
}

bool CreateImageDiff(const Image& image1, const Image& image2, Image* out) {
  int w = std::min(image1.w(), image2.w());
  int h = std::min(image1.h(), image2.h());
  *out = Image(image1);
  bool same = (image1.w() == image2.w()) && (image1.h() == image2.h());

  // TODO(estade): do something with the extra pixels if the image sizes
  // are different.
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      uint32 base_pixel = image1.pixel_at(x, y);
      if (base_pixel != image2.pixel_at(x, y)) {
        // Set differing pixels red.
        out->set_pixel_at(x, y, RGBA_RED | RGBA_ALPHA);
        same = false;
      } else {
        // Set same pixels as faded.
        uint32 alpha = base_pixel & RGBA_ALPHA;
        uint32 new_pixel = base_pixel - ((alpha / 2) & RGBA_ALPHA);
        out->set_pixel_at(x, y, new_pixel);
      }
    }
  }

  return same;
}

int DiffImages(const base::FilePath& file1, const base::FilePath& file2,
               const base::FilePath& out_file) {
  Image actual_image;
  Image baseline_image;

  if (!actual_image.CreateFromFilename(file1)) {
    fprintf(stderr, "image_diff: Unable to open file \"%" PRFilePath "\"\n",
            file1.value().c_str());
    return kStatusError;
  }
  if (!baseline_image.CreateFromFilename(file2)) {
    fprintf(stderr, "image_diff: Unable to open file \"%" PRFilePath "\"\n",
            file2.value().c_str());
    return kStatusError;
  }

  Image diff_image;
  bool same = CreateImageDiff(baseline_image, actual_image, &diff_image);
  if (same)
    return kStatusSame;

  std::vector<unsigned char> png_encoding;
  image_diff_png::EncodeRGBAPNG(
      diff_image.data(), diff_image.w(), diff_image.h(),
      diff_image.w() * 4, &png_encoding);
  if (base::WriteFile(out_file,
          reinterpret_cast<char*>(&png_encoding.front()),
          base::checked_cast<int>(png_encoding.size())) < 0)
    return kStatusError;

  return kStatusDifferent;
}

// It isn't strictly correct to only support ASCII paths, but this
// program reads paths on stdin and the program that spawns it outputs
// paths as non-wide strings anyway.
base::FilePath FilePathFromASCII(const std::string& str) {
#if defined(OS_WIN)
  return base::FilePath(base::ASCIIToUTF16(str));
#else
  return base::FilePath(str);
#endif
}

int main(int argc, const char* argv[]) {
  base::EnableTerminationOnHeapCorruption();
  base::CommandLine::Init(argc, argv);
  const base::CommandLine& parsed_command_line =
      *base::CommandLine::ForCurrentProcess();
  bool histograms = parsed_command_line.HasSwitch(kOptionCompareHistograms);
  if (parsed_command_line.HasSwitch(kOptionPollStdin)) {
    // Watch stdin for filenames.
    std::string stdin_buffer;
    base::FilePath filename1;
    while (std::getline(std::cin, stdin_buffer)) {
      if (stdin_buffer.empty())
        continue;

      if (!filename1.empty()) {
        // CompareImages writes results to stdout unless an error occurred.
        base::FilePath filename2 = FilePathFromASCII(stdin_buffer);
        if (CompareImages(filename1, filename2, histograms) == kStatusError)
          printf("error\n");
        fflush(stdout);
        filename1 = base::FilePath();
      } else {
        // Save the first filename in another buffer and wait for the second
        // filename to arrive via stdin.
        filename1 = FilePathFromASCII(stdin_buffer);
      }
    }
    return 0;
  }

  const base::CommandLine::StringVector& args = parsed_command_line.GetArgs();
  if (parsed_command_line.HasSwitch(kOptionGenerateDiff)) {
    if (args.size() == 3) {
      return DiffImages(base::FilePath(args[0]),
                        base::FilePath(args[1]),
                        base::FilePath(args[2]));
    }
  } else if (args.size() == 2) {
    return CompareImages(
        base::FilePath(args[0]), base::FilePath(args[1]), histograms);
  }

  PrintHelp();
  return kStatusError;
}
