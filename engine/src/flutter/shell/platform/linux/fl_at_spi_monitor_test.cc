// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_at_spi_monitor.h"

#include <gio/gio.h>

#include <utility>
#include <vector>

#include "gtest/gtest.h"

namespace {

constexpr char kIntrospection[] =
    "<node>"
    "  <interface name='org.a11y.Bus'>"
    "    <method name='GetAddress'>"
    "      <arg type='s' direction='out'/>"
    "    </method>"
    "  </interface>"
    "  <interface name='org.a11y.atspi.Registry'>"
    "    <method name='GetRegisteredEvents'>"
    "      <arg type='a(ss)' direction='out'/>"
    "    </method>"
    "    <signal name='EventListenerRegistered'>"
    "      <arg type='s'/>"
    "      <arg type='s'/>"
    "      <arg type='as'/>"
    "    </signal>"
    "  </interface>"
    "</node>";

// Runs a private session bus that is also the accessibility bus, with a fake
// AT-SPI registry on it.
class FlAtSpiMonitorTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // The test changes these, and later tests need the real values.
    for (const char* name : kSavedEnvironment) {
      saved_environment_.emplace_back(name, g_strdup(g_getenv(name)));
    }
    g_unsetenv("AT_SPI_BUS_ADDRESS");

    // Start the bus directly. GTestDBus forks a watcher that calls exit(),
    // which runs the static destructors of this test binary and can hang.
    g_autofree gchar* dbus_daemon = g_find_program_in_path("dbus-daemon");
    if (dbus_daemon == nullptr) {
      GTEST_SKIP() << "dbus-daemon is not installed";
    }
    g_autoptr(GError) error = nullptr;
    daemon_ =
        g_subprocess_new(G_SUBPROCESS_FLAGS_STDOUT_PIPE, &error, "dbus-daemon",
                         "--session", "--nofork", "--print-address", nullptr);
    ASSERT_NE(daemon_, nullptr) << error->message;
    g_autoptr(GDataInputStream) out =
        g_data_input_stream_new(g_subprocess_get_stdout_pipe(daemon_));
    address_ = g_data_input_stream_read_line(out, nullptr, nullptr, &error);
    ASSERT_NE(address_, nullptr);
    g_setenv("DBUS_SESSION_BUS_ADDRESS", address_, TRUE);

    connection_ = g_dbus_connection_new_for_address_sync(
        address_,
        static_cast<GDBusConnectionFlags>(
            G_DBUS_CONNECTION_FLAGS_AUTHENTICATION_CLIENT |
            G_DBUS_CONNECTION_FLAGS_MESSAGE_BUS_CONNECTION),
        nullptr, nullptr, &error);
    ASSERT_NE(connection_, nullptr) << error->message;
    node_ = g_dbus_node_info_new_for_xml(kIntrospection, &error);
    ASSERT_NE(node_, nullptr) << error->message;

