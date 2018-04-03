// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FLUTTER_EXPORT __attribute__((visibility("default")))

#include "flutter/shell/platform/embedder/embedder.h"

#include <type_traits>
#include "flutter/common/threads.h"
#include "flutter/fml/message_loop.h"
#include "flutter/shell/platform/embedder/platform_view_embedder.h"
#include "lib/fxl/functional/make_copyable.h"

#define SAFE_ACCESS(pointer, member, default_value)                      \
  ({                                                                     \
    auto _return_value =                                                 \
        static_cast<__typeof__(pointer->member)>((default_value));       \
    if (offsetof(std::remove_pointer<decltype(pointer)>::type, member) + \
            sizeof(pointer->member) <=                                   \
        pointer->struct_size) {                                          \
      _return_value = pointer->member;                                   \
    }                                                                    \
    _return_value;                                                       \
  })

bool IsRendererValid(const FlutterRendererConfig* config) {
  if (config == nullptr || config->type != kOpenGL) {
    return false;
  }

  const FlutterOpenGLRendererConfig* open_gl_config = &config->open_gl;

  if (SAFE_ACCESS(open_gl_config, make_current, nullptr) == nullptr ||
      SAFE_ACCESS(open_gl_config, clear_current, nullptr) == nullptr ||
      SAFE_ACCESS(open_gl_config, present, nullptr) == nullptr ||
      SAFE_ACCESS(open_gl_config, fbo_callback, nullptr) == nullptr) {
    return false;
  }

  return true;
}

class PlatformViewHolder {
 public:
  PlatformViewHolder(std::shared_ptr<shell::PlatformViewEmbedder> ptr)
      : platform_view_(std::move(ptr)) {}

  std::shared_ptr<shell::PlatformViewEmbedder> view() const {
    return platform_view_;
  }

 private:
  std::shared_ptr<shell::PlatformViewEmbedder> platform_view_;

  FXL_DISALLOW_COPY_AND_ASSIGN(PlatformViewHolder);
};

struct _FlutterPlatformMessageResponseHandle {
  fxl::RefPtr<blink::PlatformMessage> message;
};

