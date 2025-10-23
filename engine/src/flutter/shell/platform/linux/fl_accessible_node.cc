// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_accessible_node.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"

// Maps Flutter semantics actions to ATK actions.
typedef struct {
  FlutterSemanticsAction action;
  const gchar* name;
} ActionData;
static ActionData action_mapping[] = {
    {kFlutterSemanticsActionTap, "Tap"},
    {kFlutterSemanticsActionLongPress, "LongPress"},
    {kFlutterSemanticsActionScrollLeft, "ScrollLeft"},
    {kFlutterSemanticsActionScrollRight, "ScrollRight"},
    {kFlutterSemanticsActionScrollUp, "ScrollUp"},
    {kFlutterSemanticsActionScrollDown, "ScrollDown"},
    {kFlutterSemanticsActionIncrease, "Increase"},
    {kFlutterSemanticsActionDecrease, "Decrease"},
    {kFlutterSemanticsActionShowOnScreen, "ShowOnScreen"},
    {kFlutterSemanticsActionMoveCursorForwardByCharacter,
     "MoveCursorForwardByCharacter"},
    {kFlutterSemanticsActionMoveCursorBackwardByCharacter,
     "MoveCursorBackwardByCharacter"},
    {kFlutterSemanticsActionCopy, "Copy"},
    {kFlutterSemanticsActionCut, "Cut"},
    {kFlutterSemanticsActionPaste, "Paste"},
    {kFlutterSemanticsActionDidGainAccessibilityFocus,
     "DidGainAccessibilityFocus"},
    {kFlutterSemanticsActionDidLoseAccessibilityFocus,
     "DidLoseAccessibilityFocus"},
    {kFlutterSemanticsActionCustomAction, "CustomAction"},
    {kFlutterSemanticsActionDismiss, "Dismiss"},
    {kFlutterSemanticsActionMoveCursorForwardByWord, "MoveCursorForwardByWord"},
    {kFlutterSemanticsActionMoveCursorBackwardByWord,
     "MoveCursorBackwardByWord"},
    {kFlutterSemanticsActionFocus, "Focus"},
    {kFlutterSemanticsActionExpand, "Expand"},
    {kFlutterSemanticsActionCollapse, "Collapse"},
    {static_cast<FlutterSemanticsAction>(0), nullptr}};

struct FlAccessibleNodePrivate {
  AtkObject parent_instance;

  // Weak reference to the engine this node is created for.
  FlEngine* engine;

  /// The unique identifier of the view to which this node belongs.
  FlutterViewId view_id;

  // Weak reference to the parent node of this one or %NULL.
  AtkObject* parent;

  int32_t node_id;
  gchar* name;
  gint index;
  gint x, y, width, height;
  GPtrArray* actions;
  gsize actions_length;
  GPtrArray* children;
  FlutterSemanticsFlags flags;
};

enum { PROP_0, PROP_ENGINE, PROP_VIEW_ID, PROP_ID, PROP_LAST };

#define FL_ACCESSIBLE_NODE_GET_PRIVATE(node)                          \
  ((FlAccessibleNodePrivate*)fl_accessible_node_get_instance_private( \
      FL_ACCESSIBLE_NODE(node)))

static void fl_accessible_node_component_interface_init(
    AtkComponentIface* iface);
static void fl_accessible_node_action_interface_init(AtkActionIface* iface);

G_DEFINE_TYPE_WITH_CODE(
    FlAccessibleNode,
    fl_accessible_node,
    ATK_TYPE_OBJECT,
    G_ADD_PRIVATE(FlAccessibleNode)
        G_IMPLEMENT_INTERFACE(ATK_TYPE_COMPONENT,
                              fl_accessible_node_component_interface_init)
            G_IMPLEMENT_INTERFACE(ATK_TYPE_ACTION,
                                  fl_accessible_node_action_interface_init))

// Returns TRUE if [flags] indicate this element is checkable.
static gboolean is_checkable(FlutterSemanticsFlags flags) {
  return flags.is_checked != kFlutterCheckStateNone ||
         flags.is_toggled != kFlutterTristateNone;
}

// Returns TRUE if [flags] indicate this element is checked.
static gboolean is_checked(FlutterSemanticsFlags flags) {
  return flags.is_checked == kFlutterCheckStateTrue ||
         flags.is_toggled == kFlutterTristateTrue;
}