    static const GDBusInterfaceVTable vtable = {.method_call = method_call_cb};
    for (int i = 0; i < 2; i++) {
      ASSERT_NE(g_dbus_connection_register_object(
                    connection_, i == 0 ? "/org/a11y/bus" : kRegistryPath,
                    node_->interfaces[i], &vtable, this, nullptr, &error),
                0u)
          << error->message;
    }
    for (const char* name : {"org.a11y.Bus", "org.a11y.atspi.Registry"}) {
      g_autoptr(GVariant) reply = g_dbus_connection_call_sync(
          connection_, "org.freedesktop.DBus", "/org/freedesktop/DBus",
          "org.freedesktop.DBus", "RequestName", g_variant_new("(su)", name, 0),
          nullptr, G_DBUS_CALL_FLAGS_NONE, -1, nullptr, &error);
      ASSERT_NE(reply, nullptr) << error->message;
    }
  }

  void TearDown() override {
    g_clear_pointer(&node_, g_dbus_node_info_unref);
    g_clear_object(&connection_);
    if (daemon_ != nullptr) {
      g_subprocess_force_exit(daemon_);
      g_subprocess_wait(daemon_, nullptr, nullptr);
    }
    g_clear_object(&daemon_);
    g_clear_pointer(&address_, g_free);

    for (auto& [name, value] : saved_environment_) {
      if (value == nullptr) {
        g_unsetenv(name);
      } else {
        g_setenv(name, value, TRUE);
      }
      g_free(value);
    }
    saved_environment_.clear();
  }

  static constexpr const char* kSavedEnvironment[] = {
      "DBUS_SESSION_BUS_ADDRESS", "AT_SPI_BUS_ADDRESS"};
  std::vector<std::pair<const char*, gchar*>> saved_environment_;

  // Runs the main loop until the monitor has had time to read the registry.
  void Flush() {
    for (int i = 0; i < 50; i++) {
      while (g_main_context_iteration(nullptr, FALSE)) {
      }
      g_usleep(2000);
    }
  }

  void EmitListenerRegistered() {
    g_autoptr(GError) error = nullptr;
    EXPECT_TRUE(g_dbus_connection_emit_signal(
        connection_, nullptr, kRegistryPath, "org.a11y.atspi.Registry",
        "EventListenerRegistered",
        g_variant_new("(ss@as)", ":1.9",
                      "Focus:", g_variant_new_strv(nullptr, 0)),
        &error));
  }

  static constexpr char kRegistryPath[] = "/org/a11y/atspi/registry";

  // Whether GetRegisteredEvents returns a listener.
  bool has_listener_ = false;

  // Whether org.a11y.Bus gives an address that cannot be connected to.
  bool bad_bus_address_ = false;

  const gchar* bus_address() { return address_; }

 private:
  static void method_call_cb(GDBusConnection* connection,
                             const gchar* sender,
                             const gchar* object_path,
                             const gchar* interface_name,
                             const gchar* method_name,
                             GVariant* parameters,
                             GDBusMethodInvocation* invocation,
                             gpointer user_data) {
    FlAtSpiMonitorTest* self = static_cast<FlAtSpiMonitorTest*>(user_data);
    if (g_strcmp0(method_name, "GetAddress") == 0) {
      g_dbus_method_invocation_return_value(
          invocation,
          g_variant_new("(s)", self->bad_bus_address_ ? "unix:path=/nonexistent"
                                                      : self->address_));
      return;
    }
    GVariantBuilder events;
    g_variant_builder_init(&events, G_VARIANT_TYPE("a(ss)"));
    if (self->has_listener_) {
      g_variant_builder_add(&events, "(ss)", ":1.9", "Focus:");
    }
    g_dbus_method_invocation_return_value(invocation,
                                          g_variant_new("(a(ss))", &events));
  }

  GSubprocess* daemon_ = nullptr;
  gchar* address_ = nullptr;
  GDBusConnection* connection_ = nullptr;
  GDBusNodeInfo* node_ = nullptr;
};

void count_cb(int* count) {
  (*count)++;
}

}  // namespace

TEST_F(FlAtSpiMonitorTest, NoClient) {
  g_autoptr(FlAtSpiMonitor) monitor = fl_at_spi_monitor_new();
  int count = 0;
  g_signal_connect_swapped(monitor, "client-registered", G_CALLBACK(count_cb),
                           &count);
  fl_at_spi_monitor_start(monitor);
  Flush();

  EXPECT_EQ(count, 0);
}

TEST_F(FlAtSpiMonitorTest, ClientAlreadyRegistered) {
  has_listener_ = true;
  g_autoptr(FlAtSpiMonitor) monitor = fl_at_spi_monitor_new();
  int count = 0;
  g_signal_connect_swapped(monitor, "client-registered", G_CALLBACK(count_cb),
                           &count);
  fl_at_spi_monitor_start(monitor);
  Flush();

  EXPECT_EQ(count, 1);
}

TEST_F(FlAtSpiMonitorTest, ClientRegistersLater) {
  g_autoptr(FlAtSpiMonitor) monitor = fl_at_spi_monitor_new();
  int count = 0;
  g_signal_connect_swapped(monitor, "client-registered", G_CALLBACK(count_cb),
                           &count);
  fl_at_spi_monitor_start(monitor);
  Flush();
  EXPECT_EQ(count, 0);

  EmitListenerRegistered();
  Flush();
  EXPECT_EQ(count, 1);

  // A second client does not emit again.
  EmitListenerRegistered();
  Flush();
  EXPECT_EQ(count, 1);
}

TEST_F(FlAtSpiMonitorTest, DisposeWhileConnecting) {
  {
    g_autoptr(FlAtSpiMonitor) monitor = fl_at_spi_monitor_new();
    fl_at_spi_monitor_start(monitor);
  }
  // The callbacks of the cancelled calls must not touch the freed monitor.
  Flush();
}

// A sandbox gives the accessibility bus in AT_SPI_BUS_ADDRESS, which is used
// before asking org.a11y.Bus.
TEST_F(FlAtSpiMonitorTest, BusAddressFromEnvironment) {
  has_listener_ = true;
  bad_bus_address_ = true;
  g_setenv("AT_SPI_BUS_ADDRESS", bus_address(), TRUE);
  g_autoptr(FlAtSpiMonitor) monitor = fl_at_spi_monitor_new();
  int count = 0;
  g_signal_connect_swapped(monitor, "client-registered", G_CALLBACK(count_cb),
                           &count);
  fl_at_spi_monitor_start(monitor);
  Flush();

  EXPECT_EQ(count, 1);
}
