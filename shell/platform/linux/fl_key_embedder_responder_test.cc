// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_key_embedder_responder.h"

#include "gtest/gtest.h"

#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"

namespace {
constexpr gboolean kRelease = FALSE;
constexpr gboolean kPress = TRUE;

constexpr gboolean kIsModifier = TRUE;
constexpr gboolean kIsNotModifier = FALSE;

constexpr guint16 kKeyCodeKeyA = 0x26u;
constexpr guint16 kKeyCodeShiftRight = 0x3Eu;
constexpr guint16 kKeyCodeNumpad1 = 0x57u;
constexpr guint16 kKeyCodeNumLock = 0x4Du;
constexpr guint16 kKeyCodeCapsLock = 0x42u;
constexpr guint16 kKeyCodeControlLeft = 0x25u;
constexpr guint16 kKeyCodeControlRight = 0x69u;

constexpr uint64_t kPhysicalKeyA = 0x00070004;
constexpr uint64_t kPhysicalControlLeft = 0x000700e0;
constexpr uint64_t kPhysicalShiftRight = 0x000700E5;
constexpr uint64_t kPhysicalNumpad1 = 0x00070059;
constexpr uint64_t kPhysicalNumLock = 0x00070053;
constexpr uint64_t kPhysicalCapsLock = 0x00070039;

constexpr uint64_t kLogicalKeyA = 0x00000061;
constexpr uint64_t kLogicalKeyQ = 0x00000071;
constexpr uint64_t kLogicalControlLeft = 0x30000000105;
constexpr uint64_t kLogicalShiftRight = 0x4000000010D;
constexpr uint64_t kLogicalNumpad1 = 0x50000000031;
constexpr uint64_t kLogicalNumLock = 0x100000010A;
constexpr uint64_t kLogicalCapsLock = 0x1000000104;
}  // namespace

static void g_ptr_array_clear(GPtrArray* array) {
  g_ptr_array_remove_range(array, 0, array->len);
}

G_DECLARE_FINAL_TYPE(FlKeyEmbedderCallRecord,
                     fl_key_embedder_call_record,
                     FL,
                     KEY_EMBEDDER_CALL_RECORD,
                     GObject);

struct _FlKeyEmbedderCallRecord {
  GObject parent_instance;

  FlutterKeyEvent* event;
  FlutterKeyEventCallback callback;
  gpointer user_data;
};

G_DEFINE_TYPE(FlKeyEmbedderCallRecord,
              fl_key_embedder_call_record,
              G_TYPE_OBJECT)

static void fl_key_embedder_call_record_init(FlKeyEmbedderCallRecord* self) {}

// Dispose method for FlKeyEmbedderCallRecord.
static void fl_key_embedder_call_record_dispose(GObject* object) {
  g_return_if_fail(FL_IS_KEY_EMBEDDER_CALL_RECORD(object));

  FlKeyEmbedderCallRecord* self = FL_KEY_EMBEDDER_CALL_RECORD(object);
  if (self->event != nullptr) {
    g_free(const_cast<char*>(self->event->character));
    g_free(self->event);
  }
  G_OBJECT_CLASS(fl_key_embedder_call_record_parent_class)->dispose(object);
}

// Class Initialization method for FlKeyEmbedderCallRecord class.
static void fl_key_embedder_call_record_class_init(
    FlKeyEmbedderCallRecordClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_key_embedder_call_record_dispose;
}

static FlKeyEmbedderCallRecord* fl_key_embedder_call_record_new(
    const FlutterKeyEvent* event,
    FlutterKeyEventCallback callback,
    gpointer user_data) {
  g_return_val_if_fail(event != nullptr, nullptr);

  FlKeyEmbedderCallRecord* self = FL_KEY_EMBEDDER_CALL_RECORD(
      g_object_new(fl_key_embedder_call_record_get_type(), nullptr));

  FlutterKeyEvent* clone_event = g_new(FlutterKeyEvent, 1);
  *clone_event = *event;
  if (event->character != nullptr) {
    size_t character_length = strlen(event->character);
    char* clone_character = g_new(char, character_length + 1);
    strcpy(clone_character, event->character);
    clone_event->character = clone_character;
  }
  self->event = clone_event;
  self->callback = callback;
  self->user_data = user_data;

  return self;
}

