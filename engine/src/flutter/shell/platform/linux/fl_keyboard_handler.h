// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_KEYBOARD_HANDLER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_KEYBOARD_HANDLER_H_

#include <gdk/gdk.h>

#include "flutter/shell/platform/linux/fl_keyboard_view_delegate.h"

G_BEGIN_DECLS

#define FL_TYPE_KEYBOARD_HANDLER fl_keyboard_handler_get_type()
G_DECLARE_FINAL_TYPE(FlKeyboardHandler,
                     fl_keyboard_handler,
                     FL,
                     KEYBOARD_HANDLER,
                     GObject);

/**
 * FlKeyboardHandler:
 *
 * Processes keyboard events and cooperate with `TextInputHandler`.
 *
 * A keyboard event goes through a few sections, each can choose to handle the
 * event, and only unhandled events can move to the next section:
 *
 * - Keyboard: Dispatch to the embedder responder and the channel responder
 *   simultaneously. After both responders have responded (asynchronously), the
 *   event is considered handled if either responder handles it.
 * - Text input: Events are sent to IM filter (usually owned by
 *   `TextInputHandler`) and are handled synchronously.
 * - Redispatching: Events are inserted back to the system for redispatching.
 */

/**
 * fl_keyboard_handler_new:
 * @view_delegate: An interface that the handler requires to communicate with
 * the platform. Usually implemented by FlView.
 *
 * Create a new #FlKeyboardHandler.
 *
 * Returns: a new #FlKeyboardHandler.
 */
FlKeyboardHandler* fl_keyboard_handler_new(
    FlBinaryMessenger* messenger,
    FlKeyboardViewDelegate* view_delegate);

/**
 * fl_keyboard_handler_handle_event:
 * @handler: the #FlKeyboardHandler self.
 * @event: the event to be dispatched. It is usually a wrap of a GdkEventKey.
 * This event will be managed and released by #FlKeyboardHandler.
 *
 * Make the handler process a system key event. This might eventually send
 * messages to the framework, trigger text input effects, or redispatch the
 * event back to the system.
 */
gboolean fl_keyboard_handler_handle_event(FlKeyboardHandler* handler,
                                          FlKeyEvent* event);

/**
 * fl_keyboard_handler_is_state_clear:
 * @handler: the #FlKeyboardHandler self.
 *
 * A debug-only method that queries whether the handler's various states are
 * cleared, i.e. no pending events for redispatching or for responding.
 *
 * Returns: true if the handler's various states are cleared.
 */
gboolean fl_keyboard_handler_is_state_clear(FlKeyboardHandler* handler);

/**
 * fl_keyboard_handler_sync_modifier_if_needed:
 * @handler: the #FlKeyboardHandler self.
 * @state: the state of the modifiers mask.
 * @event_time: the time attribute of the incoming GDK event.
 *
 * If needed, synthesize modifier keys up and down event by comparing their
 * current pressing states with the given modifiers mask.
 */
void fl_keyboard_handler_sync_modifier_if_needed(FlKeyboardHandler* handler,
                                                 guint state,
                                                 double event_time);

/**
 * fl_keyboard_handler_get_pressed_state:
 * @handler: the #FlKeyboardHandler self.
 *
 * Returns the keyboard pressed state. The hash table contains one entry per
 * pressed keys, mapping from the logical key to the physical key.*
 */
GHashTable* fl_keyboard_handler_get_pressed_state(FlKeyboardHandler* handler);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_KEYBOARD_HANDLER_H_
