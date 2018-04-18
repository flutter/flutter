// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_UI_DART_STATE_H_
#define FLUTTER_LIB_UI_UI_DART_STATE_H_

#include <memory>
#include <string>
#include <utility>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/flow/skia_gpu_object.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/sky/engine/wtf/RefPtr.h"
#include "lib/fxl/build_config.h"
#include "lib/tonic/dart_microtask_queue.h"
#include "lib/tonic/dart_persistent_value.h"
#include "lib/tonic/dart_state.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace blink {
class FontSelector;
class Window;

class UIDartState : public tonic::DartState {
 public:
  static UIDartState* Current();

  Dart_Port main_port() const { return main_port_; }

  const std::string& debug_name() const { return debug_name_; }

  const std::string& logger_prefix() const { return logger_prefix_; }

  Window* window() const { return window_.get(); }

  void set_font_selector(PassRefPtr<FontSelector> selector);

  PassRefPtr<FontSelector> font_selector();

  bool use_blink() const { return use_blink_; }

  const TaskRunners& GetTaskRunners() const;

  void ScheduleMicrotask(Dart_Handle handle);

  void FlushMicrotasksNow();

  fxl::RefPtr<flow::SkiaUnrefQueue> GetSkiaUnrefQueue() const;

  fml::WeakPtr<GrContext> GetResourceContext() const;

  template <class T>
  static flow::SkiaGPUObject<T> CreateGPUObject(sk_sp<T> object) {
    if (!object) {
      return {};
    }
    auto state = UIDartState::Current();
    FXL_DCHECK(state);
    auto queue = state->GetSkiaUnrefQueue();
    return {std::move(object), std::move(queue)};
  };

 protected:
  UIDartState(TaskRunners task_runners,
              TaskObserverAdd add_callback,
              TaskObserverRemove remove_callback,
              fml::WeakPtr<GrContext> resource_context,
              fxl::RefPtr<flow::SkiaUnrefQueue> skia_unref_queue,
              std::string advisory_script_uri,
              std::string advisory_script_entrypoint,
              std::string logger_prefix);

  ~UIDartState() override;

  void SetWindow(std::unique_ptr<Window> window);

  void set_use_blink(bool use_blink) { use_blink_ = use_blink; }

  const std::string& GetAdvisoryScriptURI() const;

  const std::string& GetAdvisoryScriptEntrypoint() const;

 private:
  void DidSetIsolate() override;

  const TaskRunners task_runners_;
  const TaskObserverAdd add_callback_;
  const TaskObserverRemove remove_callback_;
  fml::WeakPtr<GrContext> resource_context_;
  const std::string advisory_script_uri_;
  const std::string advisory_script_entrypoint_;
  const std::string logger_prefix_;
  Dart_Port main_port_ = ILLEGAL_PORT;
  std::string debug_name_;
  std::unique_ptr<Window> window_;
  RefPtr<FontSelector> font_selector_;
  fxl::RefPtr<flow::SkiaUnrefQueue> skia_unref_queue_;
  tonic::DartMicrotaskQueue microtask_queue_;

  void AddOrRemoveTaskObserver(bool add);

  bool use_blink_ = false;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_UI_DART_STATE_H_
