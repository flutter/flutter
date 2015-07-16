// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_util.h"
#include "base/logging.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkFlattenableSerialization.h"
#include "third_party/skia/include/core/SkImageFilter.h"

namespace {

static const int BitmapSize = 24;

bool ReadTestCase(const char* filename, std::string* ipc_filter_message) {
  base::FilePath filepath = base::FilePath::FromUTF8Unsafe(filename);

  if (!base::ReadFileToString(filepath, ipc_filter_message)) {
    LOG(ERROR) << filename << ": couldn't read file.";
    return false;
  }

  return true;
}

void RunTestCase(std::string& ipc_filter_message, SkBitmap& bitmap,
                 SkCanvas* canvas) {
  // This call shouldn't crash or cause ASAN to flag any memory issues
  // If nothing bad happens within this call, everything is fine
  SkFlattenable* flattenable = SkValidatingDeserializeFlattenable(
        ipc_filter_message.c_str(), ipc_filter_message.size(),
        SkImageFilter::GetFlattenableType());

  // Adding some info, but the test passed if we got here without any trouble
  if (flattenable != NULL) {
    LOG(INFO) << "Valid stream detected.";
    // Let's see if using the filters can cause any trouble...
    SkPaint paint;
    paint.setImageFilter(static_cast<SkImageFilter*>(flattenable))->unref();
    canvas->save();
    canvas->clipRect(SkRect::MakeXYWH(
        0, 0, SkIntToScalar(BitmapSize), SkIntToScalar(BitmapSize)));

    // This call shouldn't crash or cause ASAN to flag any memory issues
    // If nothing bad happens within this call, everything is fine
    canvas->drawBitmap(bitmap, 0, 0, &paint);

    LOG(INFO) << "Filter DAG rendered successfully";
    canvas->restore();
  } else {
    LOG(INFO) << "Invalid stream detected.";
  }
}

bool ReadAndRunTestCase(const char* filename, SkBitmap& bitmap,
                        SkCanvas* canvas) {
  std::string ipc_filter_message;

  LOG(INFO) << "Test case: " << filename;

  // ReadTestCase will print a useful error message if it fails.
  if (!ReadTestCase(filename, &ipc_filter_message))
    return false;

  RunTestCase(ipc_filter_message, bitmap, canvas);

  return true;
}

}

int main(int argc, char** argv) {
  int ret = 0;

  SkBitmap bitmap;
  bitmap.allocN32Pixels(BitmapSize, BitmapSize);
  SkCanvas canvas(bitmap);
  canvas.clear(0x00000000);

  for (int i = 1; i < argc; i++)
    if (!ReadAndRunTestCase(argv[i], bitmap, &canvas))
      ret = 2;

  // Cluster-Fuzz likes "#EOF" as the last line of output to help distinguish
  // successful runs from crashes.
  printf("#EOF\n");

  return ret;
}

