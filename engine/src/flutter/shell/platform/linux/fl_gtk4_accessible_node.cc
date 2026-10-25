// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_gtk4_accessible_node_private.h"

#if FLUTTER_LINUX_GTK4 && defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)

#include <cmath>
#include <cstddef>

#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_gtk.h"
#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_gtk4_text_accessible_node.h"
#include "flutter/shell/platform/linux/fl_view_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_message_codec.h"

// Actions exposed without GTK parameters. Cursor movement encodes Flutter's
// boolean payload below; arbitrary selection and text edits need adapters.
static constexpr struct {
  const char* name;
  FlutterSemanticsAction action;
  bool moves_cursor = false;
} kNativeActions[] = {
    {"flutter.tap", kFlutterSemanticsActionTap},
    {"flutter.long-press", kFlutterSemanticsActionLongPress},
    {"flutter.scroll-left", kFlutterSemanticsActionScrollLeft},
    {"flutter.scroll-right", kFlutterSemanticsActionScrollRight},
    {"flutter.scroll-up", kFlutterSemanticsActionScrollUp},
    {"flutter.scroll-down", kFlutterSemanticsActionScrollDown},
    {"flutter.increase", kFlutterSemanticsActionIncrease},
    {"flutter.decrease", kFlutterSemanticsActionDecrease},
    {"flutter.show-on-screen", kFlutterSemanticsActionShowOnScreen},
    {"flutter.dismiss", kFlutterSemanticsActionDismiss},
    {"flutter.focus", kFlutterSemanticsActionFocus},
    {"flutter.expand", kFlutterSemanticsActionExpand},
    {"flutter.collapse", kFlutterSemanticsActionCollapse},
    {"flutter.copy", kFlutterSemanticsActionCopy},
    {"flutter.cut", kFlutterSemanticsActionCut},
    {"flutter.paste", kFlutterSemanticsActionPaste},
    {"flutter.move-cursor-forward-by-character",
     kFlutterSemanticsActionMoveCursorForwardByCharacter, true},
    {"flutter.move-cursor-backward-by-character",
     kFlutterSemanticsActionMoveCursorBackwardByCharacter, true},
    {"flutter.move-cursor-forward-by-word",
     kFlutterSemanticsActionMoveCursorForwardByWord, true},
    {"flutter.move-cursor-backward-by-word",
     kFlutterSemanticsActionMoveCursorBackwardByWord, true},
};

#if GTK_CHECK_VERSION(4, 10, 0)
constexpr GtkAccessibleRole kFlGtkAccessibleRoleToggleButton =
    GTK_ACCESSIBLE_ROLE_TOGGLE_BUTTON;
#else
constexpr GtkAccessibleRole kFlGtkAccessibleRoleToggleButton =
    static_cast<GtkAccessibleRole>(GTK_ACCESSIBLE_ROLE_WINDOW + 1);
#endif

#if GTK_CHECK_VERSION(4, 10, 0)
static_assert(sizeof(FlGtkAccessibleInterface4_10) ==
              sizeof(GtkAccessibleInterface));
static_assert(kFlGtkAccessibleRoleToggleButton ==
              GTK_ACCESSIBLE_ROLE_TOGGLE_BUTTON);
static_assert(offsetof(FlGtkAccessibleInterface4_10, get_at_context) ==
              offsetof(GtkAccessibleInterface, get_at_context));
static_assert(offsetof(FlGtkAccessibleInterface4_10, get_platform_state) ==
              offsetof(GtkAccessibleInterface, get_platform_state));
static_assert(offsetof(FlGtkAccessibleInterface4_10, get_accessible_parent) ==
              offsetof(GtkAccessibleInterface, get_accessible_parent));
static_assert(offsetof(FlGtkAccessibleInterface4_10,
                       get_first_accessible_child) ==
              offsetof(GtkAccessibleInterface, get_first_accessible_child));
static_assert(offsetof(FlGtkAccessibleInterface4_10,
                       get_next_accessible_sibling) ==
              offsetof(GtkAccessibleInterface, get_next_accessible_sibling));
static_assert(offsetof(FlGtkAccessibleInterface4_10, get_bounds) ==
              offsetof(GtkAccessibleInterface, get_bounds));
#endif

static void fl_gtk4_accessible_node_accessible_iface_init(
    GtkAccessibleInterface* iface);

G_DEFINE_TYPE_WITH_CODE(
    FlGtk4AccessibleNode,
    fl_gtk4_accessible_node,
    GTK_TYPE_WIDGET,
    G_IMPLEMENT_INTERFACE(GTK_TYPE_ACCESSIBLE,
                          fl_gtk4_accessible_node_accessible_iface_init))