// Returns TRUE if [flags] indicate this element is focusable.
static gboolean is_focusable(FlutterSemanticsFlags flags) {
  return flags.is_focused != kFlutterTristateNone;
}

// Returns TRUE if [flags] indicate this element is focused.
static gboolean is_focused(FlutterSemanticsFlags flags) {
  return flags.is_focused == kFlutterTristateTrue;
}

// Returns TRUE if [flags] indicate this element is selected.
static gboolean is_selected(FlutterSemanticsFlags flags) {
  return flags.is_selected == kFlutterTristateTrue;
}

// Returns TRUE if [flags] indicate this element is sensitive.
static gboolean is_sensitive(FlutterSemanticsFlags flags) {
  return flags.is_enabled != kFlutterTristateNone;
}

// Returns TRUE if [flags] indicate this element is enabled.
static gboolean is_enabled(FlutterSemanticsFlags flags) {
  return flags.is_enabled == kFlutterTristateTrue;
}

// Returns TRUE if [action] is set in [actions].
static gboolean has_action(FlutterSemanticsAction actions,
                           FlutterSemanticsAction action) {
  return (actions & action) != 0;
}

// Gets the nth action.
static ActionData* get_action(FlAccessibleNodePrivate* priv, gint index) {
  if (index < 0 || static_cast<guint>(index) >= priv->actions->len) {
    return nullptr;
  }
  return static_cast<ActionData*>(g_ptr_array_index(priv->actions, index));
}

// Checks if [object] is in [children].
static gboolean has_child(GPtrArray* children, AtkObject* object) {
  for (guint i = 0; i < children->len; i++) {
    if (g_ptr_array_index(children, i) == object) {
      return TRUE;
    }
  }

  return FALSE;
}

static void fl_accessible_node_set_property(GObject* object,
                                            guint prop_id,
                                            const GValue* value,
                                            GParamSpec* pspec) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(object);
  switch (prop_id) {
    case PROP_ENGINE:
      g_assert(priv->engine == nullptr);
      priv->engine = FL_ENGINE(g_value_get_object(value));
      g_object_add_weak_pointer(object,
                                reinterpret_cast<gpointer*>(&priv->engine));
      break;
    case PROP_VIEW_ID:
      priv->view_id = g_value_get_int64(value);
      break;
    case PROP_ID:
      priv->node_id = g_value_get_int(value);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
      break;
  }
}

static void fl_accessible_node_dispose(GObject* object) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(object);

  if (priv->engine != nullptr) {
    g_object_remove_weak_pointer(object,
                                 reinterpret_cast<gpointer*>(&(priv->engine)));
    priv->engine = nullptr;
  }
  if (priv->parent != nullptr) {
    g_object_remove_weak_pointer(object,
                                 reinterpret_cast<gpointer*>(&(priv->parent)));
    priv->parent = nullptr;
  }
  g_clear_pointer(&priv->name, g_free);
  g_clear_pointer(&priv->actions, g_ptr_array_unref);
  g_clear_pointer(&priv->children, g_ptr_array_unref);

  G_OBJECT_CLASS(fl_accessible_node_parent_class)->dispose(object);
}

// Implements AtkObject::get_name.
static const gchar* fl_accessible_node_get_name(AtkObject* accessible) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(accessible);
  return priv->name;
}

// Implements AtkObject::get_parent.
static AtkObject* fl_accessible_node_get_parent(AtkObject* accessible) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(accessible);
  return priv->parent;
}

// Implements AtkObject::get_index_in_parent.
static gint fl_accessible_node_get_index_in_parent(AtkObject* accessible) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(accessible);
  return priv->index;
}

// Implements AtkObject::get_n_children.
static gint fl_accessible_node_get_n_children(AtkObject* accessible) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(accessible);
  return priv->children->len;
}

// Implements AtkObject::ref_child.
static AtkObject* fl_accessible_node_ref_child(AtkObject* accessible, gint i) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(accessible);

  if (i < 0 || static_cast<guint>(i) >= priv->children->len) {
    return nullptr;
  }

  return ATK_OBJECT(g_object_ref(g_ptr_array_index(priv->children, i)));
}

