// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_keyboard_manager.h"

#include <cstring>
#include <vector>

#include "flutter/shell/platform/embedder/test_utils/key_codes.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_json_message_codec.h"
#include "flutter/shell/platform/linux/testing/mock_text_input_plugin.h"
#include "gtest/gtest.h"

// Define compound `expect` in macros. If they were defined in functions, the
// stacktrace wouldn't print where the function is called in the unit tests.

#define EXPECT_KEY_EVENT(EVENT, TYPE, PHYSICAL, LOGICAL, CHAR, SYNTHESIZED) \
  EXPECT_EQ((EVENT)->type, (TYPE));                                         \
  EXPECT_EQ((EVENT)->physical, (PHYSICAL));                                 \
  EXPECT_EQ((EVENT)->logical, (LOGICAL));                                   \
  EXPECT_STREQ((EVENT)->character, (CHAR));                                 \
  EXPECT_EQ((EVENT)->synthesized, (SYNTHESIZED));

namespace {
using ::flutter::testing::keycodes::kLogicalKeyA;
using ::flutter::testing::keycodes::kLogicalKeyB;
using ::flutter::testing::keycodes::kPhysicalKeyA;
using ::flutter::testing::keycodes::kPhysicalKeyB;

// Hardware key codes.
typedef std::function<void(bool handled)> AsyncKeyCallback;
typedef std::function<void(AsyncKeyCallback callback)> ChannelCallHandler;
typedef std::function<void(const FlutterKeyEvent* event,
                           AsyncKeyCallback callback)>
    EmbedderCallHandler;
typedef std::function<void(std::unique_ptr<FlKeyEvent>)> RedispatchHandler;

// A type that can record all kinds of effects that the keyboard manager
// triggers.
//
// An instance of `CallRecord` might not have all the fields filled.
typedef struct {
  enum {
    kKeyCallEmbedder,
    kKeyCallChannel,
  } type;

  AsyncKeyCallback callback;
  std::unique_ptr<FlutterKeyEvent> event;
  std::unique_ptr<char[]> event_character;
} CallRecord;

// Clone a C-string.
//
// Must be deleted by delete[].
char* cloneString(const char* source) {
  if (source == nullptr) {
    return nullptr;
  }
  size_t charLen = strlen(source);
  char* target = new char[charLen + 1];
  strncpy(target, source, charLen + 1);
  return target;
}

constexpr guint16 kKeyCodeKeyA = 0x26u;
constexpr guint16 kKeyCodeKeyB = 0x38u;

static constexpr char kKeyEventChannelName[] = "flutter/keyevent";

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlMockViewDelegate,
                     fl_mock_view_delegate,
                     FL,
                     MOCK_VIEW_DELEGATE,
                     GObject);

G_DECLARE_FINAL_TYPE(FlMockKeyBinaryMessenger,
                     fl_mock_key_binary_messenger,
                     FL,
                     MOCK_KEY_BINARY_MESSENGER,
                     GObject)

G_END_DECLS

/***** FlMockKeyBinaryMessenger *****/
/* Mock a binary messenger that only processes messages from the embedding on
 * the key event channel, and does so according to the callback set by
 * fl_mock_key_binary_messenger_set_callback_handler */

struct _FlMockKeyBinaryMessenger {
  GObject parent_instance;

  ChannelCallHandler callback_handler;
};

static void fl_mock_key_binary_messenger_iface_init(
    FlBinaryMessengerInterface* iface);

G_DEFINE_TYPE_WITH_CODE(
    FlMockKeyBinaryMessenger,
    fl_mock_key_binary_messenger,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(fl_binary_messenger_get_type(),
                          fl_mock_key_binary_messenger_iface_init))

static void fl_mock_key_binary_messenger_class_init(
    FlMockKeyBinaryMessengerClass* klass) {}

