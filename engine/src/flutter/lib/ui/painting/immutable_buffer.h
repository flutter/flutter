// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTNIG_IMMUTABLE_BUFER_H_
#define FLUTTER_LIB_UI_PAINTNIG_IMMUTABLE_BUFER_H_

#include <cstdint>

#include "flutter/fml/macros.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/logging/dart_invoke.h"
#include "third_party/tonic/typed_data/typed_list.h"

namespace flutter {

//------------------------------------------------------------------------------
/// A simple opaque handle to an immutable byte buffer suitable for use
/// internally by the engine.
///
/// This data is not known by the Dart VM.
///
/// It is expected that C++ users of this object will not modify the data
/// argument. No Dart side calls are provided to do so.
class ImmutableBuffer : public RefCountedDartWrappable<ImmutableBuffer> {
 public:
  ~ImmutableBuffer() override;

  /// Initializes a new ImmutableData from a Dart Uint8List.
  ///
  /// The zero indexed argument is the the caller that will be registered as the
  /// Dart peer of the native ImmutableBuffer object.
  ///
  /// The first indexed argumented is a tonic::Uint8List of bytes to copy.
  ///
  /// The second indexed argument is expected to be a void callback to signal
  /// when the copy has completed.
  static void init(Dart_NativeArguments args);

  /// The length of the data in bytes.
  size_t length() const {
    FML_DCHECK(data_);
    return data_->size();
  }

  /// Callers should not modify the returned data. This is not exposed to Dart.
  sk_sp<SkData> data() const { return data_; }

  /// Clears the Dart native fields and removes the reference to the underlying
  /// byte buffer.
  ///
  /// The byte buffer will continue to live if other objects hold a reference to
  /// it.
  void dispose() {
    ClearDartWrapper();
    data_.reset();
  }

  size_t GetAllocationSize() const override;

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  explicit ImmutableBuffer(sk_sp<SkData> data) : data_(std::move(data)) {}

  sk_sp<SkData> data_;

  static sk_sp<SkData> MakeSkDataWithCopy(const void* data, size_t length);

  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(ImmutableBuffer);
  FML_DISALLOW_COPY_AND_ASSIGN(ImmutableBuffer);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTNIG_IMMUTABLE_BUFER_H_