// Implements AtkObject::get_role.
static AtkRole fl_accessible_node_get_role(AtkObject* accessible) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(accessible);
  if (priv->flags.is_button) {
    return ATK_ROLE_PUSH_BUTTON;
  }
  if (priv->flags.is_in_mutually_exclusive_group &&
      priv->flags.is_checked != kFlutterCheckStateNone) {
    return ATK_ROLE_RADIO_BUTTON;
  }
  if (priv->flags.is_checked != kFlutterCheckStateNone) {
    return ATK_ROLE_CHECK_BOX;
  }
  if (priv->flags.is_toggled != kFlutterTristateNone) {
    return ATK_ROLE_TOGGLE_BUTTON;
  }
  if (priv->flags.is_slider) {
    return ATK_ROLE_SLIDER;
  }
  if (priv->flags.is_text_field && priv->flags.is_obscured) {
    return ATK_ROLE_PASSWORD_TEXT;
  }
  if (priv->flags.is_text_field) {
    return ATK_ROLE_TEXT;
  }
  if (priv->flags.is_header) {
    return ATK_ROLE_HEADER;
  }
  if (priv->flags.is_link) {
    return ATK_ROLE_LINK;
  }
  if (priv->flags.is_image) {
    return ATK_ROLE_IMAGE;
  }

  return ATK_ROLE_PANEL;
}

// Implements AtkObject::ref_state_set.
static AtkStateSet* fl_accessible_node_ref_state_set(AtkObject* accessible) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(accessible);

  AtkStateSet* state_set = atk_state_set_new();

  if (!priv->flags.is_obscured) {
    atk_state_set_add_state(state_set, ATK_STATE_SHOWING);
  }
  if (!priv->flags.is_hidden) {
    atk_state_set_add_state(state_set, ATK_STATE_VISIBLE);
  }
  if (is_checkable(priv->flags)) {
    atk_state_set_add_state(state_set, ATK_STATE_CHECKABLE);
  }
  if (is_checked(priv->flags)) {
    atk_state_set_add_state(state_set, ATK_STATE_CHECKED);
  }
  if (is_focusable(priv->flags)) {
    atk_state_set_add_state(state_set, ATK_STATE_FOCUSABLE);
  }
  if (is_focused(priv->flags)) {
    atk_state_set_add_state(state_set, ATK_STATE_FOCUSED);
  }
  if (is_selected(priv->flags)) {
    atk_state_set_add_state(state_set, ATK_STATE_SELECTED);
  }
  if (is_enabled(priv->flags)) {
    atk_state_set_add_state(state_set, ATK_STATE_ENABLED);
  }
  if (is_sensitive(priv->flags)) {
    atk_state_set_add_state(state_set, ATK_STATE_SENSITIVE);
  }
  if (priv->flags.is_read_only) {
    atk_state_set_add_state(state_set, ATK_STATE_READ_ONLY);
  }
  if (priv->flags.is_text_field) {
    atk_state_set_add_state(state_set, ATK_STATE_EDITABLE);
  }

  return state_set;
}

// Implements AtkComponent::get_extents.
static void fl_accessible_node_get_extents(AtkComponent* component,
                                           gint* x,
                                           gint* y,
                                           gint* width,
                                           gint* height,
                                           AtkCoordType coord_type) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(component);

  *x = 0;
  *y = 0;
  if (priv->parent != nullptr) {
    atk_component_get_extents(ATK_COMPONENT(priv->parent), x, y, nullptr,
                              nullptr, coord_type);
  }

  *x += priv->x;
  *y += priv->y;
  *width = priv->width;
  *height = priv->height;
}

// Implements AtkComponent::get_layer.
static AtkLayer fl_accessible_node_get_layer(AtkComponent* component) {
  return ATK_LAYER_WIDGET;
}

// Implements AtkAction::do_action.
static gboolean fl_accessible_node_do_action(AtkAction* action, gint i) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(action);

  if (priv->engine == nullptr) {
    return FALSE;
  }

  ActionData* data = get_action(priv, i);
  if (data == nullptr) {
    return FALSE;
  }

  fl_accessible_node_perform_action(FL_ACCESSIBLE_NODE(action), data->action,
                                    nullptr);
  return TRUE;
}

// Implements AtkAction::get_n_actions.
static gint fl_accessible_node_get_n_actions(AtkAction* action) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(action);
  return priv->actions->len;
}

