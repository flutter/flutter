// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This small program is used to measure the performance of the various
// resize algorithms offered by the ImageOperations::Resize function.
// It will generate an empty source bitmap, and rescale it to specified
// dimensions. It will repeat this operation multiple time to get more accurate
// average throughput. Because it uses elapsed time to do its math, it is only
// accurate on an idle system (but that approach was deemed more accurate
// than the use of the times() call.
// To present a single number in MB/s, it calculates the 'speed' by taking
// source surface + destination surface and dividing by the elapsed time.
// This number is somewhat reasonable way to measure this, given our current
// implementation which somewhat scales this way.

#include <stdio.h>

#include "base/basictypes.h"
#include "base/command_line.h"
#include "base/format_macros.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"
#include "base/time/time.h"
#include "skia/ext/image_operations.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkRect.h"

namespace {

struct StringMethodPair {
  const char* name;
  skia::ImageOperations::ResizeMethod method;
};
#define ADD_METHOD(x) { #x, skia::ImageOperations::RESIZE_##x }
const StringMethodPair resize_methods[] = {
  ADD_METHOD(GOOD),
  ADD_METHOD(BETTER),
  ADD_METHOD(BEST),
  ADD_METHOD(BOX),
  ADD_METHOD(HAMMING1),
  ADD_METHOD(LANCZOS2),
  ADD_METHOD(LANCZOS3),
};

// converts a string into one of the image operation method to resize.
// Returns true on success, false otherwise.
bool StringToMethod(const std::string& arg,
                    skia::ImageOperations::ResizeMethod* method) {
  for (size_t i = 0; i < arraysize(resize_methods); ++i) {
    if (base::strcasecmp(arg.c_str(), resize_methods[i].name) == 0) {
      *method = resize_methods[i].method;
      return true;
    }
  }
  return false;
}

const char* MethodToString(skia::ImageOperations::ResizeMethod method) {
  for (size_t i = 0; i < arraysize(resize_methods); ++i) {
    if (method == resize_methods[i].method) {
      return resize_methods[i].name;
    }
  }
  return "unknown";
}

// Prints all supported resize methods
void PrintMethods() {
  bool print_comma = false;
  for (size_t i = 0; i < arraysize(resize_methods); ++i) {
    if (print_comma) {
      printf(",");
    } else {
      print_comma = true;
    }
    printf(" %s", resize_methods[i].name);
  }
}

// Returns the number of bytes that the bitmap has. This number is different
// from what SkBitmap::getSize() returns since it does not take into account
// the stride. The difference between the stride and the width can be large
// because of the alignment constraints on bitmaps created for SRB scaling
// (32 pixels) as seen on GTV platforms. Using this metric instead of the
// getSize seemed to be a more accurate representation of the work done (even
// though in terms of memory bandwidth that might be similar because of the
// cache line size).
int GetBitmapSize(const SkBitmap* bitmap) {
  return bitmap->height() * bitmap->bytesPerPixel() * bitmap->width();
}

// Simple class to represent dimensions of a bitmap (width, height).
class Dimensions {
 public:
  Dimensions()
      : width_(0),
        height_(0) {}

  void set(int w, int h) {
    width_ = w;
    height_ = h;
  }

  int width() const {
    return width_;
  }

  int height() const {
    return height_;
  }

  bool IsValid() const {
    return (width_ > 0 && height_ > 0);
  }

  // On failure, will set its state in such a way that IsValid will return
  // false.
  void FromString(const std::string& arg) {
    std::vector<std::string> strings;
    base::SplitString(std::string(arg), 'x', &strings);
    if (strings.size() != 2 ||
        base::StringToInt(strings[0], &width_) == false ||
        base::StringToInt(strings[1], &height_) == false) {
      width_ = -1;  // force the dimension object to be invalid.
    }
  }
 private:
  int width_;
  int height_;
};

// main class used for the benchmarking.
class Benchmark {
 public:
  static const int kDefaultNumberIterations;
  static const skia::ImageOperations::ResizeMethod kDefaultResizeMethod;

  Benchmark()
      : num_iterations_(kDefaultNumberIterations),
        method_(kDefaultResizeMethod) {}

  // Returns true if command line parsing was successful, false otherwise.
  bool ParseArgs(const base::CommandLine* command_line);

  // Returns true if successful, false otherwise.
  bool Run() const;

