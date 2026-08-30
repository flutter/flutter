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
      callback_cache_(callback_cache
                          ? std::move(callback_cache)
                          : std::make_shared<DefaultCallbackCacheProvider>()),
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
                                        const uint8_t* message,
                                        size_t message_size,
                                        int32_t response_id,
                                        int64_t message_data) {
  TRACE_EVENT1("flutter", "JniDelegate::HandlePlatformMessage", "channel",
               channel.c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->HandlePlatformMessage(channel, message, message_size,
                                             response_id, message_data);
}

bool JniDelegate::HandlePlatformMessage(const std::string& channel,
                                        const std::vector<uint8_t>& message,
                                        int32_t response_id,
                                        int64_t message_data) {
  return HandlePlatformMessage(channel, message.data(), message.size(),
                               response_id, message_data);
}

bool JniDelegate::HandlePlatformMessageResponse(int32_t response_id,
                                                const uint8_t* data,
                                                size_t data_size) {
  TRACE_EVENT0("flutter", "JniDelegate::HandlePlatformMessageResponse");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->HandlePlatformMessageResponse(response_id, data,
                                                     data_size);
}

bool JniDelegate::HandlePlatformMessageResponse(
    int32_t response_id,
    const std::vector<uint8_t>& data) {
  return HandlePlatformMessageResponse(response_id, data.data(), data.size());
}

bool JniDelegate::UpdateSemantics(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings,
    const std::vector<std::vector<uint8_t>>& string_attribute_args) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateSemantics");
  if (!jvm_invoker_) {
    return false;
  }
  if (buffer.empty()) {
    return true;
  }
  return jvm_invoker_->UpdateSemantics(buffer, strings, string_attribute_args);
}

bool JniDelegate::UpdateCustomAccessibilityActions(
    const std::vector<uint8_t>& actions_buffer,
    const std::vector<std::string>& action_strings) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateCustomAccessibilityActions");
  if (!jvm_invoker_) {
    return false;
  }
  if (actions_buffer.empty()) {
    return true;
  }
  return jvm_invoker_->UpdateCustomAccessibilityActions(actions_buffer,
                                                        action_strings);
}

bool JniDelegate::UpdateSemantics(const FlutterSemanticsUpdate2& update) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateSemantics(struct)");
  EncodedSemanticsBatch batch =
      AndroidSemanticsMapper::MapSemanticsUpdate(update);
  bool success = true;
  if (!batch.custom_actions.empty()) {
    success &= UpdateCustomAccessibilityActions(batch.custom_actions.buffer,
                                                batch.custom_actions.strings);
  }
  if (!batch.nodes.empty()) {
    success &= UpdateSemantics(batch.nodes.buffer, batch.nodes.strings,
                               batch.nodes.string_attribute_args);
  }
  return success;
}

bool JniDelegate::SetSemanticsTreeEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "JniDelegate::SetSemanticsTreeEnabled");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->SetSemanticsTreeEnabled(enabled);
}