static GtkAccessibleRole fl_gtk4_accessible_node_get_role(
    const FlAccessibilitySemanticsNode* semantics) {
  const FlutterSemanticsFlags* flags = &semantics->flags;

  // GtkEntry and GtkPasswordEntry both use TEXT_BOX. Read-only is represented
  // by GTK_ACCESSIBLE_PROPERTY_READ_ONLY rather than a distinct role.
  if (flags->is_text_field) {
    return GTK_ACCESSIBLE_ROLE_TEXT_BOX;
  }
  if (flags->is_in_mutually_exclusive_group &&
      flags->is_checked != kFlutterCheckStateNone) {
    return GTK_ACCESSIBLE_ROLE_RADIO;
  }
  if (flags->is_checked != kFlutterCheckStateNone) {
    return GTK_ACCESSIBLE_ROLE_CHECKBOX;
  }
  if (flags->is_toggled != kFlutterTristateNone) {
    return kFlGtkAccessibleRoleToggleButton;
  }
  if (flags->is_slider) {
    return GTK_ACCESSIBLE_ROLE_SLIDER;
  }
  if (flags->is_button) {
    return GTK_ACCESSIBLE_ROLE_BUTTON;
  }
  if (flags->is_header || semantics->heading_level > 0) {
    return GTK_ACCESSIBLE_ROLE_HEADING;
  }
  if (flags->is_image) {
    return GTK_ACCESSIBLE_ROLE_IMG;
  }
  if (flags->is_link) {
    return GTK_ACCESSIBLE_ROLE_LINK;
  }
  // Scroll containers may temporarily have no exported children or available
  // directional actions. Keep their container role at scroll boundaries and
  // as children appear. Explicit control roles above still take precedence.
  const uint64_t scroll_actions =
      kFlutterSemanticsActionScrollLeft | kFlutterSemanticsActionScrollRight |
      kFlutterSemanticsActionScrollUp | kFlutterSemanticsActionScrollDown;
  if (flags->has_implicit_scrolling || (semantics->actions & scroll_actions)) {
    // A semantic group preserves the name; GTK's generic containers prohibit
    // accessible names, even when the label property is supplied.
    return GTK_ACCESSIBLE_ROLE_GROUP;
  }
  const bool has_label =
      semantics->label != nullptr && semantics->label[0] != '\0';
  if (semantics->child_count > 0) {
    // Layout-only containers preserve traversal without claiming a semantic
    // grouping. Named containers still need GROUP to expose their names.
    return has_label ? GTK_ACCESSIBLE_ROLE_GROUP : GTK_ACCESSIBLE_ROLE_GENERIC;
  }
  if (has_label || (!flags->is_obscured && semantics->value != nullptr &&
                    semantics->value[0] != '\0')) {
    // Value-only leaves use the value as their name below. GENERIC prohibits
    // names and would hide that text from assistive technology.
    return GTK_ACCESSIBLE_ROLE_LABEL;
  }
  return GTK_ACCESSIBLE_ROLE_GENERIC;
}

static void fl_gtk4_accessible_node_set_string_property(
    FlGtk4AccessibleNode* self,
    GtkAccessibleProperty property,
    const gchar* value) {
  if (value == nullptr || value[0] == '\0') {
    gtk_accessible_reset_property(GTK_ACCESSIBLE(self), property);
    return;
  }

  GtkAccessibleProperty properties[] = {property};
  GValue property_value = G_VALUE_INIT;
  gtk_accessible_property_init_value(property, &property_value);
  g_value_set_string(&property_value, value);
  gtk_accessible_update_property_value(GTK_ACCESSIBLE(self), 1, properties,
                                       &property_value);
  g_value_unset(&property_value);
}

static void fl_gtk4_accessible_node_set_bool_property(
    FlGtk4AccessibleNode* self,
    GtkAccessibleProperty property,
    gboolean value) {
  GtkAccessibleProperty properties[] = {property};
  GValue property_value = G_VALUE_INIT;
  gtk_accessible_property_init_value(property, &property_value);
  g_value_set_boolean(&property_value, value);
  gtk_accessible_update_property_value(GTK_ACCESSIBLE(self), 1, properties,
                                       &property_value);
  g_value_unset(&property_value);
}

static void fl_gtk4_accessible_node_set_int_property(
    FlGtk4AccessibleNode* self,
    GtkAccessibleProperty property,
    gint value) {
  GtkAccessibleProperty properties[] = {property};
  GValue property_value = G_VALUE_INIT;
  gtk_accessible_property_init_value(property, &property_value);
  g_value_set_int(&property_value, value);
  gtk_accessible_update_property_value(GTK_ACCESSIBLE(self), 1, properties,
                                       &property_value);
  g_value_unset(&property_value);
}

static void fl_gtk4_accessible_node_set_state_bool(FlGtk4AccessibleNode* self,
                                                   GtkAccessibleState state,
                                                   gboolean value) {
  GtkAccessibleState states[] = {state};
  GValue state_value = G_VALUE_INIT;
  gtk_accessible_state_init_value(state, &state_value);
  // GTK represents some boolean-like states (for example, selected and
  // expanded) as ints so they can also use GTK_ACCESSIBLE_VALUE_UNDEFINED.
  if (G_VALUE_HOLDS_BOOLEAN(&state_value)) {
    g_value_set_boolean(&state_value, value);
  } else if (G_VALUE_HOLDS_INT(&state_value)) {
    g_value_set_int(&state_value, value);
  } else {
    g_value_unset(&state_value);
    return;
  }
  gtk_accessible_update_state_value(GTK_ACCESSIBLE(self), 1, states,
                                    &state_value);
  g_value_unset(&state_value);
}

static void fl_gtk4_accessible_node_set_state_tristate(
    FlGtk4AccessibleNode* self,
    GtkAccessibleState state,
    GtkAccessibleTristate value) {
  gtk_accessible_update_state(GTK_ACCESSIBLE(self), state, value, -1);
}

static void fl_gtk4_accessible_node_reset_property(
    FlGtk4AccessibleNode* self,
    GtkAccessibleProperty property) {
  gtk_accessible_reset_property(GTK_ACCESSIBLE(self), property);
}

static void fl_gtk4_accessible_node_reset_state(FlGtk4AccessibleNode* self,
                                                GtkAccessibleState state) {
  gtk_accessible_reset_state(GTK_ACCESSIBLE(self), state);
}

static gboolean fl_gtk4_accessible_node_get_platform_state(
    GtkAccessible* accessible,
    FlGtkAccessiblePlatformState state) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  switch (state) {
    case FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSABLE:
      return self->focusable;
    case FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSED:
      return self->focused;
    case FL_GTK_ACCESSIBLE_PLATFORM_STATE_ACTIVE:
      return self->active;
  }
  return FALSE;
}

static GtkATContext* fl_gtk4_accessible_node_get_at_context(
    GtkAccessible* accessible) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  if (self->at_context != nullptr) {
    return GTK_AT_CONTEXT(g_object_ref(self->at_context));
  }

  if (self->view == nullptr) {
    return nullptr;
  }
  GtkWidget* widget = GTK_WIDGET(self->view);
  GdkDisplay* display = gtk_widget_get_display(widget);
  if (display == nullptr) {
    return nullptr;
  }

  self->at_context =
      gtk_at_context_create(self->role, GTK_ACCESSIBLE(self), display);
  return self->at_context == nullptr
             ? nullptr
             : GTK_AT_CONTEXT(g_object_ref(self->at_context));
}

static GtkAccessible* fl_gtk4_accessible_node_get_accessible_parent(
    GtkAccessible* accessible) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  if (self->parent != nullptr) {
    return GTK_ACCESSIBLE(g_object_ref(self->parent));
  }
  return self->view == nullptr
             ? nullptr
             : GTK_ACCESSIBLE(g_object_ref(self->view->render_area));
}

GtkAccessible* fl_gtk4_accessible_node_get_first_accessible_child(
    GtkAccessible* accessible) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  if (self->children->len == 0) {
    return nullptr;
  }
  return GTK_ACCESSIBLE(g_object_ref(g_ptr_array_index(self->children, 0)));
}

GtkAccessible* fl_gtk4_accessible_node_get_next_accessible_sibling(
    GtkAccessible* accessible) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  if (self->next_sibling == nullptr) {
    return nullptr;
  }
  return GTK_ACCESSIBLE(g_object_ref(self->next_sibling));
}

gboolean fl_gtk4_accessible_node_get_bounds(GtkAccessible* accessible,
                                            int* x,
                                            int* y,
                                            int* width,
                                            int* height) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  if (!self->has_bounds || self->view == nullptr ||
      (self->parent != nullptr && !self->parent->has_bounds)) {
    return FALSE;
  }

  // Composed semantics bounds are in view physical pixels. GTK expects logical
  // coordinates relative to the accessible parent and adds ancestor positions
  // when answering AT-SPI window-coordinate queries. Convert both origins in
  // the same view space before subtracting to preserve rounding across levels.
  const double scale =
      MAX(fl_gtk_widget_get_scale(self->view->render_area), 1.0);
  const int left = static_cast<int>(floor(self->bounds_x / scale));
  const int top = static_cast<int>(floor(self->bounds_y / scale));
  const int parent_left =
      self->parent == nullptr
          ? 0
          : static_cast<int>(floor(self->parent->bounds_x / scale));
  const int parent_top =
      self->parent == nullptr
          ? 0
          : static_cast<int>(floor(self->parent->bounds_y / scale));
  if (x != nullptr) {
    *x = left - parent_left;
  }
  if (y != nullptr) {
    *y = top - parent_top;
  }
  if (width != nullptr) {
    *width = static_cast<int>(ceil(
                 (static_cast<double>(self->bounds_x) + self->bounds_width) /
                 scale)) -
             left;
  }
  if (height != nullptr) {
    *height = static_cast<int>(ceil(
                  (static_cast<double>(self->bounds_y) + self->bounds_height) /
                  scale)) -
              top;
  }
  return TRUE;
}

static void fl_gtk4_accessible_node_get_transformed_bounds(
    const FlutterRect& rect,
    const FlutterTransformation& transform,
    int* x,
    int* y,
    int* width,
    int* height) {
  // Export the axis-aligned bounds of all four transformed corners rather
  // than only applying translation, which loses scale and skew.
  const double points[4][2] = {{rect.left, rect.top},
                               {rect.right, rect.top},
                               {rect.left, rect.bottom},
                               {rect.right, rect.bottom}};
  // Zero-initialized FlutterTransformation values represent the identity in
  // embedder test fixtures and older semantics payloads.
  const double scale_x = transform.scaleX == 0.0 ? 1.0 : transform.scaleX;
  const double scale_y = transform.scaleY == 0.0 ? 1.0 : transform.scaleY;
  const double perspective_scale =
      transform.pers0 == 0.0 && transform.pers1 == 0.0 && transform.pers2 == 0.0
          ? 1.0
          : transform.pers2;
  double min_x = G_MAXDOUBLE;
  double min_y = G_MAXDOUBLE;
  double max_x = -G_MAXDOUBLE;
  double max_y = -G_MAXDOUBLE;
  for (const auto& point : points) {
    const double denominator = transform.pers0 * point[0] +
                               transform.pers1 * point[1] + perspective_scale;
    // A singular projective transform has no finite accessible rectangle.
    // Keep the affine envelope rather than exporting infinities or NaNs.
    const double safe_denominator =
        std::abs(denominator) < 1e-12 ? 1.0 : denominator;
    const double transformed_x =
        (scale_x * point[0] + transform.skewX * point[1] + transform.transX) /
        safe_denominator;
    const double transformed_y =
        (transform.skewY * point[0] + scale_y * point[1] + transform.transY) /
        safe_denominator;
    min_x = MIN(min_x, transformed_x);
    min_y = MIN(min_y, transformed_y);
    max_x = MAX(max_x, transformed_x);
    max_y = MAX(max_y, transformed_y);
  }
  const double floored_x = floor(min_x);
  const double floored_y = floor(min_y);
  *x = static_cast<int>(floored_x);
  *y = static_cast<int>(floored_y);
  *width = static_cast<int>(ceil(max_x) - floored_x);
  *height = static_cast<int>(ceil(max_y) - floored_y);
}

static void fl_gtk4_accessible_node_set_platform_states(
    FlGtk4AccessibleNode* self,
    gboolean focusable,
    gboolean focused,
    gboolean active) {
  const gboolean focusable_changed = self->focusable != focusable;
  const gboolean focused_changed = self->focused != focused;
  const gboolean active_changed = self->active != active;
  self->focusable = focusable;
  self->focused = focused;
  self->active = active;
  // These nonvisual widgets take focus state from Flutter semantics, so GTK's
  // widget focus machinery does not emit the notifications on their behalf.
  if (focusable_changed) {
    fl_gtk_runtime_accessible_update_platform_state(
        GTK_ACCESSIBLE(self), FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSABLE);
  }
  if (focused_changed) {
    fl_gtk_runtime_accessible_update_platform_state(
        GTK_ACCESSIBLE(self), FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSED);
  }
  if (active_changed) {
    fl_gtk_runtime_accessible_update_platform_state(
        GTK_ACCESSIBLE(self), FL_GTK_ACCESSIBLE_PLATFORM_STATE_ACTIVE);
  }
}