FlutterResult FlutterEngineRun(size_t version,
                               const FlutterRendererConfig* config,
                               const FlutterProjectArgs* args,
                               void* user_data,
                               FlutterEngine* engine_out) {
  if (version != FLUTTER_ENGINE_VERSION) {
    return kInvalidLibraryVersion;
  }

  if (engine_out == nullptr) {
    return kInvalidArguments;
  }

  if (args == nullptr) {
    return kInvalidArguments;
  }

  if (SAFE_ACCESS(args, assets_path, nullptr) == nullptr ||
      SAFE_ACCESS(args, main_path, nullptr) == nullptr ||
      SAFE_ACCESS(args, packages_path, nullptr) == nullptr) {
    return kInvalidArguments;
  }

  if (!IsRendererValid(config)) {
    return kInvalidArguments;
  }

  auto make_current =
      [ ptr = config->open_gl.make_current, user_data ]()->bool {
    return ptr(user_data);
  };

  auto clear_current =
      [ ptr = config->open_gl.clear_current, user_data ]()->bool {
    return ptr(user_data);
  };

  auto present = [ ptr = config->open_gl.present, user_data ]()->bool {
    return ptr(user_data);
  };

  auto fbo_callback =
      [ ptr = config->open_gl.fbo_callback, user_data ]()->intptr_t {
    return ptr(user_data);
  };

  shell::PlatformViewEmbedder::PlatformMessageResponseCallback
      platform_message_response_callback = nullptr;
  if (SAFE_ACCESS(args, platform_message_callback, nullptr) != nullptr) {
    platform_message_response_callback =
        [ ptr = args->platform_message_callback,
          user_data ](fxl::RefPtr<blink::PlatformMessage> message) {
      auto handle = new FlutterPlatformMessageResponseHandle();
      const FlutterPlatformMessage incoming_message = {
          .struct_size = sizeof(FlutterPlatformMessage),
          .channel = message->channel().c_str(),
          .message = message->data().data(),
          .message_size = message->data().size(),
          .response_handle = handle,
      };
      handle->message = std::move(message);
      return ptr(&incoming_message, user_data);
    };
  }

  const FlutterOpenGLRendererConfig* open_gl_config = &config->open_gl;
  std::function<bool()> make_resource_current_callback = nullptr;
  if (SAFE_ACCESS(open_gl_config, make_resource_current, nullptr) != nullptr) {
    make_resource_current_callback =
        [ ptr = config->open_gl.make_resource_current, user_data ]() {
      return ptr(user_data);
    };
  }

  std::string icu_data_path;
  if (SAFE_ACCESS(args, icu_data_path, nullptr) != nullptr) {
    icu_data_path = SAFE_ACCESS(args, icu_data_path, nullptr);
  }

  fxl::CommandLine command_line;
  if (SAFE_ACCESS(args, command_line_argc, 0) != 0 &&
      SAFE_ACCESS(args, command_line_argv, nullptr) != nullptr) {
    command_line = fxl::CommandLineFromArgcArgv(
        SAFE_ACCESS(args, command_line_argc, 0),
        SAFE_ACCESS(args, command_line_argv, nullptr));
  }

  static std::once_flag once_shell_initialization;
  std::call_once(once_shell_initialization, [&]() {
    fxl::CommandLine null_command_line;
    shell::Shell::InitStandalone(
        std::move(command_line),
        icu_data_path,  // icu data path default lookup.
        "",             // application library not supported in JIT mode.
        args->assets_path
    );
  });

  shell::PlatformViewEmbedder::DispatchTable table = {
      .gl_make_current_callback = make_current,
      .gl_clear_current_callback = clear_current,
      .gl_present_callback = present,
      .gl_fbo_callback = fbo_callback,
      .platform_message_response_callback = platform_message_response_callback,
      .gl_make_resource_current_callback = make_resource_current_callback,
  };

  auto platform_view = std::make_shared<shell::PlatformViewEmbedder>(table);
  platform_view->Attach();

  std::string assets(args->assets_path);
  std::string main(args->main_path);
  std::string packages(args->packages_path);

  blink::Threads::UI()->PostTask([
    weak_engine = platform_view->engine().GetWeakPtr(),  //
    assets = std::move(assets),                          //
    main = std::move(main),                              //
    packages = std::move(packages)                       //
  ] {
    if (auto engine = weak_engine) {
      if (main.empty()) {
        engine->RunBundle(assets);
      } else {
        engine->RunBundleAndSource(assets, main, packages);
      }
    }
  });

  *engine_out = reinterpret_cast<FlutterEngine>(
      new PlatformViewHolder(std::move(platform_view)));

  return kSuccess;
}

FlutterResult FlutterEngineShutdown(FlutterEngine engine) {
  if (engine == nullptr) {
    return kInvalidArguments;
  }
  delete reinterpret_cast<PlatformViewHolder*>(engine);
  return kSuccess;
}

FlutterResult FlutterEngineSendWindowMetricsEvent(
    FlutterEngine engine,
    const FlutterWindowMetricsEvent* flutter_metrics) {
  if (engine == nullptr || flutter_metrics == nullptr) {
    return kInvalidArguments;
  }

  auto holder = reinterpret_cast<PlatformViewHolder*>(engine);

  blink::ViewportMetrics metrics;

  metrics.physical_width = SAFE_ACCESS(flutter_metrics, width, 0.0);
  metrics.physical_height = SAFE_ACCESS(flutter_metrics, height, 0.0);
  metrics.device_pixel_ratio = SAFE_ACCESS(flutter_metrics, pixel_ratio, 1.0);

  blink::Threads::UI()->PostTask(
      [ weak_engine = holder->view()->engine().GetWeakPtr(), metrics ] {
        if (auto engine = weak_engine) {
          engine->SetViewportMetrics(metrics);
        }
      });
  return kSuccess;
}