namespace {
// A global variable to store new event. It is a global variable so that it can
// be returned by #fl_key_event_new_by_mock for easy use.
FlKeyEvent _g_key_event;
}  // namespace

// Create a new #FlKeyEvent with the given information.
//
// This event is passed to #fl_key_responder_handle_event,
// which assumes that the event is managed by callee.
// Therefore #fl_key_event_new_by_mock doesn't need to
// dynamically allocate, but reuses the same global object.
static FlKeyEvent* fl_key_event_new_by_mock(guint32 time_in_milliseconds,
                                            bool is_press,
                                            guint keyval,
                                            guint16 keycode,
                                            int state,
                                            gboolean is_modifier) {
  _g_key_event.is_press = is_press;
  _g_key_event.time = time_in_milliseconds;
  _g_key_event.state = state;
  _g_key_event.keyval = keyval;
  _g_key_event.string = nullptr;
  _g_key_event.keycode = keycode;
  _g_key_event.origin = nullptr;
  _g_key_event.dispose_origin = nullptr;
  return &_g_key_event;
}

static gboolean g_expected_handled;
static gpointer g_expected_user_data;

static void verify_response_handled(bool handled, gpointer user_data) {
  EXPECT_EQ(handled, g_expected_handled);
}

static void invoke_record_callback_and_verify(FlKeyEmbedderCallRecord* record,
                                              bool expected_handled,
                                              void* expected_user_data) {
  g_return_if_fail(record->callback != nullptr);
  g_expected_handled = expected_handled;
  g_expected_user_data = expected_user_data;
  record->callback(expected_handled, record->user_data);
}

namespace {
GPtrArray* g_call_records;
}

static FlEngine* make_mock_engine_with_records() {
  FlEngine* engine = make_mock_engine();
  FlutterEngineProcTable* embedder_api = fl_engine_get_embedder_api(engine);
  embedder_api->SendKeyEvent = [](auto engine, const FlutterKeyEvent* event,
                                  FlutterKeyEventCallback callback,
                                  void* user_data) {
    if (g_call_records != nullptr) {
      g_ptr_array_add(g_call_records, fl_key_embedder_call_record_new(
                                          event, callback, user_data));
    }
    return kSuccess;
  };

  return engine;
}

static void clear_g_call_records() {
  g_ptr_array_free(g_call_records, TRUE);
  g_call_records = nullptr;
}

// Basic key presses
TEST(FlKeyEmbedderResponderTest, SendKeyEvent) {
  EXPECT_EQ(g_call_records, nullptr);
  g_call_records = g_ptr_array_new_with_free_func(g_object_unref);
  FlEngine* engine = make_mock_engine_with_records();
  FlKeyResponder* responder =
      FL_KEY_RESPONDER(fl_key_embedder_responder_new(engine));
  int user_data = 123;  // Arbitrary user data

  FlKeyEmbedderCallRecord* record;

  // On a QWERTY keyboard, press key Q (physically key A), and release.
  // Key down
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(12345, kPress, GDK_KEY_a, kKeyCodeKeyA, 0,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->struct_size, sizeof(FlutterKeyEvent));
  EXPECT_EQ(record->event->timestamp, 12345000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, "a");
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Skip testing key repeats, which is not present on GDK.

  // Key up
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(12346, kRelease, GDK_KEY_a, kKeyCodeKeyA, 0,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->struct_size, sizeof(FlutterKeyEvent));
  EXPECT_EQ(record->event->timestamp, 12346000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, FALSE, &user_data);
  g_ptr_array_clear(g_call_records);

  // On an AZERTY keyboard, press key Q (physically key A), and release.
  // Key down
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(12347, kPress, GDK_KEY_q, kKeyCodeKeyA, 0,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->struct_size, sizeof(FlutterKeyEvent));
  EXPECT_EQ(record->event->timestamp, 12347000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyQ);
  EXPECT_STREQ(record->event->character, "q");
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Key up
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(12348, kRelease, GDK_KEY_q, kKeyCodeKeyA, 0,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->struct_size, sizeof(FlutterKeyEvent));
  EXPECT_EQ(record->event->timestamp, 12348000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyQ);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, FALSE, &user_data);
  g_ptr_array_clear(g_call_records);

  clear_g_call_records();
  // TODO(dkwingsmt): Convert `engine` and `responder` to `g_autofree`.
  // The current implementation is because `responder` must be unreferenced
  // after `engine`, otherwise crash will *consistantly* occur on CI even if
  // everything passes locally.  This is a strange bug I've tried to track for
  // dozens of hours in vain.  It shouldn't affect real application anyway,
  // since it seems to appear only during the "reboot" of the engine.
  g_object_unref(engine);
  g_object_unref(responder);
}