void fl_gtk4_accessible_node_detach(FlGtk4AccessibleNode* self) {
  fl_gtk4_editable_accessible_node_cancel(self);
  // End the proxy's GTK lifecycle before clearing semantics links. Removed
  // ancestors may already have released their AT contexts, so descendants must
  // not flush pending state notifications through that detached hierarchy.
  if (gtk_widget_get_realized(GTK_WIDGET(self))) {
    gtk_widget_unrealize(GTK_WIDGET(self));
  }
  fl_gtk4_accessible_node_set_platform_states(self, FALSE, FALSE, FALSE);
  self->parent = nullptr;
  self->next_sibling = nullptr;
  self->view = nullptr;
  self->has_bounds = FALSE;
  self->actions_enabled = FALSE;
  self->text_actions_enabled = FALSE;
  self->text_editable = FALSE;
  self->actions = 0;
  // A client may retain a replaced text object when the new semantics become
  // protected. Detached objects must not keep readable contents or selection.
  g_clear_pointer(&self->text, g_free);
  g_clear_pointer(&self->protected_text_offsets, g_array_unref);
  self->text_selection_base = 0;
  self->text_selection_extent = 0;
  for (const auto& action : kNativeActions) {
    gtk_widget_action_set_enabled(GTK_WIDGET(self), action.name, FALSE);
  }
  g_ptr_array_set_size(self->children, 0);
  if (gtk_widget_get_parent(GTK_WIDGET(self)) != nullptr) {
    gtk_widget_unparent(GTK_WIDGET(self));
  }
  fl_gtk_runtime_accessible_set_accessible_parent(GTK_ACCESSIBLE(self), nullptr,
                                                  nullptr);
  g_clear_object(&self->at_context);
}

static void fl_gtk4_accessible_node_dispose(GObject* object) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(object);

  g_clear_object(&self->at_context);
  g_clear_pointer(&self->children, g_ptr_array_unref);
  g_clear_pointer(&self->text, g_free);
  g_clear_pointer(&self->protected_text_offsets, g_array_unref);

  G_OBJECT_CLASS(fl_gtk4_accessible_node_parent_class)->dispose(object);
}

static void fl_gtk4_accessible_node_get_property(GObject* object,
                                                 guint property_id,
                                                 GValue* value,
                                                 GParamSpec* pspec) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(object);

  switch (property_id) {
    case PROP_GTK4_ACCESSIBLE_NODE_ACCESSIBLE_ROLE:
      g_value_set_enum(value, self->role);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
      break;
  }
}

static void fl_gtk4_accessible_node_set_property(GObject* object,
                                                 guint property_id,
                                                 const GValue* value,
                                                 GParamSpec* pspec) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(object);

  switch (property_id) {
    case PROP_GTK4_ACCESSIBLE_NODE_ACCESSIBLE_ROLE:
      self->role = static_cast<GtkAccessibleRole>(g_value_get_enum(value));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
      break;
  }
}

static void fl_gtk4_accessible_node_activate(GtkWidget* widget,
                                             const char* name,
                                             GVariant*) {
  auto* self = FL_GTK4_ACCESSIBLE_NODE(widget);
  if (self->view == nullptr || !self->actions_enabled) {
    return;
  }
  for (const auto& action : kNativeActions) {
    if (g_str_equal(name, action.name) &&
        (self->actions & action.action) != 0) {
      g_autoptr(GBytes) message = nullptr;
      if (action.moves_cursor) {
        if (!self->text_actions_enabled) {
          return;
        }
        // Match GTK3: move the cursor without extending the selection.
        g_autoptr(FlValue) extend_selection = fl_value_new_bool(false);
        g_autoptr(FlStandardMessageCodec) codec =
            fl_standard_message_codec_new();
        message = fl_message_codec_encode_message(FL_MESSAGE_CODEC(codec),
                                                  extend_selection, nullptr);
        if (message == nullptr) {
          return;
        }
      }
      fl_engine_dispatch_semantics_action(fl_view_get_engine(self->view),
                                          self->view_id, self->semantics_id,
                                          action.action, message);
      return;
    }
  }
}

static void fl_gtk4_accessible_node_class_init(
    FlGtk4AccessibleNodeClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->get_property = fl_gtk4_accessible_node_get_property;
  object_class->set_property = fl_gtk4_accessible_node_set_property;
  object_class->dispose = fl_gtk4_accessible_node_dispose;

  GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);
  for (const auto& action : kNativeActions) {
    gtk_widget_class_install_action(widget_class, action.name, nullptr,
                                    fl_gtk4_accessible_node_activate);
  }

  g_object_class_install_property(
      object_class, PROP_GTK4_ACCESSIBLE_NODE_ACCESSIBLE_ROLE,
      g_param_spec_enum("accessible-role", nullptr, nullptr,
                        GTK_TYPE_ACCESSIBLE_ROLE, GTK_ACCESSIBLE_ROLE_GENERIC,
                        static_cast<GParamFlags>(G_PARAM_READWRITE |
                                                 G_PARAM_STATIC_STRINGS)));
}

static void fl_gtk4_accessible_node_init(FlGtk4AccessibleNode* self) {
  self->children = g_ptr_array_new_with_free_func(g_object_unref);
  gtk_widget_set_can_target(GTK_WIDGET(self), FALSE);
  gtk_widget_set_focusable(GTK_WIDGET(self), FALSE);
  gtk_widget_set_child_visible(GTK_WIDGET(self), FALSE);
  for (const auto& action : kNativeActions) {
    gtk_widget_action_set_enabled(GTK_WIDGET(self), action.name, FALSE);
  }
}