inline blink::PointerData::Change ToPointerDataChange(
    FlutterPointerPhase phase) {
  switch (phase) {
    case kCancel:
      return blink::PointerData::Change::kCancel;
    case kUp:
      return blink::PointerData::Change::kUp;
    case kDown:
      return blink::PointerData::Change::kDown;
    case kMove:
      return blink::PointerData::Change::kMove;
  }
  return blink::PointerData::Change::kCancel;
}

FlutterResult FlutterEngineSendPointerEvent(FlutterEngine engine,
                                            const FlutterPointerEvent* pointers,
                                            size_t events_count) {
  if (engine == nullptr || pointers == nullptr || events_count == 0) {
    return kInvalidArguments;
  }

  auto packet = std::make_unique<blink::PointerDataPacket>(events_count);

  const FlutterPointerEvent* current = pointers;

  for (size_t i = 0; i < events_count; ++i) {
    blink::PointerData pointer_data;
    pointer_data.Clear();
    pointer_data.time_stamp = SAFE_ACCESS(current, timestamp, 0);
    pointer_data.change = ToPointerDataChange(
        SAFE_ACCESS(current, phase, FlutterPointerPhase::kCancel));
    pointer_data.kind = blink::PointerData::DeviceKind::kMouse;
    pointer_data.physical_x = SAFE_ACCESS(current, x, 0.0);
    pointer_data.physical_y = SAFE_ACCESS(current, y, 0.0);
    packet->SetPointerData(i, pointer_data);
    current = reinterpret_cast<const FlutterPointerEvent*>(
        reinterpret_cast<const uint8_t*>(current) + current->struct_size);
  }

  blink::Threads::UI()->PostTask(fxl::MakeCopyable([
    weak_engine = reinterpret_cast<PlatformViewHolder*>(engine)
                      ->view()
                      ->engine()
                      .GetWeakPtr(),
    packet = std::move(packet)
  ] {
    if (auto engine = weak_engine) {
      engine->DispatchPointerDataPacket(*packet);
    }
  }));

  return kSuccess;
}

FlutterResult FlutterEngineSendPlatformMessage(
    FlutterEngine engine,
    const FlutterPlatformMessage* flutter_message) {
  if (engine == nullptr || flutter_message == nullptr) {
    return kInvalidArguments;
  }

  if (SAFE_ACCESS(flutter_message, channel, nullptr) == nullptr ||
      SAFE_ACCESS(flutter_message, message, nullptr) == nullptr) {
    return kInvalidArguments;
  }

  auto holder = reinterpret_cast<PlatformViewHolder*>(engine);

  auto message = fxl::MakeRefCounted<blink::PlatformMessage>(
      flutter_message->channel,
      std::vector<uint8_t>(
          flutter_message->message,
          flutter_message->message + flutter_message->message_size),
      nullptr);

  blink::Threads::UI()->PostTask(
      [ weak_engine = holder->view()->engine().GetWeakPtr(), message ] {
        if (auto engine = weak_engine) {
          engine->DispatchPlatformMessage(message);
        }
      });
  return kSuccess;
}

FlutterResult FlutterEngineSendPlatformMessageResponse(
    FlutterEngine engine,
    const FlutterPlatformMessageResponseHandle* handle,
    const uint8_t* data,
    size_t data_length) {
  if (data_length != 0 && data == nullptr) {
    return kInvalidArguments;
  }

  auto response = handle->message->response();

  if (data_length == 0) {
    response->CompleteEmpty();
  } else {
    response->Complete({data, data + data_length});
  }

  delete handle;

  return kSuccess;
}

FlutterResult __FlutterEngineFlushPendingTasksNow() {
  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
  return kSuccess;
}
