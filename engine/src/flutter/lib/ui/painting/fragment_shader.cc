// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <utility>

#include "flutter/lib/ui/painting/fragment_shader.h"

#include "flutter/display_list/dl_tile_mode.h"
#include "flutter/display_list/effects/dl_color_source.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/fragment_program.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/typed_data/typed_list.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, ReusableFragmentShader);

ReusableFragmentShader::ReusableFragmentShader(
    fml::RefPtr<FragmentProgram> program,
    uint64_t float_count,
    uint64_t sampler_count)
    : program_(std::move(program)),
      uniform_data_(SkData::MakeUninitialized(
          (float_count + 2 * sampler_count) * sizeof(float))),
      samplers_(sampler_count),
      float_count_(float_count) {}

Dart_Handle ReusableFragmentShader::Create(Dart_Handle wrapper,
                                           Dart_Handle program,
                                           Dart_Handle float_count_handle,
                                           Dart_Handle sampler_count_handle) {
  auto* fragment_program =
      tonic::DartConverter<FragmentProgram*>::FromDart(program);
  uint64_t float_count =
      tonic::DartConverter<uint64_t>::FromDart(float_count_handle);
  uint64_t sampler_count =
      tonic::DartConverter<uint64_t>::FromDart(sampler_count_handle);

  auto res = fml::MakeRefCounted<ReusableFragmentShader>(
      fml::Ref(fragment_program), float_count, sampler_count);
  res->AssociateWithDartWrapper(wrapper);

  void* raw_uniform_data =
      reinterpret_cast<void*>(res->uniform_data_->writable_data());
  return Dart_NewExternalTypedData(Dart_TypedData_kFloat32, raw_uniform_data,
                                   float_count);
}

bool ReusableFragmentShader::ValidateSamplers() {
  for (auto i = 0u; i < samplers_.size(); i += 1) {
    if (samplers_[i] == nullptr) {
      return false;
    }
  }
  return true;
}

void ReusableFragmentShader::SetImageSampler(Dart_Handle index_handle,
                                             Dart_Handle image_handle) {
  uint64_t index = tonic::DartConverter<uint64_t>::FromDart(index_handle);
  CanvasImage* image =
      tonic::DartConverter<CanvasImage*>::FromDart(image_handle);
  if (index >= samplers_.size()) {
    Dart_ThrowException(tonic::ToDart("Sampler index out of bounds"));
  }

  // TODO(115794): Once the DlImageSampling enum is replaced, expose the
  //               sampling options as a new default parameter for users.
  samplers_[index] = std::make_shared<DlImageColorSource>(
      image->image(), DlTileMode::kClamp, DlTileMode::kClamp,
      DlImageSampling::kNearestNeighbor, nullptr);

  auto* uniform_floats =
      reinterpret_cast<float*>(uniform_data_->writable_data());
  uniform_floats[float_count_ + 2 * index] = image->width();
  uniform_floats[float_count_ + 2 * index + 1] = image->height();
}

std::shared_ptr<DlColorSource> ReusableFragmentShader::shader(
    DlImageSampling sampling) {
  FML_CHECK(program_);

  // The lifetime of this object is longer than a frame, and the uniforms can be
  // continually changed on the UI thread. So we take a copy of the uniforms
  // before handing it to the DisplayList for consumption on the render thread.
  auto uniform_data = std::make_shared<std::vector<uint8_t>>();
  uniform_data->resize(uniform_data_->size());
  memcpy(uniform_data->data(), uniform_data_->bytes(), uniform_data->size());

  return program_->MakeDlColorSource(std::move(uniform_data), samplers_);
}

void ReusableFragmentShader::Dispose() {
  uniform_data_.reset();
  program_ = nullptr;
  samplers_.clear();
  ClearDartWrapper();
}

ReusableFragmentShader::~ReusableFragmentShader() = default;

}  // namespace flutter
