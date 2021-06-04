// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/primitives/primitive.h"

namespace impeller {

Primitive::Primitive(std::shared_ptr<Context> context)
    : context_(std::move(context)) {}

Primitive::~Primitive() = default;

std::shared_ptr<Context> Primitive::GetContext() const {
  return context_;
}

}  // namespace impeller
