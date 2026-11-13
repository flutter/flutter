// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_gtk4_text_accessible_node.h"

#if FLUTTER_LINUX_GTK4 && defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)

#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_gtk4_accessible_node_private.h"
#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_message_codec.h"

typedef struct _FlGtk4TextAccessibleNode FlGtk4TextAccessibleNode;
typedef struct _FlGtk4TextAccessibleNodeClass FlGtk4TextAccessibleNodeClass;
typedef struct _FlGtk4EditableAccessibleNode FlGtk4EditableAccessibleNode;
typedef struct _FlGtk4EditableAccessibleNodeClass
    FlGtk4EditableAccessibleNodeClass;

struct _FlGtk4TextAccessibleNode {
  FlGtk4AccessibleNode parent_instance;
};

struct _FlGtk4TextAccessibleNodeClass {
  FlGtk4AccessibleNodeClass parent_class;
};

struct _FlGtk4EditableAccessibleNode {
  FlGtk4TextAccessibleNode parent_instance;
  gchar* pending_text;
  guint pending_source;
  guint pending_caret;
  gboolean awaiting_semantics;
};

struct _FlGtk4EditableAccessibleNodeClass {
  FlGtk4TextAccessibleNodeClass parent_class;
};

static void fl_gtk4_text_accessible_node_text_iface_init(
    FlGtkAccessibleTextInterface4_14* iface);
static void fl_gtk4_editable_accessible_node_iface_init(
    GtkEditableInterface* iface);

G_DEFINE_TYPE_WITH_CODE(
    FlGtk4TextAccessibleNode,
    fl_gtk4_text_accessible_node,
    FL_TYPE_GTK4_ACCESSIBLE_NODE,
    G_IMPLEMENT_INTERFACE(fl_gtk_runtime_accessible_text_get_type(),
                          fl_gtk4_text_accessible_node_text_iface_init))

G_DEFINE_TYPE_WITH_CODE(
    FlGtk4EditableAccessibleNode,
    fl_gtk4_editable_accessible_node,
    FL_TYPE_GTK4_TEXT_ACCESSIBLE_NODE,
    G_IMPLEMENT_INTERFACE(GTK_TYPE_EDITABLE,
                          fl_gtk4_editable_accessible_node_iface_init))

static const gchar* fl_gtk4_text_accessible_node_get_text(
    FlGtk4AccessibleNode* self) {
  return self->text == nullptr ? "" : self->text;
}

static guint fl_gtk4_text_accessible_node_get_text_length(
    FlGtk4AccessibleNode* self) {
  return static_cast<guint>(
      g_utf8_strlen(fl_gtk4_text_accessible_node_get_text(self), -1));
}

