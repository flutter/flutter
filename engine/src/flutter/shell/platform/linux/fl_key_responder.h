// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_RESPONDER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_RESPONDER_H_

#include <gdk/gdk.h>
#include <cinttypes>

#include "flutter/shell/platform/linux/fl_key_event.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_value.h"

G_BEGIN_DECLS

typedef struct _FlKeyboardManager FlKeyboardManager;

/**
 * FlKeyResponderAsyncCallback:
 * @event: whether the event has been handled.
 * @user_data: the same value as user_data sent by
 * #fl_key_responder_handle_event.
 *
 * The signature for a callback with which a #FlKeyResponder asynchronously
 * reports whether the responder handles the event.
 **/
typedef void (*FlKeyResponderAsyncCallback)(bool handled, gpointer user_data);

#define FL_TYPE_KEY_RESPONDER fl_key_responder_get_type()
G_DECLARE_INTERFACE(FlKeyResponder,
                    fl_key_responder,
                    FL,
                    KEY_RESPONDER,
                    GObject);

/**
 * FlKeyResponder:
 *
 * An interface for a responder that can process a key event and decides
 * asynchronously whether to handle an event.
 *
 * To use this class, add it with #fl_keyboard_manager_add_responder.
 */

struct _FlKeyResponderInterface {
  GTypeInterface g_iface;

  /**
   * FlKeyResponder::handle_event:
   *
   * The implementation of #fl_key_responder_handle_event.
   */
  void (*handle_event)(FlKeyResponder* responder,
                       FlKeyEvent* event,
                       uint64_t specified_logical_key,
                       FlKeyResponderAsyncCallback callback,
                       gpointer user_data);
};

/**
 * fl_key_responder_handle_event:
 * @responder: the #FlKeyResponder self.
 * @event: the event to be handled. Must not be null. The object is managed
 * by callee and must not be assumed available after this function.
 * @callback: the callback to report the result. It should be called exactly
 * once. Must not be null.
 * @user_data: a value that will be sent back in the callback. Can be null.
 *
 * Let the responder handle an event, expecting the responder to report
 * whether to handle the event. The result will be reported by invoking
 * `callback` exactly once, which might happen after
 * `fl_key_responder_handle_event` or during it.
 */
void fl_key_responder_handle_event(FlKeyResponder* responder,
                                   FlKeyEvent* event,
                                   FlKeyResponderAsyncCallback callback,
                                   gpointer user_data,
                                   uint64_t specified_logical_key = 0);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_RESPONDER_H_
