// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_CODEC_H_
#define FLUTTER_LIB_UI_PAINTING_CODEC_H_

#include "lib/tonic/dart_wrappable.h"
#include "third_party/skia/include/codec/SkCodec.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

// A handle to an SkCodec object.
//
// Doesn't mirror SkCodec's API but provides a simple sequential access API.
class Codec : public fxl::RefCountedThreadSafe<Codec>,
              public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();

 public:
  virtual int frameCount() = 0;
  virtual int repetitionCount() = 0;
  void dispose();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);
};

class MultiFrameCodec : public Codec {
 public:
  int frameCount() { return frameCount_; }
  int repetitionCount() { return repetitionCount_; }

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  MultiFrameCodec(std::unique_ptr<SkCodec> codec);
  ~MultiFrameCodec() {}

  const std::unique_ptr<SkCodec> codec_;
  int frameCount_;
  int repetitionCount_;

  FRIEND_MAKE_REF_COUNTED(MultiFrameCodec);
  FRIEND_REF_COUNTED_THREAD_SAFE(MultiFrameCodec);
};
}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_CODEC_H_