GBytes* fl_gtk4_text_accessible_node_get_contents(GtkAccessible* accessible,
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

  // Character offsets are Unicode code points, not UTF-8 byte offsets.
  if (granularity == FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_CHARACTER) {
    const guint next = offset < length ? offset + 1 : length;
    if (start != nullptr) {
      *start = offset;
    }
    if (end != nullptr) {
      *end = next;
    }
    return fl_gtk4_text_accessible_node_get_contents(accessible, offset, next);
  }

  if (granularity == FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_WORD ||
      granularity == FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_SENTENCE) {
    // Use linguistic boundaries without treating Pango's layout as Flutter's
    // visual layout. Only compute these attributes when queried.
    PangoLayout* layout = gtk_widget_create_pango_layout(
        GTK_WIDGET(self), fl_gtk4_text_accessible_node_get_text(self));
    int n_attrs = 0;
    const PangoLogAttr* attrs =
        pango_layout_get_log_attrs_readonly(layout, &n_attrs);
    guint first = offset;
    // GTK ranges extend to the next start, including intervening separators.
    guint last = offset < length ? offset + 1 : length;
    const gboolean word =
        granularity == FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_WORD;
    while (first > 0 && !(word ? attrs[first].is_word_start
                               : attrs[first].is_sentence_start)) {
      first--;
    }
    while (last < length && !(word ? attrs[last].is_word_start
                                   : attrs[last].is_sentence_start)) {
      last++;
    }
    g_object_unref(layout);
    if (start != nullptr) {
      *start = first;
    }
    if (end != nullptr) {
      *end = last;
    }
    return fl_gtk4_text_accessible_node_get_contents(accessible, first, last);
  }

  if (granularity == FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_PARAGRAPH) {
    const gchar* paragraph = fl_gtk4_text_accessible_node_get_text(self);
    guint first = 0;
    guint last = 0;
    while (true) {
      int delimiter = 0;
      int next = 0;
      pango_find_paragraph_boundary(paragraph, -1, &delimiter, &next);
      last = first + g_utf8_strlen(paragraph, next);
      // Include separators up to the next paragraph start. If there is no
      // delimiter, this is the last paragraph (possibly an empty trailing one).
      if (offset < last || delimiter == next) {
        break;
      }
      paragraph += next;
      first = last;
    }
    if (start != nullptr) {
      *start = first;
    }
    if (end != nullptr) {
      *end = last;
    }
    return fl_gtk4_text_accessible_node_get_contents(accessible, first, last);
  }

  // Semantics does not provide visual line runs; keep the whole-text fallback
  // for layout-dependent queries rather than inventing Flutter's wrapping.
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

static gboolean fl_gtk4_text_accessible_node_dispatch_selection(
    FlGtk4AccessibleNode* self,
    const char* text,
    gsize start,
    gsize end) {
  if (self->view == nullptr || !self->text_actions_enabled ||
      (self->actions & kFlutterSemanticsActionSetSelection) == 0) {
    return FALSE;
  }
  // GTK offsets count characters; Flutter's selection action uses UTF-16 units.
  gint64 base = 0;
  gint64 extent = 0;
  if (self->protected_text_offsets != nullptr && text == self->text) {
    if (MAX(start, end) >= self->protected_text_offsets->len) {
      return FALSE;
    }
    base = g_array_index(self->protected_text_offsets, guint, start);
    extent = g_array_index(self->protected_text_offsets, guint, end);
  } else {
    const gchar* cursor = text;
    for (gsize i = 0; i < MAX(start, end); i++) {
      if (*cursor == '\0') {
        return FALSE;
      }
      const int units = g_utf8_get_char(cursor) > 0xffff ? 2 : 1;
      if (i < start) {
        base += units;
      }
      if (i < end) {
        extent += units;
      }
      cursor = g_utf8_next_char(cursor);
    }
  }
  g_autoptr(FlValue) value = fl_value_new_map();
  fl_value_set_string_take(value, "base", fl_value_new_int(base));
  fl_value_set_string_take(value, "extent", fl_value_new_int(extent));
  g_autoptr(FlStandardMessageCodec) codec = fl_standard_message_codec_new();
  g_autoptr(GBytes) message =
      fl_message_codec_encode_message(FL_MESSAGE_CODEC(codec), value, nullptr);
  if (message == nullptr) {
    return FALSE;
  }
  fl_engine_dispatch_semantics_action(
      fl_view_get_engine(self->view), self->view_id, self->semantics_id,
      kFlutterSemanticsActionSetSelection, message);
  // Flutter semantics remains authoritative; do not optimistically change
  // state.
  return TRUE;
}

static gboolean fl_gtk4_text_accessible_node_set_selection(
    GtkAccessible* accessible,
    gsize index,
    FlGtkAccessibleTextRange4_14* range) {
  auto* self = FL_GTK4_ACCESSIBLE_NODE(accessible);
  const guint length = fl_gtk4_text_accessible_node_get_text_length(self);
  if (index != 0 || range == nullptr || range->start > length ||
      range->length > length - range->start ||
      (GTK_IS_EDITABLE(self) &&
       reinterpret_cast<FlGtk4EditableAccessibleNode*>(self)
           ->awaiting_semantics)) {
    return FALSE;
  }
  return fl_gtk4_text_accessible_node_dispatch_selection(
      self, fl_gtk4_text_accessible_node_get_text(self), range->start,
      range->start + range->length);
}

static gboolean fl_gtk4_text_accessible_node_set_caret_position(
    GtkAccessible* accessible,
    unsigned int offset) {
  FlGtkAccessibleTextRange4_14 range = {offset, 0};
  return fl_gtk4_text_accessible_node_set_selection(accessible, 0, &range);
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
  fl_gtk_runtime_accessible_text_install_editing_callbacks(
      iface, fl_gtk4_text_accessible_node_set_caret_position,
      fl_gtk4_text_accessible_node_set_selection);
}

static guint utf16_offset_to_character_offset(const gchar* text, gint offset) {
  guint characters = 0;
  // Flutter selections count UTF-16 code units; GTK counts Unicode code points.
  // Clamp invalid offsets to a character boundary without splitting a
  // surrogate.
  while (*text != '\0' && offset > 0) {
    const gint units = g_utf8_get_char(text) > 0xffff ? 2 : 1;
    if (offset < units) {
      break;
    }
    offset -= units;
    characters++;
    text = g_utf8_next_char(text);
  }
  return characters;
}

void fl_gtk4_text_accessible_node_set_text(FlGtk4AccessibleNode* self,
                                           const gchar* text,
                                           gint selection_base,
                                           gint selection_extent,
                                           gboolean is_obscured) {
  const gchar* source_text = text == nullptr ? "" : text;
  g_autofree gchar* masked_text = nullptr;
  if (is_obscured) {
    masked_text = g_strnfill(g_utf8_strlen(source_text, -1), '*');
    if (self->protected_text_offsets == nullptr) {
      self->protected_text_offsets = g_array_new(FALSE, FALSE, sizeof(guint));
    }
    g_array_set_size(self->protected_text_offsets, 0);
    guint units = 0;
    g_array_append_val(self->protected_text_offsets, units);
    for (const gchar* cursor = source_text; *cursor != '\0';
         cursor = g_utf8_next_char(cursor)) {
      units += g_utf8_get_char(cursor) > 0xffff ? 2 : 1;
      g_array_append_val(self->protected_text_offsets, units);
    }
  } else {
    g_clear_pointer(&self->protected_text_offsets, g_array_unref);
  }
  const gchar* new_text = is_obscured ? masked_text : source_text;
  const gboolean text_changed = g_strcmp0(self->text, new_text) != 0;
  if (GTK_IS_EDITABLE(self)) {
    auto* editable = reinterpret_cast<FlGtk4EditableAccessibleNode*>(self);
    if (editable->awaiting_semantics || text_changed || !self->text_editable) {
      fl_gtk4_editable_accessible_node_cancel(self);
    }
  }
  guint change_start = 0;
  guint removed = 0;
  guint inserted = 0;
  if (text_changed) {
    const gchar* old_start = fl_gtk4_text_accessible_node_get_text(self);
    const gchar* new_start = new_text;
    const gchar* old_end = old_start + strlen(old_start);
    const gchar* new_end = new_start + strlen(new_start);
    // Trim equal code points, not bytes: UTF-8 characters can share leading
    // bytes. A single replacement range preserves unchanged prefix/suffix text.
    while (*old_start != '\0' && *new_start != '\0' &&
           g_utf8_get_char(old_start) == g_utf8_get_char(new_start)) {
      old_start = g_utf8_next_char(old_start);
      new_start = g_utf8_next_char(new_start);
      change_start++;
    }
    while (old_end > old_start && new_end > new_start) {
      const gchar* old_previous = g_utf8_prev_char(old_end);
      const gchar* new_previous = g_utf8_prev_char(new_end);
      if (g_utf8_get_char(old_previous) != g_utf8_get_char(new_previous)) {
        break;
      }
      old_end = old_previous;
      new_end = new_previous;
    }
    removed = g_utf8_strlen(old_start, old_end - old_start);
    inserted = g_utf8_strlen(new_start, new_end - new_start);
    // GTK reads removed contents synchronously into the AT-SPI event payload.
    // When protection is enabled, redact them first so the deletion event can
    // invalidate AT caches without broadcasting the formerly readable value.
    // Preserve the old character count for GTK's pre-removal query contract.
    if (is_obscured) {
      gchar* redacted =
          g_strnfill(fl_gtk4_text_accessible_node_get_text_length(self), '*');
      g_free(self->text);
      self->text = redacted;
    }
    if (removed != 0) {
      fl_gtk_runtime_accessible_text_update_contents(
          GTK_ACCESSIBLE(self), 1, change_start, change_start + removed);
    }
    g_free(self->text);
    self->text = g_strdup(new_text);
  }

  const guint new_base =
      utf16_offset_to_character_offset(source_text, selection_base);
  const guint new_extent =
      utf16_offset_to_character_offset(source_text, selection_extent);
  const gboolean caret_changed = self->text_selection_extent != new_extent;
  const gboolean selection_changed =
      self->text_selection_base != new_base || caret_changed;
  self->text_selection_base = new_base;
  self->text_selection_extent = new_extent;

  if (inserted != 0) {
    fl_gtk_runtime_accessible_text_update_contents(
        GTK_ACCESSIBLE(self), 0, change_start, change_start + inserted);
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

static gboolean fl_gtk4_editable_accessible_node_can_edit(
    GtkEditable* editable) {
  auto* self = FL_GTK4_ACCESSIBLE_NODE(editable);
  auto* node = reinterpret_cast<FlGtk4EditableAccessibleNode*>(editable);
  return self->view != nullptr && self->text_editable &&
         !node->awaiting_semantics;
}

void fl_gtk4_editable_accessible_node_cancel(FlGtk4AccessibleNode* self) {
  if (!GTK_IS_EDITABLE(self)) {
    return;
  }
  auto* node = reinterpret_cast<FlGtk4EditableAccessibleNode*>(self);
  const guint source = node->pending_source;
  node->pending_source = 0;
  g_clear_pointer(&node->pending_text, g_free);
  node->awaiting_semantics = FALSE;
  if (source != 0) {
    g_source_remove(source);
  }
}

static gboolean fl_gtk4_editable_accessible_node_flush(gpointer data) {
  auto* self = FL_GTK4_ACCESSIBLE_NODE(data);
  auto* node = reinterpret_cast<FlGtk4EditableAccessibleNode*>(self);
  node->pending_source = 0;
  g_autofree gchar* text =
      static_cast<gchar*>(g_steal_pointer(&node->pending_text));
  if (text == nullptr ||
      !fl_gtk4_editable_accessible_node_can_edit(GTK_EDITABLE(self))) {
    return G_SOURCE_REMOVE;
  }
  const guint caret = node->pending_caret;
  if (g_strcmp0(text, fl_gtk4_text_accessible_node_get_text(self)) == 0 &&
      self->text_selection_base == caret &&
      self->text_selection_extent == caret) {
    return G_SOURCE_REMOVE;
  }
  g_autoptr(FlValue) value = fl_value_new_string(text);
  g_autoptr(FlStandardMessageCodec) codec = fl_standard_message_codec_new();
  g_autoptr(GBytes) message =
      fl_message_codec_encode_message(FL_MESSAGE_CODEC(codec), value, nullptr);
  if (message == nullptr) {
    return G_SOURCE_REMOVE;
  }
  // Serialize requests until Flutter publishes an authoritative semantics
  // batch. Queries continue to return committed text while the request is in
  // flight.
  node->awaiting_semantics = TRUE;
  const guint64 revision = self->semantics_revision;
  fl_engine_dispatch_semantics_action(fl_view_get_engine(self->view),
                                      self->view_id, self->semantics_id,
                                      kFlutterSemanticsActionSetText, message);
  // A synchronous semantics response may reject or format the requested text.
  // Otherwise the ordered selection request applies to the replacement text.
  if (self->semantics_revision == revision ||
      g_strcmp0(text, fl_gtk4_text_accessible_node_get_text(self)) == 0) {
    fl_gtk4_text_accessible_node_dispatch_selection(self, text, caret, caret);
  }
  return G_SOURCE_REMOVE;
}

static void fl_gtk4_editable_accessible_node_schedule(
    FlGtk4EditableAccessibleNode* node) {
  if (node->pending_source == 0) {
    node->pending_source = g_idle_add_full(
        G_PRIORITY_DEFAULT_IDLE, fl_gtk4_editable_accessible_node_flush,
        g_object_ref(node), g_object_unref);
  }
}

static const char* fl_gtk4_editable_accessible_node_get_text(
    GtkEditable* editable) {
  return fl_gtk4_text_accessible_node_get_text(
      FL_GTK4_ACCESSIBLE_NODE(editable));
}

static void fl_gtk4_editable_accessible_node_insert(GtkEditable* editable,
                                                    const char* text,
                                                    int bytes,
                                                    int* position) {
  if (!fl_gtk4_editable_accessible_node_can_edit(editable) ||
      !g_utf8_validate(text, bytes, nullptr)) {
    return;
  }
  auto* node = reinterpret_cast<FlGtk4EditableAccessibleNode*>(editable);
  const char* current =
      node->pending_text != nullptr
          ? node->pending_text
          : fl_gtk4_editable_accessible_node_get_text(editable);
  const glong length = g_utf8_strlen(current, -1);
  const int start = *position == -1 ? length : *position;
  if (start < 0 || start > length || bytes == 0) {
    return;
  }
  const char* split = g_utf8_offset_to_pointer(current, start);
  g_autofree gchar* prefix = g_strndup(current, split - current);
  g_autofree gchar* inserted = g_strndup(text, bytes);
  gchar* replacement = g_strconcat(prefix, inserted, split, nullptr);
  const guint caret = start + g_utf8_strlen(inserted, -1);
  g_free(node->pending_text);
  node->pending_text = replacement;
  node->pending_caret = caret;
  *position = caret;
  fl_gtk4_editable_accessible_node_schedule(node);
}

static void fl_gtk4_editable_accessible_node_delete(GtkEditable* editable,
                                                    int start,
                                                    int end) {
  if (!fl_gtk4_editable_accessible_node_can_edit(editable)) {
    return;
  }
  auto* node = reinterpret_cast<FlGtk4EditableAccessibleNode*>(editable);
  const char* current =
      node->pending_text != nullptr
          ? node->pending_text
          : fl_gtk4_editable_accessible_node_get_text(editable);
  const glong length = g_utf8_strlen(current, -1);
  if (end == -1) {
    end = length;
  }
  if (start < 0 || end < start || end > length || start == end) {
    return;
  }
  const char* first = g_utf8_offset_to_pointer(current, start);
  const char* last = g_utf8_offset_to_pointer(current, end);
  g_autofree gchar* prefix = g_strndup(current, first - current);
  gchar* replacement = g_strconcat(prefix, last, nullptr);
  g_free(node->pending_text);
  node->pending_text = replacement;
  node->pending_caret = start;
  fl_gtk4_editable_accessible_node_schedule(node);
}

static gboolean fl_gtk4_editable_accessible_node_get_selection(
    GtkEditable* editable,
    int* start,
    int* end) {
  auto* self = FL_GTK4_ACCESSIBLE_NODE(editable);
  *start = self->text_selection_base;
  *end = self->text_selection_extent;
  return *start != *end;
}

static void fl_gtk4_editable_accessible_node_select(GtkEditable* editable,
                                                    int start,
                                                    int end) {
  auto* self = FL_GTK4_ACCESSIBLE_NODE(editable);
  const guint length = fl_gtk4_text_accessible_node_get_text_length(self);
  if (start == -1) {
    start = length;
  }
  if (end == -1) {
    end = length;
  }
  if (start < 0 || end < 0 || static_cast<guint>(start) > length ||
      static_cast<guint>(end) > length ||
      reinterpret_cast<FlGtk4EditableAccessibleNode*>(editable)
          ->awaiting_semantics) {
    return;
  }
  fl_gtk4_text_accessible_node_dispatch_selection(
      self, fl_gtk4_text_accessible_node_get_text(self), start, end);
}

static void fl_gtk4_editable_accessible_node_get_property(GObject* object,
                                                          guint property,
                                                          GValue* value,
                                                          GParamSpec* spec) {
  auto* self = FL_GTK4_ACCESSIBLE_NODE(object);
  if (property < LAST_GTK4_ACCESSIBLE_NODE_PROPERTY) {
    G_OBJECT_CLASS(fl_gtk4_editable_accessible_node_parent_class)
        ->get_property(object, property, value, spec);
    return;
  }
  switch (property - LAST_GTK4_ACCESSIBLE_NODE_PROPERTY) {
    case GTK_EDITABLE_PROP_TEXT:
      g_value_set_string(value, fl_gtk4_text_accessible_node_get_text(self));
      break;
    case GTK_EDITABLE_PROP_CURSOR_POSITION:
      g_value_set_int(value, self->text_selection_extent);
      break;
    case GTK_EDITABLE_PROP_SELECTION_BOUND:
      g_value_set_int(value, self->text_selection_base);
      break;
    case GTK_EDITABLE_PROP_EDITABLE:
      g_value_set_boolean(
          value, fl_gtk4_editable_accessible_node_can_edit(GTK_EDITABLE(self)));
      break;
    default:
      g_param_value_set_default(spec, value);
      break;
  }
}

static void fl_gtk4_editable_accessible_node_set_property(GObject* object,
                                                          guint property,
                                                          const GValue* value,
                                                          GParamSpec* spec) {
  if (property < LAST_GTK4_ACCESSIBLE_NODE_PROPERTY) {
    G_OBJECT_CLASS(fl_gtk4_editable_accessible_node_parent_class)
        ->set_property(object, property, value, spec);
  } else if (property == LAST_GTK4_ACCESSIBLE_NODE_PROPERTY +
                             static_cast<guint>(GTK_EDITABLE_PROP_TEXT)) {
    gtk_editable_set_text(GTK_EDITABLE(object), g_value_get_string(value));
  }
  // Other editable properties are controlled by Flutter semantics or layout.
}

static void fl_gtk4_editable_accessible_node_dispose(GObject* object) {
  fl_gtk4_editable_accessible_node_cancel(FL_GTK4_ACCESSIBLE_NODE(object));
  G_OBJECT_CLASS(fl_gtk4_editable_accessible_node_parent_class)
      ->dispose(object);
}

static void fl_gtk4_editable_accessible_node_class_init(
    FlGtk4EditableAccessibleNodeClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->get_property = fl_gtk4_editable_accessible_node_get_property;
  object_class->set_property = fl_gtk4_editable_accessible_node_set_property;
  object_class->dispose = fl_gtk4_editable_accessible_node_dispose;
  gtk_editable_install_properties(object_class,
                                  LAST_GTK4_ACCESSIBLE_NODE_PROPERTY);
}

static void fl_gtk4_editable_accessible_node_init(
    FlGtk4EditableAccessibleNode*) {}

static void fl_gtk4_editable_accessible_node_iface_init(
    GtkEditableInterface* iface) {
  iface->get_text = fl_gtk4_editable_accessible_node_get_text;
  iface->do_insert_text = fl_gtk4_editable_accessible_node_insert;
  iface->do_delete_text = fl_gtk4_editable_accessible_node_delete;
  iface->get_selection_bounds = fl_gtk4_editable_accessible_node_get_selection;
  iface->set_selection_bounds = fl_gtk4_editable_accessible_node_select;
}

#endif  // FLUTTER_LINUX_GTK4 && FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE
