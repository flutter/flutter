// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_PLATFORM_ATK_UTIL_AURALINUX_H_
#define UI_ACCESSIBILITY_PLATFORM_ATK_UTIL_AURALINUX_H_

#include <atk/atk.h>

#include "base/macros.h"
#include "base/memory/singleton.h"
#include "ui/accessibility/ax_export.h"
#include "ui/accessibility/platform/ax_platform_node_auralinux.h"

namespace ui {

// These values are duplicates of the GDK values that can be found in
// <gdk/gdktypes.h>. ATK expects the GDK values, but we don't want to depend on
// GDK here.
typedef enum {
  kAtkShiftMask = 1 << 0,
  kAtkLockMask = 1 << 1,
  kAtkControlMask = 1 << 2,
  kAtkMod1Mask = 1 << 3,
  kAtkMod2Mask = 1 << 4,
  kAtkMod3Mask = 1 << 5,
  kAtkMod4Mask = 1 << 6,
  KAtkMod5Mask = 1 << 7,
} AtkKeyModifierMask;

enum DiscardAtkKeyEvent { Discard, Retain };

// This singleton class initializes ATK (accessibility toolkit) and
// registers an implementation of the AtkUtil class, a global class that
// every accessible application needs to register once.
class AX_EXPORT AtkUtilAuraLinux {
 public:
  // Get the single instance of this class.
  static AtkUtilAuraLinux* GetInstance();

  AtkUtilAuraLinux() = default;

  void InitializeAsync();
  void InitializeForTesting();

  bool IsAtSpiReady();
  void SetAtSpiReady(bool ready);

  // Nodes with postponed events will get the function RunPostponedEvents()
  // called as soon as AT-SPI is detected to be ready
  void PostponeEventsFor(AXPlatformNodeAuraLinux* node);

  void CancelPostponedEventsFor(AXPlatformNodeAuraLinux* node);

  static DiscardAtkKeyEvent HandleAtkKeyEvent(AtkKeyEventStruct* key_event);

 private:
  friend struct base::DefaultSingletonTraits<AtkUtilAuraLinux>;

  bool ShouldEnableAccessibility();

  void PlatformInitializeAsync();

  bool at_spi_ready_ = false;

  DISALLOW_COPY_AND_ASSIGN(AtkUtilAuraLinux);
};

}  // namespace ui

#endif  // UI_ACCESSIBILITY_PLATFORM_ATK_UTIL_AURALINUX_H_