static void fl_mock_key_binary_messenger_send_on_channel(
    FlBinaryMessenger* messenger,
    const gchar* channel,
    GBytes* message,
    GCancellable* cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data) {
  FlMockKeyBinaryMessenger* self = FL_MOCK_KEY_BINARY_MESSENGER(messenger);

  if (callback != nullptr) {
    EXPECT_STREQ(channel, kKeyEventChannelName);
    self->callback_handler([self, cancellable, callback,
                            user_data](bool handled) {
      g_autoptr(GTask) task =
          g_task_new(self, cancellable, callback, user_data);
      g_autoptr(FlValue) result = fl_value_new_map();
      fl_value_set_string_take(result, "handled", fl_value_new_bool(handled));
      g_autoptr(FlJsonMessageCodec) codec = fl_json_message_codec_new();
      g_autoptr(GError) error = nullptr;
      GBytes* data = fl_message_codec_encode_message(FL_MESSAGE_CODEC(codec),
                                                     result, &error);

      g_task_return_pointer(task, data,
                            reinterpret_cast<GDestroyNotify>(g_bytes_unref));
    });
  }
}

static GBytes* fl_mock_key_binary_messenger_send_on_channel_finish(
    FlBinaryMessenger* messenger,
    GAsyncResult* result,
    GError** error) {
  return static_cast<GBytes*>(g_task_propagate_pointer(G_TASK(result), error));
}

static void fl_mock_key_binary_messenger_iface_init(
    FlBinaryMessengerInterface* iface) {
  iface->set_message_handler_on_channel =
      [](FlBinaryMessenger* messenger, const gchar* channel,
         FlBinaryMessengerMessageHandler handler, gpointer user_data,
         GDestroyNotify destroy_notify) {
        EXPECT_STREQ(channel, kKeyEventChannelName);
        // No need to mock. The key event channel expects no incoming messages
        // from the framework.
      };
  iface->send_response = [](FlBinaryMessenger* messenger,
                            FlBinaryMessengerResponseHandle* response_handle,
                            GBytes* response, GError** error) -> gboolean {
    // The key event channel expects no incoming messages from the framework,
    // hence no responses either.
    g_return_val_if_reached(TRUE);
    return TRUE;
  };
  iface->send_on_channel = fl_mock_key_binary_messenger_send_on_channel;
  iface->send_on_channel_finish =
      fl_mock_key_binary_messenger_send_on_channel_finish;
}

static void fl_mock_key_binary_messenger_init(FlMockKeyBinaryMessenger* self) {}

static FlMockKeyBinaryMessenger* fl_mock_key_binary_messenger_new() {
  FlMockKeyBinaryMessenger* self = FL_MOCK_KEY_BINARY_MESSENGER(
      g_object_new(fl_mock_key_binary_messenger_get_type(), NULL));

  // Added to stop compiler complaining about an unused function.
  FL_IS_MOCK_KEY_BINARY_MESSENGER(self);

  return self;
}

static void fl_mock_key_binary_messenger_set_callback_handler(
    FlMockKeyBinaryMessenger* self,
    ChannelCallHandler handler) {
  self->callback_handler = std::move(handler);
}

/***** FlMockViewDelegate *****/

struct _FlMockViewDelegate {
  GObject parent_instance;

  FlMockKeyBinaryMessenger* messenger;
  EmbedderCallHandler embedder_handler;
  bool text_filter_result;
  RedispatchHandler redispatch_handler;
};

static void fl_mock_view_keyboard_delegate_iface_init(
    FlKeyboardViewDelegateInterface* iface);

G_DEFINE_TYPE_WITH_CODE(
    FlMockViewDelegate,
    fl_mock_view_delegate,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(fl_keyboard_view_delegate_get_type(),
                          fl_mock_view_keyboard_delegate_iface_init))

static void fl_mock_view_delegate_init(FlMockViewDelegate* self) {}

static void fl_mock_view_delegate_dispose(GObject* object) {
  FlMockViewDelegate* self = FL_MOCK_VIEW_DELEGATE(object);

  g_clear_object(&self->messenger);

  G_OBJECT_CLASS(fl_mock_view_delegate_parent_class)->dispose(object);
}

static void fl_mock_view_delegate_class_init(FlMockViewDelegateClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_mock_view_delegate_dispose;
}

static FlKeyEvent* fl_key_event_clone_information_only(FlKeyEvent* event);

