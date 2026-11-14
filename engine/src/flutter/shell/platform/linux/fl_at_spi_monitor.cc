// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_at_spi_monitor.h"

#include <gio/gio.h>

static constexpr char kA11yBusName[] = "org.a11y.Bus";
static constexpr char kA11yBusPath[] = "/org/a11y/bus";
static constexpr char kRegistryName[] = "org.a11y.atspi.Registry";
static constexpr char kRegistryPath[] = "/org/a11y/atspi/registry";

enum { SIGNAL_CLIENT_REGISTERED, LAST_SIGNAL };

static guint fl_at_spi_monitor_signals[LAST_SIGNAL];

struct _FlAtSpiMonitor {
  GObject parent_instance;

  GCancellable* cancellable;

  // Connection to the accessibility bus.
  GDBusConnection* connection;

  guint listener_registered_id;

  gboolean client_registered;
};

G_DEFINE_TYPE(FlAtSpiMonitor, fl_at_spi_monitor, G_TYPE_OBJECT)

static void unsubscribe(FlAtSpiMonitor* self) {
  if (self->listener_registered_id != 0) {
    g_dbus_connection_signal_unsubscribe(self->connection,
                                         self->listener_registered_id);
    self->listener_registered_id = 0;
  }
}

static void notify_client_registered(FlAtSpiMonitor* self) {
  if (self->client_registered) {
    return;
  }
  self->client_registered = TRUE;
  unsubscribe(self);
  g_signal_emit(self, fl_at_spi_monitor_signals[SIGNAL_CLIENT_REGISTERED], 0);
}

static void listener_registered_cb(GDBusConnection* connection,
                                   const gchar* sender_name,
                                   const gchar* object_path,
                                   const gchar* interface_name,
                                   const gchar* signal_name,
                                   GVariant* parameters,
                                   gpointer user_data) {
  notify_client_registered(FL_AT_SPI_MONITOR(user_data));
}

static void get_registered_events_cb(GObject* object,
                                     GAsyncResult* result,
                                     gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) value =
      g_dbus_connection_call_finish(G_DBUS_CONNECTION(object), result, &error);
  if (value == nullptr) {
    if (!g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
      g_debug("Failed to read AT-SPI listeners: %s", error->message);
    }
    return;
  }

  g_autoptr(GVariant) events = g_variant_get_child_value(value, 0);
  if (g_variant_n_children(events) > 0) {
    notify_client_registered(FL_AT_SPI_MONITOR(user_data));
  }
}

static void a11y_connection_cb(GObject* object,
                               GAsyncResult* result,
                               gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(GDBusConnection) connection =
      g_dbus_connection_new_for_address_finish(result, &error);
  if (connection == nullptr) {
    if (!g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
      g_debug("Failed to connect to the accessibility bus: %s", error->message);
    }
    return;
  }

  FlAtSpiMonitor* self = FL_AT_SPI_MONITOR(user_data);
  self->connection = G_DBUS_CONNECTION(g_steal_pointer(&connection));

  // Subscribe before the read, so a listener registered between the two is
  // not missed.
  self->listener_registered_id = g_dbus_connection_signal_subscribe(
      self->connection, kRegistryName, kRegistryName, "EventListenerRegistered",
      kRegistryPath, nullptr, G_DBUS_SIGNAL_FLAGS_NONE, listener_registered_cb,
      self, nullptr);
  g_dbus_connection_call(self->connection, kRegistryName, kRegistryPath,
                         kRegistryName, "GetRegisteredEvents", nullptr,
                         G_VARIANT_TYPE("(a(ss))"), G_DBUS_CALL_FLAGS_NONE, -1,
                         self->cancellable, get_registered_events_cb, self);
}

