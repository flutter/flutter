// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_gtk4_accessibility.h"

#if FLUTTER_LINUX_GTK4

#include <cstddef>

#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_render_texture_gtk4.h"
#include "flutter/shell/platform/linux/fl_view_private.h"

typedef struct _FlGtk4AccessibleNode FlGtk4AccessibleNode;
typedef struct _FlGtk4AccessibleNodeClass FlGtk4AccessibleNodeClass;
typedef struct _FlGtk4TextAccessibleNode FlGtk4TextAccessibleNode;
typedef struct _FlGtk4TextAccessibleNodeClass FlGtk4TextAccessibleNodeClass;
typedef struct _FlViewGtk4Accessibility FlViewGtk4Accessibility;

struct _FlViewGtk4Accessibility {
  FlView* view;
  FlutterViewId view_id;
  FlAccessibilitySemanticsStore* semantics_store;
  FlGtk4AccessibleNode* root_node;
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  GHashTable* native_nodes_by_id;
#endif
};

#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
#define FL_TYPE_GTK4_ACCESSIBLE_NODE (fl_gtk4_accessible_node_get_type())
#define FL_GTK4_ACCESSIBLE_NODE(obj)                               \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), FL_TYPE_GTK4_ACCESSIBLE_NODE, \
                              FlGtk4AccessibleNode))
#define FL_IS_GTK4_ACCESSIBLE_NODE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), FL_TYPE_GTK4_ACCESSIBLE_NODE))
#define FL_TYPE_GTK4_TEXT_ACCESSIBLE_NODE \
  (fl_gtk4_text_accessible_node_get_type())
#define FL_GTK4_TEXT_ACCESSIBLE_NODE(obj)                               \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), FL_TYPE_GTK4_TEXT_ACCESSIBLE_NODE, \
                              FlGtk4TextAccessibleNode))
#define FL_IS_GTK4_TEXT_ACCESSIBLE_NODE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), FL_TYPE_GTK4_TEXT_ACCESSIBLE_NODE))

struct _FlGtk4AccessibleNode {
  GObject parent_instance;

  FlView* view;
  FlutterViewId view_id;
  GtkAccessibleRole role;
  GtkATContext* at_context;
  guint64 semantics_revision;

  gchar* text;
  guint text_selection_base;
  guint text_selection_extent;

  GPtrArray* children;
  FlGtk4AccessibleNode* parent;
  FlGtk4AccessibleNode* next_sibling;

  gboolean focusable;
  gboolean focused;
  gboolean active;
  gboolean has_bounds;
  int bounds_x;
  int bounds_y;
  int bounds_width;
  int bounds_height;
};

struct _FlGtk4AccessibleNodeClass {
  GObjectClass parent_class;
};

struct _FlGtk4TextAccessibleNode {
  FlGtk4AccessibleNode parent_instance;
};

