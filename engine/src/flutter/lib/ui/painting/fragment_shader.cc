// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iostream>

#include "flutter/lib/ui/painting/fragment_shader.h"

#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/typed_data/typed_list.h"

using tonic::ToDart;

namespace flutter {

// Since _FragmentShader is a private class, we can't use
// IMPLEMENT_WRAPPERTYPEINFO
static const tonic::DartWrapperInfo kDartWrapperInfo_ui_FragmentShader = {
    "ui",
    "_FragmentShader",
    sizeof(FragmentShader),
};
const tonic::DartWrapperInfo& FragmentShader::dart_wrapper_info_ =
    kDartWrapperInfo_ui_FragmentShader;

void FragmentShader::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({});
}

std::shared_ptr<DlColorSource> FragmentShader::shader(
    DlImageSampling sampling) {
  // Sampling options are ignored, since sampling options don't make sense for
  // generative shaders.
  return source_;
}

fml::RefPtr<FragmentShader> FragmentShader::Create(Dart_Handle dart_handle,
                                                   sk_sp<SkShader> shader) {
  auto fragment_shader = fml::MakeRefCounted<FragmentShader>(std::move(shader));
  fragment_shader->AssociateWithDartWrapper(dart_handle);
  return fragment_shader;
}

FragmentShader::FragmentShader(sk_sp<SkShader> shader)
    : source_(DlColorSource::From(shader)) {}

FragmentShader::~FragmentShader() = default;

}  // namespace flutter
