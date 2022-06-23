// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/ui_dart_state.h"

#include <iostream>

#include "flutter/fml/message_loop.h"
#include "flutter/lib/ui/window/platform_configuration.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_message_handler.h"

#if defined(FML_OS_ANDROID)
#include <android/log.h>
#elif defined(FML_OS_IOS)
extern "C" {
// Cannot import the syslog.h header directly because of macro collision.
extern void syslog(int, const char*, ...);
}
#endif

using tonic::ToDart;

namespace flutter {

UIDartState::Context::Context(const TaskRunners& task_runners)
    : task_runners(task_runners) {}

UIDartState::Context::Context(
    const TaskRunners& task_runners,
    fml::WeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::WeakPtr<IOManager> io_manager,
    fml::RefPtr<SkiaUnrefQueue> unref_queue,
    fml::WeakPtr<ImageDecoder> image_decoder,
    fml::WeakPtr<ImageGeneratorRegistry> image_generator_registry,
    std::string advisory_script_uri,
    std::string advisory_script_entrypoint,
    std::shared_ptr<VolatilePathTracker> volatile_path_tracker)
    : task_runners(task_runners),
      snapshot_delegate(snapshot_delegate),
      io_manager(io_manager),
      unref_queue(unref_queue),
      image_decoder(image_decoder),
      image_generator_registry(image_generator_registry),
      advisory_script_uri(advisory_script_uri),
      advisory_script_entrypoint(advisory_script_entrypoint),
      volatile_path_tracker(volatile_path_tracker) {}

UIDartState::UIDartState(
    TaskObserverAdd add_callback,
    TaskObserverRemove remove_callback,
    std::string logger_prefix,
    UnhandledExceptionCallback unhandled_exception_callback,
    LogMessageCallback log_message_callback,
    std::shared_ptr<IsolateNameServer> isolate_name_server,
    bool is_root_isolate,
    bool enable_skparagraph,
    const UIDartState::Context& context)
    : add_callback_(std::move(add_callback)),
      remove_callback_(std::move(remove_callback)),
      logger_prefix_(std::move(logger_prefix)),
      is_root_isolate_(is_root_isolate),
      unhandled_exception_callback_(unhandled_exception_callback),
      log_message_callback_(log_message_callback),
      isolate_name_server_(std::move(isolate_name_server)),
      enable_skparagraph_(enable_skparagraph),
      context_(std::move(context)) {
  AddOrRemoveTaskObserver(true /* add */);
}

UIDartState::~UIDartState() {
  AddOrRemoveTaskObserver(false /* remove */);
}

const std::string& UIDartState::GetAdvisoryScriptURI() const {
  return context_.advisory_script_uri;
}

void UIDartState::DidSetIsolate() {
  main_port_ = Dart_GetMainPortId();
  std::ostringstream debug_name;
  // main.dart$main-1234
  debug_name << context_.advisory_script_uri << "$"
             << context_.advisory_script_entrypoint << "-" << main_port_;
  SetDebugName(debug_name.str());
}

void UIDartState::ThrowIfUIOperationsProhibited() {
  if (!UIDartState::Current()->IsRootIsolate()) {
    Dart_ThrowException(
        tonic::ToDart("UI actions are only available on root isolate."));
  }
}

void UIDartState::SetDebugName(const std::string debug_name) {
  debug_name_ = debug_name;
  if (platform_configuration_) {
    platform_configuration_->client()->UpdateIsolateDescription(debug_name_,
                                                                main_port_);
  }
}

UIDartState* UIDartState::Current() {
  return static_cast<UIDartState*>(DartState::Current());
}

void UIDartState::SetPlatformConfiguration(
    std::unique_ptr<PlatformConfiguration> platform_configuration) {
  platform_configuration_ = std::move(platform_configuration);
  if (platform_configuration_) {
    platform_configuration_->client()->UpdateIsolateDescription(debug_name_,
                                                                main_port_);
  }
}

const TaskRunners& UIDartState::GetTaskRunners() const {
  return context_.task_runners;
}

fml::WeakPtr<IOManager> UIDartState::GetIOManager() const {
  return context_.io_manager;
}

fml::RefPtr<flutter::SkiaUnrefQueue> UIDartState::GetSkiaUnrefQueue() const {
  return context_.unref_queue;
}

std::shared_ptr<VolatilePathTracker> UIDartState::GetVolatilePathTracker()
    const {
  return context_.volatile_path_tracker;
}

void UIDartState::ScheduleMicrotask(Dart_Handle closure) {
  if (tonic::CheckAndHandleError(closure) || !Dart_IsClosure(closure)) {
    return;
  }

  microtask_queue_.ScheduleMicrotask(closure);
}

void UIDartState::FlushMicrotasksNow() {
  microtask_queue_.RunMicrotasks();
}

void UIDartState::AddOrRemoveTaskObserver(bool add) {
  auto task_runner = context_.task_runners.GetUITaskRunner();
  if (!task_runner) {
    // This may happen in case the isolate has no thread affinity (for example,
    // the service isolate).
    return;
  }
  FML_DCHECK(add_callback_ && remove_callback_);
  if (add) {
    add_callback_(reinterpret_cast<intptr_t>(this),
                  [this]() { this->FlushMicrotasksNow(); });
  } else {
    remove_callback_(reinterpret_cast<intptr_t>(this));
  }
}

fml::WeakPtr<SnapshotDelegate> UIDartState::GetSnapshotDelegate() const {
  return context_.snapshot_delegate;
}

fml::WeakPtr<ImageDecoder> UIDartState::GetImageDecoder() const {
  return context_.image_decoder;
}

fml::WeakPtr<ImageGeneratorRegistry> UIDartState::GetImageGeneratorRegistry()
    const {
  return context_.image_generator_registry;
}

std::shared_ptr<IsolateNameServer> UIDartState::GetIsolateNameServer() const {
  return isolate_name_server_;
}

tonic::DartErrorHandleType UIDartState::GetLastError() {
  tonic::DartErrorHandleType error = message_handler().isolate_last_error();
  if (error == tonic::kNoError) {
    error = microtask_queue_.GetLastError();
  }
  return error;
}

void UIDartState::LogMessage(const std::string& tag,
                             const std::string& message) const {
  if (log_message_callback_) {
    log_message_callback_(tag, message);
  } else {
    // Fall back to previous behavior if unspecified.
#if defined(FML_OS_ANDROID)
    __android_log_print(ANDROID_LOG_INFO, tag.c_str(), "%.*s",
                        (int)message.size(), message.c_str());
#elif defined(FML_OS_IOS)
    std::stringstream stream;
    if (!tag.empty()) {
      stream << tag << ": ";
    }
    stream << message;
    std::string log = stream.str();
    syslog(1 /* LOG_ALERT */, "%.*s", (int)log.size(), log.c_str());
#else
    if (!tag.empty()) {
      std::cout << tag << ": ";
    }
    std::cout << message << std::endl;
#endif
  }
}

bool UIDartState::enable_skparagraph() const {
  return enable_skparagraph_;
}

}  // namespace flutter
