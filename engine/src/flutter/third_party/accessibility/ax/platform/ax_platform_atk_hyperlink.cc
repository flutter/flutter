// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/platform/ax_platform_atk_hyperlink.h"

#include <string>
#include <utility>

#include "ui/accessibility/ax_enum_util.h"
#include "ui/accessibility/platform/ax_platform_node_auralinux.h"
#include "ui/accessibility/platform/ax_platform_node_delegate.h"

namespace ui {

struct _AXPlatformAtkHyperlinkPrivate {
  AXPlatformNodeAuraLinux* platform_node = nullptr;
};

static gpointer kAXPlatformAtkHyperlinkParentClass = nullptr;

static AXPlatformNodeAuraLinux* ToAXPlatformNodeAuraLinux(
    AXPlatformAtkHyperlink* atk_hyperlink) {
  if (!atk_hyperlink)
    return nullptr;
  return atk_hyperlink->priv->platform_node;
}

static void AXPlatformAtkHyperlinkFinalize(GObject* self) {
  AX_PLATFORM_ATK_HYPERLINK(self)->priv->~AXPlatformAtkHyperlinkPrivate();
  G_OBJECT_CLASS(kAXPlatformAtkHyperlinkParentClass)->finalize(self);
}

static gchar* AXPlatformAtkHyperlinkGetUri(AtkHyperlink* atk_hyperlink,
                                           gint index) {
  AXPlatformNodeAuraLinux* obj =
      ToAXPlatformNodeAuraLinux(AX_PLATFORM_ATK_HYPERLINK(atk_hyperlink));
  if (!obj)
    return nullptr;

  if (index != 0)
    return nullptr;

  return g_strdup(
      obj->GetStringAttribute(ax::mojom::StringAttribute::kUrl).c_str());
}

static AtkObject* AXPlatformAtkHyperlinkGetObject(AtkHyperlink* atk_hyperlink,
                                                  gint index) {
  AXPlatformNodeAuraLinux* obj =
      ToAXPlatformNodeAuraLinux(AX_PLATFORM_ATK_HYPERLINK(atk_hyperlink));
  if (!obj)
    return nullptr;

  if (index != 0)
    return nullptr;

  return ATK_OBJECT(obj->GetNativeViewAccessible());
}

static gint AXPlatformAtkHyperlinkGetNAnchors(AtkHyperlink* atk_hyperlink) {
  AXPlatformNodeAuraLinux* obj =
      ToAXPlatformNodeAuraLinux(AX_PLATFORM_ATK_HYPERLINK(atk_hyperlink));

  return obj ? 1 : 0;
}

static gboolean AXPlatformAtkHyperlinkIsValid(AtkHyperlink* atk_hyperlink) {
  AXPlatformNodeAuraLinux* obj =
      ToAXPlatformNodeAuraLinux(AX_PLATFORM_ATK_HYPERLINK(atk_hyperlink));

  return obj ? TRUE : FALSE;
}

static gboolean AXPlatformAtkHyperlinkIsSelectedLink(
    AtkHyperlink* atk_hyperlink) {
  AXPlatformNodeAuraLinux* obj =
      ToAXPlatformNodeAuraLinux(AX_PLATFORM_ATK_HYPERLINK(atk_hyperlink));
  if (!obj)
    return false;

  return obj->GetDelegate()->GetFocus() == obj->GetNativeViewAccessible();
}

static int AXPlatformAtkHyperlinkGetStartIndex(AtkHyperlink* atk_hyperlink) {
  g_return_val_if_fail(IS_AX_PLATFORM_ATK_HYPERLINK(atk_hyperlink), 0);
  AXPlatformAtkHyperlink* link = AX_PLATFORM_ATK_HYPERLINK(atk_hyperlink);
  base::Optional<std::pair<int, int>> indices =
      link->priv->platform_node->GetEmbeddedObjectIndices();
  return indices.has_value() ? indices->first : 0;
}

static int AXPlatformAtkHyperlinkGetEndIndex(AtkHyperlink* atk_hyperlink) {
  g_return_val_if_fail(IS_AX_PLATFORM_ATK_HYPERLINK(atk_hyperlink), 0);
  AXPlatformAtkHyperlink* link = AX_PLATFORM_ATK_HYPERLINK(atk_hyperlink);
  base::Optional<std::pair<int, int>> indices =
      link->priv->platform_node->GetEmbeddedObjectIndices();
  return indices.has_value() ? indices->second : 0;
}

static void AXPlatformAtkHyperlinkClassInit(AtkHyperlinkClass* klass) {
  GObjectClass* gobject_class = G_OBJECT_CLASS(klass);
  kAXPlatformAtkHyperlinkParentClass = g_type_class_peek_parent(klass);

  g_type_class_add_private(gobject_class,
                           sizeof(AXPlatformAtkHyperlinkPrivate));

  gobject_class->finalize = AXPlatformAtkHyperlinkFinalize;
  klass->get_uri = AXPlatformAtkHyperlinkGetUri;
  klass->get_object = AXPlatformAtkHyperlinkGetObject;
  klass->is_valid = AXPlatformAtkHyperlinkIsValid;
  klass->get_n_anchors = AXPlatformAtkHyperlinkGetNAnchors;
  klass->is_selected_link = AXPlatformAtkHyperlinkIsSelectedLink;
  klass->get_start_index = AXPlatformAtkHyperlinkGetStartIndex;
  klass->get_end_index = AXPlatformAtkHyperlinkGetEndIndex;
}

//
// AtkAction interface.
//

static AXPlatformNodeAuraLinux* ToAXPlatformNodeAuraLinuxFromHyperlinkAction(
    AtkAction* atk_action) {
  if (!IS_AX_PLATFORM_ATK_HYPERLINK(atk_action))
    return nullptr;

  return ToAXPlatformNodeAuraLinux(AX_PLATFORM_ATK_HYPERLINK(atk_action));
}

static gboolean ax_platform_atk_hyperlink_do_action(AtkAction* action,
                                                    gint index) {
  g_return_val_if_fail(ATK_IS_ACTION(action), FALSE);
  g_return_val_if_fail(!index, FALSE);

  AXPlatformNodeAuraLinux* obj =
      ToAXPlatformNodeAuraLinuxFromHyperlinkAction(action);
  if (!obj)
    return FALSE;

  obj->DoDefaultAction();

  return TRUE;
}

static gint ax_platform_atk_hyperlink_get_n_actions(AtkAction* action) {
  g_return_val_if_fail(ATK_IS_ACTION(action), FALSE);

  AXPlatformNodeAuraLinux* obj =
      ToAXPlatformNodeAuraLinuxFromHyperlinkAction(action);
  if (!obj)
    return 0;

  return 1;
}

static const gchar* ax_platform_atk_hyperlink_get_description(AtkAction* action,
                                                              gint index) {
  g_return_val_if_fail(ATK_IS_ACTION(action), FALSE);
  g_return_val_if_fail(!index, FALSE);

  AXPlatformNodeAuraLinux* obj =
      ToAXPlatformNodeAuraLinuxFromHyperlinkAction(action);
  if (!obj)
    return nullptr;

  // Not implemented
  return nullptr;
}

static const gchar* ax_platform_atk_hyperlink_get_keybinding(AtkAction* action,
                                                             gint index) {
  g_return_val_if_fail(ATK_IS_ACTION(action), FALSE);
  g_return_val_if_fail(!index, FALSE);

  AXPlatformNodeAuraLinux* obj =
      ToAXPlatformNodeAuraLinuxFromHyperlinkAction(action);
  if (!obj)
    return nullptr;

  return obj->GetStringAttribute(ax::mojom::StringAttribute::kAccessKey)
      .c_str();
}

static const gchar* ax_platform_atk_hyperlink_get_name(AtkAction* atk_action,
                                                       gint index) {
  g_return_val_if_fail(ATK_IS_ACTION(atk_action), FALSE);
  g_return_val_if_fail(!index, FALSE);

  AXPlatformNodeAuraLinux* obj =
      ToAXPlatformNodeAuraLinuxFromHyperlinkAction(atk_action);
  if (!obj)
    return nullptr;

  int action;
  if (!obj->GetIntAttribute(ax::mojom::IntAttribute::kDefaultActionVerb,
                            &action))
    return nullptr;
  std::string action_verb =
      ui::ToString(static_cast<ax::mojom::DefaultActionVerb>(action));
  ATK_AURALINUX_RETURN_STRING(action_verb);
}

static const gchar* ax_platform_atk_hyperlink_get_localized_name(
    AtkAction* atk_action,
    gint index) {
  g_return_val_if_fail(ATK_IS_ACTION(atk_action), FALSE);
  g_return_val_if_fail(!index, FALSE);

  AXPlatformNodeAuraLinux* obj =
      ToAXPlatformNodeAuraLinuxFromHyperlinkAction(atk_action);
  if (!obj)
    return nullptr;

  int action;
  if (!obj->GetIntAttribute(ax::mojom::IntAttribute::kDefaultActionVerb,
                            &action))
    return nullptr;
  std::string action_verb =
      ui::ToLocalizedString(static_cast<ax::mojom::DefaultActionVerb>(action));
  ATK_AURALINUX_RETURN_STRING(action_verb);
}

static void atk_action_interface_init(AtkActionIface* iface) {
  iface->do_action = ax_platform_atk_hyperlink_do_action;
  iface->get_n_actions = ax_platform_atk_hyperlink_get_n_actions;
  iface->get_description = ax_platform_atk_hyperlink_get_description;
  iface->get_keybinding = ax_platform_atk_hyperlink_get_keybinding;
  iface->get_name = ax_platform_atk_hyperlink_get_name;
  iface->get_localized_name = ax_platform_atk_hyperlink_get_localized_name;
}

void ax_platform_atk_hyperlink_set_object(
    AXPlatformAtkHyperlink* atk_hyperlink,
    AXPlatformNodeAuraLinux* platform_node) {
  g_return_if_fail(AX_PLATFORM_ATK_HYPERLINK(atk_hyperlink));
  atk_hyperlink->priv->platform_node = platform_node;
}

static void AXPlatformAtkHyperlinkInit(AXPlatformAtkHyperlink* self, gpointer) {
  AXPlatformAtkHyperlinkPrivate* priv =
      G_TYPE_INSTANCE_GET_PRIVATE(self, ax_platform_atk_hyperlink_get_type(),
                                  AXPlatformAtkHyperlinkPrivate);
  self->priv = priv;
  new (priv) AXPlatformAtkHyperlinkPrivate();
}

GType ax_platform_atk_hyperlink_get_type() {
  static volatile gsize type_volatile = 0;

  AXPlatformNodeAuraLinux::EnsureGTypeInit();

  if (g_once_init_enter(&type_volatile)) {
    static const GTypeInfo tinfo = {
        sizeof(AXPlatformAtkHyperlinkClass),
        (GBaseInitFunc) nullptr,
        (GBaseFinalizeFunc) nullptr,
        (GClassInitFunc)AXPlatformAtkHyperlinkClassInit,
        (GClassFinalizeFunc) nullptr,
        nullptr,                        /* class data */
        sizeof(AXPlatformAtkHyperlink), /* instance size */
        0,                              /* nb preallocs */
        (GInstanceInitFunc)AXPlatformAtkHyperlinkInit,
        nullptr /* value table */
    };

    static const GInterfaceInfo actionInfo = {
        (GInterfaceInitFunc)(GInterfaceInitFunc)atk_action_interface_init,
        (GInterfaceFinalizeFunc)0, 0};

    GType type = g_type_register_static(
        ATK_TYPE_HYPERLINK, "AXPlatformAtkHyperlink", &tinfo, GTypeFlags(0));
    g_type_add_interface_static(type, ATK_TYPE_ACTION, &actionInfo);
    g_once_init_leave(&type_volatile, type);
  }

  return type_volatile;
}

}  // namespace ui
