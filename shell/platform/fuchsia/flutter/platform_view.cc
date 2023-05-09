// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define RAPIDJSON_HAS_STDSTRING 1

#include "platform_view.h"

#include <fuchsia/ui/app/cpp/fidl.h>
#include <zircon/status.h>

#include <algorithm>
#include <cstring>
#include <limits>
#include <sstream>

#include "flutter/fml/logging.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/lib/ui/window/pointer_data.h"
#include "flutter/lib/ui/window/window.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/encodable_value.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/standard_message_codec.h"
#include "third_party/rapidjson/include/rapidjson/document.h"
#include "third_party/rapidjson/include/rapidjson/stringbuffer.h"
#include "third_party/rapidjson/include/rapidjson/writer.h"

#include "logging.h"
#include "pointer_injector_delegate.h"
#include "runtime/dart/utils/inlines.h"
#include "text_delegate.h"
#include "vsync_waiter.h"

namespace {
// Helper to extract a given member with a given type from a rapidjson object.
template <typename T, typename O, typename F>
bool CallWithMember(O obj, const char* member_name, F func) {
  auto it = obj.FindMember(member_name);
  if (it == obj.MemberEnd()) {
    return false;
  }
  if (!it->value.template Is<T>()) {
    return false;
  }
  func(it->value.template Get<T>());
  return true;
}
}  // namespace

