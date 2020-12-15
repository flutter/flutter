// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_ATK_HYPERLINK_H_
#define UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_ATK_HYPERLINK_H_

#include <atk/atk.h>

namespace ui {

class AXPlatformNodeAuraLinux;

G_BEGIN_DECLS

#define AX_PLATFORM_ATK_HYPERLINK_TYPE (ax_platform_atk_hyperlink_get_type())
#define AX_PLATFORM_ATK_HYPERLINK(obj)                               \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), AX_PLATFORM_ATK_HYPERLINK_TYPE, \
                              AXPlatformAtkHyperlink))
#define AX_PLATFORM_ATK_HYPERLINK_CLASS(klass)                      \
  (G_TYPE_CHECK_CLASS_CAST((klass), AX_PLATFORM_ATK_HYPERLINK_TYPE, \
                           AXPlatformAtkHyperlinkClass))
#define IS_AX_PLATFORM_ATK_HYPERLINK(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), AX_PLATFORM_ATK_HYPERLINK_TYPE))
#define IS_AX_PLATFORM_ATK_HYPERLINK_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), AX_PLATFORM_ATK_HYPERLINK_TYPE))
#define AX_PLATFORM_ATK_HYPERLINK_GET_CLASS(obj)                    \
  (G_TYPE_INSTANCE_GET_CLASS((obj), AX_PLATFORM_ATK_HYPERLINK_TYPE, \
                             AXPlatformAtkHyperlinkClass))

typedef struct _AXPlatformAtkHyperlink AXPlatformAtkHyperlink;
typedef struct _AXPlatformAtkHyperlinkClass AXPlatformAtkHyperlinkClass;
typedef struct _AXPlatformAtkHyperlinkPrivate AXPlatformAtkHyperlinkPrivate;

struct _AXPlatformAtkHyperlink {
  AtkHyperlink parent;

  /*< private >*/
  AXPlatformAtkHyperlinkPrivate* priv;
};

struct _AXPlatformAtkHyperlinkClass {
  AtkHyperlinkClass parent_class;
};

GType ax_platform_atk_hyperlink_get_type(void) G_GNUC_CONST;
void ax_platform_atk_hyperlink_set_object(AXPlatformAtkHyperlink* hyperlink,
                                          AXPlatformNodeAuraLinux* obj);

G_END_DECLS

}  // namespace ui

#endif  // UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_ATK_HYPERLINK_H_