struct _FlGtk4TextAccessibleNodeClass {
  FlGtk4AccessibleNodeClass parent_class;
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

#if GTK_CHECK_VERSION(4, 14, 0)
static_assert(sizeof(FlGtkAccessibleTextInterface4_14) ==
              sizeof(GtkAccessibleTextInterface));
static_assert(offsetof(FlGtkAccessibleTextInterface4_14, get_contents) ==
              offsetof(GtkAccessibleTextInterface, get_contents));
static_assert(offsetof(FlGtkAccessibleTextInterface4_14,
                       get_default_attributes) ==
              offsetof(GtkAccessibleTextInterface, get_default_attributes));
#endif

enum {
  PROP_GTK4_ACCESSIBLE_NODE_0,
  PROP_GTK4_ACCESSIBLE_NODE_ACCESSIBLE_ROLE,
  LAST_GTK4_ACCESSIBLE_NODE_PROPERTY,
};

static void fl_gtk4_accessible_node_accessible_iface_init(
    GtkAccessibleInterface* iface);
static void fl_gtk4_text_accessible_node_text_iface_init(
    FlGtkAccessibleTextInterface4_14* iface);

G_DEFINE_TYPE_WITH_CODE(
    FlGtk4AccessibleNode,
    fl_gtk4_accessible_node,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(GTK_TYPE_ACCESSIBLE,
                          fl_gtk4_accessible_node_accessible_iface_init))

G_DEFINE_TYPE_WITH_CODE(
    FlGtk4TextAccessibleNode,
    fl_gtk4_text_accessible_node,
    FL_TYPE_GTK4_ACCESSIBLE_NODE,
    G_IMPLEMENT_INTERFACE(fl_gtk_runtime_accessible_text_get_type(),
                          fl_gtk4_text_accessible_node_text_iface_init))

static GtkAccessibleRole fl_view_gtk4_accessibility_get_role(
    const FlAccessibilitySemanticsNode* semantics) {
  const FlutterSemanticsFlags* flags = &semantics->flags;

  // GtkEntry and GtkPasswordEntry both use TEXT_BOX. Read-only is represented
  // by GTK_ACCESSIBLE_PROPERTY_READ_ONLY rather than a distinct role.
  if (flags->is_text_field) {
    return GTK_ACCESSIBLE_ROLE_TEXT_BOX;
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
  if (semantics->child_count > 0) {
    return GTK_ACCESSIBLE_ROLE_GROUP;
  }
  if (semantics->label != nullptr && semantics->label[0] != '\0') {
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
#if GTK_CHECK_VERSION(4, 10, 0)
    case GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSABLE:
#else
    case FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSABLE:
#endif
      return self->focusable;
#if GTK_CHECK_VERSION(4, 10, 0)
    case GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSED:
#else
    case FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSED:
#endif
      return self->focused;
#if GTK_CHECK_VERSION(4, 10, 0)
    case GTK_ACCESSIBLE_PLATFORM_STATE_ACTIVE:
#else
    case FL_GTK_ACCESSIBLE_PLATFORM_STATE_ACTIVE:
#endif
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
  return GTK_ACCESSIBLE(g_object_ref(self->view->render_area));
}

static GtkAccessible* fl_gtk4_accessible_node_get_first_accessible_child(
    GtkAccessible* accessible) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  if (self->children->len == 0) {
    return nullptr;
  }
  return GTK_ACCESSIBLE(g_object_ref(g_ptr_array_index(self->children, 0)));
}

static GtkAccessible* fl_gtk4_accessible_node_get_next_accessible_sibling(
    GtkAccessible* accessible) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  if (self->next_sibling == nullptr) {
    return nullptr;
  }
  return GTK_ACCESSIBLE(g_object_ref(self->next_sibling));
}

static gboolean fl_gtk4_accessible_node_get_bounds(GtkAccessible* accessible,
                                                   int* x,
                                                   int* y,
                                                   int* width,
                                                   int* height) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  if (!self->has_bounds) {
    return FALSE;
  }

  if (x != nullptr) {
    *x = self->bounds_x;
  }
  if (y != nullptr) {
    *y = self->bounds_y;
  }
  if (width != nullptr) {
    *width = self->bounds_width;
  }
  if (height != nullptr) {
    *height = self->bounds_height;
  }
  return TRUE;
}

static void fl_gtk4_accessible_node_dispose(GObject* object) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(object);

  g_clear_object(&self->at_context);
  g_clear_pointer(&self->children, g_ptr_array_unref);
  g_clear_pointer(&self->text, g_free);

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

static void fl_gtk4_accessible_node_class_init(
    FlGtk4AccessibleNodeClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->get_property = fl_gtk4_accessible_node_get_property;
  object_class->set_property = fl_gtk4_accessible_node_set_property;
  object_class->dispose = fl_gtk4_accessible_node_dispose;

  g_object_class_install_property(
      object_class, PROP_GTK4_ACCESSIBLE_NODE_ACCESSIBLE_ROLE,
      g_param_spec_enum("accessible-role", nullptr, nullptr,
                        GTK_TYPE_ACCESSIBLE_ROLE, GTK_ACCESSIBLE_ROLE_GENERIC,
                        static_cast<GParamFlags>(G_PARAM_READWRITE |
                                                 G_PARAM_STATIC_STRINGS)));
}

static void fl_gtk4_accessible_node_init(FlGtk4AccessibleNode* self) {
  self->children = g_ptr_array_new_with_free_func(g_object_unref);
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

static const gchar* fl_gtk4_text_accessible_node_get_text(
    FlGtk4AccessibleNode* self) {
  return self->text == nullptr ? "" : self->text;
}

static guint fl_gtk4_text_accessible_node_get_text_length(
    FlGtk4AccessibleNode* self) {
  return static_cast<guint>(
      g_utf8_strlen(fl_gtk4_text_accessible_node_get_text(self), -1));
}

static GBytes* fl_gtk4_text_accessible_node_get_contents(
    GtkAccessible* accessible,
    unsigned int start,
    unsigned int end) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  const gchar* text = fl_gtk4_text_accessible_node_get_text(self);
  const guint length = fl_gtk4_text_accessible_node_get_text_length(self);
  start = MIN(start, length);
  end = MIN(end, length);
  if (end <= start) {
    return g_bytes_new_static("", 1);
  }

  const gchar* first = g_utf8_offset_to_pointer(text, start);
  const gchar* last = g_utf8_offset_to_pointer(text, end);
  return g_bytes_new(first, last - first);
}

static GBytes* fl_gtk4_text_accessible_node_get_contents_at(
    GtkAccessible* accessible,
    unsigned int offset,
    FlGtkAccessibleTextGranularity4_14 granularity,
    unsigned int* start,
    unsigned int* end) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  const guint length = fl_gtk4_text_accessible_node_get_text_length(self);
  offset = MIN(offset, length);

  // Flutter's semantics payload has text but no layout runs. Character ranges
  // are exact; broader queries safely return the complete text range.
  if (granularity == FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_CHARACTER &&
      offset < length) {
    if (start != nullptr) {
      *start = offset;
    }
    if (end != nullptr) {
      *end = offset + 1;
    }
    return fl_gtk4_text_accessible_node_get_contents(accessible, offset,
                                                     offset + 1);
  }

  if (start != nullptr) {
    *start = 0;
  }
  if (end != nullptr) {
    *end = length;
  }
  return fl_gtk4_text_accessible_node_get_contents(accessible, 0, length);
}

static unsigned int fl_gtk4_text_accessible_node_get_caret_position(
    GtkAccessible* accessible) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  return MIN(self->text_selection_extent,
             fl_gtk4_text_accessible_node_get_text_length(self));
}

static gboolean fl_gtk4_text_accessible_node_get_selection(
    GtkAccessible* accessible,
    gsize* n_ranges,
    FlGtkAccessibleTextRange4_14** ranges) {
  FlGtk4AccessibleNode* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  const guint length = fl_gtk4_text_accessible_node_get_text_length(self);
  const guint start = MIN(self->text_selection_base, length);
  const guint end = MIN(self->text_selection_extent, length);
  if (start == end) {
    return FALSE;
  }

  if (n_ranges != nullptr) {
    *n_ranges = 1;
  }
  if (ranges != nullptr) {
    *ranges = g_new(FlGtkAccessibleTextRange4_14, 1);
    (*ranges)[0].start = MIN(start, end);
    (*ranges)[0].length = MAX(start, end) - MIN(start, end);
  }
  return TRUE;
}

static gboolean fl_gtk4_text_accessible_node_get_attributes(
    GtkAccessible*,
    unsigned int,
    gsize*,
    FlGtkAccessibleTextRange4_14**,
    char***,
    char***) {
  return FALSE;
}

static void fl_gtk4_text_accessible_node_get_default_attributes(
    GtkAccessible*,
    char*** attribute_names,
    char*** attribute_values) {
  if (attribute_names != nullptr) {
    *attribute_names = g_new0(char*, 1);
  }
  if (attribute_values != nullptr) {
    *attribute_values = g_new0(char*, 1);
  }
}

static void fl_gtk4_text_accessible_node_text_iface_init(
    FlGtkAccessibleTextInterface4_14* iface) {
  iface->get_contents = fl_gtk4_text_accessible_node_get_contents;
  iface->get_contents_at = fl_gtk4_text_accessible_node_get_contents_at;
  iface->get_caret_position = fl_gtk4_text_accessible_node_get_caret_position;
  iface->get_selection = fl_gtk4_text_accessible_node_get_selection;
  iface->get_attributes = fl_gtk4_text_accessible_node_get_attributes;
  iface->get_default_attributes =
      fl_gtk4_text_accessible_node_get_default_attributes;
}

static void fl_gtk4_text_accessible_node_set_text(FlGtk4AccessibleNode* self,
                                                  const gchar* text,
                                                  gint selection_base,
                                                  gint selection_extent) {
  const gchar* new_text = text == nullptr ? "" : text;
  const guint old_length = fl_gtk4_text_accessible_node_get_text_length(self);
  const gboolean text_changed = g_strcmp0(self->text, new_text) != 0;
  if (text_changed && self->text != nullptr) {
    fl_gtk_runtime_accessible_text_update_contents(GTK_ACCESSIBLE(self), 1, 0,
                                                   old_length);
  }

  if (text_changed) {
    g_free(self->text);
    self->text = g_strdup(new_text);
  }

  const guint text_length = fl_gtk4_text_accessible_node_get_text_length(self);
  const guint new_base =
      selection_base <= 0
          ? 0
          : MIN(static_cast<guint>(selection_base), text_length);
  const guint new_extent =
      selection_extent <= 0
          ? 0
          : MIN(static_cast<guint>(selection_extent), text_length);
  const gboolean caret_changed = self->text_selection_extent != new_extent;
  const gboolean selection_changed =
      self->text_selection_base != new_base || caret_changed;
  self->text_selection_base = new_base;
  self->text_selection_extent = new_extent;

  if (text_changed) {
    fl_gtk_runtime_accessible_text_update_contents(GTK_ACCESSIBLE(self), 0, 0,
                                                   text_length);
  }
  if (caret_changed) {
    fl_gtk_runtime_accessible_text_update_caret_position(GTK_ACCESSIBLE(self));
  }
  if (selection_changed) {
    fl_gtk_runtime_accessible_text_update_selection_bound(GTK_ACCESSIBLE(self));
  }
}

static void fl_gtk4_text_accessible_node_class_init(
    FlGtk4TextAccessibleNodeClass*) {}

static void fl_gtk4_text_accessible_node_init(FlGtk4TextAccessibleNode*) {}

