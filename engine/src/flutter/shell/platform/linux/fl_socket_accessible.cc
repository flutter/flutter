// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_socket_accessible.h"

G_DECLARE_FINAL_TYPE(FlAtkSocket, fl_atk_socket, FL, ATK_SOCKET, AtkSocket)

struct _FlAtkSocket {
  AtkSocket parent_instance;
};

G_DEFINE_TYPE(FlAtkSocket, fl_atk_socket, ATK_TYPE_SOCKET)

// Override getting the state, which is normally done via a D-Bus call to the
// other process containing the plug. Our plug is in this process, so use the
// visibility of the parent widget.
static AtkStateSet* fl_atk_socket_ref_state_set(AtkObject* object) {
  AtkStateSet* states =
      ATK_OBJECT_CLASS(fl_atk_socket_parent_class)->ref_state_set(object);

  AtkObject* parent = atk_object_get_parent(object);
  if (parent != nullptr) {
    g_autoptr(AtkStateSet) parent_states = atk_object_ref_state_set(parent);
    AtkStateType parent_types[] = {ATK_STATE_VISIBLE, ATK_STATE_SHOWING};
    for (AtkStateType state : parent_types) {
      if (atk_state_set_contains_state(parent_states, state)) {
        atk_state_set_add_state(states, state);
      }
    }
  }

  return states;
}

static void fl_atk_socket_class_init(FlAtkSocketClass* klass) {
  ATK_OBJECT_CLASS(klass)->ref_state_set = fl_atk_socket_ref_state_set;
}

static void fl_atk_socket_init(FlAtkSocket* self) {
  ATK_OBJECT(self)->role = ATK_ROLE_FILLER;
  ATK_OBJECT(self)->layer = ATK_LAYER_WIDGET;
}

static AtkObject* fl_atk_socket_new() {
  return ATK_OBJECT(g_object_new(fl_atk_socket_get_type(), nullptr));
}

// This is a copy of GtkSocketAccessible, which requires GTK 3.24.30

struct _FlSocketAccessible {
  GtkContainerAccessible parent;
  AtkObject* accessible_socket;
};

G_DEFINE_TYPE(FlSocketAccessible,
              fl_socket_accessible,
              GTK_TYPE_CONTAINER_ACCESSIBLE)

static AtkObject* fl_socket_accessible_ref_child(AtkObject* object, int i) {
  FlSocketAccessible* self = FL_SOCKET_ACCESSIBLE(object);
  return i == 0 ? ATK_OBJECT(g_object_ref(self->accessible_socket)) : nullptr;
}

static int fl_socket_accessible_get_n_children(AtkObject* object) {
  return 1;
}

static void fl_socket_accessible_dispose(GObject* object) {
  FlSocketAccessible* self = FL_SOCKET_ACCESSIBLE(object);

  g_clear_object(&self->accessible_socket);

  G_OBJECT_CLASS(fl_socket_accessible_parent_class)->dispose(object);
}

static void fl_socket_accessible_initialize(AtkObject* object, gpointer data) {
  FlSocketAccessible* self = FL_SOCKET_ACCESSIBLE(object);

  ATK_OBJECT_CLASS(fl_socket_accessible_parent_class)->initialize(object, data);

  self->accessible_socket = fl_atk_socket_new();
  atk_object_set_parent(self->accessible_socket, object);
}

static void fl_socket_accessible_class_init(FlSocketAccessibleClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = fl_socket_accessible_dispose;

  AtkObjectClass* atk_class = ATK_OBJECT_CLASS(klass);
  atk_class->initialize = fl_socket_accessible_initialize;
  atk_class->get_n_children = fl_socket_accessible_get_n_children;
  atk_class->ref_child = fl_socket_accessible_ref_child;
}

static void fl_socket_accessible_init(FlSocketAccessible* self) {}

void fl_socket_accessible_embed(FlSocketAccessible* self, AtkPlug* plug) {
  atk_object_set_parent(ATK_OBJECT(plug), self->accessible_socket);

  // AtkSocket and AtkPlug are designed for use between processes. at-spi2-atk
  // replaces ref_state_set with a blocking D-Bus call to the plug, which can't
  // be answered as the plug is in this process. Keep our implementation.
  AtkObjectClass* socket_class = ATK_OBJECT_GET_CLASS(self->accessible_socket);
  auto ref_state_set = socket_class->ref_state_set;
  g_autofree gchar* id = atk_plug_get_id(plug);
  atk_socket_embed(ATK_SOCKET(self->accessible_socket), id);
  socket_class->ref_state_set = ref_state_set;
}
