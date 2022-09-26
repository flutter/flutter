// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iostream>
#include <utility>

#include "flutter/lib/ui/painting/fragment_shader.h"

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

void ReusableFragmentShader::SetSampler(Dart_Handle index_handle,
                                        Dart_Handle sampler_handle) {
  uint64_t index = tonic::DartConverter<uint64_t>::FromDart(index_handle);
  ImageShader* sampler =
      tonic::DartConverter<ImageShader*>::FromDart(sampler_handle);
  if (index >= samplers_.size()) {
    Dart_ThrowException(tonic::ToDart("Sampler index out of bounds"));
  }

  // ImageShaders can hold a preferred value for sampling options and
  // developers are encouraged to use that value or the value will be supplied
  // by "the environment where it is used". The environment here does not
  // contain a value to be used if the developer did not specify a preference
  // when they constructed the ImageShader, so we will use kNearest which is
  // the default filterQuality in a Paint object.
  DlImageSampling sampling = DlImageSampling::kNearestNeighbor;
  auto* uniform_floats =
      reinterpret_cast<float*>(uniform_data_->writable_data());
  samplers_[index] = sampler->shader(sampling);
  uniform_floats[float_count_ + 2 * index] = sampler->width();
  uniform_floats[float_count_ + 2 * index + 1] = sampler->height();
}

std::shared_ptr<DlColorSource> ReusableFragmentShader::shader(
    DlImageSampling sampling) {
  FML_CHECK(program_);
  return program_->MakeDlColorSource(uniform_data_, samplers_);
}

void ReusableFragmentShader::Dispose() {
  uniform_data_.reset();
  program_ = nullptr;
  samplers_.clear();
  ClearDartWrapper();
}

ReusableFragmentShader::~ReusableFragmentShader() = default;

}  // namespace flutter
