// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/immutable_buffer.h"

#include <cstring>

#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/platform_configuration.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"

#if FML_OS_ANDROID
#include <sys/mman.h>
#endif

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, ImmutableBuffer);

#define FOR_EACH_BINDING(V)   \
  V(ImmutableBuffer, dispose) \
  V(ImmutableBuffer, length)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

ImmutableBuffer::~ImmutableBuffer() {}

void ImmutableBuffer::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({{"ImmutableBuffer_init", ImmutableBuffer::init, 3, true},
                     FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
  natives->Register({{"ImmutableBuffer_initFromAsset",
                      ImmutableBuffer::initFromAsset, 3, true},
                     FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

void ImmutableBuffer::init(Dart_NativeArguments args) {
  Dart_Handle callback_handle = Dart_GetNativeArgument(args, 2);
  if (!Dart_IsClosure(callback_handle)) {
    Dart_SetReturnValue(args, tonic::ToDart("Callback must be a function"));
    return;
  }

  Dart_Handle buffer_handle = Dart_GetNativeArgument(args, 0);
  tonic::Uint8List data = tonic::Uint8List(Dart_GetNativeArgument(args, 1));

  auto sk_data = MakeSkDataWithCopy(data.data(), data.num_elements());
  data.Release();
  auto buffer = fml::MakeRefCounted<ImmutableBuffer>(sk_data);
  buffer->AssociateWithDartWrapper(buffer_handle);
  tonic::DartInvoke(callback_handle, {Dart_TypeVoid()});
}

void ImmutableBuffer::initFromAsset(Dart_NativeArguments args) {
  UIDartState::ThrowIfUIOperationsProhibited();
  Dart_Handle callback_handle = Dart_GetNativeArgument(args, 2);
  if (!Dart_IsClosure(callback_handle)) {
    Dart_SetReturnValue(args, tonic::ToDart("Callback must be a function"));
    return;
  }
  Dart_Handle asset_name_handle = Dart_GetNativeArgument(args, 1);
  uint8_t* chars = nullptr;
  intptr_t asset_length = 0;
  Dart_Handle result =
      Dart_StringToUTF8(asset_name_handle, &chars, &asset_length);
  if (Dart_IsError(result)) {
    Dart_SetReturnValue(args, tonic::ToDart("Asset must be valid UTF8"));
    return;
  }
  Dart_Handle immutable_buffer = Dart_GetNativeArgument(args, 0);

  std::string asset_name = std::string{reinterpret_cast<const char*>(chars),
                                       static_cast<size_t>(asset_length)};

  std::shared_ptr<AssetManager> asset_manager = UIDartState::Current()
                                                    ->platform_configuration()
                                                    ->client()
                                                    ->GetAssetManager();
  std::unique_ptr<fml::Mapping> data = asset_manager->GetAsMapping(asset_name);
  if (data == nullptr) {
    Dart_SetReturnValue(args, tonic::ToDart("Asset not found"));
    return;
  }

  auto size = data->GetSize();
  const void* bytes = static_cast<const void*>(data->GetMapping());
  auto sk_data = MakeSkDataWithCopy(bytes, size);
  auto buffer = fml::MakeRefCounted<ImmutableBuffer>(sk_data);
  buffer->AssociateWithDartWrapper(immutable_buffer);
  tonic::DartInvoke(callback_handle, {tonic::ToDart(size)});
}

size_t ImmutableBuffer::GetAllocationSize() const {
  return sizeof(ImmutableBuffer) + data_->size();
}

#if FML_OS_ANDROID

// Compressed image buffers are allocated on the UI thread but are deleted on a
// decoder worker thread.  Android's implementation of malloc appears to
// continue growing the native heap size when the allocating thread is
// different from the freeing thread.  To work around this, create an SkData
// backed by an anonymous mapping.
sk_sp<SkData> ImmutableBuffer::MakeSkDataWithCopy(const void* data,
                                                  size_t length) {
  if (length == 0) {
    return SkData::MakeEmpty();
  }

  size_t mapping_length = length + sizeof(size_t);
  void* mapping = ::mmap(nullptr, mapping_length, PROT_READ | PROT_WRITE,
                         MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);

  if (mapping == MAP_FAILED) {
    return SkData::MakeEmpty();
  }

  *reinterpret_cast<size_t*>(mapping) = mapping_length;
  void* mapping_data = reinterpret_cast<char*>(mapping) + sizeof(size_t);
  ::memcpy(mapping_data, data, length);

  SkData::ReleaseProc proc = [](const void* ptr, void* context) {
    size_t* size_ptr = reinterpret_cast<size_t*>(context);
    FML_DCHECK(ptr == size_ptr + 1);
    if (::munmap(const_cast<void*>(context), *size_ptr) == -1) {
      FML_LOG(ERROR) << "munmap of codec SkData failed";
    }
  };

  return SkData::MakeWithProc(mapping_data, length, proc, mapping);
}

#else

sk_sp<SkData> ImmutableBuffer::MakeSkDataWithCopy(const void* data,
                                                  size_t length) {
  return SkData::MakeWithCopy(data, length);
}

#endif  // FML_OS_ANDROID

}  // namespace flutter