// Press Shift, key A, then release Shift, key A.
TEST(FlKeyEmbedderResponderTest, PressShiftDuringLetterKeyTap) {
  EXPECT_EQ(g_call_records, nullptr);
  g_call_records = g_ptr_array_new_with_free_func(g_object_unref);
  FlEngine* engine = make_mock_engine_with_records();
  FlKeyResponder* responder =
      FL_KEY_RESPONDER(fl_key_embedder_responder_new(engine));
  int user_data = 123;  // Arbitrary user data

  FlKeyEmbedderCallRecord* record;

  // Press shift right
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(101, kPress, GDK_KEY_Shift_R, kKeyCodeShiftRight,
                               0, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalShiftRight);
  EXPECT_EQ(record->event->logical, kLogicalShiftRight);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Press key A
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(102, kPress, GDK_KEY_A, kKeyCodeKeyA, 0x1,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, "A");
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release shift right
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(103, kRelease, GDK_KEY_Shift_R,
                               kKeyCodeShiftRight, 0x1, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalShiftRight);
  EXPECT_EQ(record->event->logical, kLogicalShiftRight);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release key A
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(104, kRelease, GDK_KEY_A, kKeyCodeKeyA, 0,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  clear_g_call_records();
  g_object_unref(engine);
  g_object_unref(responder);
}

// Press or release Numpad 1 between presses/releases of NumLock.
//
// This tests interaction between lock keys and non-lock keys in cases that do
// not have events missed.
//
// This also tests the result of Numpad keys across NumLock taps, which is
// test-worthy because the keyval for the numpad key will change before and
// after the NumLock tap, which should not alter the resulting logical key.
TEST(FlKeyEmbedderResponderTest, TapNumPadKeysBetweenNumLockEvents) {
  EXPECT_EQ(g_call_records, nullptr);
  g_call_records = g_ptr_array_new_with_free_func(g_object_unref);
  FlEngine* engine = make_mock_engine_with_records();
  FlKeyResponder* responder =
      FL_KEY_RESPONDER(fl_key_embedder_responder_new(engine));
  int user_data = 123;  // Arbitrary user data

  FlKeyEmbedderCallRecord* record;

  // Press Numpad 1 (stage 0)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(101, kPress, GDK_KEY_KP_End, kKeyCodeNumpad1, 0,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalNumpad1);
  EXPECT_EQ(record->event->logical, kLogicalNumpad1);
  EXPECT_STREQ(record->event->character, nullptr);  // TODO
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Press NumLock (stage 0 -> 1)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(102, kPress, GDK_KEY_Num_Lock, kKeyCodeNumLock,
                               0, kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release numpad 1 (stage 1)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(104, kRelease, GDK_KEY_KP_1, kKeyCodeNumpad1,
                               0x10, kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalNumpad1);
  EXPECT_EQ(record->event->logical, kLogicalNumpad1);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release NumLock (stage 1 -> 2)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(103, kRelease, GDK_KEY_Num_Lock, kKeyCodeNumLock,
                               0x10, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Press Numpad 1 (stage 2)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(101, kPress, GDK_KEY_KP_End, kKeyCodeNumpad1,
                               0x10, kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalNumpad1);
  EXPECT_EQ(record->event->logical, kLogicalNumpad1);
  EXPECT_STREQ(record->event->character, nullptr);  // TODO
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Press NumLock (stage 2 -> 3)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(102, kPress, GDK_KEY_Num_Lock, kKeyCodeNumLock,
                               0x10, kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release numpad 1 (stage 3)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(104, kRelease, GDK_KEY_KP_1, kKeyCodeNumpad1,
                               0x10, kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalNumpad1);
  EXPECT_EQ(record->event->logical, kLogicalNumpad1);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release NumLock (stage 3 -> 0)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(103, kRelease, GDK_KEY_Num_Lock, kKeyCodeNumLock,
                               0x10, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  clear_g_call_records();
  g_object_unref(engine);
  g_object_unref(responder);
}

// Press or release letter key between presses/releases of CapsLock.
//
// This tests interaction between lock keys and non-lock keys in cases that do
// not have events missed.
TEST(FlKeyEmbedderResponderTest, TapLetterKeysBetweenCapsLockEvents) {
  EXPECT_EQ(g_call_records, nullptr);
  g_call_records = g_ptr_array_new_with_free_func(g_object_unref);
  FlEngine* engine = make_mock_engine_with_records();
  FlKeyResponder* responder =
      FL_KEY_RESPONDER(fl_key_embedder_responder_new(engine));
  int user_data = 123;  // Arbitrary user data

  FlKeyEmbedderCallRecord* record;

  // Press CapsLock (stage 0 -> 1)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(101, kPress, GDK_KEY_Caps_Lock, kKeyCodeCapsLock,
                               0x0, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalCapsLock);
  EXPECT_EQ(record->event->logical, kLogicalCapsLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Press key A (stage 1)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(102, kPress, GDK_KEY_A, kKeyCodeKeyA, 0x2,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, "A");
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release CapsLock (stage 1 -> 2)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(103, kRelease, GDK_KEY_Caps_Lock,
                               kKeyCodeCapsLock, 0x2, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalCapsLock);
  EXPECT_EQ(record->event->logical, kLogicalCapsLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release key A (stage 2)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(104, kRelease, GDK_KEY_A, kKeyCodeKeyA, 0x2,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Press CapsLock (stage 2 -> 3)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(105, kPress, GDK_KEY_Caps_Lock, kKeyCodeCapsLock,
                               0x2, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalCapsLock);
  EXPECT_EQ(record->event->logical, kLogicalCapsLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Press key A (stage 3)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(106, kPress, GDK_KEY_A, kKeyCodeKeyA, 0x2,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, "A");
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release CapsLock (stage 3 -> 0)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(107, kRelease, GDK_KEY_Caps_Lock,
                               kKeyCodeCapsLock, 0x2, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalCapsLock);
  EXPECT_EQ(record->event->logical, kLogicalCapsLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release key A (stage 0)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(108, kRelease, GDK_KEY_a, kKeyCodeKeyA, 0x0,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  clear_g_call_records();
  g_object_unref(engine);
  g_object_unref(responder);
}

// Press or release letter key between presses/releases of CapsLock, on
// a platform with reversed logic.
//
// This happens when using a Chrome remote desktop on MacOS.
TEST(FlKeyEmbedderResponderTest, TapLetterKeysBetweenCapsLockEventsReversed) {
  EXPECT_EQ(g_call_records, nullptr);
  g_call_records = g_ptr_array_new_with_free_func(g_object_unref);
  FlEngine* engine = make_mock_engine_with_records();
  FlKeyResponder* responder =
      FL_KEY_RESPONDER(fl_key_embedder_responder_new(engine));
  int user_data = 123;  // Arbitrary user data

  FlKeyEmbedderCallRecord* record;

  // Press key A (stage 0)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(101, kPress, GDK_KEY_a, kKeyCodeKeyA, 0x0,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, "a");
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Press CapsLock (stage 0 -> 1)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(102, kPress, GDK_KEY_Caps_Lock, kKeyCodeCapsLock,
                               0x2, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalCapsLock);
  EXPECT_EQ(record->event->logical, kLogicalCapsLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release CapsLock (stage 1 -> 2)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(103, kRelease, GDK_KEY_Caps_Lock,
                               kKeyCodeCapsLock, 0x2, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalCapsLock);
  EXPECT_EQ(record->event->logical, kLogicalCapsLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release key A (stage 2)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(104, kRelease, GDK_KEY_A, kKeyCodeKeyA, 0x2,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Press key A (stage 2)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(105, kPress, GDK_KEY_A, kKeyCodeKeyA, 0x2,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, "A");
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Press CapsLock (stage 2 -> 3)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(106, kPress, GDK_KEY_Caps_Lock, kKeyCodeCapsLock,
                               0x0, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalCapsLock);
  EXPECT_EQ(record->event->logical, kLogicalCapsLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release CapsLock (stage 3 -> 0)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(107, kRelease, GDK_KEY_Caps_Lock,
                               kKeyCodeCapsLock, 0x2, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalCapsLock);
  EXPECT_EQ(record->event->logical, kLogicalCapsLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release key A (stage 0)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(108, kRelease, GDK_KEY_a, kKeyCodeKeyA, 0x0,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  clear_g_call_records();
  g_object_unref(engine);
  g_object_unref(responder);
}

TEST(FlKeyEmbedderResponderTest, IgnoreDuplicateDownEvent) {
  EXPECT_EQ(g_call_records, nullptr);
  g_call_records = g_ptr_array_new_with_free_func(g_object_unref);
  FlEngine* engine = make_mock_engine_with_records();
  FlKeyResponder* responder =
      FL_KEY_RESPONDER(fl_key_embedder_responder_new(engine));
  int user_data = 123;  // Arbitrary user data

  FlKeyEmbedderCallRecord* record;

  // Press KeyA
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(101, kPress, GDK_KEY_a, kKeyCodeKeyA, 0,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Press KeyA again (with different logical key, which is not necessari but
  // for coverage).
  g_expected_handled = true;  // The ignored event is always handled.
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(102, kPress, GDK_KEY_q, kKeyCodeKeyA, 0,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 0u);

  // Release KeyA
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(103, kRelease, GDK_KEY_q, kKeyCodeKeyA, 0,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  clear_g_call_records();
  g_object_unref(engine);
  g_object_unref(responder);
}

TEST(FlKeyEmbedderResponderTest, IgnoreAbruptUpEvent) {
  EXPECT_EQ(g_call_records, nullptr);
  g_call_records = g_ptr_array_new_with_free_func(g_object_unref);
  FlEngine* engine = make_mock_engine_with_records();
  FlKeyResponder* responder =
      FL_KEY_RESPONDER(fl_key_embedder_responder_new(engine));
  int user_data = 123;  // Arbitrary user data

  // Release KeyA before it was even pressed.
  g_expected_handled = true;  // The ignored event is always handled.
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(103, kRelease, GDK_KEY_q, kKeyCodeKeyA, 0,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 0u);

  clear_g_call_records();
  g_object_unref(engine);
  g_object_unref(responder);
}

// Test if missed modifier keys can be detected and synthesized with state
// information upon events that are for this modifier key.
TEST(FlKeyEmbedderResponderTest, SynthesizeForDesyncPressingStateOnSelfEvents) {
  EXPECT_EQ(g_call_records, nullptr);
  g_call_records = g_ptr_array_new_with_free_func(g_object_unref);
  FlEngine* engine = make_mock_engine_with_records();
  FlKeyResponder* responder =
      FL_KEY_RESPONDER(fl_key_embedder_responder_new(engine));
  int user_data = 123;  // Arbitrary user data

  FlKeyEmbedderCallRecord* record;

  // Test 1: synthesize key down.

  // A key down of control left is missed.
  guint state = GDK_CONTROL_MASK;

  // Send a ControlLeft up
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(101, kRelease, GDK_KEY_Control_L,
                               kKeyCodeControlLeft, state, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 2u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->timestamp, 101000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalControlLeft);
  EXPECT_EQ(record->event->logical, kLogicalControlLeft);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 1));
  EXPECT_EQ(record->event->timestamp, 101000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalControlLeft);
  EXPECT_EQ(record->event->logical, kLogicalControlLeft);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Test 2: synthesize key up.

  // Send a ControlLeft down.
  state = 0;
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(102, kPress, GDK_KEY_Control_L,
                               kKeyCodeControlLeft, state, kIsModifier),
      verify_response_handled, &user_data);
  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // A key up of control left is missed.
  state = 0;

  // Send another ControlLeft down
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(103, kPress, GDK_KEY_Control_L,
                               kKeyCodeControlLeft, state, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 2u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->timestamp, 103000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalControlLeft);
  EXPECT_EQ(record->event->logical, kLogicalControlLeft);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 1));
  EXPECT_EQ(record->event->timestamp, 103000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalControlLeft);
  EXPECT_EQ(record->event->logical, kLogicalControlLeft);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Send a ControlLeft up to clear up state.
  state = GDK_CONTROL_MASK;
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(104, kRelease, GDK_KEY_Control_L,
                               kKeyCodeControlLeft, state, kIsModifier),
      verify_response_handled, &user_data);
  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Test 3: synthesize by right modifier.

  // A key down of control right is missed.
  state = GDK_CONTROL_MASK;

  // Send a ControlRight up.
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(105, kRelease, GDK_KEY_Control_R,
                               kKeyCodeControlRight, state, kIsModifier),
      verify_response_handled, &user_data);

  // A ControlLeft down is synthesized, with no non-synthesized event.
  // Reason: The ControlLeft down is synthesized to synchronize the state
  // showing Control as pressed. The ControlRight event is ignored because
  // the event is considered a duplicate up event.
  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->timestamp, 105000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalControlLeft);
  EXPECT_EQ(record->event->logical, kLogicalControlLeft);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  g_ptr_array_clear(g_call_records);

  clear_g_call_records();
  g_object_unref(engine);
  g_object_unref(responder);
}

// Test if missed modifier keys can be detected and synthesized with state
// information upon events that are not for this modifier key.
TEST(FlKeyEmbedderResponderTest,
     SynthesizeForDesyncPressingStateOnNonSelfEvents) {
  EXPECT_EQ(g_call_records, nullptr);
  g_call_records = g_ptr_array_new_with_free_func(g_object_unref);
  FlEngine* engine = make_mock_engine_with_records();
  FlKeyResponder* responder =
      FL_KEY_RESPONDER(fl_key_embedder_responder_new(engine));
  int user_data = 123;  // Arbitrary user data

  FlKeyEmbedderCallRecord* record;

  // A key down of control left is missed.
  guint state = GDK_CONTROL_MASK;

  // Send a normal event (KeyA down)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(101, kPress, GDK_KEY_a, kKeyCodeKeyA, state,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 2u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->timestamp, 101000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalControlLeft);
  EXPECT_EQ(record->event->logical, kLogicalControlLeft);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 1));
  EXPECT_EQ(record->event->timestamp, 101000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, "a");
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // A key up of control left is missed.
  state = 0;

  // Send a normal event (KeyA up)
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(102, kRelease, GDK_KEY_A, kKeyCodeKeyA, state,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 2u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->timestamp, 102000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalControlLeft);
  EXPECT_EQ(record->event->logical, kLogicalControlLeft);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 1));
  EXPECT_EQ(record->event->timestamp, 102000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Test non-default key mapping.

  // Press a key with physical CapsLock and logical ControlLeft.
  state = 0;

  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(101, kPress, GDK_KEY_Control_L, kKeyCodeCapsLock,
                               state, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->timestamp, 101000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalCapsLock);
  EXPECT_EQ(record->event->logical, kLogicalControlLeft);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // The key up of the control left press is missed.
  state = 0;

  // Send a normal event (KeyA down).
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(102, kPress, GDK_KEY_A, kKeyCodeKeyA, state,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  // The synthesized event should have physical CapsLock and logical
  // ControlLeft.
  EXPECT_EQ(g_call_records->len, 2u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->timestamp, 102000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalCapsLock);
  EXPECT_EQ(record->event->logical, kLogicalControlLeft);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 1));
  EXPECT_EQ(record->event->timestamp, 102000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, "A");
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  clear_g_call_records();
  g_object_unref(engine);
  g_object_unref(responder);
}

// Test if missed modifier keys can be detected and synthesized with state
// information upon events that do not have the standard key mapping.
TEST(FlKeyEmbedderResponderTest,
     SynthesizeForDesyncPressingStateOnRemappedEvents) {
  EXPECT_EQ(g_call_records, nullptr);
  g_call_records = g_ptr_array_new_with_free_func(g_object_unref);
  FlEngine* engine = make_mock_engine_with_records();
  FlKeyResponder* responder =
      FL_KEY_RESPONDER(fl_key_embedder_responder_new(engine));
  int user_data = 123;  // Arbitrary user data

  FlKeyEmbedderCallRecord* record;

  // Press a key with physical CapsLock and logical ControlLeft.
  guint state = 0;

  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(101, kPress, GDK_KEY_Control_L, kKeyCodeCapsLock,
                               state, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 1u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->timestamp, 101000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalCapsLock);
  EXPECT_EQ(record->event->logical, kLogicalControlLeft);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // The key up of the control left press is missed.
  state = 0;

  // Send a normal event (KeyA down).
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(102, kPress, GDK_KEY_A, kKeyCodeKeyA, state,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  // The synthesized event should have physical CapsLock and logical
  // ControlLeft.
  EXPECT_EQ(g_call_records->len, 2u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->timestamp, 102000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalCapsLock);
  EXPECT_EQ(record->event->logical, kLogicalControlLeft);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 1));
  EXPECT_EQ(record->event->timestamp, 102000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, "A");
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  clear_g_call_records();
  g_object_unref(engine);
  g_object_unref(responder);
}

// Test if missed lock keys can be detected and synthesized with state
// information upon events that are not for this modifier key.
TEST(FlKeyEmbedderResponderTest, SynthesizeForDesyncLockModeOnNonSelfEvents) {
  EXPECT_EQ(g_call_records, nullptr);
  g_call_records = g_ptr_array_new_with_free_func(g_object_unref);
  FlEngine* engine = make_mock_engine_with_records();
  FlKeyResponder* responder =
      FL_KEY_RESPONDER(fl_key_embedder_responder_new(engine));
  int user_data = 123;  // Arbitrary user data

  FlKeyEmbedderCallRecord* record;

  // The NumLock is desynchronized by being enabled.
  guint state = GDK_MOD2_MASK;

  // Send a normal event
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(101, kPress, GDK_KEY_a, kKeyCodeKeyA, state,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 2u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->timestamp, 101000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 1));
  EXPECT_EQ(record->event->timestamp, 101000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, "a");
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // The NumLock is desynchronized by being disabled.
  state = 0;

  // Release key A
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(102, kRelease, GDK_KEY_A, kKeyCodeKeyA, state,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 4u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->timestamp, 102000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 1));
  EXPECT_EQ(record->event->timestamp, 102000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 2));
  EXPECT_EQ(record->event->timestamp, 102000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 3));
  EXPECT_EQ(record->event->timestamp, 102000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalKeyA);
  EXPECT_EQ(record->event->logical, kLogicalKeyA);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // Release NumLock. Since the previous event should have synthesized NumLock
  // to be released, this should result in no events.
  g_expected_handled = true;
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(103, kRelease, GDK_KEY_Num_Lock, kKeyCodeNumLock,
                               state, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 0u);

  clear_g_call_records();
  g_object_unref(engine);
  g_object_unref(responder);
}

// Test if missed lock keys can be detected and synthesized with state
// information upon events that are for this modifier key.
TEST(FlKeyEmbedderResponderTest, SynthesizeForDesyncLockModeOnSelfEvents) {
  EXPECT_EQ(g_call_records, nullptr);
  g_call_records = g_ptr_array_new_with_free_func(g_object_unref);
  FlEngine* engine = make_mock_engine_with_records();
  FlKeyResponder* responder =
      FL_KEY_RESPONDER(fl_key_embedder_responder_new(engine));
  int user_data = 123;  // Arbitrary user data

  FlKeyEmbedderCallRecord* record;

  // The NumLock is desynchronized by being enabled.
  guint state = GDK_MOD2_MASK;

  // NumLock down
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(101, kPress, GDK_KEY_Num_Lock, kKeyCodeNumLock,
                               state, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 3u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->timestamp, 101000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 1));
  EXPECT_EQ(record->event->timestamp, 101000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 2));
  EXPECT_EQ(record->event->timestamp, 101000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  // The NumLock is desynchronized by being enabled in a press event.
  state = GDK_MOD2_MASK;

  // NumLock up
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(102, kPress, GDK_KEY_Num_Lock, kKeyCodeNumLock,
                               state, kIsModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 4u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->timestamp, 102000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 1));
  EXPECT_EQ(record->event->timestamp, 102000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 2));
  EXPECT_EQ(record->event->timestamp, 102000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeUp);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 3));
  EXPECT_EQ(record->event->timestamp, 102000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, false);

  invoke_record_callback_and_verify(record, TRUE, &user_data);
  g_ptr_array_clear(g_call_records);

  clear_g_call_records();
  g_object_unref(engine);
  g_object_unref(responder);
}

