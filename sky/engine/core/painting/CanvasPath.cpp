// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/CanvasPath.h"

namespace blink {

CanvasPath::CanvasPath()
{
}

CanvasPath::~CanvasPath()
{
}

PassRefPtr<CanvasPath> CanvasPath::shift(const Offset& offset) {
  RefPtr<CanvasPath> path = CanvasPath::create();
  m_path.offset(offset.sk_size.width(), offset.sk_size.height(), &path->m_path);
  return path.release();
}

} // namespace blink
