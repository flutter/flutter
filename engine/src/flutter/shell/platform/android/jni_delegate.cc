// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jni_delegate.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
namespace android {

JniDelegate::JniDelegate(std::shared_ptr<JvmInvoker> jvm_invoker,
                         std::shared_ptr<CallbackCacheProvider> callback_cache,
                         std::shared_ptr<ImageDecoderProvider> image_decoder)
    : jvm_invoker_(std::move(jvm_invoker)),
      callback_cache_(std::move(callback_cache)),
      image_decoder_(std::move(image_decoder)) {
  TRACE_EVENT0("flutter", "JniDelegate::JniDelegate");
  FML_DCHECK(jvm_invoker_ != nullptr);
}

JniDelegate::~JniDelegate() {
  TRACE_EVENT0("flutter", "JniDelegate::~JniDelegate");
}

std::shared_ptr<JvmInvoker> JniDelegate::GetJvmInvoker() const {
  return jvm_invoker_;
}

bool JniDelegate::HandlePlatformMessage(const std::string& channel,
                                        const std::vector<uint8_t>& message,
                                        int32_t response_id) {
  TRACE_EVENT1("flutter", "JniDelegate::HandlePlatformMessage", "channel",
               channel.c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("handlePlatformMessage",
                                        "(Ljava/lang/String;[BI)V", message);
}

bool JniDelegate::HandlePlatformMessageResponse(
    int32_t response_id,
    const std::vector<uint8_t>& data) {
  TRACE_EVENT0("flutter", "JniDelegate::HandlePlatformMessageResponse");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("handlePlatformMessageResponse",
                                        "(I[B)V", data);
}

bool JniDelegate::UpdateSemantics(const std::vector<uint8_t>& buffer,
                                  const std::vector<std::string>& strings) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateSemantics");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("updateSemantics",
                                        "([B[Ljava/lang/String;)V", buffer);
}

bool JniDelegate::SetSemanticsEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "JniDelegate::SetSemanticsEnabled");
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload = {static_cast<uint8_t>(enabled ? 1 : 0)};
  return jvm_invoker_->InvokeVoidMethod("setSemanticsEnabled", "(Z)V", payload);
}

bool JniDelegate::SetApplicationLocale(const std::string& locale) {
  TRACE_EVENT1("flutter", "JniDelegate::SetApplicationLocale", "locale",
               locale.c_str());
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload(locale.begin(), locale.end());
  return jvm_invoker_->InvokeVoidMethod("setApplicationLocale",
                                        "(Ljava/lang/String;)V", payload);
}

bool JniDelegate::OnFirstFrame() {
  TRACE_EVENT0("flutter", "JniDelegate::OnFirstFrame");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("onFirstFrame", "()V");
}

bool JniDelegate::OnPreEngineRestart() {
  TRACE_EVENT0("flutter", "JniDelegate::OnPreEngineRestart");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("onPreEngineRestart", "()V");
}

bool JniDelegate::OnVsync(int64_t frame_time_nanos,
                          int64_t frame_target_time_nanos) {
  TRACE_EVENT0("flutter", "JniDelegate::OnVsync");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("onVsync", "(JJ)V");
}

bool JniDelegate::DispatchViewportMetrics(int64_t view_id,
                                          double width,
                                          double height,
                                          double pixel_ratio) {
  TRACE_EVENT0("flutter", "JniDelegate::DispatchViewportMetrics");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("onViewportMetrics", "(IDDD)V");
}

bool JniDelegate::RequestDartDeferredLibrary(int64_t loading_unit_id) {
  TRACE_EVENT0("flutter", "JniDelegate::RequestDartDeferredLibrary");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeBooleanMethod("requestDartDeferredLibrary",
                                           "(I)Z");
}

bool JniDelegate::OnAssetManagerChanged() {
  TRACE_EVENT0("flutter", "JniDelegate::OnAssetManagerChanged");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("onAssetManagerChanged", "()V");
}

static FlutterEngineResult GetCallbackInformationFromEngine(
    int64_t handle,
    FlutterCallbackInformation* info) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.GetCallbackInformation) {
    return s_procs.GetCallbackInformation(handle, info);
  }
  return kInternalInconsistency;
}

std::optional<DartCallbackInfo> JniDelegate::LookupCallbackInformation(
    int64_t handle) {
  TRACE_EVENT0("flutter", "JniDelegate::LookupCallbackInformation");
  if (callback_cache_) {
    return callback_cache_->GetCallbackInformation(handle);
  }

  FlutterCallbackInformation info = {};
  info.struct_size = sizeof(FlutterCallbackInformation);
  if (GetCallbackInformationFromEngine(handle, &info) == kSuccess) {
    DartCallbackInfo result;
    result.name = info.name ? info.name : "";
    result.class_name = info.class_name ? info.class_name : "";
    result.library_path = info.library_path ? info.library_path : "";
    return result;
  }
  return std::nullopt;
}

void JniDelegate::SetCallbackCache(
    std::shared_ptr<CallbackCacheProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetCallbackCache");
  callback_cache_ = std::move(provider);
}

std::shared_ptr<CallbackCacheProvider> JniDelegate::GetCallbackCache() const {
  return callback_cache_;
}

bool JniDelegate::DecodeImage(const uint8_t* data,
                              size_t size,
                              int64_t generator_handle) {
  TRACE_EVENT0("flutter", "JniDelegate::DecodeImage");
  if (image_decoder_) {
    return image_decoder_->DecodeImage(data, size, generator_handle);
  }
  if (!jvm_invoker_ || !data || size == 0) {
    return false;
  }
  std::vector<uint8_t> payload(data, data + size);
  return jvm_invoker_->InvokeBooleanMethod(
      "decodeImage", "(Ljava/nio/ByteBuffer;J)Landroid/graphics/Bitmap;",
      payload);
}

void JniDelegate::OnNativeImageHeader(int64_t generator_handle,
                                      int32_t width,
                                      int32_t height) {
  TRACE_EVENT0("flutter", "JniDelegate::OnNativeImageHeader");
  if (image_decoder_) {
    image_decoder_->OnImageHeader(generator_handle, width, height);
  }
}

std::optional<ImageHeaderInfo> JniDelegate::GetImageHeader(
    int64_t generator_handle) {
  TRACE_EVENT0("flutter", "JniDelegate::GetImageHeader");
  if (image_decoder_) {
    return image_decoder_->GetImageHeader(generator_handle);
  }
  return std::nullopt;
}

void JniDelegate::SetImageDecoderProvider(
    std::shared_ptr<ImageDecoderProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetImageDecoderProvider");
  image_decoder_ = std::move(provider);
}

std::shared_ptr<ImageDecoderProvider> JniDelegate::GetImageDecoderProvider()
    const {
  return image_decoder_;
}

bool JniDelegate::PushPlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    const AndroidMutatorsStack& mutators_stack) {
  TRACE_EVENT0("flutter", "JniDelegate::PushPlatformViewMutators");
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload = mutators_stack.Serialize();
  return jvm_invoker_->InvokeVoidMethod("pushPlatformViewMutators",
                                        "(JIIII[B)V", payload);
}

bool JniDelegate::PushPlatformViewMutators(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height) {
  TRACE_EVENT0("flutter", "JniDelegate::PushPlatformViewMutators(view)");
  AndroidMutatorsStack stack =
      AndroidMutatorsMapper::MapPlatformView(platform_view);
  return PushPlatformViewMutators(platform_view.identifier, x, y, width, height,
                                  stack);
}

}  // namespace android
}  // namespace flutter
