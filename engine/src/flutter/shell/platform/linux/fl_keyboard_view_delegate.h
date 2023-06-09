// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_KEYBOARD_VIEW_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_KEYBOARD_VIEW_DELEGATE_H_

#include <gdk/gdk.h>
#include <cinttypes>
#include <functional>
#include <memory>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_key_event.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"

typedef std::function<void()> KeyboardLayoutNotifier;

G_BEGIN_DECLS

G_DECLARE_INTERFACE(FlKeyboardViewDelegate,
                    fl_keyboard_view_delegate,
                    FL,
                    KEYBOARD_VIEW_DELEGATE,
                    GObject);

/**
 * FlKeyboardViewDelegate:
 *
 * An interface for a class that provides `FlKeyboardManager` with
 * platform-related features.
 *
 * This interface is typically implemented by `FlView`.
 */

struct _FlKeyboardViewDelegateInterface {
  GTypeInterface g_iface;

  void (*send_key_event)(FlKeyboardViewDelegate* delegate,
                         const FlutterKeyEvent* event,
                         FlutterKeyEventCallback callback,
                         void* user_data);

  gboolean (*text_filter_key_press)(FlKeyboardViewDelegate* delegate,
                                    FlKeyEvent* event);

  FlBinaryMessenger* (*get_messenger)(FlKeyboardViewDelegate* delegate);

  void (*redispatch_event)(FlKeyboardViewDelegate* delegate,
                           std::unique_ptr<FlKeyEvent> event);

  void (*subscribe_to_layout_change)(FlKeyboardViewDelegate* delegate,
                                     KeyboardLayoutNotifier notifier);

  guint (*lookup_key)(FlKeyboardViewDelegate* view_delegate,
                      const GdkKeymapKey* key);

  GHashTable* (*get_keyboard_state)(FlKeyboardViewDelegate* delegate);
};

/**
 * fl_keyboard_view_delegate_send_key_event:
 *
 * Handles `FlKeyboardManager`'s request to send a `FlutterKeyEvent` through the
 * embedder API to the framework.
 *
 * The ownership of the `event` is kept by the keyboard manager, and the `event`
 * might be immediately destroyed after this function returns.
 *
 * The `callback` must eventually be called exactly once with the event result
 * and the `user_data`.
 */
void fl_keyboard_view_delegate_send_key_event(FlKeyboardViewDelegate* delegate,
                                              const FlutterKeyEvent* event,
                                              FlutterKeyEventCallback callback,
                                              void* user_data);

/**
 * fl_keyboard_view_delegate_text_filter_key_press:
 *
 * Handles `FlKeyboardManager`'s request to check if the GTK text input IM
 * filter would like to handle a GDK event.
 *
 * The ownership of the `event` is kept by the keyboard manager.
 */
gboolean fl_keyboard_view_delegate_text_filter_key_press(
    FlKeyboardViewDelegate* delegate,
    FlKeyEvent* event);

/**
 * fl_keyboard_view_delegate_get_messenger:
 *
 * Returns a binary messenger that can be used to send messages to the
 * framework.
 *
 * The ownership of messenger is kept by the view delegate.
 */
FlBinaryMessenger* fl_keyboard_view_delegate_get_messenger(
    FlKeyboardViewDelegate* delegate);

/**
 * fl_keyboard_view_delegate_redispatch_event:
 *
 * Handles `FlKeyboardManager`'s request to insert a GDK event to the system for
 * redispatching.
 *
 * The ownership of event will be transferred to the view delegate. The view
 * delegate is responsible to call fl_key_event_dispose.
 */
void fl_keyboard_view_delegate_redispatch_event(
    FlKeyboardViewDelegate* delegate,
    std::unique_ptr<FlKeyEvent> event);

void fl_keyboard_view_delegate_subscribe_to_layout_change(
    FlKeyboardViewDelegate* delegate,
    KeyboardLayoutNotifier notifier);

guint fl_keyboard_view_delegate_lookup_key(FlKeyboardViewDelegate* delegate,
                                           const GdkKeymapKey* key);

/**
 * fl_keyboard_view_delegate_get_keyboard_state:
 *
 * Returns the keyboard pressed state. The hash table contains one entry per
 * pressed keys, mapping from the logical key to the physical key.*
 *
 */
GHashTable* fl_keyboard_view_delegate_get_keyboard_state(
    FlKeyboardViewDelegate* delegate);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_KEYBOARD_VIEW_DELEGATE_H_
