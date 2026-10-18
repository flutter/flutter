// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/skia/typeface_skia.h"

namespace impeller {

TypefaceSkia::TypefaceSkia(sk_sp<SkTypeface> typeface)
    : typeface_(std::move(typeface)) {}

TypefaceSkia::~TypefaceSkia() = default;

bool TypefaceSkia::IsValid() const {
  return !!typeface_;
}

std::size_t TypefaceSkia::GetHash() const {
  if (!IsValid()) {
    return 0u;
  }

  return typeface_->uniqueID();
}

bool TypefaceSkia::IsEqual(const Typeface& other) const {
  auto sk_other = reinterpret_cast<const TypefaceSkia*>(&other);
  return SkTypeface::Equal(sk_other->typeface_.get(), typeface_.get());
}

const sk_sp<SkTypeface>& TypefaceSkia::GetSkiaTypeface() const {
  return typeface_;
}

}  // namespace impeller