static void connect_to_a11y_bus(FlAtSpiMonitor* self, const gchar* address) {
  g_dbus_connection_new_for_address(
      address,
      static_cast<GDBusConnectionFlags>(
          G_DBUS_CONNECTION_FLAGS_AUTHENTICATION_CLIENT |
          G_DBUS_CONNECTION_FLAGS_MESSAGE_BUS_CONNECTION),
      nullptr, self->cancellable, a11y_connection_cb, self);
}

static void get_address_cb(GObject* object,
                           GAsyncResult* result,
                           gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) value =
      g_dbus_connection_call_finish(G_DBUS_CONNECTION(object), result, &error);
  if (value == nullptr) {
    if (!g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
      g_debug("Failed to find the accessibility bus: %s", error->message);
    }
    return;
  }

  const gchar* address;
  g_variant_get(value, "(&s)", &address);
  connect_to_a11y_bus(FL_AT_SPI_MONITOR(user_data), address);
}

static void session_bus_cb(GObject* object,
                           GAsyncResult* result,
                           gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(GDBusConnection) session =
      g_dbus_connection_new_for_address_finish(result, &error);
  if (session == nullptr) {
    if (!g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
      g_debug("Failed to connect to the session bus: %s", error->message);
    }
    return;
  }

  FlAtSpiMonitor* self = FL_AT_SPI_MONITOR(user_data);
  g_dbus_connection_call(session, kA11yBusName, kA11yBusPath, kA11yBusName,
                         "GetAddress", nullptr, G_VARIANT_TYPE("(s)"),
                         G_DBUS_CALL_FLAGS_NONE, -1, self->cancellable,
                         get_address_cb, self);
}

static void fl_at_spi_monitor_dispose(GObject* object) {
  FlAtSpiMonitor* self = FL_AT_SPI_MONITOR(object);

  g_cancellable_cancel(self->cancellable);
  unsubscribe(self);
  g_clear_object(&self->cancellable);
  g_clear_object(&self->connection);

  G_OBJECT_CLASS(fl_at_spi_monitor_parent_class)->dispose(object);
}

static void fl_at_spi_monitor_class_init(FlAtSpiMonitorClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_at_spi_monitor_dispose;

  fl_at_spi_monitor_signals[SIGNAL_CLIENT_REGISTERED] = g_signal_new(
      "client-registered", fl_at_spi_monitor_get_type(), G_SIGNAL_RUN_LAST, 0,
      nullptr, nullptr, nullptr, G_TYPE_NONE, 0);
}

static void fl_at_spi_monitor_init(FlAtSpiMonitor* self) {
  self->cancellable = g_cancellable_new();
}

FlAtSpiMonitor* fl_at_spi_monitor_new() {
  return FL_AT_SPI_MONITOR(g_object_new(fl_at_spi_monitor_get_type(), nullptr));
}

void fl_at_spi_monitor_start(FlAtSpiMonitor* self) {
  g_return_if_fail(FL_IS_AT_SPI_MONITOR(self));

  // Use the same bus as the ATK bridge. A sandbox such as Flatpak gives its
  // proxy of the bus in this variable.
  const gchar* address = g_getenv("AT_SPI_BUS_ADDRESS");
  if (address != nullptr && address[0] != '\0') {
    connect_to_a11y_bus(self, address);
    return;
  }

  // A connection of its own, not the shared session bus connection, which
  // exits the process when the bus goes away.
  g_autoptr(GError) error = nullptr;
  g_autofree gchar* session_address =
      g_dbus_address_get_for_bus_sync(G_BUS_TYPE_SESSION, nullptr, &error);
  if (session_address == nullptr) {
    g_debug("Failed to find the session bus: %s", error->message);
    return;
  }
  g_dbus_connection_new_for_address(
      session_address,
      static_cast<GDBusConnectionFlags>(
          G_DBUS_CONNECTION_FLAGS_AUTHENTICATION_CLIENT |
          G_DBUS_CONNECTION_FLAGS_MESSAGE_BUS_CONNECTION),
      nullptr, self->cancellable, session_bus_cb, self);
}
