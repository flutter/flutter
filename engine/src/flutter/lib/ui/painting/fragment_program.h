// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_FRAGMENT_PROGRAM_H_
#define FLUTTER_LIB_UI_PAINTING_FRAGMENT_PROGRAM_H_

#include "display_list/effects/dl_image_filter.h"
#include "flutter/display_list/effects/dl_runtime_effect.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/shader.h"

#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/typed_data/typed_list.h"

#include <memory>
#include <string>
#include <vector>

namespace tonic {

// DartConverter template for converting a Dart Uint8List to a C++
// std::vector<uint8_t>.
template <>
struct DartConverter<std::vector<uint8_t>> {
  using NativeType = std::vector<uint8_t>;
  using FfiType = Dart_Handle;
  static constexpr const char* kDartRepresentation = "Uint8List";
  static constexpr bool kAllowedInLeafCall = false;

  static NativeType FromDart(Dart_Handle handle) {
    if (Dart_IsError(handle) || !Dart_IsTypedData(handle)) {
      return {};
    }

    Dart_TypedData_Type type;
    void* data = nullptr;
    intptr_t length = 0;

    Dart_TypedDataAcquireData(handle, &type, &data, &length);

    if (type != Dart_TypedData_kUint8) {
      Dart_TypedDataReleaseData(handle);
      return {};
    }

    const uint8_t* bytes = static_cast<const uint8_t*>(data);
    NativeType result(bytes, bytes + length);

    Dart_TypedDataReleaseData(handle);

    return result;
  }

  static NativeType FromArguments(Dart_NativeArguments args,
                                  int index,
                                  Dart_Handle& exception) {
    Dart_Handle handle = Dart_GetNativeArgument(args, index);
    if (Dart_IsError(handle)) {
      exception = handle;
      return {};
    }
    if (!Dart_IsTypedData(handle)) {
      exception = Dart_NewApiError("Expected a Uint8List argument.");
      return {};
    }
    return FromDart(handle);
  }

  static NativeType FromFfi(FfiType val) { return FromDart(val); }
  static const char* GetDartRepresentation() { return kDartRepresentation; }
  static bool AllowedInLeafCall() { return kAllowedInLeafCall; }
};

}  // namespace tonic

namespace flutter {

class FragmentShader;

class FragmentProgram : public RefCountedDartWrappable<FragmentProgram> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(FragmentProgram);

 public:
  ~FragmentProgram() override;
  static void Create(Dart_Handle wrapper);

  std::string initFromAsset(const std::string& asset_name);

  std::string initFromBytes(const std::string& asset_name,
                            std::vector<uint8_t> bytes);

  fml::RefPtr<FragmentShader> shader(Dart_Handle shader,
                                     Dart_Handle uniforms_handle,
                                     Dart_Handle samplers);

  std::shared_ptr<DlColorSource> MakeDlColorSource(
      std::shared_ptr<std::vector<uint8_t>> float_uniforms,
      const std::vector<std::shared_ptr<DlColorSource>>& children);

  std::shared_ptr<DlImageFilter> MakeDlImageFilter(
      std::shared_ptr<std::vector<uint8_t>> float_uniforms,
      const std::vector<std::shared_ptr<DlColorSource>>& children);

 private:
  FragmentProgram();
  std::string Init(const std::string& asset_name,
                   std::unique_ptr<fml::Mapping> data);
  sk_sp<DlRuntimeEffect> runtime_effect_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_FRAGMENT_PROGRAM_H_
