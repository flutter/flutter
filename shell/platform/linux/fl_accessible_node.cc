// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_accessible_node.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"

// Maps Flutter semantics flags to ATK flags.
static struct {
  AtkStateType state;
  FlutterSemanticsFlag flag;
  gboolean invert;
} flag_mapping[] = {
    {ATK_STATE_SHOWING, kFlutterSemanticsFlagIsObscured, TRUE},
    {ATK_STATE_VISIBLE, kFlutterSemanticsFlagIsHidden, TRUE},
    {ATK_STATE_CHECKABLE, kFlutterSemanticsFlagHasCheckedState, FALSE},
    {ATK_STATE_FOCUSABLE, kFlutterSemanticsFlagIsFocusable, FALSE},
    {ATK_STATE_FOCUSED, kFlutterSemanticsFlagIsFocused, FALSE},
    {ATK_STATE_CHECKED, kFlutterSemanticsFlagIsChecked, FALSE},
    {ATK_STATE_SELECTED, kFlutterSemanticsFlagIsSelected, FALSE},
    {ATK_STATE_ENABLED, kFlutterSemanticsFlagIsEnabled, FALSE},
    {ATK_STATE_READ_ONLY, kFlutterSemanticsFlagIsReadOnly, FALSE},
    {ATK_STATE_INVALID, static_cast<FlutterSemanticsFlag>(0), FALSE},
};

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
    {kFlutterSemanticsActionSetSelection, "SetSelection"},
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
    {static_cast<FlutterSemanticsAction>(0), nullptr}};

struct _FlAccessibleNode {
  AtkObject parent_instance;

  // Weak reference to the engine this node is created for.
  FlEngine* engine;

  // Weak reference to the parent node of this one or %NULL.
  AtkObject* parent;

  int32_t id;
  gchar* name;
  gint x, y, width, height;
  GPtrArray* actions;
  gsize actions_length;
  GPtrArray* children;
  FlutterSemanticsFlag flags;
};

static void fl_accessible_node_component_interface_init(
    AtkComponentIface* iface);
static void fl_accessible_node_action_interface_init(AtkActionIface* iface);
static void fl_accessible_node_text_interface_init(AtkTextIface* iface);

G_DEFINE_TYPE_WITH_CODE(
    FlAccessibleNode,
    fl_accessible_node,
    ATK_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(ATK_TYPE_COMPONENT,
                          fl_accessible_node_component_interface_init)
        G_IMPLEMENT_INTERFACE(ATK_TYPE_ACTION,
                              fl_accessible_node_action_interface_init)
            G_IMPLEMENT_INTERFACE(ATK_TYPE_TEXT,
                                  fl_accessible_node_text_interface_init))

// Returns TRUE if [flag] has changed between [old_flags] and [flags].
static gboolean flag_is_changed(FlutterSemanticsFlag old_flags,
                                FlutterSemanticsFlag flags,
                                FlutterSemanticsFlag flag) {
  return (old_flags & flag) != (flags & flag);
}

// Returns TRUE if [flag] is set in [flags].
static gboolean has_flag(FlutterSemanticsFlag flags,
                         FlutterSemanticsFlag flag) {
  return (flags & flag) != 0;
}

// Returns TRUE if [action] is set in [actions].
static gboolean has_action(FlutterSemanticsAction actions,
                           FlutterSemanticsAction action) {
  return (actions & action) != 0;
}

// Gets the nth action.
static ActionData* get_action(FlAccessibleNode* self, gint index) {
  if (index < 0 || static_cast<guint>(index) >= self->actions->len)
    return nullptr;
  return static_cast<ActionData*>(g_ptr_array_index(self->actions, index));
}

static void fl_accessible_node_dispose(GObject* object) {
  FlAccessibleNode* self = FL_ACCESSIBLE_NODE(object);

  if (self->engine != nullptr) {
    g_object_remove_weak_pointer(G_OBJECT(self),
                                 reinterpret_cast<gpointer*>(&(self->engine)));
    self->engine = nullptr;
  }
  if (self->parent != nullptr) {
    g_object_remove_weak_pointer(G_OBJECT(self),
                                 reinterpret_cast<gpointer*>(&(self->parent)));
    self->parent = nullptr;
  }
  g_clear_pointer(&self->name, g_free);
  g_clear_pointer(&self->actions, g_ptr_array_unref);
  g_clear_pointer(&self->children, g_ptr_array_unref);

  G_OBJECT_CLASS(fl_accessible_node_parent_class)->dispose(object);
}