static void fl_mock_view_keyboard_send_key_event(
    FlKeyboardViewDelegate* view_delegate,
    const FlutterKeyEvent* event,
    FlutterKeyEventCallback callback,
    void* user_data) {
  FlMockViewDelegate* self = FL_MOCK_VIEW_DELEGATE(view_delegate);
  self->embedder_handler(event, [callback, user_data](bool handled) {
    if (callback != nullptr) {
      callback(handled, user_data);
    }
  });
}

static gboolean fl_mock_view_keyboard_text_filter_key_press(
    FlKeyboardViewDelegate* view_delegate,
    FlKeyEvent* event) {
  FlMockViewDelegate* self = FL_MOCK_VIEW_DELEGATE(view_delegate);
  return self->text_filter_result;
}

static FlBinaryMessenger* fl_mock_view_keyboard_get_messenger(
    FlKeyboardViewDelegate* view_delegate) {
  FlMockViewDelegate* self = FL_MOCK_VIEW_DELEGATE(view_delegate);
  return FL_BINARY_MESSENGER(self->messenger);
}

static void fl_mock_view_keyboard_redispatch_event(
    FlKeyboardViewDelegate* view_delegate,
    std::unique_ptr<FlKeyEvent> event) {
  FlMockViewDelegate* self = FL_MOCK_VIEW_DELEGATE(view_delegate);
  if (self->redispatch_handler) {
    self->redispatch_handler(std::move(event));
  }
}

static void fl_mock_view_keyboard_delegate_iface_init(
    FlKeyboardViewDelegateInterface* iface) {
  iface->send_key_event = fl_mock_view_keyboard_send_key_event;
  iface->text_filter_key_press = fl_mock_view_keyboard_text_filter_key_press;
  iface->get_messenger = fl_mock_view_keyboard_get_messenger;
  iface->redispatch_event = fl_mock_view_keyboard_redispatch_event;
}

static FlMockViewDelegate* fl_mock_view_delegate_new() {
  FlMockViewDelegate* self = FL_MOCK_VIEW_DELEGATE(
      g_object_new(fl_mock_view_delegate_get_type(), nullptr));

  // Added to stop compiler complaining about an unused function.
  FL_IS_MOCK_VIEW_DELEGATE(self);

  self->messenger = fl_mock_key_binary_messenger_new();

  return self;
}

static void fl_mock_view_set_embedder_handler(FlMockViewDelegate* self,
                                              EmbedderCallHandler handler) {
  self->embedder_handler = std::move(handler);
}

static void fl_mock_view_set_text_filter_result(FlMockViewDelegate* self,
                                                bool result) {
  self->text_filter_result = result;
}

static void fl_mock_view_set_redispatch_handler(FlMockViewDelegate* self,
                                                RedispatchHandler handler) {
  self->redispatch_handler = std::move(handler);
}

/***** End FlMockViewDelegate *****/

// Return a newly allocated #FlKeyEvent that is a clone to the given #event
// but with #origin and #dispose set to 0.
static FlKeyEvent* fl_key_event_clone_information_only(FlKeyEvent* event) {
  FlKeyEvent* new_event = fl_key_event_clone(event);
  new_event->origin = nullptr;
  new_event->dispose_origin = nullptr;
  return new_event;
}

// Create a new #FlKeyEvent with the given information.
//
// The #origin will be another #FlKeyEvent with the exact information,
// so that it can be used to redispatch, and is freed upon disposal.
static FlKeyEvent* fl_key_event_new_by_mock(bool is_press,
                                            guint keyval,
                                            guint16 keycode,
                                            int state,
                                            gboolean is_modifier) {
  FlKeyEvent* event = g_new(FlKeyEvent, 1);
  event->is_press = is_press;
  event->time = 0;
  event->state = state;
  event->keyval = keyval;
  event->string = nullptr;
  event->keycode = keycode;
  FlKeyEvent* origin_event = fl_key_event_clone_information_only(event);
  event->origin = origin_event;
  event->dispose_origin = [](gpointer origin) { g_free(origin); };
  return event;
}

class KeyboardTester {
 public:
  KeyboardTester() {
    view_ = fl_mock_view_delegate_new();
    respondToEmbedderCallsWith(false);
    respondToChannelCallsWith(false);
    respondToTextInputWith(false);

    manager_ = fl_keyboard_manager_new(FL_KEYBOARD_VIEW_DELEGATE(view_));
  }

