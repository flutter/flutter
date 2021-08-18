// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/aiks/canvas.h"
#include "impeller/aiks/picture.h"

namespace impeller {

class PictureRecorder {
 public:
  PictureRecorder();

  ~PictureRecorder();

  std::shared_ptr<Canvas> GetCanvas() const;

  Picture EndRecordingAsPicture();

 private:
  std::shared_ptr<Canvas> canvas_;
};

}  // namespace impeller