namespace flutter_runner {

static constexpr char kFlutterPlatformChannel[] = "flutter/platform";
static constexpr char kAccessibilityChannel[] = "flutter/accessibility";
static constexpr char kFlutterPlatformViewsChannel[] = "flutter/platform_views";
static constexpr char kFuchsiaShaderWarmupChannel[] = "fuchsia/shader_warmup";
static constexpr char kFuchsiaInputTestChannel[] = "fuchsia/input_test";
static constexpr char kFuchsiaChildViewChannel[] = "fuchsia/child_view";

PlatformView::PlatformView(
    bool is_flatland,
    flutter::PlatformView::Delegate& delegate,
    flutter::TaskRunners task_runners,
    fuchsia::ui::views::ViewRef view_ref,
    std::shared_ptr<flutter::ExternalViewEmbedder> external_view_embedder,
    fuchsia::ui::input::ImeServiceHandle ime_service,
    fuchsia::ui::input3::KeyboardHandle keyboard,
    fuchsia::ui::pointer::TouchSourceHandle touch_source,
    fuchsia::ui::pointer::MouseSourceHandle mouse_source,
    fuchsia::ui::views::FocuserHandle focuser,
    fuchsia::ui::views::ViewRefFocusedHandle view_ref_focused,
    fuchsia::ui::pointerinjector::RegistryHandle pointerinjector_registry,
    OnEnableWireframe wireframe_enabled_callback,
    OnUpdateView on_update_view_callback,
    OnCreateSurface on_create_surface_callback,
    OnSemanticsNodeUpdate on_semantics_node_update_callback,
    OnRequestAnnounce on_request_announce_callback,
    OnShaderWarmup on_shader_warmup,
    AwaitVsyncCallback await_vsync_callback,
    AwaitVsyncForSecondaryCallbackCallback
        await_vsync_for_secondary_callback_callback,
    std::shared_ptr<sys::ServiceDirectory> dart_application_svc)
    : flutter::PlatformView(delegate, std::move(task_runners)),
      external_view_embedder_(external_view_embedder),
      focus_delegate_(
          std::make_shared<FocusDelegate>(std::move(view_ref_focused),
                                          std::move(focuser))),
      pointer_delegate_(
          std::make_shared<PointerDelegate>(std::move(touch_source),
                                            std::move(mouse_source))),
      wireframe_enabled_callback_(std::move(wireframe_enabled_callback)),
      on_update_view_callback_(std::move(on_update_view_callback)),
      on_create_surface_callback_(std::move(on_create_surface_callback)),
      on_semantics_node_update_callback_(
          std::move(on_semantics_node_update_callback)),
      on_request_announce_callback_(std::move(on_request_announce_callback)),
      on_shader_warmup_(std::move(on_shader_warmup)),
      await_vsync_callback_(await_vsync_callback),
      await_vsync_for_secondary_callback_callback_(
          await_vsync_for_secondary_callback_callback),
      dart_application_svc_(dart_application_svc),
      weak_factory_(this) {
  fuchsia::ui::views::ViewRef view_ref_clone;
  fidl::Clone(view_ref, &view_ref_clone);

  text_delegate_ =
      std::make_unique<TextDelegate>(
          std::move(view_ref), std::move(ime_service), std::move(keyboard),
          [weak = weak_factory_.GetWeakPtr()](
              std::unique_ptr<flutter::PlatformMessage> message) {
            if (!weak) {
              FML_LOG(WARNING)
                  << "PlatformView use-after-free attempted. Ignoring.";
            }
            weak->delegate_.OnPlatformViewDispatchPlatformMessage(
                std::move(message));
          });

  // Begin watching for focus changes.
  focus_delegate_->WatchLoop([weak = weak_factory_.GetWeakPtr()](bool focused) {
    if (!weak) {
      FML_LOG(WARNING) << "PlatformView use-after-free attempted. Ignoring.";
      return;
    }

    // Ensure last_text_state_ is set to make sure Flutter actually wants
    // an IME.
    if (focused && weak->text_delegate_->HasTextState()) {
      weak->text_delegate_->ActivateIme();
    } else if (!focused) {
      weak->text_delegate_->DeactivateIme();
    }
  });

  // Begin watching for pointer events.
  pointer_delegate_->WatchLoop([weak = weak_factory_.GetWeakPtr()](
                                   std::vector<flutter::PointerData> events) {
    if (!weak) {
      FML_LOG(WARNING) << "PlatformView use-after-free attempted. Ignoring.";
      return;
    }

    if (events.empty()) {
      return;  // No work, bounce out.
    }

    // If pixel ratio hasn't been set, use a default value of 1.
    const float pixel_ratio = weak->view_pixel_ratio_.value_or(1.f);
    auto packet = std::make_unique<flutter::PointerDataPacket>(events.size());
    for (size_t i = 0; i < events.size(); ++i) {
      auto& event = events[i];
      // Translate logical to physical coordinates, as per
      // flutter::PointerData contract. Done here because pixel ratio comes
      // from the graphics API.
      event.physical_x = event.physical_x * pixel_ratio;
      event.physical_y = event.physical_y * pixel_ratio;
      packet->SetPointerData(i, event);
    }
    weak->DispatchPointerDataPacket(std::move(packet));
  });

  // Configure the pointer injector delegate.
  pointer_injector_delegate_ = std::make_unique<PointerInjectorDelegate>(
      std::move(pointerinjector_registry), std::move(view_ref_clone),
      is_flatland);

  // This is only used by the integration tests.
  if (dart_application_svc) {
    // Connect to TouchInputListener
    fuchsia::ui::test::input::TouchInputListenerHandle touch_input_listener;
    zx_status_t touch_input_listener_status =
        dart_application_svc
            ->Connect<fuchsia::ui::test::input::TouchInputListener>(
                touch_input_listener.NewRequest());
    if (touch_input_listener_status != ZX_OK) {
      FML_LOG(WARNING)
          << "fuchsia::ui::test::input::TouchInputListener connection failed: "
          << zx_status_get_string(touch_input_listener_status);
    } else {
      touch_input_listener_.Bind(std::move(touch_input_listener));
    }

    // Connect to KeyboardInputListener
    fuchsia::ui::test::input::KeyboardInputListenerHandle
        keyboard_input_listener;
    zx_status_t keyboard_input_listener_status =
        dart_application_svc
            ->Connect<fuchsia::ui::test::input::KeyboardInputListener>(
                keyboard_input_listener.NewRequest());
    if (keyboard_input_listener_status != ZX_OK) {
      FML_LOG(WARNING) << "fuchsia::ui::test::input::KeyboardInputListener "
                          "connection failed: "
                       << zx_status_get_string(keyboard_input_listener_status);
    } else {
      keyboard_input_listener_.Bind(std::move(keyboard_input_listener));
    }
    // Connect to MouseInputListener
    fuchsia::ui::test::input::MouseInputListenerHandle mouse_input_listener;
    zx_status_t mouse_input_listener_status =
        dart_application_svc
            ->Connect<fuchsia::ui::test::input::MouseInputListener>(
                mouse_input_listener.NewRequest());
    if (mouse_input_listener_status != ZX_OK) {
      FML_LOG(WARNING)
          << "fuchsia::ui::test::input::MouseInputListener connection failed: "
          << zx_status_get_string(mouse_input_listener_status);
    } else {
      mouse_input_listener_.Bind(std::move(mouse_input_listener));
    }
  }

  // Finally! Register the native platform message handlers.
  RegisterPlatformMessageHandlers();
}

PlatformView::~PlatformView() = default;

void PlatformView::RegisterPlatformMessageHandlers() {
  platform_message_handlers_[kFlutterPlatformChannel] =
      std::bind(&PlatformView::HandleFlutterPlatformChannelPlatformMessage,
                this, std::placeholders::_1);
  platform_message_handlers_[kTextInputChannel] =
      std::bind(&TextDelegate::HandleFlutterTextInputChannelPlatformMessage,
                text_delegate_.get(), std::placeholders::_1);
  platform_message_handlers_[kAccessibilityChannel] =
      std::bind(&PlatformView::HandleAccessibilityChannelPlatformMessage, this,
                std::placeholders::_1);
  platform_message_handlers_[kFlutterPlatformViewsChannel] =
      std::bind(&PlatformView::HandleFlutterPlatformViewsChannelPlatformMessage,
                this, std::placeholders::_1);
  platform_message_handlers_[kFuchsiaShaderWarmupChannel] =
      std::bind(&HandleFuchsiaShaderWarmupChannelPlatformMessage,
                on_shader_warmup_, std::placeholders::_1);
  platform_message_handlers_[kFuchsiaInputTestChannel] =
      std::bind(&PlatformView::HandleFuchsiaInputTestChannelPlatformMessage,
                this, std::placeholders::_1);
  platform_message_handlers_[kFuchsiaChildViewChannel] =
      std::bind(&PlatformView::HandleFuchsiaChildViewChannelPlatformMessage,
                this, std::placeholders::_1);
}

static flutter::PointerData::Change GetChangeFromPointerEventPhase(
    fuchsia::ui::input::PointerEventPhase phase) {
  switch (phase) {
    case fuchsia::ui::input::PointerEventPhase::ADD:
      return flutter::PointerData::Change::kAdd;
    case fuchsia::ui::input::PointerEventPhase::HOVER:
      return flutter::PointerData::Change::kHover;
    case fuchsia::ui::input::PointerEventPhase::DOWN:
      return flutter::PointerData::Change::kDown;
    case fuchsia::ui::input::PointerEventPhase::MOVE:
      return flutter::PointerData::Change::kMove;
    case fuchsia::ui::input::PointerEventPhase::UP:
      return flutter::PointerData::Change::kUp;
    case fuchsia::ui::input::PointerEventPhase::REMOVE:
      return flutter::PointerData::Change::kRemove;
    case fuchsia::ui::input::PointerEventPhase::CANCEL:
      return flutter::PointerData::Change::kCancel;
    default:
      return flutter::PointerData::Change::kCancel;
  }
}

static flutter::PointerData::DeviceKind GetKindFromPointerType(
    fuchsia::ui::input::PointerEventType type) {
  switch (type) {
    case fuchsia::ui::input::PointerEventType::TOUCH:
      return flutter::PointerData::DeviceKind::kTouch;
    case fuchsia::ui::input::PointerEventType::MOUSE:
      return flutter::PointerData::DeviceKind::kMouse;
    default:
      return flutter::PointerData::DeviceKind::kTouch;
  }
}

// TODO(SCN-1278): Remove this.
// Turns two floats (high bits, low bits) into a 64-bit uint.
static trace_flow_id_t PointerTraceHACK(float fa, float fb) {
  uint32_t ia, ib;
  memcpy(&ia, &fa, sizeof(uint32_t));
  memcpy(&ib, &fb, sizeof(uint32_t));
  return (((uint64_t)ia) << 32) | ib;
}

// For certain scenarios that must avoid floating-point drift, compute a
// coordinate that falls within the logical view bounding box.
std::array<float, 2> PlatformView::ClampToViewSpace(const float x,
                                                    const float y) const {
  if (!view_logical_size_.has_value() || !view_logical_origin_.has_value()) {
    return {x, y};  // If we can't do anything, return the original values.
  }

  const auto origin = view_logical_origin_.value();
  const auto size = view_logical_size_.value();
  const float min_x = origin[0];
  const float max_x = origin[0] + size[0];
  const float min_y = origin[1];
  const float max_y = origin[1] + size[1];
  if (min_x <= x && x < max_x && min_y <= y && y < max_y) {
    return {x, y};  // No clamping to perform.
  }

  // View boundary is [min_x, max_x) x [min_y, max_y). Note that min is
  // inclusive, but max is exclusive - so we subtract epsilon.
  const float max_x_inclusive = max_x - std::numeric_limits<float>::epsilon();
  const float max_y_inclusive = max_y - std::numeric_limits<float>::epsilon();
  const float& clamped_x = std::clamp(x, min_x, max_x_inclusive);
  const float& clamped_y = std::clamp(y, min_y, max_y_inclusive);
  FML_LOG(INFO) << "Clamped (" << x << ", " << y << ") to (" << clamped_x
                << ", " << clamped_y << ").";
  return {clamped_x, clamped_y};
}

bool PlatformView::OnHandlePointerEvent(
    const fuchsia::ui::input::PointerEvent& pointer) {
  TRACE_EVENT0("flutter", "PlatformView::OnHandlePointerEvent");

  // TODO(SCN-1278): Use proper trace_id for tracing flow.
  trace_flow_id_t trace_id =
      PointerTraceHACK(pointer.radius_major, pointer.radius_minor);
  TRACE_FLOW_END("input", "dispatch_event_to_client", trace_id);

  const float pixel_ratio =
      view_pixel_ratio_.has_value() ? *view_pixel_ratio_ : 0.f;

  flutter::PointerData pointer_data;
  pointer_data.Clear();
  pointer_data.time_stamp = pointer.event_time / 1000;
  pointer_data.change = GetChangeFromPointerEventPhase(pointer.phase);
  pointer_data.kind = GetKindFromPointerType(pointer.type);
  pointer_data.device = pointer.pointer_id;
  // Pointer events are in logical pixels, so scale to physical.
  pointer_data.physical_x = pointer.x * pixel_ratio;
  pointer_data.physical_y = pointer.y * pixel_ratio;
  // Buttons are single bit values starting with kMousePrimaryButton = 1.
  pointer_data.buttons = static_cast<uint64_t>(pointer.buttons);

  switch (pointer_data.change) {
    case flutter::PointerData::Change::kDown: {
      // Make the pointer start in the view space, despite numerical drift.
      auto clamped_pointer = ClampToViewSpace(pointer.x, pointer.y);
      pointer_data.physical_x = clamped_pointer[0] * pixel_ratio;
      pointer_data.physical_y = clamped_pointer[1] * pixel_ratio;

      down_pointers_.insert(pointer_data.device);
      break;
    }
    case flutter::PointerData::Change::kCancel:
    case flutter::PointerData::Change::kUp:
      down_pointers_.erase(pointer_data.device);
      break;
    case flutter::PointerData::Change::kMove:
      if (down_pointers_.count(pointer_data.device) == 0) {
        pointer_data.change = flutter::PointerData::Change::kHover;
      }
      break;
    case flutter::PointerData::Change::kAdd:
      if (down_pointers_.count(pointer_data.device) != 0) {
        FML_LOG(ERROR) << "Received add event for down pointer.";
      }
      break;
    case flutter::PointerData::Change::kRemove:
      if (down_pointers_.count(pointer_data.device) != 0) {
        FML_LOG(ERROR) << "Received remove event for down pointer.";
      }
      break;
    case flutter::PointerData::Change::kHover:
      if (down_pointers_.count(pointer_data.device) != 0) {
        FML_LOG(ERROR) << "Received hover event for down pointer.";
      }
      break;
    case flutter::PointerData::Change::kPanZoomStart:
    case flutter::PointerData::Change::kPanZoomUpdate:
    case flutter::PointerData::Change::kPanZoomEnd:
      FML_DLOG(ERROR) << "Unexpectedly received pointer pan/zoom event";
      break;
  }

  auto packet = std::make_unique<flutter::PointerDataPacket>(1);
  packet->SetPointerData(0, pointer_data);
  DispatchPointerDataPacket(std::move(packet));
  return true;
}

// |flutter::PlatformView|
std::unique_ptr<flutter::VsyncWaiter> PlatformView::CreateVSyncWaiter() {
  return std::make_unique<flutter_runner::VsyncWaiter>(
      await_vsync_callback_, await_vsync_for_secondary_callback_callback_,
      task_runners_);
}

// |flutter::PlatformView|
std::unique_ptr<flutter::Surface> PlatformView::CreateRenderingSurface() {
  return on_create_surface_callback_ ? on_create_surface_callback_() : nullptr;
}

// |flutter::PlatformView|
std::shared_ptr<flutter::ExternalViewEmbedder>
PlatformView::CreateExternalViewEmbedder() {
  return external_view_embedder_;
}

// |flutter::PlatformView|
void PlatformView::HandlePlatformMessage(
    std::unique_ptr<flutter::PlatformMessage> message) {
  if (!message) {
    return;
  }
  const std::string channel = message->channel();
  auto found = platform_message_handlers_.find(channel);
  if (found == platform_message_handlers_.end()) {
    const bool already_errored = unregistered_channels_.count(channel);
    if (!already_errored) {
      FML_LOG(INFO)
          << "Platform view received message on channel '" << message->channel()
          << "' with no registered handler. An empty response will be "
             "generated. Please implement the native message handler. This "
             "message will appear only once per channel.";
      unregistered_channels_.insert(channel);
    }
    flutter::PlatformView::HandlePlatformMessage(std::move(message));
    return;
  }
  auto response = message->response();
  bool response_handled = found->second(std::move(message));

  // Ensure all responses are completed.
  if (response && !response_handled) {
    // response_handled should be true if the response was completed.
    FML_DCHECK(!response->is_complete());
    response->CompleteEmpty();
  }
}

// |flutter::PlatformView|
void PlatformView::SetSemanticsEnabled(bool enabled) {
  flutter::PlatformView::SetSemanticsEnabled(enabled);
  if (enabled) {
    SetAccessibilityFeatures(static_cast<int32_t>(
        flutter::AccessibilityFeatureFlag::kAccessibleNavigation));
  } else {
    SetAccessibilityFeatures(0);
  }
}

// |flutter::PlatformView|
void PlatformView::UpdateSemantics(
    flutter::SemanticsNodeUpdates update,
    flutter::CustomAccessibilityActionUpdates actions) {
  const float pixel_ratio =
      view_pixel_ratio_.has_value() ? *view_pixel_ratio_ : 0.f;

  on_semantics_node_update_callback_(update, pixel_ratio);
}

// Channel handler for kAccessibilityChannel
bool PlatformView::HandleAccessibilityChannelPlatformMessage(
    std::unique_ptr<flutter::PlatformMessage> message) {
  FML_DCHECK(message->channel() == kAccessibilityChannel);

  const flutter::StandardMessageCodec& standard_message_codec =
      flutter::StandardMessageCodec::GetInstance(nullptr);
  std::unique_ptr<flutter::EncodableValue> decoded =
      standard_message_codec.DecodeMessage(message->data().GetMapping(),
                                           message->data().GetSize());

  flutter::EncodableMap map = std::get<flutter::EncodableMap>(*decoded);
  std::string type =
      std::get<std::string>(map.at(flutter::EncodableValue("type")));
  if (type == "announce") {
    flutter::EncodableMap data_map = std::get<flutter::EncodableMap>(
        map.at(flutter::EncodableValue("data")));
    std::string text =
        std::get<std::string>(data_map.at(flutter::EncodableValue("message")));

    on_request_announce_callback_(text);
  }

  // Complete with an empty response.
  return false;
}

// Channel handler for kFlutterPlatformChannel
bool PlatformView::HandleFlutterPlatformChannelPlatformMessage(
    std::unique_ptr<flutter::PlatformMessage> message) {
  FML_DCHECK(message->channel() == kFlutterPlatformChannel);

  // Fuchsia does not handle any platform messages at this time.

  // Complete with an empty response.
  return false;
}

bool PlatformView::HandleFlutterPlatformViewsChannelPlatformMessage(
    std::unique_ptr<flutter::PlatformMessage> message) {
  FML_DCHECK(message->channel() == kFlutterPlatformViewsChannel);
  const auto& data = message->data();
  rapidjson::Document document;
  document.Parse(reinterpret_cast<const char*>(data.GetMapping()),
                 data.GetSize());
  if (document.HasParseError() || !document.IsObject()) {
    FML_LOG(ERROR) << "Could not parse document";
    return false;
  }
  auto root = document.GetObject();
  auto method_member = root.FindMember("method");
  if (method_member == root.MemberEnd() || !method_member->value.IsString()) {
    return false;
  }
  std::string method(method_member->value.GetString());

  if (method == "View.enableWireframe") {
    auto args_it = root.FindMember("args");
    if (args_it == root.MemberEnd() || !args_it->value.IsObject()) {
      FML_LOG(ERROR) << "No arguments found.";
      return false;
    }
    const auto& args = args_it->value;

    auto enable = args.FindMember("enable");
    if (!enable->value.IsBool()) {
      FML_LOG(ERROR) << "Argument 'enable' is not a bool";
      return false;
    }

    wireframe_enabled_callback_(enable->value.GetBool());
  } else if (method == "View.create") {
    auto args_it = root.FindMember("args");
    if (args_it == root.MemberEnd() || !args_it->value.IsObject()) {
      FML_LOG(ERROR) << "No arguments found.";
      return false;
    }
    const auto& args = args_it->value;

    auto view_id = args.FindMember("viewId");
    if (!view_id->value.IsUint64()) {
      FML_LOG(ERROR) << "Argument 'viewId' is not a int64";
      return false;
    }

    auto hit_testable = args.FindMember("hitTestable");
    if (!hit_testable->value.IsBool()) {
      FML_LOG(ERROR) << "Argument 'hitTestable' is not a bool";
      return false;
    }

    auto focusable = args.FindMember("focusable");
    if (!focusable->value.IsBool()) {
      FML_LOG(ERROR) << "Argument 'focusable' is not a bool";
      return false;
    }

    auto on_view_created = fml::MakeCopyable(
        [platform_task_runner = task_runners_.GetPlatformTaskRunner(),
         message = std::move(message)]() {
          // The client is waiting for view creation. Send an empty response
          // back to signal the view was created.
          if (message->response()) {
            message->response()->Complete(std::make_unique<fml::DataMapping>(
                std::vector<uint8_t>({'[', '0', ']'})));
          }
        });
    OnCreateView(std::move(on_view_created), view_id->value.GetUint64(),
                 hit_testable->value.GetBool(), focusable->value.GetBool());
    return true;
  } else if (method == "View.update") {
    auto args_it = root.FindMember("args");
    if (args_it == root.MemberEnd() || !args_it->value.IsObject()) {
      FML_LOG(ERROR) << "No arguments found.";
      return false;
    }
    const auto& args = args_it->value;

    auto view_id = args.FindMember("viewId");
    if (!view_id->value.IsUint64()) {
      FML_LOG(ERROR) << "Argument 'viewId' is not a int64";
      return false;
    }

    auto hit_testable = args.FindMember("hitTestable");
    if (!hit_testable->value.IsBool()) {
      FML_LOG(ERROR) << "Argument 'hitTestable' is not a bool";
      return false;
    }

    auto focusable = args.FindMember("focusable");
    if (!focusable->value.IsBool()) {
      FML_LOG(ERROR) << "Argument 'focusable' is not a bool";
      return false;
    }

    SkRect view_occlusion_hint_raw = SkRect::MakeEmpty();
    auto view_occlusion_hint = args.FindMember("viewOcclusionHintLTRB");
    if (view_occlusion_hint != args.MemberEnd()) {
      if (view_occlusion_hint->value.IsArray()) {
        const auto& view_occlusion_hint_array =
            view_occlusion_hint->value.GetArray();
        if (view_occlusion_hint_array.Size() == 4) {
          bool parse_error = false;
          for (int i = 0; i < 4; i++) {
            auto& array_val = view_occlusion_hint_array[i];
            if (!array_val.IsDouble()) {
              FML_LOG(ERROR) << "Argument 'viewOcclusionHintLTRB' element " << i
                             << " is not a double";
              parse_error = true;
              break;
            }
          }

          if (!parse_error) {
            view_occlusion_hint_raw =
                SkRect::MakeLTRB(view_occlusion_hint_array[0].GetDouble(),
                                 view_occlusion_hint_array[1].GetDouble(),
                                 view_occlusion_hint_array[2].GetDouble(),
                                 view_occlusion_hint_array[3].GetDouble());
          }
        } else {
          FML_LOG(ERROR)
              << "Argument 'viewOcclusionHintLTRB' expected size 4; got "
              << view_occlusion_hint_array.Size();
        }
      } else {
        FML_LOG(ERROR)
            << "Argument 'viewOcclusionHintLTRB' is not a double array";
      }
    } else {
      FML_LOG(WARNING) << "Argument 'viewOcclusionHintLTRB' is missing";
    }

    on_update_view_callback_(
        view_id->value.GetUint64(), view_occlusion_hint_raw,
        hit_testable->value.GetBool(), focusable->value.GetBool());
    if (message->response()) {
      message->response()->Complete(std::make_unique<fml::DataMapping>(
          std::vector<uint8_t>({'[', '0', ']'})));
      return true;
    }
  } else if (method == "View.dispose") {
    auto args_it = root.FindMember("args");
    if (args_it == root.MemberEnd() || !args_it->value.IsObject()) {
      FML_LOG(ERROR) << "No arguments found.";
      return false;
    }
    const auto& args = args_it->value;

    auto view_id = args.FindMember("viewId");
    if (!view_id->value.IsUint64()) {
      FML_LOG(ERROR) << "Argument 'viewId' is not a int64";
      return false;
    }

    OnDisposeView(view_id->value.GetUint64());
    if (message->response()) {
      message->response()->Complete(std::make_unique<fml::DataMapping>(
          std::vector<uint8_t>({'[', '0', ']'})));
      return true;
    }
  } else if (method.rfind("View.focus", 0) == 0) {
    return focus_delegate_->HandlePlatformMessage(root, message->response());
  } else if (method.rfind(PointerInjectorDelegate::kPointerInjectorMethodPrefix,
                          0) == 0) {
    return pointer_injector_delegate_->HandlePlatformMessage(
        root, message->response());
  } else {
    FML_LOG(ERROR) << "Unknown " << message->channel() << " method " << method;
  }
  // Complete with an empty response by default.
  return false;
}

bool PlatformView::HandleFuchsiaShaderWarmupChannelPlatformMessage(
    OnShaderWarmup on_shader_warmup,
    std::unique_ptr<flutter::PlatformMessage> message) {
  FML_DCHECK(message->channel() == kFuchsiaShaderWarmupChannel);

  if (!on_shader_warmup) {
    FML_LOG(ERROR) << "No shader warmup callback set!";
    std::string result = "[0]";
    message->response()->Complete(
        std::make_unique<fml::DataMapping>(std::vector<uint8_t>(
            (const uint8_t*)result.c_str(),
            (const uint8_t*)result.c_str() + result.length())));
    return true;
  }

  const auto& data = message->data();
  rapidjson::Document document;
  document.Parse(reinterpret_cast<const char*>(data.GetMapping()),
                 data.GetSize());
  if (document.HasParseError() || !document.IsObject()) {
    FML_LOG(ERROR) << "Could not parse document";
    return false;
  }
  auto root = document.GetObject();
  auto method = root.FindMember("method");
  if (method == root.MemberEnd() || !method->value.IsString() ||
      method->value != "WarmupSkps") {
    FML_LOG(ERROR) << "Invalid method name";
    return false;
  }

  auto args_it = root.FindMember("args");
  if (args_it == root.MemberEnd() || !args_it->value.IsObject()) {
    FML_LOG(ERROR) << "No arguments found.";
    return false;
  }

  auto shaders_it = root["args"].FindMember("shaders");
  if (shaders_it == root["args"].MemberEnd() || !shaders_it->value.IsArray()) {
    FML_LOG(ERROR) << "No shaders found.";
    return false;
  }

  auto width_it = root["args"].FindMember("width");
  auto height_it = root["args"].FindMember("height");
  if (width_it == root["args"].MemberEnd() || !width_it->value.IsNumber()) {
    FML_LOG(ERROR) << "Invalid width";
    return false;
  }
  if (height_it == root["args"].MemberEnd() || !height_it->value.IsNumber()) {
    FML_LOG(ERROR) << "Invalid height";
    return false;
  }
  auto width = width_it->value.GetUint64();
  auto height = height_it->value.GetUint64();

  std::vector<std::string> skp_paths;
  const auto& shaders = shaders_it->value;
  for (rapidjson::Value::ConstValueIterator itr = shaders.Begin();
       itr != shaders.End(); ++itr) {
    skp_paths.push_back((*itr).GetString());
  }

  auto completion_callback = [response =
                                  message->response()](uint32_t num_successes) {
    std::ostringstream result_stream;
    result_stream << "[" << num_successes << "]";

    std::string result(result_stream.str());

    response->Complete(std::make_unique<fml::DataMapping>(std::vector<uint8_t>(
        (const uint8_t*)result.c_str(),
        (const uint8_t*)result.c_str() + result.length())));
  };

  on_shader_warmup(skp_paths, completion_callback, width, height);
  // The response has already been completed by us.
  return true;
}

// Channel handler for kFuchsiaInputTestChannel
bool PlatformView::HandleFuchsiaInputTestChannelPlatformMessage(
    std::unique_ptr<flutter::PlatformMessage> message) {
  FML_DCHECK(message->channel() == kFuchsiaInputTestChannel);

  const auto& data = message->data();
  rapidjson::Document document;
  document.Parse(reinterpret_cast<const char*>(data.GetMapping()),
                 data.GetSize());
  if (document.HasParseError() || !document.IsObject()) {
    FML_LOG(ERROR) << "Could not parse document";
    return false;
  }
  auto root = document.GetObject();
  auto method = root.FindMember("method");
  if (method == root.MemberEnd() || !method->value.IsString()) {
    FML_LOG(ERROR) << "Missing method";
    return false;
  }

  FML_LOG(INFO) << "fuchsia/input_test: method=" << method->value.GetString();

  if (method->value == "TouchInputListener.ReportTouchInput") {
    if (!touch_input_listener_) {
      FML_LOG(ERROR) << "TouchInputListener not found.";
      return false;
    }

    fuchsia::ui::test::input::TouchInputListenerReportTouchInputRequest request;
    CallWithMember<double>(
        root, "local_x", [&](double local_x) { request.set_local_x(local_x); });
    CallWithMember<double>(
        root, "local_y", [&](double local_y) { request.set_local_y(local_y); });
    CallWithMember<int64_t>(root, "time_received", [&](uint64_t time_received) {
      request.set_time_received(time_received);
    });
    CallWithMember<std::string>(root, "component_name",
                                [&](std::string component_name) {
                                  request.set_component_name(component_name);
                                });

    touch_input_listener_->ReportTouchInput(std::move(request));
    return true;
  }

  if (method->value == "KeyboardInputListener.ReportTextInput") {
    if (!keyboard_input_listener_) {
      FML_LOG(ERROR) << "KeyboardInputListener not found.";
      return false;
    }

    fuchsia::ui::test::input::KeyboardInputListenerReportTextInputRequest
        request;
    CallWithMember<std::string>(
        root, "text", [&](std::string text) { request.set_text(text); });

    keyboard_input_listener_->ReportTextInput(std::move(request));
    return true;
  }

  if (method->value == "MouseInputListener.ReportMouseInput") {
    if (!mouse_input_listener_) {
      FML_LOG(ERROR) << "MouseInputListener not found.";
      return false;
    }

    fuchsia::ui::test::input::MouseInputListenerReportMouseInputRequest request;
    CallWithMember<double>(
        root, "local_x", [&](double local_x) { request.set_local_x(local_x); });
    CallWithMember<double>(
        root, "local_y", [&](double local_y) { request.set_local_y(local_y); });
    CallWithMember<int64_t>(root, "time_received", [&](uint64_t time_received) {
      request.set_time_received(time_received);
    });
    CallWithMember<std::string>(root, "component_name",
                                [&](std::string component_name) {
                                  request.set_component_name(component_name);
                                });
    CallWithMember<int>(root, "buttons", [&](int button_mask) {
      std::vector<fuchsia::ui::test::input::MouseButton> buttons;
      if (button_mask & 1) {
        buttons.push_back(fuchsia::ui::test::input::MouseButton::FIRST);
      }
      if (button_mask & 2) {
        buttons.push_back(fuchsia::ui::test::input::MouseButton::SECOND);
      }
      if (button_mask & 4) {
        buttons.push_back(fuchsia::ui::test::input::MouseButton::THIRD);
      }
      request.set_buttons(buttons);
    });
    CallWithMember<std::string>(root, "phase", [&](std::string phase) {
      if (phase == "add") {
        request.set_phase(fuchsia::ui::test::input::MouseEventPhase::ADD);
      } else if (phase == "hover") {
        request.set_phase(fuchsia::ui::test::input::MouseEventPhase::HOVER);
      } else if (phase == "down") {
        request.set_phase(fuchsia::ui::test::input::MouseEventPhase::DOWN);
      } else if (phase == "move") {
        request.set_phase(fuchsia::ui::test::input::MouseEventPhase::MOVE);
      } else if (phase == "up") {
        request.set_phase(fuchsia::ui::test::input::MouseEventPhase::UP);
      } else {
        FML_LOG(ERROR) << "Unexpected mouse phase: " << phase;
      }
    });
    CallWithMember<double>(
        root, "wheel_x_physical_pixel", [&](double wheel_x_physical_pixel) {
          request.set_wheel_x_physical_pixel(wheel_x_physical_pixel);
        });
    CallWithMember<double>(
        root, "wheel_y_physical_pixel", [&](double wheel_y_physical_pixel) {
          request.set_wheel_y_physical_pixel(wheel_y_physical_pixel);
        });

    mouse_input_listener_->ReportMouseInput(std::move(request));
    return true;
  }

  FML_LOG(ERROR) << "fuchsia/input_test: unrecognized method "
                 << method->value.GetString();
  return false;
}

// Channel handler for kFuchsiaChildViewChannel
bool PlatformView::HandleFuchsiaChildViewChannelPlatformMessage(
    std::unique_ptr<flutter::PlatformMessage> message) {
  FML_DCHECK(message->channel() == kFuchsiaChildViewChannel);

  if (message->data().GetSize() != 1 ||
      (message->data().GetMapping()[0] != '0' &&
       message->data().GetMapping()[0] != '1')) {
    FML_LOG(ERROR) << kFuchsiaChildViewChannel
                   << " data must be '0' (for gfx) or '1' (for flatland).";
    return false;
  }

  bool flatland = message->data().GetMapping()[0] == '1';

  if (!message->response()) {
    FML_LOG(ERROR) << kFuchsiaChildViewChannel
                   << " must have a response callback.";
    return false;
  }

  if (!dart_application_svc_) {
    FML_LOG(ERROR) << "No service directory.";
    return false;
  }

  fuchsia::ui::app::ViewProviderHandle view_provider_handle;
  zx_status_t status =
      dart_application_svc_->Connect(view_provider_handle.NewRequest());
  if (status != ZX_OK) {
    FML_LOG(ERROR) << "Failed to connect to view provider.";
    return false;
  }
  fuchsia::ui::app::ViewProviderPtr view_provider;
  view_provider.Bind(std::move(view_provider_handle));

  zx::handle view_id;

  if (flatland) {
    zx::channel view_tokens[2];
    fuchsia::ui::views::ViewportCreationToken viewport_creation_token;
    fuchsia::ui::views::ViewCreationToken view_creation_token;
    status = zx::channel::create(0, &viewport_creation_token.value,
                                 &view_creation_token.value);
    if (status != ZX_OK) {
      FML_LOG(ERROR) << "Creating view tokens: "
                     << zx_status_get_string(status);
      return false;
    }

    fuchsia::ui::app::CreateView2Args create_view_args;
    create_view_args.set_view_creation_token(std::move(view_creation_token));
    view_provider->CreateView2(std::move(create_view_args));

    view_id = std::move(viewport_creation_token.value);
  } else {
    zx::eventpair view_tokens[2];
    status = zx::eventpair::create(0, &view_tokens[0], &view_tokens[1]);
    if (status != ZX_OK) {
      FML_LOG(ERROR) << "Creating view tokens: "
                     << zx_status_get_string(status);
      return false;
    }
    fuchsia::ui::views::ViewHolderToken view_holder_token;
    view_holder_token.value = std::move(view_tokens[0]);

    zx::eventpair view_refs[2];
    status = zx::eventpair::create(0, &view_refs[0], &view_refs[1]);
    if (status != ZX_OK) {
      FML_LOG(ERROR) << "Creating view refs: " << zx_status_get_string(status);
      return false;
    }
    fuchsia::ui::views::ViewRefControl view_ref_control;
    view_refs[0].duplicate(ZX_DEFAULT_EVENTPAIR_RIGHTS & ~ZX_RIGHT_DUPLICATE,
                           &view_ref_control.reference);
    fuchsia::ui::views::ViewRef view_ref;
    view_refs[1].duplicate(ZX_RIGHTS_BASIC, &view_ref.reference);

    view_provider->CreateViewWithViewRef(std::move(view_tokens[1]),
                                         std::move(view_ref_control),
                                         std::move(view_ref));

    view_id = std::move(view_holder_token.value);
  }

  if (view_id) {
    message->response()->Complete(
        std::make_unique<fml::DataMapping>(std::to_string(view_id.release())

                                               ));
    return true;
  } else {
    return false;
  }
}

}  // namespace flutter_runner
