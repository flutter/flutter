// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_COMPOSITOR_CONFIG_H_
#define SKY_COMPOSITOR_COMPOSITOR_CONFIG_H_

// SkPictures that dont mutate from frame to frame are rasterized by the picture
// rasterizer. This guard enables highlighting the rasterized images. Useful
// when debugging caching
#define COMPOSITOR_HIGHLIGHT_RASTERIZED_PICTURES 0

#endif  // SKY_COMPOSITOR_COMPOSITOR_CONFIG_H_