// Implements AtkObject::get_name.
static const gchar* fl_accessible_node_get_name(AtkObject* accessible) {
  FlAccessibleNode* self = FL_ACCESSIBLE_NODE(accessible);
  return self->name;
}

// Implements AtkObject::get_parent.
static AtkObject* fl_accessible_node_get_parent(AtkObject* accessible) {
  FlAccessibleNode* self = FL_ACCESSIBLE_NODE(accessible);
  return self->parent;
}

// Implements AtkObject::get_n_children.
static gint fl_accessible_node_get_n_children(AtkObject* accessible) {
  FlAccessibleNode* self = FL_ACCESSIBLE_NODE(accessible);
  return self->children->len;
}

// Implements AtkObject::ref_child.
static AtkObject* fl_accessible_node_ref_child(AtkObject* accessible, gint i) {
  FlAccessibleNode* self = FL_ACCESSIBLE_NODE(accessible);

  if (i < 0 || static_cast<guint>(i) >= self->children->len) {
    return nullptr;
  }

  return ATK_OBJECT(g_object_ref(g_ptr_array_index(self->children, i)));
}

// Implements AtkObject::get_role.
static AtkRole fl_accessible_node_get_role(AtkObject* accessible) {
  FlAccessibleNode* self = FL_ACCESSIBLE_NODE(accessible);
  if ((self->flags & kFlutterSemanticsFlagIsButton) != 0) {
    return ATK_ROLE_PUSH_BUTTON;
  }
  if ((self->flags & kFlutterSemanticsFlagIsTextField) != 0) {
    return ATK_ROLE_TEXT;
  }
  if ((self->flags & kFlutterSemanticsFlagIsHeader) != 0) {
    return ATK_ROLE_HEADER;
  }
  if ((self->flags & kFlutterSemanticsFlagIsLink) != 0) {
    return ATK_ROLE_LINK;
  }
  if ((self->flags & kFlutterSemanticsFlagIsImage) != 0) {
    return ATK_ROLE_IMAGE;
  }

  return ATK_ROLE_FRAME;
}

// Implements AtkObject::ref_state_set.
static AtkStateSet* fl_accessible_node_ref_state_set(AtkObject* accessible) {
  FlAccessibleNode* self = FL_ACCESSIBLE_NODE(accessible);

  AtkStateSet* state_set = atk_state_set_new();

  for (int i = 0; flag_mapping[i].state != ATK_STATE_INVALID; i++) {
    gboolean enabled = has_flag(self->flags, flag_mapping[i].flag);
    if (flag_mapping[i].invert) {
      enabled = !enabled;
    }
    if (enabled) {
      atk_state_set_add_state(state_set, flag_mapping[i].state);
    }
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
  FlAccessibleNode* self = FL_ACCESSIBLE_NODE(component);

  *x = 0;
  *y = 0;
  if (self->parent != nullptr) {
    atk_component_get_extents(ATK_COMPONENT(self->parent), x, y, nullptr,
                              nullptr, coord_type);
  }

  *x += self->x;
  *y += self->y;
  *width = self->width;
  *height = self->height;
}

// Implements AtkComponent::get_layer.
static AtkLayer fl_accessible_node_get_layer(AtkComponent* component) {
  return ATK_LAYER_WIDGET;
}

// Implements AtkAction::do_action.
static gboolean fl_accessible_node_do_action(AtkAction* action, gint i) {
  FlAccessibleNode* self = FL_ACCESSIBLE_NODE(action);

  if (self->engine == nullptr) {
    return FALSE;
  }

  ActionData* data = get_action(self, i);
  if (data == nullptr) {
    return FALSE;
  }

  fl_engine_dispatch_semantics_action(self->engine, self->id, data->action,
                                      nullptr);
  return TRUE;
}

// Implements AtkAction::get_n_actions.
static gint fl_accessible_node_get_n_actions(AtkAction* action) {
  FlAccessibleNode* self = FL_ACCESSIBLE_NODE(action);
  return self->actions->len;
}

// Implements AtkAction::get_name.
static const gchar* fl_accessible_node_get_name(AtkAction* action, gint i) {
  FlAccessibleNode* self = FL_ACCESSIBLE_NODE(action);

  ActionData* data = get_action(self, i);
  if (data == nullptr) {
    return nullptr;
  }

  return data->name;
}

// Implements AtkText::get_text.
static gchar* fl_accessible_node_get_text(AtkText* text,
                                          gint start_offset,
                                          gint end_offset) {
  return nullptr;
}

static void fl_accessible_node_class_init(FlAccessibleNodeClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_accessible_node_dispose;
  ATK_OBJECT_CLASS(klass)->get_name = fl_accessible_node_get_name;
  ATK_OBJECT_CLASS(klass)->get_parent = fl_accessible_node_get_parent;
  ATK_OBJECT_CLASS(klass)->get_n_children = fl_accessible_node_get_n_children;
  ATK_OBJECT_CLASS(klass)->ref_child = fl_accessible_node_ref_child;
  ATK_OBJECT_CLASS(klass)->get_role = fl_accessible_node_get_role;
  ATK_OBJECT_CLASS(klass)->ref_state_set = fl_accessible_node_ref_state_set;
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

static void fl_accessible_node_text_interface_init(AtkTextIface* iface) {
  iface->get_text = fl_accessible_node_get_text;
}

static void fl_accessible_node_init(FlAccessibleNode* self) {
  self->actions = g_ptr_array_new();
  self->children = g_ptr_array_new_with_free_func(g_object_unref);
}

FlAccessibleNode* fl_accessible_node_new(FlEngine* engine, int32_t id) {
  FlAccessibleNode* self =
      FL_ACCESSIBLE_NODE(g_object_new(fl_accessible_node_get_type(), nullptr));
  self->engine = engine;
  g_object_add_weak_pointer(G_OBJECT(self),
                            reinterpret_cast<gpointer*>(&(self->engine)));
  self->id = id;
  return self;
}

void fl_accessible_node_set_parent(FlAccessibleNode* self, AtkObject* parent) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));
  self->parent = parent;
  g_object_add_weak_pointer(G_OBJECT(self),
                            reinterpret_cast<gpointer*>(&(self->parent)));
}

void fl_accessible_node_set_children(FlAccessibleNode* self,
                                     GPtrArray* children) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));

  g_ptr_array_remove_range(self->children, 0, self->children->len);
  for (guint i = 0; i < children->len; i++) {
    AtkObject* object = ATK_OBJECT(g_ptr_array_index(children, i));
    g_ptr_array_add(self->children, g_object_ref(object));
    g_signal_emit_by_name(self, "children-changed::add", i, object, nullptr);
  }
}

void fl_accessible_node_set_name(FlAccessibleNode* self, const gchar* name) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));
  g_free(self->name);
  self->name = g_strdup(name);
}

void fl_accessible_node_set_extents(FlAccessibleNode* self,
                                    gint x,
                                    gint y,
                                    gint width,
                                    gint height) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));
  self->x = x;
  self->y = y;
  self->width = width;
  self->height = height;
}

void fl_accessible_node_set_flags(FlAccessibleNode* self,
                                  FlutterSemanticsFlag flags) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));

  FlutterSemanticsFlag old_flags = self->flags;
  self->flags = flags;

  for (int i = 0; flag_mapping[i].state != ATK_STATE_INVALID; i++) {
    if (flag_is_changed(old_flags, flags, flag_mapping[i].flag)) {
      gboolean enabled = has_flag(flags, flag_mapping[i].flag);
      if (flag_mapping[i].invert) {
        enabled = !enabled;
      }

      atk_object_notify_state_change(ATK_OBJECT(self), flag_mapping[i].state,
                                     enabled);
    }
  }
}

void fl_accessible_node_set_actions(FlAccessibleNode* self,
                                    FlutterSemanticsAction actions) {
  g_return_if_fail(FL_IS_ACCESSIBLE_NODE(self));

  // NOTE(robert-ancell): It appears that AtkAction doesn't have a method of
  // notifying that actions have changed, and even if it did an ATK client
  // might access the old IDs before checking for new ones. Keep an eye
  // out for a case where Flutter changes the actions on an item and see
  // if we can resolve this in another way.
  g_ptr_array_remove_range(self->actions, 0, self->actions->len);
  for (int i = 0; action_mapping[i].name != nullptr; i++) {
    if (has_action(actions, action_mapping[i].action)) {
      g_ptr_array_add(self->actions, &action_mapping[i]);
    }
  }
}
