// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef KEYBOARD_MAP_H_
#define KEYBOARD_MAP_H_

#include <gdk/gdk.h>
#include <cinttypes>
#include <map>

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

#endif  // KEYBOARD_MAP_H_
