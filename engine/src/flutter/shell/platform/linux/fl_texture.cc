// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_texture.h"
#include "flutter/shell/platform/linux/fl_texture_private.h"

#include <gmodule.h>
#include <cstdio>

// Added here to stop the compiler from optimising this function away.
G_MODULE_EXPORT GType fl_texture_get_type();

G_DEFINE_INTERFACE(FlTexture, fl_texture, G_TYPE_OBJECT)

static void fl_texture_default_init(FlTextureInterface* self) {}

int64_t fl_texture_get_texture_id(FlTexture* self) {
  g_return_val_if_fail(FL_IS_TEXTURE(self), -1);
  return reinterpret_cast<int64_t>(self);
}
