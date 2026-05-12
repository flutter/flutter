// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_MAPPING_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_MAPPING_H_

#include <gdk/gdk.h>
#include <cinttypes>
#include <map>
#include <vector>

/**
 * FlKeyEmbedderCheckedKey:
 *
 * The information for a key that #FlKeyEmbedderResponder should keep state
 * synchronous on. For every record of #FlKeyEmbedderCheckedKey, the responder
 * will check the #GdkEvent::state and the internal state, and synchronize
 * events if they don't match.
 *
 * #FlKeyEmbedderCheckedKey can synchronize pressing states (such as
 * whether ControlLeft is pressed) or lock states (such as whether CapsLock
 * is enabled).
 *
 * #FlKeyEmbedderCheckedKey has a "primary key". For pressing states, the
 * primary key is the left of the modifiers. For lock states, the primary
 * key is the key.
 *
 * #FlKeyEmbedderCheckedKey may also have a "secondary key". It is only
 * available to pressing states, which is the right of the modifiers.
 */
typedef struct {
  // The physical key for the primary key.
  uint64_t primary_physical_key;
  // The logical key for the primary key.
  uint64_t primary_logical_key;
  // The logical key for the secondary key.
  uint64_t secondary_logical_key;
  // Whether this key is CapsLock.  CapsLock uses a different event model in GDK
  // and needs special treatment.
  bool is_caps_lock;
} FlKeyEmbedderCheckedKey;

inline uint64_t gpointer_to_uint64(gpointer pointer) {
  return pointer == nullptr ? 0 : reinterpret_cast<uint64_t>(pointer);
}

inline gpointer uint64_to_gpointer(uint64_t number) {
  return reinterpret_cast<gpointer>(number);
}

// Maps XKB specific key code values to Flutter's physical key code values.
extern std::map<uint64_t, uint64_t> xkb_to_physical_key_map;

// Maps GDK keyval values to Flutter's logical key code values.
extern std::map<uint64_t, uint64_t> gtk_keyval_to_logical_key_map;

void initialize_modifier_bit_to_checked_keys(GHashTable* table);

void initialize_lock_bit_to_checked_keys(GHashTable* table);

// Mask for the 32-bit value portion of the key code.
extern const uint64_t kValueMask;

// The plane value for keys which have a Unicode representation.
extern const uint64_t kUnicodePlane;

// The plane value for the private keys defined by the GTK embedding.
extern const uint64_t kGtkPlane;

typedef struct {
  // The key code for a key that prints `keyChar` in the US keyboard layout.
  uint16_t keycode;

  // The logical key for this key.
  uint64_t logical_key;

  // If the goal is mandatory, the keyboard handler will make sure to find a
  // logical key for this character, falling back to the US keyboard layout.
  bool mandatory;
} LayoutGoal;

// NOLINTNEXTLINE(readability-identifier-naming)
extern const std::vector<LayoutGoal> layout_goals;

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_KEY_MAPPING_H_