// Implements AtkAction::get_name.
static const gchar* fl_accessible_node_get_name(AtkAction* action, gint i) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(action);

  ActionData* data = get_action(priv, i);
  if (data == nullptr) {
    return nullptr;
  }

  return data->name;
}

// Implements FlAccessibleNode::set_name.
static void fl_accessible_node_set_name_impl(FlAccessibleNode* self,
                                             const gchar* name) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(self);
  g_free(priv->name);
  priv->name = g_strdup(name);
}

// Implements FlAccessibleNode::set_extents.
static void fl_accessible_node_set_extents_impl(FlAccessibleNode* self,
                                                gint x,
                                                gint y,
                                                gint width,
                                                gint height) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(self);
  priv->x = x;
  priv->y = y;
  priv->width = width;
  priv->height = height;
}

// Check two boolean flags are different, in a way that handles true values
// being different (e.g. 1 and 2).
static bool flag_changed(bool old_flag, bool new_flag) {
  return !old_flag != !new_flag;
}

// Implements FlAccessibleNode::set_flags.
static void fl_accessible_node_set_flags_impl(FlAccessibleNode* self,
                                              FlutterSemanticsFlags* flags) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(self);

  FlutterSemanticsFlags old_flags = priv->flags;
  priv->flags = *flags;

  if (flag_changed(old_flags.is_obscured, flags->is_obscured)) {
    atk_object_notify_state_change(ATK_OBJECT(self), ATK_STATE_SHOWING,
                                   !flags->is_obscured);
  }
  if (flag_changed(old_flags.is_hidden, flags->is_hidden)) {
    atk_object_notify_state_change(ATK_OBJECT(self), ATK_STATE_VISIBLE,
                                   !flags->is_hidden);
  }
  if (flag_changed(is_checkable(old_flags), is_checkable(priv->flags))) {
    atk_object_notify_state_change(ATK_OBJECT(self), ATK_STATE_CHECKABLE,
                                   is_checkable(priv->flags));
  }
  if (flag_changed(is_checked(old_flags), is_checked(priv->flags))) {
    atk_object_notify_state_change(ATK_OBJECT(self), ATK_STATE_CHECKED,
                                   is_checked(priv->flags));
  }
  if (flag_changed(is_focusable(old_flags), is_focusable(priv->flags))) {
    atk_object_notify_state_change(ATK_OBJECT(self), ATK_STATE_FOCUSABLE,
                                   is_focusable(priv->flags));
  }
  if (flag_changed(is_focused(old_flags), is_focused(priv->flags))) {
    atk_object_notify_state_change(ATK_OBJECT(self), ATK_STATE_FOCUSED,
                                   is_focused(priv->flags));
  }
  if (flag_changed(is_selected(old_flags), is_selected(priv->flags))) {
    atk_object_notify_state_change(ATK_OBJECT(self), ATK_STATE_SELECTED,
                                   is_selected(priv->flags));
  }
  if (flag_changed(is_sensitive(old_flags), is_sensitive(priv->flags))) {
    atk_object_notify_state_change(ATK_OBJECT(self), ATK_STATE_SENSITIVE,
                                   is_sensitive(priv->flags));
  }
  if (flag_changed(is_enabled(old_flags), is_enabled(priv->flags))) {
    atk_object_notify_state_change(ATK_OBJECT(self), ATK_STATE_ENABLED,
                                   is_enabled(priv->flags));
  }
  if (flag_changed(old_flags.is_read_only, flags->is_read_only)) {
    atk_object_notify_state_change(ATK_OBJECT(self), ATK_STATE_READ_ONLY,
                                   flags->is_read_only);
  }
  if (flag_changed(old_flags.is_text_field, flags->is_text_field)) {
    atk_object_notify_state_change(ATK_OBJECT(self), ATK_STATE_EDITABLE,
                                   flags->is_text_field);
  }
}

