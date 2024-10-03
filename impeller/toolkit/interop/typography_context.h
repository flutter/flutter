// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TOOLKIT_INTEROP_TYPOGRAPHY_CONTEXT_H_
#define FLUTTER_IMPELLER_TOOLKIT_INTEROP_TYPOGRAPHY_CONTEXT_H_

#include <memory>

#include "flutter/third_party/txt/src/txt/font_collection.h"
#include "impeller/toolkit/interop/impeller.h"
#include "impeller/toolkit/interop/object.h"

namespace impeller::interop {

class TypographyContext final
    : public Object<TypographyContext,
                    IMPELLER_INTERNAL_HANDLE_NAME(ImpellerTypographyContext)> {
 public:
  TypographyContext();

  ~TypographyContext() override;

  TypographyContext(const TypographyContext&) = delete;

  TypographyContext& operator=(const TypographyContext&) = delete;

  bool IsValid() const;

  const std::shared_ptr<txt::FontCollection>& GetFontCollection() const;

 private:
  std::shared_ptr<txt::FontCollection> collection_;
};

}  // namespace impeller::interop

#endif  // FLUTTER_IMPELLER_TOOLKIT_INTEROP_TYPOGRAPHY_CONTEXT_H_
