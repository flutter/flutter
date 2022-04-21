// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_KEYBOARD_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_KEYBOARD_MANAGER_H_

#include <gdk/gdk.h>

#include "flutter/shell/platform/linux/fl_keyboard_view_delegate.h"

G_BEGIN_DECLS

#define FL_TYPE_KEYBOARD_MANAGER fl_keyboard_manager_get_type()
G_DECLARE_FINAL_TYPE(FlKeyboardManager,
                     fl_keyboard_manager,
                     FL,
                     KEYBOARD_MANAGER,
                     GObject);

/**
 * FlKeyboardManager:
 *
 * Processes keyboard events and cooperate with `TextInputPlugin`.
 *
 * A keyboard event goes through a few sections, each can choose to handle the
 * event, and only unhandled events can move to the next section:
 *
 * - Keyboard: Dispatch to the embedder responder and the channel responder
 *   simultaneously. After both responders have responded (asynchronously), the
 *   event is considered handled if either responder handles it.
 * - Text input: Events are sent to IM filter (usually owned by
 *   `TextInputPlugin`) and are handled synchronously.
 * - Redispatching: Events are inserted back to the system for redispatching.
 */

/**
 * fl_keyboard_manager_new:
 * @view_delegate: An interface that the manager requires to communicate with
 * the platform. Usually implemented by FlView.
 *
 * Create a new #FlKeyboardManager.
 *
 * Returns: a new #FlKeyboardManager.
 */
FlKeyboardManager* fl_keyboard_manager_new(
    FlKeyboardViewDelegate* view_delegate);

/**
 * fl_keyboard_manager_handle_event:
 * @manager: the #FlKeyboardManager self.
 * @event: the event to be dispatched. It is usually a wrap of a GdkEventKey.
 * This event will be managed and released by #FlKeyboardManager.
 *
 * Make the manager process a system key event. This might eventually send
 * messages to the framework, trigger text input effects, or redispatch the
 * event back to the system.
 */
gboolean fl_keyboard_manager_handle_event(FlKeyboardManager* manager,
                                          FlKeyEvent* event);

/**
 * fl_keyboard_manager_is_state_clear:
 * @manager: the #FlKeyboardManager self.
 *
 * A debug-only method that queries whether the manager's various states are
 * cleared, i.e. no pending events for redispatching or for responding.
 *
 * Returns: true if the manager's various states are cleared.
 */
gboolean fl_keyboard_manager_is_state_clear(FlKeyboardManager* manager);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_KEYBOARD_MANAGER_H_
