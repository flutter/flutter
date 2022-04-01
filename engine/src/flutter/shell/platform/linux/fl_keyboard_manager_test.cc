// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_keyboard_manager.h"

#include <cstring>
#include <vector>

#include "flutter/shell/platform/linux/testing/mock_text_input_plugin.h"
#include "gtest/gtest.h"

namespace {
typedef void (*CallbackHandler)(FlKeyResponderAsyncCallback callback,
                                gpointer user_data);

// Hardware key codes.
constexpr guint16 kKeyCodeKeyA = 0x26u;
constexpr guint16 kKeyCodeKeyB = 0x38u;

typedef std::function<void(bool handled)> AsyncKeyCallback;
typedef struct _FlKeyMockResponder FlKeyMockResponder;

class CallRecord {
 public:
  CallRecord(FlKeyMockResponder* responder,
             FlKeyEvent* event,
             FlKeyResponderAsyncCallback callback,
             gpointer user_data)
      : responder(responder),
        event(event),
        callback(callback == nullptr ? AsyncKeyCallback()
                                     : [callback, user_data](bool handled) {
                                         callback(handled, user_data);
                                       }) {}

  CallRecord(CallRecord&& origin)
      : responder(origin.responder),
        event(origin.event),
        callback(std::move(origin.callback)) {
    origin.event = nullptr;
  }

  ~CallRecord() {
    if (event != nullptr) {
      fl_key_event_dispose(event);
    }
  }

  FlKeyMockResponder* responder;
  FlKeyEvent* event;
  AsyncKeyCallback callback;
};

#define FL_TYPE_KEY_MOCK_RESPONDER fl_key_mock_responder_get_type()
G_DECLARE_FINAL_TYPE(FlKeyMockResponder,
                     fl_key_mock_responder,
                     FL,
                     KEY_MOCK_RESPONDER,
                     GObject);

struct _FlKeyMockResponder {
  GObject parent_instance;

  std::vector<CallRecord>* call_records;
  CallbackHandler callback_handler;
  int delegate_id;
};

static void dont_respond(FlKeyResponderAsyncCallback callback,
                         gpointer user_data) {}
static void respond_true(FlKeyResponderAsyncCallback callback,
                         gpointer user_data) {
  callback(true, user_data);
}
static void respond_false(FlKeyResponderAsyncCallback callback,
                          gpointer user_data) {
  callback(false, user_data);
}

static gboolean filter_keypress_returns_true(FlTextInputPlugin* self,
                                             FlKeyEvent* event) {
  return TRUE;
}

static gboolean filter_keypress_returns_false(FlTextInputPlugin* self,
                                              FlKeyEvent* event) {
  return FALSE;
}

/***** FlKeyMockResponder *****/

static void fl_key_mock_responder_iface_init(FlKeyResponderInterface* iface);

G_DEFINE_TYPE_WITH_CODE(FlKeyMockResponder,
                        fl_key_mock_responder,
                        G_TYPE_OBJECT,
                        G_IMPLEMENT_INTERFACE(FL_TYPE_KEY_RESPONDER,
                                              fl_key_mock_responder_iface_init))

static void fl_key_mock_responder_handle_event(
    FlKeyResponder* responder,
    FlKeyEvent* event,
    FlKeyResponderAsyncCallback callback,
    gpointer user_data);

static void fl_key_mock_responder_iface_init(FlKeyResponderInterface* iface) {
  iface->handle_event = fl_key_mock_responder_handle_event;
}

/***** End FlKeyMockResponder *****/

// Return a newly allocated #FlKeyEvent that is a clone to the given #event
// but with #origin and #dispose set to 0.
static FlKeyEvent* fl_key_event_clone_information_only(FlKeyEvent* event) {
  FlKeyEvent* new_event = fl_key_event_clone(event);
  new_event->origin = nullptr;
  new_event->dispose_origin = nullptr;
  return new_event;
}
static void fl_key_mock_responder_handle_event(
    FlKeyResponder* responder,
    FlKeyEvent* event,
    FlKeyResponderAsyncCallback callback,
    gpointer user_data) {
  FlKeyMockResponder* self = FL_KEY_MOCK_RESPONDER(responder);
  self->call_records->push_back(CallRecord(
      self, fl_key_event_clone_information_only(event), callback, user_data));
  self->callback_handler(callback, user_data);
}

static void fl_key_mock_responder_class_init(FlKeyMockResponderClass* klass) {}

static void fl_key_mock_responder_init(FlKeyMockResponder* self) {}

static FlKeyMockResponder* fl_key_mock_responder_new(
    std::vector<CallRecord>* call_records,
    int delegate_id) {
  FlKeyMockResponder* self = FL_KEY_MOCK_RESPONDER(
      g_object_new(fl_key_mock_responder_get_type(), nullptr));
  g_return_val_if_fail(FL_IS_KEY_MOCK_RESPONDER(self), nullptr);

  self->call_records = call_records;
  self->callback_handler = dont_respond;
  self->delegate_id = delegate_id;

  return self;
}

static void fl_key_event_free_origin_by_mock(gpointer origin) {
  g_free(origin);
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
  event->dispose_origin = fl_key_event_free_origin_by_mock;
  return event;
}

class KeyboardTester {
 public:
  explicit KeyboardTester(FlTextInputPlugin* text_input_plugin) {
    manager_ = fl_keyboard_manager_new(
        text_input_plugin, [this](std::unique_ptr<FlKeyEvent> event) {
          if (real_redispatcher_ != nullptr) {
            real_redispatcher_(std::move(event));
          }
        });
  }

