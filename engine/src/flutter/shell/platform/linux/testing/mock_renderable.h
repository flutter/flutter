// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_RENDERABLE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_RENDERABLE_H_

#include "flutter/shell/platform/linux/fl_renderable.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlMockRenderable,
                     fl_mock_renderable,
                     FL,
                     MOCK_RENDERABLE,
                     GObject)

FlMockRenderable* fl_mock_renderable_new();

size_t fl_mock_renderable_get_redraw_count(FlMockRenderable* renderable);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_RENDERABLE_H_