// Ensures that even if the primary event is ignored (due to duplicate
// key up or down events), key synthesization is still performed.
TEST(FlKeyEmbedderResponderTest, SynthesizationOccursOnIgnoredEvents) {
  EXPECT_EQ(g_call_records, nullptr);
  g_call_records = g_ptr_array_new_with_free_func(g_object_unref);
  FlEngine* engine = make_mock_engine_with_records();
  FlKeyResponder* responder =
      FL_KEY_RESPONDER(fl_key_embedder_responder_new(engine));
  int user_data = 123;  // Arbitrary user data

  FlKeyEmbedderCallRecord* record;

  // The NumLock is desynchronized by being enabled, and Control is pressed.
  guint state = GDK_MOD2_MASK | GDK_CONTROL_MASK;

  // Send a KeyA up event, which will be ignored.
  g_expected_handled = true;  // The ignored event is always handled.
  fl_key_responder_handle_event(
      responder,
      fl_key_event_new_by_mock(101, kRelease, GDK_KEY_a, kKeyCodeKeyA, state,
                               kIsNotModifier),
      verify_response_handled, &user_data);

  EXPECT_EQ(g_call_records->len, 2u);
  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 0));
  EXPECT_EQ(record->event->timestamp, 101000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalNumLock);
  EXPECT_EQ(record->event->logical, kLogicalNumLock);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  record = FL_KEY_EMBEDDER_CALL_RECORD(g_ptr_array_index(g_call_records, 1));
  EXPECT_EQ(record->event->timestamp, 101000);
  EXPECT_EQ(record->event->type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(record->event->physical, kPhysicalControlLeft);
  EXPECT_EQ(record->event->logical, kLogicalControlLeft);
  EXPECT_STREQ(record->event->character, nullptr);
  EXPECT_EQ(record->event->synthesized, true);

  g_ptr_array_clear(g_call_records);

  clear_g_call_records();
  g_object_unref(engine);
  g_object_unref(responder);
}