// Implements FlAccessibleNode::set_actions.
static void fl_accessible_node_set_actions_impl(
    FlAccessibleNode* self,
    FlutterSemanticsAction actions) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(self);

  // NOTE(robert-ancell): It appears that AtkAction doesn't have a method of
  // notifying that actions have changed, and even if it did an ATK client
  // might access the old IDs before checking for new ones. Keep an eye
  // out for a case where Flutter changes the actions on an item and see
  // if we can resolve this in another way.
  g_ptr_array_remove_range(priv->actions, 0, priv->actions->len);
  for (int i = 0; action_mapping[i].name != nullptr; i++) {
    if (has_action(actions, action_mapping[i].action)) {
      g_ptr_array_add(priv->actions, &action_mapping[i]);
    }
  }
}

// Implements FlAccessibleNode::set_value.
static void fl_accessible_node_set_value_impl(FlAccessibleNode* self,
                                              const gchar* value) {}

// Implements FlAccessibleNode::set_text_selection.
static void fl_accessible_node_set_text_selection_impl(FlAccessibleNode* self,
                                                       gint base,
                                                       gint extent) {}

// Implements FlAccessibleNode::set_text_direction.
static void fl_accessible_node_set_text_direction_impl(
    FlAccessibleNode* self,
    FlutterTextDirection direction) {}

// Implements FlAccessibleNode::perform_action.
static void fl_accessible_node_perform_action_impl(
    FlAccessibleNode* self,
    FlutterSemanticsAction action,
    GBytes* data) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(self);
  fl_engine_dispatch_semantics_action(priv->engine, priv->view_id,
                                      priv->node_id, action, data);
}

static void fl_accessible_node_class_init(FlAccessibleNodeClass* klass) {
  G_OBJECT_CLASS(klass)->set_property = fl_accessible_node_set_property;
  G_OBJECT_CLASS(klass)->dispose = fl_accessible_node_dispose;
  ATK_OBJECT_CLASS(klass)->get_name = fl_accessible_node_get_name;
  ATK_OBJECT_CLASS(klass)->get_parent = fl_accessible_node_get_parent;
  ATK_OBJECT_CLASS(klass)->get_index_in_parent =
      fl_accessible_node_get_index_in_parent;
  ATK_OBJECT_CLASS(klass)->get_n_children = fl_accessible_node_get_n_children;
  ATK_OBJECT_CLASS(klass)->ref_child = fl_accessible_node_ref_child;
  ATK_OBJECT_CLASS(klass)->get_role = fl_accessible_node_get_role;
  ATK_OBJECT_CLASS(klass)->ref_state_set = fl_accessible_node_ref_state_set;
  FL_ACCESSIBLE_NODE_CLASS(klass)->set_name = fl_accessible_node_set_name_impl;
  FL_ACCESSIBLE_NODE_CLASS(klass)->set_extents =
      fl_accessible_node_set_extents_impl;
  FL_ACCESSIBLE_NODE_CLASS(klass)->set_flags =
      fl_accessible_node_set_flags_impl;
  FL_ACCESSIBLE_NODE_CLASS(klass)->set_actions =
      fl_accessible_node_set_actions_impl;
  FL_ACCESSIBLE_NODE_CLASS(klass)->set_value =
      fl_accessible_node_set_value_impl;
  FL_ACCESSIBLE_NODE_CLASS(klass)->set_text_selection =
      fl_accessible_node_set_text_selection_impl;
  FL_ACCESSIBLE_NODE_CLASS(klass)->set_text_direction =
      fl_accessible_node_set_text_direction_impl;
  FL_ACCESSIBLE_NODE_CLASS(klass)->perform_action =
      fl_accessible_node_perform_action_impl;

  g_object_class_install_property(
      G_OBJECT_CLASS(klass), PROP_ENGINE,
      g_param_spec_object(
          "engine", "engine", "Flutter engine", fl_engine_get_type(),
          static_cast<GParamFlags>(G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY |
                                   G_PARAM_STATIC_STRINGS)));
  g_object_class_install_property(
      G_OBJECT_CLASS(klass), PROP_VIEW_ID,
      g_param_spec_int64(
          "view-id", "view-id", "View ID that this node belongs to", 0,
          G_MAXINT64, 0,
          static_cast<GParamFlags>(G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY)));
  g_object_class_install_property(
      G_OBJECT_CLASS(klass), PROP_ID,
      g_param_spec_int(
          "node-id", "node-id", "Accessibility node ID", 0, G_MAXINT, 0,
          static_cast<GParamFlags>(G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY |
                                   G_PARAM_STATIC_STRINGS)));
}

