// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_renderer.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlMockRenderer,
                     fl_mock_renderer,
                     FL,
                     MOCK_RENDERER,
                     FlRenderer)

FlMockRenderer* fl_mock_renderer_new();

G_END_DECLS
