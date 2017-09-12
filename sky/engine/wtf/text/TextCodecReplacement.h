// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_WTF_TEXT_TEXTCODECREPLACEMENT_H_
#define SKY_ENGINE_WTF_TEXT_TEXTCODECREPLACEMENT_H_

#include "flutter/sky/engine/wtf/text/TextCodec.h"
#include "flutter/sky/engine/wtf/text/TextCodecUTF8.h"

namespace WTF {

class TextCodecReplacement final : public TextCodecUTF8 {
 public:
  TextCodecReplacement();

  static void registerEncodingNames(EncodingNameRegistrar);
  static void registerCodecs(TextCodecRegistrar);

 private:
  virtual String decode(const char*,
                        size_t length,
                        FlushBehavior,
                        bool stopOnError,
                        bool& sawError) override;

  bool m_sentEOF;
};

}  // namespace WTF

#endif  // SKY_ENGINE_WTF_TEXT_TEXTCODECREPLACEMENT_H_