bool JniDelegate::SetApplicationLocale(const std::string& locale) {
  TRACE_EVENT1("flutter", "JniDelegate::SetApplicationLocale", "locale",
               locale.c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->SetApplicationLocale(locale);
}

bool JniDelegate::OnFirstFrame() {
  TRACE_EVENT0("flutter", "JniDelegate::OnFirstFrame");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->OnFirstFrame();
}

bool JniDelegate::OnPreEngineRestart() {
  TRACE_EVENT0("flutter", "JniDelegate::OnPreEngineRestart");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->OnPreEngineRestart();
}

bool JniDelegate::RequestDartDeferredLibrary(int loading_unit_id) {
  TRACE_EVENT0("flutter", "JniDelegate::RequestDartDeferredLibrary");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->RequestDartDeferredLibrary(loading_unit_id);
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

DefaultCallbackCacheProvider::DefaultCallbackCacheProvider() {
  TRACE_EVENT0("flutter",
               "DefaultCallbackCacheProvider::DefaultCallbackCacheProvider");
}

DefaultCallbackCacheProvider::~DefaultCallbackCacheProvider() {
  TRACE_EVENT0("flutter",
               "DefaultCallbackCacheProvider::~DefaultCallbackCacheProvider");
}

std::optional<DartCallbackInfo>
DefaultCallbackCacheProvider::GetCallbackInformation(int64_t handle) {
  TRACE_EVENT0("flutter",
               "DefaultCallbackCacheProvider::GetCallbackInformation");
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

InMemoryCallbackCacheProvider::InMemoryCallbackCacheProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryCallbackCacheProvider::InMemoryCallbackCacheProvider");
}

InMemoryCallbackCacheProvider::~InMemoryCallbackCacheProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryCallbackCacheProvider::~InMemoryCallbackCacheProvider");
}

void InMemoryCallbackCacheProvider::AddCallback(
    int64_t handle,
    const std::string& name,
    const std::string& class_name,
    const std::string& library_path) {
  TRACE_EVENT0("flutter", "InMemoryCallbackCacheProvider::AddCallback");
  std::unique_lock lock(mutex_);
  cache_[handle] = DartCallbackInfo{name, class_name, library_path};
}

void InMemoryCallbackCacheProvider::RemoveCallback(int64_t handle) {
  TRACE_EVENT0("flutter", "InMemoryCallbackCacheProvider::RemoveCallback");
  std::unique_lock lock(mutex_);
  cache_.erase(handle);
}

void InMemoryCallbackCacheProvider::Clear() {
  TRACE_EVENT0("flutter", "InMemoryCallbackCacheProvider::Clear");
  std::unique_lock lock(mutex_);
  cache_.clear();
}

size_t InMemoryCallbackCacheProvider::GetSize() const {
  std::shared_lock lock(mutex_);
  return cache_.size();
}

std::optional<DartCallbackInfo>
InMemoryCallbackCacheProvider::GetCallbackInformation(int64_t handle) {
  TRACE_EVENT0("flutter",
               "InMemoryCallbackCacheProvider::GetCallbackInformation");
  std::shared_lock lock(mutex_);
  auto it = cache_.find(handle);
  if (it != cache_.end()) {
    return it->second;
  }
  return std::nullopt;
}

std::optional<DartCallbackInfo> JniDelegate::LookupCallbackInformation(
    int64_t handle) {
  TRACE_EVENT0("flutter", "JniDelegate::LookupCallbackInformation");
  std::shared_ptr<CallbackCacheProvider> cache;
  {
    std::scoped_lock lock(callback_cache_mutex_);
    cache = callback_cache_;
  }
  if (cache) {
    return cache->GetCallbackInformation(handle);
  }
  return std::nullopt;
}

void JniDelegate::SetCallbackCache(
    std::shared_ptr<CallbackCacheProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetCallbackCache");
  std::scoped_lock lock(callback_cache_mutex_);
  callback_cache_ = provider ? std::move(provider)
                             : std::make_shared<DefaultCallbackCacheProvider>();
}

std::shared_ptr<CallbackCacheProvider> JniDelegate::GetCallbackCache() const {
  std::scoped_lock lock(callback_cache_mutex_);
  return callback_cache_;
}

bool JniDelegate::DecodeImage(const uint8_t* data,
                              size_t size,
                              int64_t generator_handle) {
  TRACE_EVENT0("flutter", "JniDelegate::DecodeImage");
  std::shared_ptr<ImageDecoderProvider> decoder;
  {
    std::scoped_lock lock(image_decoder_mutex_);
    decoder = image_decoder_;
  }
  if (decoder) {
    return decoder->DecodeImage(data, size, generator_handle);
  }
  if (!jvm_invoker_ || !data || size == 0) {
    return false;
  }
  return jvm_invoker_->DecodeImage(data, size, generator_handle);
}

void JniDelegate::OnNativeImageHeader(int64_t generator_handle,
                                      int32_t width,
                                      int32_t height) {
  TRACE_EVENT0("flutter", "JniDelegate::OnNativeImageHeader");
  std::shared_ptr<ImageDecoderProvider> decoder;
  {
    std::scoped_lock lock(image_decoder_mutex_);
    decoder = image_decoder_;
  }
  if (decoder) {
    decoder->OnImageHeader(generator_handle, width, height);
  }
}

std::optional<ImageHeaderInfo> JniDelegate::GetImageHeader(
    int64_t generator_handle) {
  TRACE_EVENT0("flutter", "JniDelegate::GetImageHeader");
  std::shared_ptr<ImageDecoderProvider> decoder;
  {
    std::scoped_lock lock(image_decoder_mutex_);
    decoder = image_decoder_;
  }
  if (decoder) {
    return decoder->GetImageHeader(generator_handle);
  }
  return std::nullopt;
}

void JniDelegate::RemoveImageHeader(int64_t generator_handle) {
  TRACE_EVENT0("flutter", "JniDelegate::RemoveImageHeader");
  std::shared_ptr<ImageDecoderProvider> decoder;
  {
    std::scoped_lock lock(image_decoder_mutex_);
    decoder = image_decoder_;
  }
  if (decoder) {
    decoder->RemoveImageHeader(generator_handle);
  }
}

void JniDelegate::SetImageDecoderProvider(
    std::shared_ptr<ImageDecoderProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetImageDecoderProvider");
  std::scoped_lock lock(image_decoder_mutex_);
  image_decoder_ = std::move(provider);
}

std::shared_ptr<ImageDecoderProvider> JniDelegate::GetImageDecoderProvider()
    const {
  std::scoped_lock lock(image_decoder_mutex_);
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
  return jvm_invoker_->PushPlatformViewMutators(view_id, x, y, width, height,
                                                payload);
}

bool JniDelegate::PushPlatformViewMutators(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height) {
  TRACE_EVENT0("flutter", "JniDelegate::PushPlatformViewMutators(view)");
  if (platform_view.struct_size < sizeof(FlutterPlatformView)) {
    return false;
  }
  AndroidMutatorsStack stack =
      AndroidMutatorsMapper::MapPlatformView(platform_view);
  return PushPlatformViewMutators(platform_view.identifier, x, y, width, height,
                                  stack);
}

}  // namespace android
}  // namespace flutter