  ~KeyboardTester() {
    g_clear_object(&view_);
    g_clear_object(&manager_);
  }

  FlKeyboardManager* manager() { return manager_; }

  // Block until all GdkMainLoop messages are processed, which is basically
  // used only for channel messages.
  void flushChannelMessages() {
    GMainLoop* loop = g_main_loop_new(nullptr, 0);
    g_idle_add(_flushChannelMessagesCb, loop);
    g_main_loop_run(loop);
  }

  // Dispatch each of the given events, expect their results to be false
  // (unhandled), and clear the event array.
  //
  // Returns the number of events redispatched. If any result is unexpected
  // (handled), return a minus number `-x` instead, where `x` is the index of
  // the first unexpected redispatch.
  int redispatchEventsAndClear(
      std::vector<std::unique_ptr<FlKeyEvent>>& events) {
    size_t event_count = events.size();
    int first_error = -1;
    during_redispatch_ = true;
    for (size_t event_id = 0; event_id < event_count; event_id += 1) {
      bool handled = fl_keyboard_manager_handle_event(
          manager_, events[event_id].release());
      EXPECT_FALSE(handled);
      if (handled) {
        first_error = first_error == -1 ? event_id : first_error;
      }
    }
    during_redispatch_ = false;
    events.clear();
    return first_error < 0 ? event_count : -first_error;
  }

  void respondToEmbedderCallsWith(bool response) {
    fl_mock_view_set_embedder_handler(
        view_, [response, this](const FlutterKeyEvent* event,
                                AsyncKeyCallback callback) {
          EXPECT_FALSE(during_redispatch_);
          callback(response);
        });
  }

  void recordEmbedderCallsTo(std::vector<CallRecord>& storage) {
    fl_mock_view_set_embedder_handler(
        view_, [&storage, this](const FlutterKeyEvent* event,
                                AsyncKeyCallback callback) {
          EXPECT_FALSE(during_redispatch_);
          auto new_event = std::make_unique<FlutterKeyEvent>(*event);
          char* new_event_character = cloneString(event->character);
          new_event->character = new_event_character;
          storage.push_back(CallRecord{
              .type = CallRecord::kKeyCallEmbedder,
              .callback = std::move(callback),
              .event = std::move(new_event),
              .event_character = std::unique_ptr<char[]>(new_event_character),
          });
        });
  }

  void respondToEmbedderCallsWithAndRecordsTo(
      bool response,
      std::vector<CallRecord>& storage) {
    fl_mock_view_set_embedder_handler(
        view_, [&storage, response, this](const FlutterKeyEvent* event,
                                          AsyncKeyCallback callback) {
          EXPECT_FALSE(during_redispatch_);
          auto new_event = std::make_unique<FlutterKeyEvent>(*event);
          char* new_event_character = cloneString(event->character);
          new_event->character = new_event_character;
          storage.push_back(CallRecord{
              .type = CallRecord::kKeyCallEmbedder,
              .event = std::move(new_event),
              .event_character = std::unique_ptr<char[]>(new_event_character),
          });
          callback(response);
        });
  }

  void respondToChannelCallsWith(bool response) {
    fl_mock_key_binary_messenger_set_callback_handler(
        view_->messenger, [response, this](AsyncKeyCallback callback) {
          EXPECT_FALSE(during_redispatch_);
          callback(response);
        });
  }

  void recordChannelCallsTo(std::vector<CallRecord>& storage) {
    fl_mock_key_binary_messenger_set_callback_handler(
        view_->messenger, [&storage, this](AsyncKeyCallback callback) {
          EXPECT_FALSE(during_redispatch_);
          storage.push_back(CallRecord{
              .type = CallRecord::kKeyCallChannel,
              .callback = std::move(callback),
          });
        });
  }

  void respondToTextInputWith(bool response) {
    fl_mock_view_set_text_filter_result(view_, response);
  }

  void recordRedispatchedEventsTo(
      std::vector<std::unique_ptr<FlKeyEvent>>& storage) {
    fl_mock_view_set_redispatch_handler(
        view_, [&storage](std::unique_ptr<FlKeyEvent> key) {
          storage.push_back(std::move(key));
        });
  }

 private:
  FlMockViewDelegate* view_;
  FlKeyboardManager* manager_;
  bool during_redispatch_ = false;

  static gboolean _flushChannelMessagesCb(gpointer data) {
    g_autoptr(GMainLoop) loop = reinterpret_cast<GMainLoop*>(data);
    g_main_loop_quit(loop);
    return FALSE;
  }
};

// Make sure that the keyboard can be disposed without crashes when there are
// unresolved pending events.
TEST(FlKeyboardManagerTest, DisposeWithUnresolvedPends) {
  KeyboardTester tester;
  std::vector<CallRecord> call_records;

  // Record calls so that they aren't responded.
  tester.recordEmbedderCallsTo(call_records);
  fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(true, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));

  tester.respondToEmbedderCallsWith(true);
  fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(false, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));

  tester.flushChannelMessages();

  // Passes if the cleanup does not crash.
}

TEST(FlKeyboardManagerTest, SingleDelegateWithAsyncResponds) {
  KeyboardTester tester;
  std::vector<CallRecord> call_records;
  std::vector<std::unique_ptr<FlKeyEvent>> redispatched;

  gboolean manager_handled = false;

  /// Test 1: One event that is handled by the framework
  tester.recordEmbedderCallsTo(call_records);
  tester.recordRedispatchedEventsTo(redispatched);

  // Dispatch a key event
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(true, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));
  tester.flushChannelMessages();
  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(redispatched.size(), 0u);
  EXPECT_EQ(call_records.size(), 1u);
  EXPECT_KEY_EVENT(call_records[0].event, kFlutterKeyEventTypeDown,
                   kPhysicalKeyA, kLogicalKeyA, "a", false);

  call_records[0].callback(true);
  tester.flushChannelMessages();
  EXPECT_EQ(redispatched.size(), 0u);
  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
  call_records.clear();

  /// Test 2: Two events that are unhandled by the framework
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(false, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));
  tester.flushChannelMessages();
  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(redispatched.size(), 0u);
  EXPECT_EQ(call_records.size(), 1u);
  EXPECT_KEY_EVENT(call_records[0].event, kFlutterKeyEventTypeUp, kPhysicalKeyA,
                   kLogicalKeyA, nullptr, false);

  // Dispatch another key event
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(true, GDK_KEY_b, kKeyCodeKeyB, 0x0, false));
  tester.flushChannelMessages();
  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(redispatched.size(), 0u);
  EXPECT_EQ(call_records.size(), 2u);
  EXPECT_KEY_EVENT(call_records[1].event, kFlutterKeyEventTypeDown,
                   kPhysicalKeyB, kLogicalKeyB, "b", false);

  // Resolve the second event first to test out-of-order response
  call_records[1].callback(false);
  EXPECT_EQ(redispatched.size(), 1u);
  EXPECT_EQ(redispatched[0]->keyval, 0x62u);
  call_records[0].callback(false);
  tester.flushChannelMessages();
  EXPECT_EQ(redispatched.size(), 2u);
  EXPECT_EQ(redispatched[1]->keyval, 0x61u);

  EXPECT_FALSE(fl_keyboard_manager_is_state_clear(tester.manager()));
  call_records.clear();

  // Resolve redispatches
  EXPECT_EQ(tester.redispatchEventsAndClear(redispatched), 2);
  tester.flushChannelMessages();
  EXPECT_EQ(call_records.size(), 0u);
  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));

  /// Test 3: Dispatch the same event again to ensure that prevention from
  /// redispatching only works once.
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(false, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));
  tester.flushChannelMessages();
  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(redispatched.size(), 0u);
  EXPECT_EQ(call_records.size(), 1u);

  call_records[0].callback(true);
  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
}

TEST(FlKeyboardManagerTest, SingleDelegateWithSyncResponds) {
  KeyboardTester tester;
  gboolean manager_handled = false;
  std::vector<CallRecord> call_records;
  std::vector<std::unique_ptr<FlKeyEvent>> redispatched;

  /// Test 1: One event that is handled by the framework
  tester.respondToEmbedderCallsWithAndRecordsTo(true, call_records);
  tester.recordRedispatchedEventsTo(redispatched);

  // Dispatch a key event
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(true, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));
  tester.flushChannelMessages();
  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(call_records.size(), 1u);
  EXPECT_KEY_EVENT(call_records[0].event, kFlutterKeyEventTypeDown,
                   kPhysicalKeyA, kLogicalKeyA, "a", false);
  EXPECT_EQ(redispatched.size(), 0u);
  call_records.clear();

  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
  redispatched.clear();

  /// Test 2: An event unhandled by the framework
  tester.respondToEmbedderCallsWithAndRecordsTo(false, call_records);
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(false, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));
  tester.flushChannelMessages();
  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(call_records.size(), 1u);
  EXPECT_KEY_EVENT(call_records[0].event, kFlutterKeyEventTypeUp, kPhysicalKeyA,
                   kLogicalKeyA, nullptr, false);
  EXPECT_EQ(redispatched.size(), 1u);
  call_records.clear();

  EXPECT_FALSE(fl_keyboard_manager_is_state_clear(tester.manager()));

  EXPECT_EQ(tester.redispatchEventsAndClear(redispatched), 1);
  EXPECT_EQ(call_records.size(), 0u);

  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
}

TEST(FlKeyboardManagerTest, WithTwoAsyncDelegates) {
  KeyboardTester tester;
  std::vector<CallRecord> call_records;
  std::vector<std::unique_ptr<FlKeyEvent>> redispatched;

  gboolean manager_handled = false;

  tester.recordEmbedderCallsTo(call_records);
  tester.recordChannelCallsTo(call_records);
  tester.recordRedispatchedEventsTo(redispatched);

  /// Test 1: One delegate responds true, the other false

  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(true, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));

  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(redispatched.size(), 0u);
  EXPECT_EQ(call_records.size(), 2u);

  EXPECT_EQ(call_records[0].type, CallRecord::kKeyCallEmbedder);
  EXPECT_EQ(call_records[1].type, CallRecord::kKeyCallChannel);

  call_records[0].callback(true);
  call_records[1].callback(false);
  tester.flushChannelMessages();
  EXPECT_EQ(redispatched.size(), 0u);

  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
  call_records.clear();

  /// Test 2: All delegates respond false
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(false, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));

  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(redispatched.size(), 0u);
  EXPECT_EQ(call_records.size(), 2u);

  EXPECT_EQ(call_records[0].type, CallRecord::kKeyCallEmbedder);
  EXPECT_EQ(call_records[1].type, CallRecord::kKeyCallChannel);

  call_records[0].callback(false);
  call_records[1].callback(false);

  call_records.clear();

  // Resolve redispatch
  tester.flushChannelMessages();
  EXPECT_EQ(redispatched.size(), 1u);
  EXPECT_EQ(tester.redispatchEventsAndClear(redispatched), 1);
  EXPECT_EQ(call_records.size(), 0u);

  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
}

TEST(FlKeyboardManagerTest, TextInputPluginReturnsFalse) {
  KeyboardTester tester;
  std::vector<std::unique_ptr<FlKeyEvent>> redispatched;
  gboolean manager_handled = false;
  tester.recordRedispatchedEventsTo(redispatched);
  tester.respondToTextInputWith(false);

  // Dispatch a key event.
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(true, GDK_KEY_a, kKeyCodeKeyA, 0, false));
  tester.flushChannelMessages();
  EXPECT_EQ(manager_handled, true);
  // The event was redispatched because no one handles it.
  EXPECT_EQ(redispatched.size(), 1u);

  // Resolve redispatched event.
  EXPECT_EQ(tester.redispatchEventsAndClear(redispatched), 1);

  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
}

TEST(FlKeyboardManagerTest, TextInputPluginReturnsTrue) {
  KeyboardTester tester;
  std::vector<std::unique_ptr<FlKeyEvent>> redispatched;
  gboolean manager_handled = false;
  tester.recordRedispatchedEventsTo(redispatched);
  tester.respondToTextInputWith(true);

  // Dispatch a key event.
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(true, GDK_KEY_a, kKeyCodeKeyA, 0, false));
  tester.flushChannelMessages();
  EXPECT_EQ(manager_handled, true);
  // The event was not redispatched because text input plugin handles it.
  EXPECT_EQ(redispatched.size(), 0u);

  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
}

}  // namespace
