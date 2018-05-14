// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define RAPIDJSON_HAS_STDSTRING 1

#include "platform_view.h"

#include <sstream>

#include "flutter/lib/ui/window/pointer_data.h"
#include "lib/app/cpp/connect.h"
#include "third_party/rapidjson/rapidjson/document.h"
#include "third_party/rapidjson/rapidjson/stringbuffer.h"
#include "third_party/rapidjson/rapidjson/writer.h"
#include "vsync_waiter.h"

namespace flutter {

constexpr char kFlutterPlatformChannel[] = "flutter/platform";
constexpr char kTextInputChannel[] = "flutter/textinput";
constexpr char kKeyEventChannel[] = "flutter/keyevent";

template <class T>
void SetInterfaceErrorHandler(fidl::InterfacePtr<T>& interface,
                              std::string name) {
  interface.set_error_handler(
      [name]() { FXL_LOG(ERROR) << "Interface error on: " << name; });
}

PlatformView::PlatformView(
    PlatformView::Delegate& delegate,
    std::string debug_label,
    blink::TaskRunners task_runners,
    fidl::InterfaceHandle<component::ServiceProvider>
        parent_environment_service_provider_handle,
    fidl::InterfaceHandle<views_v1::ViewManager> view_manager_handle,
    fidl::InterfaceRequest<views_v1_token::ViewOwner> view_owner,
    zx::eventpair export_token,
    fidl::InterfaceHandle<modular::ContextWriter> accessibility_context_writer,
    zx_handle_t vsync_event_handle)
    : shell::PlatformView(delegate, std::move(task_runners)),
      debug_label_(std::move(debug_label)),
      view_manager_(view_manager_handle.Bind()),
      view_listener_(this),
      input_listener_(this),
      ime_client_(this),
      accessibility_bridge_(std::move(accessibility_context_writer)),
      surface_(std::make_unique<Surface>(debug_label_)),
      vsync_event_handle_(vsync_event_handle) {
  // Register all error handlers.
  SetInterfaceErrorHandler(view_manager_, "View Manager");
  SetInterfaceErrorHandler(view_, "View");
  SetInterfaceErrorHandler(input_connection_, "Input Connection");
  SetInterfaceErrorHandler(ime_, "Input Method Editor");
  SetInterfaceErrorHandler(clipboard_, "Clipboard");
  SetInterfaceErrorHandler(service_provider_, "Service Provider");
  SetInterfaceErrorHandler(parent_environment_service_provider_,
                           "Parent Environment Service Provider");

  // Create the view.
  view_manager_->CreateView(view_.NewRequest(),           // view
                            std::move(view_owner),        // view owner
                            view_listener_.NewBinding(),  // view listener
                            std::move(export_token),      // export token
                            debug_label_                  // diagnostic label
  );

  // Get the services from the created view.
  view_->GetServiceProvider(service_provider_.NewRequest());

  // Get the view conatiner. This will need to be returned to the isolate
  // configurator so that it can setup Mozart bindings later.
  view_->GetContainer(view_container_.NewRequest());

  // Get the input connection from the services of the view.
  component::ConnectToService(service_provider_.get(),
                              input_connection_.NewRequest());

  // Set the input listener on the input connection.
  input_connection_->SetEventListener(input_listener_.NewBinding());

  // Access the clipboard.
  parent_environment_service_provider_ =
      parent_environment_service_provider_handle.Bind();
  component::ConnectToService(parent_environment_service_provider_.get(),
                              clipboard_.NewRequest());

  // Finally! Register the native platform message handlers.
  RegisterPlatformMessageHandlers();
}

PlatformView::~PlatformView() = default;

void PlatformView::OfferServiceProvider(
    fidl::InterfaceHandle<component::ServiceProvider> service_provider,
    fidl::VectorPtr<fidl::StringPtr> services) {
  view_->OfferServiceProvider(std::move(service_provider), std::move(services));
}

void PlatformView::RegisterPlatformMessageHandlers() {
  platform_message_handlers_[kFlutterPlatformChannel] =
      std::bind(&PlatformView::HandleFlutterPlatformChannelPlatformMessage,  //
                this,                                                        //
                std::placeholders::_1);
  platform_message_handlers_[kTextInputChannel] =
      std::bind(&PlatformView::HandleFlutterTextInputChannelPlatformMessage,  //
                this,                                                         //
                std::placeholders::_1);
}

fidl::InterfaceHandle<views_v1::ViewContainer>
PlatformView::TakeViewContainer() {
  return std::move(view_container_);
}

// |views_v1::ViewListener|
void PlatformView::OnPropertiesChanged(views_v1::ViewProperties properties,
                                       OnPropertiesChangedCallback callback) {
  if (properties.view_layout) {
    UpdateViewportMetrics(*properties.view_layout);
  }
  callback();
}

void PlatformView::UpdateViewportMetrics(const views_v1::ViewLayout& layout) {
  metrics_.size.width = layout.size.width;
  metrics_.size.height = layout.size.height;
  metrics_.padding.left = layout.inset.left;
  metrics_.padding.top = layout.inset.top;
  metrics_.padding.right = layout.inset.right;
  metrics_.padding.bottom = layout.inset.bottom;

  FlushViewportMetrics();
}

void PlatformView::UpdateViewportMetrics(double pixel_ratio) {
  metrics_.scale = pixel_ratio;

  FlushViewportMetrics();
}

void PlatformView::FlushViewportMetrics() {
  const auto scale = metrics_.scale;
  blink::ViewportMetrics metrics = {
      .device_pixel_ratio = static_cast<float>(scale),

      .physical_width = static_cast<int32_t>(metrics_.size.width * scale),
      .physical_height = static_cast<int32_t>(metrics_.size.height * scale),

      .physical_padding_top =
          static_cast<int32_t>(metrics_.padding.top * scale),
      .physical_padding_right =
          static_cast<int32_t>(metrics_.padding.right * scale),
      .physical_padding_bottom =
          static_cast<int32_t>(metrics_.padding.bottom * scale),
      .physical_padding_left =
          static_cast<int32_t>(metrics_.padding.left * scale),

      .physical_view_inset_top =
          static_cast<int32_t>(metrics_.view_inset.top * scale),
      .physical_view_inset_right =
          static_cast<int32_t>(metrics_.view_inset.right * scale),
      .physical_view_inset_bottom =
          static_cast<int32_t>(metrics_.view_inset.bottom * scale),
      .physical_view_inset_left =
          static_cast<int32_t>(metrics_.view_inset.left * scale),
  };

  SetViewportMetrics(metrics);
}

// |input::InputMethodEditorClient|
void PlatformView::DidUpdateState(input::TextInputState state,
                                  std::unique_ptr<input::InputEvent>) {
  rapidjson::Document document;
  auto& allocator = document.GetAllocator();
  rapidjson::Value encoded_state(rapidjson::kObjectType);
  encoded_state.AddMember("text", state.text.get(), allocator);
  encoded_state.AddMember("selectionBase", state.selection.base, allocator);
  encoded_state.AddMember("selectionExtent", state.selection.extent, allocator);
  switch (state.selection.affinity) {
    case input::TextAffinity::UPSTREAM:
      encoded_state.AddMember("selectionAffinity",
                              rapidjson::Value("TextAffinity.upstream"),
                              allocator);
      break;
    case input::TextAffinity::DOWNSTREAM:
      encoded_state.AddMember("selectionAffinity",
                              rapidjson::Value("TextAffinity.downstream"),
                              allocator);
      break;
  }
  encoded_state.AddMember("selectionIsDirectional", true, allocator);
  encoded_state.AddMember("composingBase", state.composing.start, allocator);
  encoded_state.AddMember("composingExtent", state.composing.end, allocator);

  rapidjson::Value args(rapidjson::kArrayType);
  args.PushBack(current_text_input_client_, allocator);
  args.PushBack(encoded_state, allocator);

  document.SetObject();
  document.AddMember("method",
                     rapidjson::Value("TextInputClient.updateEditingState"),
                     allocator);
  document.AddMember("args", args, allocator);

  rapidjson::StringBuffer buffer;
  rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
  document.Accept(writer);

  const uint8_t* data = reinterpret_cast<const uint8_t*>(buffer.GetString());
  DispatchPlatformMessage(fxl::MakeRefCounted<blink::PlatformMessage>(
      kTextInputChannel,                                    // channel
      std::vector<uint8_t>(data, data + buffer.GetSize()),  // message
      nullptr)                                              // response
  );
}

// |input::InputMethodEditorClient|
void PlatformView::OnAction(input::InputMethodAction action) {
  rapidjson::Document document;
  auto& allocator = document.GetAllocator();

  rapidjson::Value args(rapidjson::kArrayType);
  args.PushBack(current_text_input_client_, allocator);

  // Done is currently the only text input action defined by Flutter.
  args.PushBack("TextInputAction.done", allocator);

  document.SetObject();
  document.AddMember(
      "method", rapidjson::Value("TextInputClient.performAction"), allocator);
  document.AddMember("args", args, allocator);

  rapidjson::StringBuffer buffer;
  rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
  document.Accept(writer);

  const uint8_t* data = reinterpret_cast<const uint8_t*>(buffer.GetString());
  DispatchPlatformMessage(fxl::MakeRefCounted<blink::PlatformMessage>(
      kTextInputChannel,                                    // channel
      std::vector<uint8_t>(data, data + buffer.GetSize()),  // message
      nullptr)                                              // response
  );
}

// |input::InputListener|
void PlatformView::OnEvent(input::InputEvent event, OnEventCallback callback) {
  using Type = input::InputEvent::Tag;
  switch (event.Which()) {
    case Type::kPointer:
      callback(OnHandlePointerEvent(event.pointer()));
      return;
    case Type::kKeyboard:
      callback(OnHandleKeyboardEvent(event.keyboard()));
      return;
    case Type::kFocus:
      callback(OnHandleFocusEvent(event.focus()));
      return;
    default:
      break;
  }

  callback(false);
}

static blink::PointerData::Change GetChangeFromPointerEventPhase(
    input::PointerEventPhase phase) {
  switch (phase) {
    case input::PointerEventPhase::ADD:
      return blink::PointerData::Change::kAdd;
    case input::PointerEventPhase::HOVER:
      return blink::PointerData::Change::kHover;
    case input::PointerEventPhase::DOWN:
      return blink::PointerData::Change::kDown;
    case input::PointerEventPhase::MOVE:
      return blink::PointerData::Change::kMove;
    case input::PointerEventPhase::UP:
      return blink::PointerData::Change::kUp;
    case input::PointerEventPhase::REMOVE:
      return blink::PointerData::Change::kRemove;
    case input::PointerEventPhase::CANCEL:
      return blink::PointerData::Change::kCancel;
    default:
      return blink::PointerData::Change::kCancel;
  }
}

static blink::PointerData::DeviceKind GetKindFromPointerType(
    input::PointerEventType type) {
  switch (type) {
    case input::PointerEventType::TOUCH:
      return blink::PointerData::DeviceKind::kTouch;
    case input::PointerEventType::MOUSE:
      return blink::PointerData::DeviceKind::kMouse;
    default:
      return blink::PointerData::DeviceKind::kTouch;
  }
}

bool PlatformView::OnHandlePointerEvent(const input::PointerEvent& pointer) {
  blink::PointerData pointer_data;
  pointer_data.time_stamp = pointer.event_time / 1000;
  pointer_data.change = GetChangeFromPointerEventPhase(pointer.phase);
  pointer_data.kind = GetKindFromPointerType(pointer.type);
  pointer_data.device = pointer.pointer_id;
  pointer_data.physical_x = pointer.x * metrics_.scale;
  pointer_data.physical_y = pointer.y * metrics_.scale;
  // Buttons are single bit values starting with kMousePrimaryButton = 1.
  pointer_data.buttons = static_cast<uint64_t>(pointer.buttons);

  switch (pointer_data.change) {
    case blink::PointerData::Change::kDown:
      down_pointers_.insert(pointer_data.device);
      break;
    case blink::PointerData::Change::kCancel:
    case blink::PointerData::Change::kUp:
      down_pointers_.erase(pointer_data.device);
      break;
    case blink::PointerData::Change::kMove:
      if (down_pointers_.count(pointer_data.device) == 0) {
        pointer_data.change = blink::PointerData::Change::kHover;
      }
      break;
    case blink::PointerData::Change::kAdd:
      if (down_pointers_.count(pointer_data.device) != 0) {
        FXL_DLOG(ERROR) << "Received add event for down pointer.";
      }
      break;
    case blink::PointerData::Change::kRemove:
      if (down_pointers_.count(pointer_data.device) != 0) {
        FXL_DLOG(ERROR) << "Received remove event for down pointer.";
      }
      break;
    case blink::PointerData::Change::kHover:
      if (down_pointers_.count(pointer_data.device) != 0) {
        FXL_DLOG(ERROR) << "Received hover event for down pointer.";
      }
      break;
  }

  auto packet = std::make_unique<blink::PointerDataPacket>(1);
  packet->SetPointerData(0, pointer_data);
  DispatchPointerDataPacket(std::move(packet));
  return true;
}

bool PlatformView::OnHandleKeyboardEvent(const input::KeyboardEvent& keyboard) {
  const char* type = nullptr;
  if (keyboard.phase == input::KeyboardEventPhase::PRESSED) {
    type = "keydown";
  } else if (keyboard.phase == input::KeyboardEventPhase::REPEAT) {
    type = "keydown";  // TODO change this to keyrepeat
  } else if (keyboard.phase == input::KeyboardEventPhase::RELEASED) {
    type = "keyup";
  }

  if (type == nullptr) {
    FXL_DLOG(ERROR) << "Unknown key event phase.";
    return false;
  }

  rapidjson::Document document;
  auto& allocator = document.GetAllocator();
  document.SetObject();
  document.AddMember("type", rapidjson::Value(type, strlen(type)), allocator);
  document.AddMember("keymap", rapidjson::Value("fuchsia"), allocator);
  document.AddMember("hidUsage", keyboard.hid_usage, allocator);
  document.AddMember("codePoint", keyboard.code_point, allocator);
  document.AddMember("modifiers", keyboard.modifiers, allocator);
  rapidjson::StringBuffer buffer;
  rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
  document.Accept(writer);

  const uint8_t* data = reinterpret_cast<const uint8_t*>(buffer.GetString());
  DispatchPlatformMessage(fxl::MakeRefCounted<blink::PlatformMessage>(
      kKeyEventChannel,                                     // channel
      std::vector<uint8_t>(data, data + buffer.GetSize()),  // data
      nullptr)                                              // response
  );

  return true;
}

bool PlatformView::OnHandleFocusEvent(const input::FocusEvent& focus) {
  if (!focus.focused && current_text_input_client_ != 0) {
    current_text_input_client_ = 0;
    if (ime_) {
      ime_->Hide();
      ime_ = nullptr;
    }
    if (ime_client_.is_bound()) {
      ime_client_.Unbind();
    }
    return true;
  }
  return false;
}

// |shell::PlatformView|
std::unique_ptr<shell::VsyncWaiter> PlatformView::CreateVSyncWaiter() {
  return std::make_unique<flutter::VsyncWaiter>(
      debug_label_, vsync_event_handle_, task_runners_);
}

// |shell::PlatformView|
std::unique_ptr<shell::Surface> PlatformView::CreateRenderingSurface() {
  // This platform does not repeatly lose and gain a surface connection. So the
  // surface is setup once during platform view setup and and returned to the
  // shell on the initial (and only) |NotifyCreated| call.
  return std::move(surface_);
}

// |shell::PlatformView|
void PlatformView::HandlePlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  if (!message) {
    return;
  }
  auto found = platform_message_handlers_.find(message->channel());
  if (found == platform_message_handlers_.end()) {
    FXL_DLOG(ERROR)
        << "Platform view received message on channel '" << message->channel()
        << "' with no registed handler. And empty response will be generated. "
           "Please implement the native message handler.";
    PlatformView::HandlePlatformMessage(std::move(message));
    return;
  }
  found->second(std::move(message));
}

// |shell::PlatformView|
void PlatformView::UpdateSemantics(blink::SemanticsNodeUpdates update) {
  accessibility_bridge_.UpdateSemantics(update);
}

// Channel handler for kFlutterPlatformChannel
void PlatformView::HandleFlutterPlatformChannelPlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  FXL_DCHECK(message->channel() == kFlutterPlatformChannel);
  const auto& data = message->data();
  rapidjson::Document document;
  document.Parse(reinterpret_cast<const char*>(data.data()), data.size());
  if (document.HasParseError() || !document.IsObject()) {
    return;
  }

  auto root = document.GetObject();
  auto method = root.FindMember("method");
  if (method == root.MemberEnd() || !method->value.IsString()) {
    return;
  }

  fxl::RefPtr<blink::PlatformMessageResponse> response = message->response();
  if (method->value == "Clipboard.setData") {
    auto text = root["args"]["text"].GetString();
    clipboard_->Push(text);
    response->CompleteEmpty();
  } else if (method->value == "Clipboard.getData") {
    clipboard_->Peek([response](fidl::StringPtr text) {
      rapidjson::StringBuffer json_buffer;
      rapidjson::Writer<rapidjson::StringBuffer> writer(json_buffer);
      writer.StartArray();
      writer.StartObject();
      writer.Key("text");
      writer.String(text.get());
      writer.EndObject();
      writer.EndArray();
      std::string result = json_buffer.GetString();
      response->Complete(std::vector<uint8_t>{result.begin(), result.end()});
    });
  } else {
    response->CompleteEmpty();
  }
}