  static void Usage();
 private:
  int num_iterations_;
  skia::ImageOperations::ResizeMethod method_;
  Dimensions source_;
  Dimensions dest_;
};

// static
const int Benchmark::kDefaultNumberIterations = 1024;
const skia::ImageOperations::ResizeMethod Benchmark::kDefaultResizeMethod =
      skia::ImageOperations::RESIZE_LANCZOS3;

// argument management
void Benchmark::Usage() {
  printf("image_operations_bench -source wxh -destination wxh "
         "[-iterations i] [-method m] [-help]\n"
         "  -source wxh: specify source width and height\n"
         "  -destination wxh: specify destination width and height\n"
         "  -iter i: perform i iterations (default:%d)\n"
         "  -method m: use method m (default:%s), which can be:",
         Benchmark::kDefaultNumberIterations,
         MethodToString(Benchmark::kDefaultResizeMethod));
  PrintMethods();
  printf("\n  -help: prints this help and exits\n");
}

bool Benchmark::ParseArgs(const base::CommandLine* command_line) {
  const base::CommandLine::SwitchMap& switches = command_line->GetSwitches();
  bool fNeedHelp = false;

  for (base::CommandLine::SwitchMap::const_iterator iter = switches.begin();
       iter != switches.end();
       ++iter) {
    const std::string& s = iter->first;
    std::string value;
#if defined(OS_WIN)
    value = base::WideToUTF8(iter->second);
#else
    value = iter->second;
#endif
    if (s == "source") {
      source_.FromString(value);
    } else if (s == "destination") {
      dest_.FromString(value);
    } else if (s == "iterations") {
      if (base::StringToInt(value, &num_iterations_) == false) {
        fNeedHelp = true;
      }
    } else if (s == "method") {
      if (!StringToMethod(value, &method_)) {
        printf("Invalid method '%s' specified\n", value.c_str());
        fNeedHelp = true;
      }
    } else {
      fNeedHelp = true;
    }
  }

  if (num_iterations_ <= 0) {
    printf("Invalid number of iterations: %d\n", num_iterations_);
    fNeedHelp = true;
  }
  if (!source_.IsValid()) {
    printf("Invalid source dimensions specified\n");
    fNeedHelp = true;
  }
  if (!dest_.IsValid()) {
    printf("Invalid dest dimensions specified\n");
    fNeedHelp = true;
  }
  if (fNeedHelp == true) {
    return false;
  }
  return true;
}

// actual benchmark.
bool Benchmark::Run() const {
  SkBitmap source;
  source.allocN32Pixels(source_.width(), source_.height());
  source.eraseARGB(0, 0, 0, 0);

  SkBitmap dest;

  const base::TimeTicks start = base::TimeTicks::Now();

  for (int i = 0; i < num_iterations_; ++i) {
    dest = skia::ImageOperations::Resize(source,
                                         method_,
                                         dest_.width(), dest_.height());
  }

  const int64 elapsed_us = (base::TimeTicks::Now() - start).InMicroseconds();

  const uint64 num_bytes = static_cast<uint64>(num_iterations_) *
      (GetBitmapSize(&source) + GetBitmapSize(&dest));

  printf("%" PRIu64 " MB/s,\telapsed = %" PRIu64 " source=%d dest=%d\n",
         static_cast<uint64>(elapsed_us == 0 ? 0 : num_bytes / elapsed_us),
         static_cast<uint64>(elapsed_us),
         GetBitmapSize(&source), GetBitmapSize(&dest));

  return true;
}

// A small class to automatically call Reset on the global command line to
// avoid nasty valgrind complaints for the leak of the global command line.
class CommandLineAutoReset {
 public:
  CommandLineAutoReset(int argc, char** argv) {
    base::CommandLine::Init(argc, argv);
  }
  ~CommandLineAutoReset() {
    base::CommandLine::Reset();
  }

  const base::CommandLine* Get() const {
    return base::CommandLine::ForCurrentProcess();
  }
};

}  // namespace

int main(int argc, char** argv) {
  Benchmark bench;
  CommandLineAutoReset command_line(argc, argv);

  if (!bench.ParseArgs(command_line.Get())) {
    Benchmark::Usage();
    return 1;
  }

  if (!bench.Run()) {
    printf("Failed to run benchmark\n");
    return 1;
  }

  return 0;
}