static FlGtk4AccessibleNode* fl_gtk4_accessible_node_update(
    FlView* view,
    FlutterViewId view_id,
    const FlAccessibilitySemanticsNode* semantics,
    FlGtk4AccessibleNode* self) {
  if (self != nullptr && self->semantics_revision == semantics->revision) {
    return self;
  }
  const GtkAccessibleRole role = fl_view_gtk4_accessibility_get_role(semantics);
  const gboolean supports_text =
      semantics->flags.is_text_field && !semantics->flags.is_obscured &&
      fl_gtk_runtime_supports_native_accessibility_text();
  // Do not evaluate the text-node type check unless GTK 4.14 is available:
  // evaluating its GType registers the dynamically resolved interface.
  if (self == nullptr ||
      (supports_text && !FL_IS_GTK4_TEXT_ACCESSIBLE_NODE(self))) {
    self = supports_text ? FL_GTK4_ACCESSIBLE_NODE(
                               g_object_new(FL_TYPE_GTK4_TEXT_ACCESSIBLE_NODE,
                                            "accessible-role", role, nullptr))
                         : FL_GTK4_ACCESSIBLE_NODE(
                               g_object_new(FL_TYPE_GTK4_ACCESSIBLE_NODE,
                                            "accessible-role", role, nullptr));
  } else if (self->role != role) {
    g_object_set(self, "accessible-role", role, nullptr);
    g_clear_object(&self->at_context);
  }
  self->view = view;
  self->view_id = view_id;
  self->semantics_revision = semantics->revision;

  const FlutterSemanticsFlags* flags = &semantics->flags;
  const gboolean is_enabled = flags->is_enabled != kFlutterTristateFalse;
  const gboolean is_focused = flags->is_focused == kFlutterTristateTrue;
  const gboolean is_hidden = flags->is_hidden;
  const gboolean is_selected = flags->is_selected == kFlutterTristateTrue;
  const gboolean is_expanded = flags->is_expanded == kFlutterTristateTrue;
  const gboolean is_required = flags->is_required == kFlutterTristateTrue;
  const gboolean is_read_only = flags->is_text_field && flags->is_read_only;
  const gboolean is_multiline = flags->is_text_field && flags->is_multiline;

  self->focusable =
      is_enabled &&
      (semantics->actions != 0 || flags->is_button || flags->is_text_field ||
       flags->is_link || flags->is_slider ||
       flags->is_checked != kFlutterCheckStateNone ||
       flags->is_toggled != kFlutterTristateNone);
  self->focused = is_focused;
  self->active = is_focused;
  self->has_bounds = TRUE;
  self->bounds_x =
      static_cast<int>(semantics->rect.left + semantics->transform.transX);
  self->bounds_y =
      static_cast<int>(semantics->rect.top + semantics->transform.transY);
  self->bounds_width =
      static_cast<int>(semantics->rect.right - semantics->rect.left);
  self->bounds_height =
      static_cast<int>(semantics->rect.bottom - semantics->rect.top);

  const gchar* label = semantics->label;
  if ((label == nullptr || label[0] == '\0') && semantics->value != nullptr &&
      semantics->value[0] != '\0' && semantics->child_count == 0) {
    label = semantics->value;
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
      self, GTK_ACCESSIBLE_PROPERTY_VALUE_TEXT, semantics->value);
  if (supports_text) {
    fl_gtk4_text_accessible_node_set_text(self, semantics->value,
                                          semantics->text_selection_base,
                                          semantics->text_selection_extent);
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
  fl_gtk4_accessible_node_set_state_bool(self, GTK_ACCESSIBLE_STATE_SELECTED,
                                         is_selected);
  fl_gtk4_accessible_node_set_state_bool(self, GTK_ACCESSIBLE_STATE_EXPANDED,
                                         is_expanded);
  if (flags->is_checked != kFlutterCheckStateNone ||
      flags->is_toggled != kFlutterTristateNone) {
    GtkAccessibleTristate checked_value = GTK_ACCESSIBLE_TRISTATE_FALSE;
    if (flags->is_checked == kFlutterCheckStateTrue ||
        flags->is_toggled == kFlutterTristateTrue) {
      checked_value = GTK_ACCESSIBLE_TRISTATE_TRUE;
    } else if (flags->is_checked == kFlutterCheckStateMixed) {
      checked_value = GTK_ACCESSIBLE_TRISTATE_MIXED;
    }
    fl_gtk4_accessible_node_set_state_tristate(
        self, GTK_ACCESSIBLE_STATE_CHECKED, checked_value);
  } else {
    fl_gtk4_accessible_node_reset_state(self, GTK_ACCESSIBLE_STATE_CHECKED);
  }
  if (flags->is_toggled != kFlutterTristateNone) {
    fl_gtk4_accessible_node_set_state_tristate(
        self, GTK_ACCESSIBLE_STATE_PRESSED,
        flags->is_toggled == kFlutterTristateTrue
            ? GTK_ACCESSIBLE_TRISTATE_TRUE
            : GTK_ACCESSIBLE_TRISTATE_FALSE);
  } else {
    fl_gtk4_accessible_node_reset_state(self, GTK_ACCESSIBLE_STATE_PRESSED);
  }

  return self;
}

static void fl_gtk4_accessible_node_attach_children(
    FlGtk4AccessibleNode* parent,
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

static FlGtk4AccessibleNode* fl_view_gtk4_accessibility_build_native_node(
    FlViewGtk4Accessibility* self,
    const FlAccessibilitySemanticsNode* semantics,
    GHashTable* visited) {
  if (semantics == nullptr) {
    return nullptr;
  }

  if (g_hash_table_contains(visited, GINT_TO_POINTER(semantics->id))) {
    return nullptr;
  }
  g_hash_table_add(visited, GINT_TO_POINTER(semantics->id));

  FlGtk4AccessibleNode* node = FL_GTK4_ACCESSIBLE_NODE(g_hash_table_lookup(
      self->native_nodes_by_id, GINT_TO_POINTER(semantics->id)));
  FlGtk4AccessibleNode* previous_node = node;
  node = fl_gtk4_accessible_node_update(self->view, self->view_id, semantics,
                                        node);
  if (node != previous_node) {
    g_hash_table_insert(self->native_nodes_by_id,
                        GINT_TO_POINTER(semantics->id), node);
  }

  g_autoptr(GPtrArray) children = g_ptr_array_new();
  if (semantics->child_count > 0 &&
      semantics->children_in_traversal_order != nullptr) {
    for (size_t i = 0; i < semantics->child_count; i++) {
      const int32_t child_id = semantics->children_in_traversal_order[i];
      const FlAccessibilitySemanticsNode* child =
          fl_accessibility_semantics_store_lookup_node(self->semantics_store,
                                                       child_id);
      if (child == nullptr) {
        continue;
      }

      FlGtk4AccessibleNode* child_node =
          fl_view_gtk4_accessibility_build_native_node(self, child, visited);
      if (child_node != nullptr) {
        g_ptr_array_add(children, child_node);
      }
    }
  }

  fl_gtk4_accessible_node_attach_children(node, children);
  return node;
}
#endif  // defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)

static const gchar* fl_view_gtk4_accessibility_get_root_label(
    FlViewGtk4Accessibility* self) {
  if (self->semantics_store == nullptr) {
    return "Flutter view";
  }

  const FlAccessibilitySemanticsNode* root =
      fl_accessibility_semantics_store_lookup_node(self->semantics_store, 0);
  if (root == nullptr || root->label == nullptr || root->label[0] == '\0') {
    return "Flutter view";
  }
  return root->label;
}

#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
static void fl_view_gtk4_accessibility_rebuild_native_tree(
    FlViewGtk4Accessibility* self) {
  FlRenderTextureGtk4* render_area =
      FL_RENDER_TEXTURE_GTK4(self->view->render_area);

  if (!fl_gtk_runtime_supports_native_accessibility_tree()) {
    return;
  }

  if (self->semantics_store == nullptr ||
      !fl_accessibility_semantics_store_has_root(self->semantics_store)) {
    return;
  }

  const FlAccessibilitySemanticsNode* root =
      fl_accessibility_semantics_store_lookup_node(self->semantics_store, 0);
  if (root == nullptr) {
    return;
  }

  GHashTableIter nodes_iter;
  gpointer node_key = nullptr;
  gpointer node_value = nullptr;

  g_autoptr(GHashTable) visited =
      g_hash_table_new(g_direct_hash, g_direct_equal);
  FlGtk4AccessibleNode* previous_root = self->root_node;
  self->root_node =
      fl_view_gtk4_accessibility_build_native_node(self, root, visited);
  if (self->root_node != nullptr && self->root_node != previous_root) {
    fl_gtk_runtime_accessible_set_accessible_parent(
        GTK_ACCESSIBLE(self->root_node),
        GTK_ACCESSIBLE(self->view->render_area), nullptr);
    fl_render_texture_gtk4_set_accessible_child(
        render_area, GTK_ACCESSIBLE(self->root_node));
  }

  g_hash_table_iter_init(&nodes_iter, self->native_nodes_by_id);
  while (g_hash_table_iter_next(&nodes_iter, &node_key, &node_value)) {
    if (!g_hash_table_contains(visited, node_key)) {
      fl_gtk_runtime_accessible_set_accessible_parent(
          GTK_ACCESSIBLE(node_value), nullptr, nullptr);
      g_hash_table_iter_remove(&nodes_iter);
    }
  }
}
#endif  // defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)

FlViewGtk4Accessibility* fl_view_gtk4_accessibility_new(FlView* view,
                                                        FlutterViewId view_id) {
  FlViewGtk4Accessibility* self = g_new0(FlViewGtk4Accessibility, 1);
  self->view = view;
  self->view_id = view_id;
  self->semantics_store = fl_accessibility_semantics_store_new(view_id);
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  self->native_nodes_by_id = g_hash_table_new_full(
      g_direct_hash, g_direct_equal, nullptr, g_object_unref);
#endif
  return self;
}

void fl_view_gtk4_accessibility_dispose(FlViewGtk4Accessibility* self) {
  if (self == nullptr) {
    return;
  }

#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  if (self->view != nullptr && self->view->render_area != nullptr) {
    fl_render_texture_gtk4_set_accessible_child(
        FL_RENDER_TEXTURE_GTK4(self->view->render_area), nullptr);
  }
  self->root_node = nullptr;
  g_clear_pointer(&self->native_nodes_by_id, g_hash_table_unref);
#endif
  g_clear_object(&self->semantics_store);
  g_free(self);
}

void fl_view_gtk4_accessibility_handle_update(
    FlViewGtk4Accessibility* self,
    const FlutterSemanticsUpdate2* update) {
  g_return_if_fail(self != nullptr);
  g_return_if_fail(update != nullptr);

  if (self->semantics_store == nullptr || update->view_id != self->view_id) {
    return;
  }

  fl_accessibility_semantics_store_handle_update(self->semantics_store, update);
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  if (fl_gtk_runtime_supports_native_accessibility_tree()) {
    gboolean rebuild = self->root_node == nullptr ||
                       fl_accessibility_semantics_store_structure_changed(
                           self->semantics_store);
    if (!rebuild) {
      for (size_t i = 0; i < update->node_count; i++) {
        const int32_t id = update->nodes[i]->id;
        auto* node = static_cast<FlGtk4AccessibleNode*>(
            g_hash_table_lookup(self->native_nodes_by_id, GINT_TO_POINTER(id)));
        const auto* semantics = fl_accessibility_semantics_store_lookup_node(
            self->semantics_store, id);
        if (node == nullptr || semantics == nullptr) {
          continue;
        }
        auto* updated = fl_gtk4_accessible_node_update(
            self->view, self->view_id, semantics, node);
        if (updated != node) {
          g_hash_table_insert(self->native_nodes_by_id, GINT_TO_POINTER(id),
                              updated);
          rebuild = TRUE;
        }
      }
    }
    if (rebuild) {
      fl_view_gtk4_accessibility_rebuild_native_tree(self);
    }
    fl_view_gtk4_accessibility_update_accessible_name(self);
  } else {
    fl_view_gtk4_accessibility_update_accessible_name(self);
    fl_view_gtk4_accessibility_update_accessible_tree(self);
  }
#else
  fl_view_gtk4_accessibility_update_accessible_name(self);
  fl_view_gtk4_accessibility_update_accessible_tree(self);
#endif
}

void fl_view_gtk4_accessibility_update_accessible_name(
    FlViewGtk4Accessibility* self) {
  g_return_if_fail(self != nullptr);

  const gchar* label = fl_view_gtk4_accessibility_get_root_label(self);
  GtkAccessibleProperty property = GTK_ACCESSIBLE_PROPERTY_LABEL;
  GtkAccessibleProperty properties[] = {property};
  GValue value = G_VALUE_INIT;
  gtk_accessible_property_init_value(property, &value);
  g_value_set_string(&value, label);
  gtk_accessible_update_property_value(GTK_ACCESSIBLE(self->view), 1,
                                       properties, &value);
  g_value_unset(&value);
}

void fl_view_gtk4_accessibility_update_accessible_tree(
    FlViewGtk4Accessibility* self) {
  g_return_if_fail(self != nullptr);

#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  if (fl_gtk_runtime_supports_native_accessibility_tree()) {
    fl_view_gtk4_accessibility_rebuild_native_tree(self);
  } else {
    fl_gtk_runtime_accessible_set_accessible_parent(
        GTK_ACCESSIBLE(self->view->render_area), GTK_ACCESSIBLE(self->view),
        nullptr);
  }
#else
  // Older GTK4 runtimes expose the widget-backed render surface only.
  fl_gtk_runtime_accessible_set_accessible_parent(
      GTK_ACCESSIBLE(self->view->render_area), GTK_ACCESSIBLE(self->view),
      nullptr);
#endif
}

void fl_view_gtk4_accessibility_send_announcement(FlViewGtk4Accessibility* self,
                                                  const char* message,
                                                  gboolean assertive) {
  g_return_if_fail(self != nullptr);

  fl_gtk_runtime_accessible_announce(GTK_ACCESSIBLE(self->view), message,
                                     assertive ? 1 : 0);
}

gboolean fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing() {
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  return fl_gtk_runtime_supports_native_accessibility_tree();
#else
  return FALSE;
#endif
}

GtkAccessible* fl_view_gtk4_accessibility_ref_native_root_for_testing(
    FlViewGtk4Accessibility* self) {
  g_return_val_if_fail(self != nullptr, nullptr);
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  return self->root_node == nullptr
             ? nullptr
             : GTK_ACCESSIBLE(g_object_ref(self->root_node));
#else
  return nullptr;
#endif
}

GtkAccessible* fl_view_gtk4_accessibility_ref_first_native_child_for_testing(
    GtkAccessible* accessible) {
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  g_return_val_if_fail(FL_IS_GTK4_ACCESSIBLE_NODE(accessible), nullptr);
  return fl_gtk4_accessible_node_get_first_accessible_child(accessible);
#else
  return nullptr;
#endif
}

GtkAccessible* fl_view_gtk4_accessibility_ref_next_native_sibling_for_testing(
    GtkAccessible* accessible) {
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  g_return_val_if_fail(FL_IS_GTK4_ACCESSIBLE_NODE(accessible), nullptr);
  return fl_gtk4_accessible_node_get_next_accessible_sibling(accessible);
#else
  return nullptr;
#endif
}

gboolean fl_view_gtk4_accessibility_get_native_bounds_for_testing(
    GtkAccessible* accessible,
    int* x,
    int* y,
    int* width,
    int* height) {
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  g_return_val_if_fail(FL_IS_GTK4_ACCESSIBLE_NODE(accessible), FALSE);
  return fl_gtk4_accessible_node_get_bounds(accessible, x, y, width, height);
#else
  return FALSE;
#endif
}

GBytes* fl_view_gtk4_accessibility_ref_native_text_for_testing(
    GtkAccessible* accessible) {
#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
  g_return_val_if_fail(FL_IS_GTK4_TEXT_ACCESSIBLE_NODE(accessible), nullptr);
  return fl_gtk4_text_accessible_node_get_contents(accessible, 0, G_MAXUINT);
#else
  return nullptr;
#endif
}

#endif  // FLUTTER_LINUX_GTK4