static void fl_gtk4_accessible_node_accessible_iface_init(
    GtkAccessibleInterface* iface) {
  if (!fl_gtk_runtime_supports_native_accessibility_tree()) {
    return;
  }

  auto* iface_4_10 = reinterpret_cast<FlGtkAccessibleInterface4_10*>(iface);
  iface_4_10->get_at_context = fl_gtk4_accessible_node_get_at_context;
  iface_4_10->get_platform_state = fl_gtk4_accessible_node_get_platform_state;
  iface_4_10->get_accessible_parent =
      fl_gtk4_accessible_node_get_accessible_parent;
  iface_4_10->get_first_accessible_child =
      fl_gtk4_accessible_node_get_first_accessible_child;
  iface_4_10->get_next_accessible_sibling =
      fl_gtk4_accessible_node_get_next_accessible_sibling;
  iface_4_10->get_bounds = fl_gtk4_accessible_node_get_bounds;
}

FlGtk4AccessibleNode* fl_gtk4_accessible_node_update(
    FlView* view,
    FlutterViewId view_id,
    const FlAccessibilitySemanticsNode* semantics,
    const FlutterTransformation& transform,
    FlGtk4AccessibleNode* self) {
  const GtkAccessibleRole role = fl_gtk4_accessible_node_get_role(semantics);
  const gboolean supports_text =
      semantics->flags.is_text_field &&
      fl_gtk_runtime_supports_native_accessibility_text();
  // Opt in while GTK's asynchronous EditableText.PasteText lifetime issue is
  // tracked upstream. GtkEditable itself is a public GTK 4.0 interface.
  const gboolean supports_editable =
      supports_text && !semantics->flags.is_obscured &&
      (semantics->actions & kFlutterSemanticsActionSetText) != 0 &&
      g_strcmp0(g_getenv("FLUTTER_GTK4_ENABLE_EDITABLE_TEXT"), "1") == 0;
  // Do not evaluate the text-node type check unless GTK 4.14 is available:
  // evaluating its GType registers the dynamically resolved interface.
  // GTK roles are immutable after construction. Replace the native object,
  // retaining descendants through the semantics-ID cache below.
  if (self == nullptr || self->role != role ||
      (supports_text && !FL_IS_GTK4_TEXT_ACCESSIBLE_NODE(self)) ||
      (supports_editable && !GTK_IS_EDITABLE(self))) {
    self = supports_editable ? FL_GTK4_ACCESSIBLE_NODE(g_object_new(
                                   fl_gtk4_editable_accessible_node_get_type(),
                                   "accessible-role", role, nullptr))
           : supports_text   ? FL_GTK4_ACCESSIBLE_NODE(
                                   g_object_new(FL_TYPE_GTK4_TEXT_ACCESSIBLE_NODE,
                                                "accessible-role", role, nullptr))
                             : FL_GTK4_ACCESSIBLE_NODE(g_object_new(
                                   FL_TYPE_GTK4_ACCESSIBLE_NODE,
                                   "accessible-role", role, nullptr));
    g_object_ref_sink(self);
  }
  self->view = view;
  self->view_id = view_id;
  self->semantics_revision = semantics->revision;
  self->semantics_id = semantics->id;
  self->actions = semantics->actions;

  const FlutterSemanticsFlags* flags = &semantics->flags;
  const gboolean is_enabled = flags->is_enabled != kFlutterTristateFalse;
  const gboolean is_hidden = flags->is_hidden;
  const gboolean is_required = flags->is_required == kFlutterTristateTrue;
  const gboolean is_read_only = flags->is_text_field && flags->is_read_only;
  const gboolean is_multiline = flags->is_text_field && flags->is_multiline;

  // Treat protection flags as authoritative even if an inconsistent semantics
  // batch advertises clipboard actions. Pasting into editable passwords is
  // safe; copying or cutting their contents is not.
  if (flags->is_obscured) {
    self->actions &= ~(static_cast<uint64_t>(kFlutterSemanticsActionCopy) |
                       kFlutterSemanticsActionCut);
  }
  if (is_read_only) {
    self->actions &= ~(static_cast<uint64_t>(kFlutterSemanticsActionCut) |
                       kFlutterSemanticsActionPaste);
  }
  self->actions_enabled = is_enabled && !is_hidden;
  self->text_actions_enabled = supports_text && self->actions_enabled;
  self->text_editable =
      supports_editable && self->actions_enabled && !is_read_only;
  for (const auto& action : kNativeActions) {
    gtk_widget_action_set_enabled(
        GTK_WIDGET(self), action.name,
        self->actions_enabled && (self->actions & action.action) != 0 &&
            (!action.moves_cursor || self->text_actions_enabled));
  }

  // A non-null focus state also marks passive Focus widgets as focusable.
  // Hidden nodes must not advertise input focus or keyboard focusability.
  const gboolean is_focusable =
      is_enabled && !is_hidden &&
      (flags->is_focused != kFlutterTristateNone || semantics->actions != 0 ||
       flags->is_button || flags->is_text_field || flags->is_link ||
       flags->is_slider || flags->is_checked != kFlutterCheckStateNone ||
       flags->is_toggled != kFlutterTristateNone);
  const gboolean is_focused =
      is_focusable && flags->is_focused == kFlutterTristateTrue;
  fl_gtk4_accessible_node_set_platform_states(self, is_focusable, is_focused,
                                              is_focused);
  self->has_bounds = TRUE;
  fl_gtk4_accessible_node_get_transformed_bounds(
      semantics->rect, transform, &self->bounds_x, &self->bounds_y,
      &self->bounds_width, &self->bounds_height);

  const gchar* value = flags->is_obscured ? nullptr : semantics->value;
  const gchar* label = semantics->label;
  if ((label == nullptr || label[0] == '\0') && value != nullptr &&
      value[0] != '\0' && semantics->child_count == 0) {
    label = value;
  }
  fl_gtk4_accessible_node_set_string_property(
      self, GTK_ACCESSIBLE_PROPERTY_LABEL, label);

  g_autofree gchar* description = nullptr;
  if (semantics->hint != nullptr || semantics->tooltip != nullptr) {
    if (semantics->hint != nullptr && semantics->tooltip != nullptr &&
        semantics->hint[0] != '\0' && semantics->tooltip[0] != '\0') {
      description =
          g_strjoin("\n", semantics->hint, semantics->tooltip, nullptr);
    } else if (semantics->hint != nullptr && semantics->hint[0] != '\0') {
      description = g_strdup(semantics->hint);
    } else if (semantics->tooltip != nullptr && semantics->tooltip[0] != '\0') {
      description = g_strdup(semantics->tooltip);
    }
  }
  fl_gtk4_accessible_node_set_string_property(
      self, GTK_ACCESSIBLE_PROPERTY_DESCRIPTION, description);

  fl_gtk4_accessible_node_set_string_property(
      self, GTK_ACCESSIBLE_PROPERTY_VALUE_TEXT, value);
  // Protected Text exposes only masking characters with usable caret/selection
  // offsets. Non-text transitions clear the cached contents.
  if (fl_gtk_runtime_supports_native_accessibility_text() &&
      FL_IS_GTK4_TEXT_ACCESSIBLE_NODE(self)) {
    fl_gtk4_text_accessible_node_set_text(
        self, supports_text ? semantics->value : nullptr,
        supports_text ? semantics->text_selection_base : 0,
        supports_text ? semantics->text_selection_extent : 0,
        flags->is_obscured);
  }
  if (semantics->heading_level > 0) {
    fl_gtk4_accessible_node_set_int_property(
        self, GTK_ACCESSIBLE_PROPERTY_LEVEL, semantics->heading_level);
  } else {
    fl_gtk4_accessible_node_reset_property(self, GTK_ACCESSIBLE_PROPERTY_LEVEL);
  }

  if (flags->is_text_field) {
    fl_gtk4_accessible_node_set_bool_property(
        self, GTK_ACCESSIBLE_PROPERTY_READ_ONLY, is_read_only);
    fl_gtk4_accessible_node_set_bool_property(
        self, GTK_ACCESSIBLE_PROPERTY_MULTI_LINE, is_multiline);
  } else {
    fl_gtk4_accessible_node_reset_property(self,
                                           GTK_ACCESSIBLE_PROPERTY_READ_ONLY);
    fl_gtk4_accessible_node_reset_property(self,
                                           GTK_ACCESSIBLE_PROPERTY_MULTI_LINE);
  }
  if (is_required) {
    fl_gtk4_accessible_node_set_bool_property(
        self, GTK_ACCESSIBLE_PROPERTY_REQUIRED, TRUE);
  } else {
    fl_gtk4_accessible_node_reset_property(self,
                                           GTK_ACCESSIBLE_PROPERTY_REQUIRED);
  }
  fl_gtk4_accessible_node_set_state_bool(self, GTK_ACCESSIBLE_STATE_HIDDEN,
                                         is_hidden);
  fl_gtk4_accessible_node_set_state_bool(self, GTK_ACCESSIBLE_STATE_DISABLED,
                                         !is_enabled);
  // Undefined differs from false: setting these states makes GTK advertise
  // selectable/expandable capabilities, even when their values are false.
  if (flags->is_selected == kFlutterTristateNone) {
    fl_gtk4_accessible_node_reset_state(self, GTK_ACCESSIBLE_STATE_SELECTED);
  } else {
    fl_gtk4_accessible_node_set_state_bool(
        self, GTK_ACCESSIBLE_STATE_SELECTED,
        flags->is_selected == kFlutterTristateTrue);
  }
  if (flags->is_expanded == kFlutterTristateNone) {
    fl_gtk4_accessible_node_reset_state(self, GTK_ACCESSIBLE_STATE_EXPANDED);
  } else {
    fl_gtk4_accessible_node_set_state_bool(
        self, GTK_ACCESSIBLE_STATE_EXPANDED,
        flags->is_expanded == kFlutterTristateTrue);
  }
  if (role == GTK_ACCESSIBLE_ROLE_CHECKBOX ||
      role == GTK_ACCESSIBLE_ROLE_RADIO) {
    GtkAccessibleTristate checked_value = GTK_ACCESSIBLE_TRISTATE_FALSE;
    if (flags->is_checked == kFlutterCheckStateTrue) {
      checked_value = GTK_ACCESSIBLE_TRISTATE_TRUE;
    } else if (flags->is_checked == kFlutterCheckStateMixed) {
      checked_value = GTK_ACCESSIBLE_TRISTATE_MIXED;
    }
    fl_gtk4_accessible_node_set_state_tristate(
        self, GTK_ACCESSIBLE_STATE_CHECKED, checked_value);
  } else {
    fl_gtk4_accessible_node_reset_state(self, GTK_ACCESSIBLE_STATE_CHECKED);
  }
  // Match GtkToggleButton: pressed describes toggle buttons; checked describes
  // checkboxes and radios. Publishing both adds spurious AT-SPI capabilities.
  if (role == kFlGtkAccessibleRoleToggleButton) {
    fl_gtk4_accessible_node_set_state_tristate(
        self, GTK_ACCESSIBLE_STATE_PRESSED,
        flags->is_toggled == kFlutterTristateTrue
            ? GTK_ACCESSIBLE_TRISTATE_TRUE
            : GTK_ACCESSIBLE_TRISTATE_FALSE);
  } else {
    fl_gtk4_accessible_node_reset_state(self, GTK_ACCESSIBLE_STATE_PRESSED);
  }

  // GTK suppresses state notifications for unrealized widgets. Give the proxy
  // the surface's lifecycle while excluding it from layout, drawing and input.
  if (gtk_widget_get_parent(GTK_WIDGET(self)) == nullptr) {
    gtk_widget_set_parent(GTK_WIDGET(self), view->render_area);
    if (gtk_widget_get_realized(view->render_area)) {
      gtk_widget_realize(GTK_WIDGET(self));
    }
  }
  return self;
}