static void fl_accessible_node_component_interface_init(
    AtkComponentIface* iface) {
  iface->get_extents = fl_accessible_node_get_extents;
  iface->get_layer = fl_accessible_node_get_layer;
}

static void fl_accessible_node_action_interface_init(AtkActionIface* iface) {
  iface->do_action = fl_accessible_node_do_action;
  iface->get_n_actions = fl_accessible_node_get_n_actions;
  iface->get_name = fl_accessible_node_get_name;
}

static void fl_accessible_node_init(FlAccessibleNode* self) {
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(self);
  priv->actions = g_ptr_array_new();
  priv->children = g_ptr_array_new_with_free_func(g_object_unref);
}

FlAccessibleNode* fl_accessible_node_new(FlEngine* engine,
                                         FlutterViewId view_id,
                                         int32_t node_id) {
  FlAccessibleNode* self = FL_ACCESSIBLE_NODE(
      g_object_new(fl_accessible_node_get_type(), "engine", engine, "view-id",
                   view_id, "node-id", node_id, nullptr));
  return self;
}

void fl_accessible_node_set_parent(FlAccessibleNode* self,
                                   AtkObject* parent,
                                   gint index) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(self);
  priv->parent = parent;
  priv->index = index;
  g_object_add_weak_pointer(G_OBJECT(self),
                            reinterpret_cast<gpointer*>(&(priv->parent)));
}

void fl_accessible_node_set_children(FlAccessibleNode* self,
                                     GPtrArray* children) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));
  FlAccessibleNodePrivate* priv = FL_ACCESSIBLE_NODE_GET_PRIVATE(self);

  // Remove nodes that are no longer required.
  for (guint i = 0; i < priv->children->len;) {
    AtkObject* object = ATK_OBJECT(g_ptr_array_index(priv->children, i));
    if (has_child(children, object)) {
      i++;
    } else {
      g_signal_emit_by_name(self, "children-changed::remove", i, object,
                            nullptr);
      g_ptr_array_remove_index(priv->children, i);
    }
  }

  // Add new nodes.
  for (guint i = 0; i < children->len; i++) {
    AtkObject* object = ATK_OBJECT(g_ptr_array_index(children, i));
    if (!has_child(priv->children, object)) {
      g_ptr_array_add(priv->children, g_object_ref(object));
      g_signal_emit_by_name(self, "children-changed::add", i, object, nullptr);
    }
  }
}

void fl_accessible_node_set_name(FlAccessibleNode* self, const gchar* name) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));

  return FL_ACCESSIBLE_NODE_GET_CLASS(self)->set_name(self, name);
}

void fl_accessible_node_set_extents(FlAccessibleNode* self,
                                    gint x,
                                    gint y,
                                    gint width,
                                    gint height) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));

  return FL_ACCESSIBLE_NODE_GET_CLASS(self)->set_extents(self, x, y, width,
                                                         height);
}

void fl_accessible_node_set_flags(FlAccessibleNode* self,
                                  FlutterSemanticsFlags* flags) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));

  return FL_ACCESSIBLE_NODE_GET_CLASS(self)->set_flags(self, flags);
}

void fl_accessible_node_set_actions(FlAccessibleNode* self,
                                    FlutterSemanticsAction actions) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));

  return FL_ACCESSIBLE_NODE_GET_CLASS(self)->set_actions(self, actions);
}

void fl_accessible_node_set_value(FlAccessibleNode* self, const gchar* value) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));

  return FL_ACCESSIBLE_NODE_GET_CLASS(self)->set_value(self, value);
}

void fl_accessible_node_set_text_selection(FlAccessibleNode* self,
                                           gint base,
                                           gint extent) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));

  return FL_ACCESSIBLE_NODE_GET_CLASS(self)->set_text_selection(self, base,
                                                                extent);
}

void fl_accessible_node_set_text_direction(FlAccessibleNode* self,
                                           FlutterTextDirection direction) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));

  return FL_ACCESSIBLE_NODE_GET_CLASS(self)->set_text_direction(self,
                                                                direction);
}

void fl_accessible_node_perform_action(FlAccessibleNode* self,
                                       FlutterSemanticsAction action,
                                       GBytes* data) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));

  return FL_ACCESSIBLE_NODE_GET_CLASS(self)->perform_action(self, action, data);
}