  ~KeyboardTester() { g_clear_object(&manager_); }

  FlKeyboardManager* manager() { return manager_; }

  void recordRedispatchedEventsTo(
      std::vector<std::unique_ptr<FlKeyEvent>>& storage) {
    real_redispatcher_ = [&storage](std::unique_ptr<FlKeyEvent> event) {
      storage.push_back(std::move(event));
    };
  }

 private:
  FlKeyboardManager* manager_;
  FlKeyboardManagerRedispatcher real_redispatcher_;
};

// Make sure that the keyboard can be disposed without crashes when there are
// unresolved pending events.
TEST(FlKeyboardManagerTest, DisposeWithUnresolvedPends) {
  KeyboardTester tester(nullptr);
  std::vector<CallRecord> call_records;

  FlKeyMockResponder* responder = fl_key_mock_responder_new(&call_records, 1);
  fl_keyboard_manager_add_responder(tester.manager(),
                                    FL_KEY_RESPONDER(responder));

  responder->callback_handler = dont_respond;
  fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(true, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));

  responder->callback_handler = respond_true;
  fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(false, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));

  // Passes if the cleanup does not crash.
}

TEST(FlKeyboardManagerTest, SingleDelegateWithAsyncResponds) {
  KeyboardTester tester(nullptr);
  std::vector<CallRecord> call_records;
  std::vector<std::unique_ptr<FlKeyEvent>> redispatched;

  gboolean manager_handled = false;
  fl_keyboard_manager_add_responder(
      tester.manager(),
      FL_KEY_RESPONDER(fl_key_mock_responder_new(&call_records, 1)));

  /// Test 1: One event that is handled by the framework
  tester.recordRedispatchedEventsTo(redispatched);

  // Dispatch a key event
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(true, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));
  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(redispatched.size(), 0u);
  EXPECT_EQ(call_records.size(), 1u);
  EXPECT_EQ(call_records[0].responder->delegate_id, 1);
  EXPECT_EQ(call_records[0].event->keyval, 0x61u);
  EXPECT_EQ(call_records[0].event->keycode, 0x26u);

  call_records[0].callback(true);
  EXPECT_EQ(redispatched.size(), 0u);

  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
  call_records.clear();

  /// Test 2: Two events that are unhandled by the framework
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(false, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));
  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(redispatched.size(), 0u);
  EXPECT_EQ(call_records.size(), 1u);
  EXPECT_EQ(call_records[0].responder->delegate_id, 1);
  EXPECT_EQ(call_records[0].event->keyval, 0x61u);
  EXPECT_EQ(call_records[0].event->keycode, 0x26u);

  // Dispatch another key event
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(true, GDK_KEY_b, kKeyCodeKeyB, 0x0, false));
  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(redispatched.size(), 0u);
  EXPECT_EQ(call_records.size(), 2u);
  EXPECT_EQ(call_records[1].responder->delegate_id, 1);
  EXPECT_EQ(call_records[1].event->keyval, 0x62u);
  EXPECT_EQ(call_records[1].event->keycode, 0x38u);

  // Resolve the second event first to test out-of-order response
  call_records[1].callback(false);
  EXPECT_EQ(redispatched.size(), 1u);
  EXPECT_EQ(redispatched[0]->keyval, 0x62u);
  call_records[0].callback(false);
  EXPECT_EQ(redispatched.size(), 2u);
  EXPECT_EQ(redispatched[1]->keyval, 0x61u);

  call_records.clear();

  // Resolve redispatches
  manager_handled = fl_keyboard_manager_handle_event(tester.manager(),
                                                     redispatched[0].release());
  EXPECT_EQ(manager_handled, false);
  manager_handled = fl_keyboard_manager_handle_event(tester.manager(),
                                                     redispatched[1].release());
  EXPECT_EQ(manager_handled, false);
  EXPECT_EQ(call_records.size(), 0u);

  redispatched.clear();
  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));

  /// Test 3: Dispatch the same event again to ensure that prevention from
  /// redispatching only works once.
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(false, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));
  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(redispatched.size(), 0u);
  EXPECT_EQ(call_records.size(), 1u);

  call_records[0].callback(true);

  redispatched.clear();
  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
}

TEST(FlKeyboardManagerTest, SingleDelegateWithSyncResponds) {
  KeyboardTester tester(nullptr);
  std::vector<CallRecord> call_records;
  std::vector<std::unique_ptr<FlKeyEvent>> redispatched;

  gboolean manager_handled = false;
  FlKeyMockResponder* responder = fl_key_mock_responder_new(&call_records, 1);
  fl_keyboard_manager_add_responder(tester.manager(),
                                    FL_KEY_RESPONDER(responder));

  /// Test 1: One event that is handled by the framework
  tester.recordRedispatchedEventsTo(redispatched);

  // Dispatch a key event
  responder->callback_handler = respond_true;
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(true, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));
  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(call_records.size(), 1u);
  EXPECT_EQ(call_records[0].responder->delegate_id, 1);
  EXPECT_EQ(call_records[0].event->keyval, 0x61u);
  EXPECT_EQ(call_records[0].event->keycode, 0x26u);
  EXPECT_EQ(redispatched.size(), 0u);

  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
  call_records.clear();

  /// Test 2: An event unhandled by the framework
  responder->callback_handler = respond_false;
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(false, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));
  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(call_records.size(), 1u);
  EXPECT_EQ(call_records[0].responder->delegate_id, 1);
  EXPECT_EQ(call_records[0].event->keyval, 0x61u);
  EXPECT_EQ(call_records[0].event->keycode, 0x26u);
  EXPECT_EQ(redispatched.size(), 1u);

  call_records.clear();

  // Resolve redispatch
  manager_handled = fl_keyboard_manager_handle_event(tester.manager(),
                                                     redispatched[0].release());
  EXPECT_EQ(manager_handled, false);
  EXPECT_EQ(call_records.size(), 0u);

  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
  redispatched.clear();
}

TEST(FlKeyboardManagerTest, WithTwoAsyncDelegates) {
  KeyboardTester tester(nullptr);
  std::vector<CallRecord> call_records;
  std::vector<std::unique_ptr<FlKeyEvent>> redispatched;

  gboolean manager_handled = false;
  fl_keyboard_manager_add_responder(
      tester.manager(),
      FL_KEY_RESPONDER(fl_key_mock_responder_new(&call_records, 1)));
  fl_keyboard_manager_add_responder(
      tester.manager(),
      FL_KEY_RESPONDER(fl_key_mock_responder_new(&call_records, 2)));

  tester.recordRedispatchedEventsTo(redispatched);

  /// Test 1: One delegate responds true, the other false

  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(true, GDK_KEY_a, kKeyCodeKeyA, 0x0, false));

  EXPECT_EQ(manager_handled, true);
  EXPECT_EQ(redispatched.size(), 0u);
  EXPECT_EQ(call_records.size(), 2u);
  EXPECT_EQ(call_records[0].responder->delegate_id, 1);
  EXPECT_EQ(call_records[0].event->keyval, 0x61u);
  EXPECT_EQ(call_records[1].responder->delegate_id, 2);
  EXPECT_EQ(call_records[1].event->keyval, 0x61u);

  call_records[0].callback(true);
  call_records[1].callback(false);
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

  call_records[0].callback(false);
  EXPECT_EQ(redispatched.size(), 0u);
  call_records[1].callback(false);
  EXPECT_EQ(redispatched.size(), 1u);

  call_records.clear();

  // Resolve redispatch
  manager_handled = fl_keyboard_manager_handle_event(tester.manager(),
                                                     redispatched[0].release());
  EXPECT_EQ(manager_handled, false);
  EXPECT_EQ(call_records.size(), 0u);

  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
  call_records.clear();

  redispatched.clear();
}

TEST(FlKeyboardManagerTest, TextInputPluginReturnsFalse) {
  // The text input plugin doesn't handle events.
  KeyboardTester tester(FL_TEXT_INPUT_PLUGIN(
      fl_mock_text_input_plugin_new(filter_keypress_returns_false)));
  std::vector<CallRecord> call_records;
  std::vector<std::unique_ptr<FlKeyEvent>> redispatched;

  gboolean manager_handled = false;
  tester.recordRedispatchedEventsTo(redispatched);

  // The responder never handles events.
  FlKeyMockResponder* responder = fl_key_mock_responder_new(&call_records, 1);
  fl_keyboard_manager_add_responder(tester.manager(),
                                    FL_KEY_RESPONDER(responder));
  responder->callback_handler = respond_false;

  // Dispatch a key event.
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(true, GDK_KEY_a, kKeyCodeKeyA, 0, false));
  EXPECT_EQ(manager_handled, true);
  // The event was redispatched because no one handles it.
  EXPECT_EQ(redispatched.size(), 1u);

  // Resolve redispatched event.
  manager_handled = fl_keyboard_manager_handle_event(tester.manager(),
                                                     redispatched[0].release());
  EXPECT_EQ(manager_handled, false);

  redispatched.clear();
  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
}

TEST(FlKeyboardManagerTest, TextInputPluginReturnsTrue) {
  KeyboardTester tester(FL_TEXT_INPUT_PLUGIN(
      fl_mock_text_input_plugin_new(filter_keypress_returns_true)));
  std::vector<CallRecord> call_records;
  std::vector<std::unique_ptr<FlKeyEvent>> redispatched;

  gboolean manager_handled = false;
  tester.recordRedispatchedEventsTo(redispatched);

  // The responder never handles events.
  FlKeyMockResponder* responder = fl_key_mock_responder_new(&call_records, 1);
  fl_keyboard_manager_add_responder(tester.manager(),
                                    FL_KEY_RESPONDER(responder));
  responder->callback_handler = respond_false;

  // Dispatch a key event.
  manager_handled = fl_keyboard_manager_handle_event(
      tester.manager(),
      fl_key_event_new_by_mock(true, GDK_KEY_a, kKeyCodeKeyA, 0, false));
  EXPECT_EQ(manager_handled, true);
  // The event was not redispatched because text input plugin handles it.
  EXPECT_EQ(redispatched.size(), 0u);

  EXPECT_TRUE(fl_keyboard_manager_is_state_clear(tester.manager()));
}

}  // namespace