void fl_gtk4_accessible_node_attach_children(FlGtk4AccessibleNode* parent,
                                             GPtrArray* children) {
  g_autoptr(GHashTable) retained =
      g_hash_table_new(g_direct_hash, g_direct_equal);
  for (guint i = 0; i < children->len; i++) {
    g_hash_table_add(retained, g_ptr_array_index(children, i));
  }
  for (guint i = 0; i < parent->children->len; i++) {
    auto* child =
        FL_GTK4_ACCESSIBLE_NODE(g_ptr_array_index(parent->children, i));
    if (!g_hash_table_contains(retained, child) && child->parent == parent) {
      child->parent = nullptr;
      child->next_sibling = nullptr;
      fl_gtk_runtime_accessible_set_accessible_parent(GTK_ACCESSIBLE(child),
                                                      nullptr, nullptr);
    }
  }
  gboolean same_children = parent->children->len == children->len;
  for (guint i = 0; i < children->len; i++) {
    FlGtk4AccessibleNode* child =
        FL_GTK4_ACCESSIBLE_NODE(g_ptr_array_index(children, i));
    FlGtk4AccessibleNode* next_sibling =
        i + 1 < children->len
            ? FL_GTK4_ACCESSIBLE_NODE(g_ptr_array_index(children, i + 1))
            : nullptr;
    if (child->parent != parent || child->next_sibling != next_sibling) {
      child->parent = parent;
      child->next_sibling = next_sibling;
      fl_gtk_runtime_accessible_set_accessible_parent(
          GTK_ACCESSIBLE(child), GTK_ACCESSIBLE(parent),
          GTK_ACCESSIBLE(next_sibling));
    }
    same_children =
        same_children && g_ptr_array_index(parent->children, i) == child;
  }
  if (!same_children) {
    g_ptr_array_set_size(parent->children, 0);
    for (guint i = 0; i < children->len; i++) {
      g_ptr_array_add(parent->children,
                      g_object_ref(g_ptr_array_index(children, i)));
    }
  }
}

#endif  // FLUTTER_LINUX_GTK4 && FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE
