// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_ENCODING_IMPELLER_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_ENCODING_IMPELLER_H_

#include "flutter/common/task_runners.h"
#include "flutter/display_list/display_list_image.h"
#include "flutter/fml/synchronization/sync_switch.h"

namespace impeller {
class Context;
}  // namespace impeller

namespace flutter {

void ConvertImageToRasterImpeller(
    const sk_sp<DlImage>& dl_image,
    std::function<void(sk_sp<SkImage>)> encode_task,
    const fml::RefPtr<fml::TaskRunner>& raster_task_runner,
    const fml::RefPtr<fml::TaskRunner>& io_task_runner,
    const std::shared_ptr<const fml::SyncSwitch>& is_gpu_disabled_sync_switch,
    const std::shared_ptr<impeller::Context>& impeller_context);

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_ENCODING_IMPELLER_H_