// Channel handler for kTextInputChannel
void PlatformView::HandleFlutterTextInputChannelPlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  FXL_DCHECK(message->channel() == kTextInputChannel);
  const auto& data = message->data();
  rapidjson::Document document;
  document.Parse(reinterpret_cast<const char*>(data.data()), data.size());
  if (document.HasParseError() || !document.IsObject()) {
    return;
  }
  auto root = document.GetObject();
  auto method = root.FindMember("method");
  if (method == root.MemberEnd() || !method->value.IsString()) {
    return;
  }

  if (method->value == "TextInput.show") {
    if (ime_) {
      ime_->Show();
    }
  } else if (method->value == "TextInput.hide") {
    if (ime_) {
      ime_->Hide();
    }
  } else if (method->value == "TextInput.setClient") {
    current_text_input_client_ = 0;
    if (ime_client_.is_bound())
      ime_client_.Unbind();
    ime_ = nullptr;

    auto args = root.FindMember("args");
    if (args == root.MemberEnd() || !args->value.IsArray() ||
        args->value.Size() != 2)
      return;
    const auto& configuration = args->value[1];
    if (!configuration.IsObject()) {
      return;
    }
    // TODO(abarth): Read the keyboard type from the configuration.
    current_text_input_client_ = args->value[0].GetInt();

    auto initial_text_input_state = input::TextInputState{};
    initial_text_input_state.text = "";
    input_connection_->GetInputMethodEditor(
        input::KeyboardType::TEXT,       // keyboard type
        input::InputMethodAction::DONE,  // input method action
        initial_text_input_state,        // initial state
        ime_client_.NewBinding(),        // client
        ime_.NewRequest()                // editor
    );
  } else if (method->value == "TextInput.setEditingState") {
    if (ime_) {
      auto args_it = root.FindMember("args");
      if (args_it == root.MemberEnd() || !args_it->value.IsObject()) {
        return;
      }
      const auto& args = args_it->value;
      input::TextInputState state;
      state.text = "";
      // TODO(abarth): Deserialize state.
      auto text = args.FindMember("text");
      if (text != args.MemberEnd() && text->value.IsString())
        state.text = text->value.GetString();
      auto selection_base = args.FindMember("selectionBase");
      if (selection_base != args.MemberEnd() && selection_base->value.IsInt())
        state.selection.base = selection_base->value.GetInt();
      auto selection_extent = args.FindMember("selectionExtent");
      if (selection_extent != args.MemberEnd() &&
          selection_extent->value.IsInt())
        state.selection.extent = selection_extent->value.GetInt();
      auto selection_affinity = args.FindMember("selectionAffinity");
      if (selection_affinity != args.MemberEnd() &&
          selection_affinity->value.IsString() &&
          selection_affinity->value == "TextAffinity.upstream")
        state.selection.affinity = input::TextAffinity::UPSTREAM;
      else
        state.selection.affinity = input::TextAffinity::DOWNSTREAM;
      // We ignore selectionIsDirectional because that concept doesn't exist on
      // Fuchsia.
      auto composing_base = args.FindMember("composingBase");
      if (composing_base != args.MemberEnd() && composing_base->value.IsInt())
        state.composing.start = composing_base->value.GetInt();
      auto composing_extent = args.FindMember("composingExtent");
      if (composing_extent != args.MemberEnd() &&
          composing_extent->value.IsInt())
        state.composing.end = composing_extent->value.GetInt();
      ime_->SetState(std::move(state));
    }
  } else if (method->value == "TextInput.clearClient") {
    current_text_input_client_ = 0;
    if (ime_client_.is_bound())
      ime_client_.Unbind();
    ime_ = nullptr;
  } else {
    FXL_DLOG(ERROR) << "Unknown " << message->channel() << " method "
                    << method->value.GetString();
  }
}

}  // namespace flutter
