// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is really a unit test for |MasterConnectionManager| and
// |SlaveConnectionManager| (since they need to be tested together).

#include "mojo/edk/system/connection_manager.h"

#include <stdint.h>

#include <memory>
#include <string>

#include "mojo/edk/base_edk/platform_task_runner_impl.h"
#include "mojo/edk/embedder/master_process_delegate.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/edk/embedder/slave_process_delegate.h"
#include "mojo/edk/platform/message_loop.h"
#include "mojo/edk/platform/platform_handle.h"
#include "mojo/edk/platform/platform_pipe.h"
#include "mojo/edk/platform/test_message_loops.h"
#include "mojo/edk/system/master_connection_manager.h"
#include "mojo/edk/system/slave_connection_manager.h"
#include "mojo/edk/test/test_utils.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/thread_checker.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::MessageLoop;
using mojo::platform::PlatformHandle;
using mojo::platform::PlatformPipe;
using mojo::platform::ScopedPlatformHandle;
using mojo::platform::TaskRunner;
using mojo::platform::test::CreateTestMessageLoop;
using mojo::util::MakeRefCounted;
using mojo::util::RefPtr;
using mojo::util::ThreadChecker;

namespace mojo {
namespace system {
namespace {

bool ArePlatformHandlesConnected(const PlatformHandle& h1,
                                 const PlatformHandle& h2) {
  const uint32_t w1 = 0xdeadbeef;
  size_t num_bytes = 0;
  if (!mojo::test::BlockingWrite(h1, &w1, sizeof(w1), &num_bytes) ||
      num_bytes != sizeof(w1))
    return false;
  uint32_t r = 0;
  num_bytes = 0;
  if (!mojo::test::BlockingRead(h2, &r, sizeof(r), &num_bytes) ||
      num_bytes != sizeof(r))
    return false;
  if (r != w1)
    return false;

  const uint32_t w2 = 0xfeedface;
  num_bytes = 0;
  if (!mojo::test::BlockingWrite(h1, &w2, sizeof(w2), &num_bytes) ||
      num_bytes != sizeof(w2))
    return false;
  r = 0;
  num_bytes = 0;
  if (!mojo::test::BlockingRead(h2, &r, sizeof(r), &num_bytes) ||
      num_bytes != sizeof(r))
    return false;
  if (r != w2)
    return false;

  return true;
}

bool IsValidSlaveProcessIdentifier(ProcessIdentifier process_identifier) {
  return process_identifier != kInvalidProcessIdentifier &&
         process_identifier != kMasterProcessIdentifier;
}

class TestSlaveInfo {
 public:
  explicit TestSlaveInfo(const std::string& name) : name_(name) {}
  ~TestSlaveInfo() { CHECK(thread_checker_.IsCreationThreadCurrent()); }

  const std::string& name() const { return name_; }

 private:
  ThreadChecker thread_checker_;
  std::string name_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestSlaveInfo);
};

class MockMasterProcessDelegate : public embedder::MasterProcessDelegate {
 public:
  MockMasterProcessDelegate()
      : current_message_loop_(), on_slave_disconnect_calls_(0) {}
  ~MockMasterProcessDelegate() override {}

  void RunUntilNotified(MessageLoop* message_loop) {
    CHECK(!current_message_loop_);
    current_message_loop_ = message_loop;
    message_loop->Run();
    current_message_loop_ = nullptr;
  }

  unsigned on_slave_disconnect_calls() const {
    return on_slave_disconnect_calls_;
  }
  const std::string& last_slave_disconnect_name() const {
    return last_slave_disconnect_name_;
  }

  // |embedder::MasterProcessDelegate| implementation:
  void OnShutdownComplete() override { NOTREACHED(); }

  void OnSlaveDisconnect(embedder::SlaveInfo slave_info) override {
    CHECK(thread_checker_.IsCreationThreadCurrent());
    on_slave_disconnect_calls_++;
    last_slave_disconnect_name_ =
        static_cast<TestSlaveInfo*>(slave_info)->name();
    DVLOG(1) << "Disconnected from slave process "
             << last_slave_disconnect_name_;
    delete static_cast<TestSlaveInfo*>(slave_info);

    if (current_message_loop_)
      current_message_loop_->QuitNow();
  }

 private:
  ThreadChecker thread_checker_;
  MessageLoop* current_message_loop_;

  unsigned on_slave_disconnect_calls_;
  std::string last_slave_disconnect_name_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MockMasterProcessDelegate);
};

class MockSlaveProcessDelegate : public embedder::SlaveProcessDelegate {
 public:
  MockSlaveProcessDelegate()
      : current_message_loop_(), on_master_disconnect_calls_(0) {}
  ~MockSlaveProcessDelegate() override {}

  void RunUntilNotified(MessageLoop* message_loop) {
    CHECK(!current_message_loop_);
    current_message_loop_ = message_loop;
    message_loop->Run();
    current_message_loop_ = nullptr;
  }

  unsigned on_master_disconnect_calls() const {
    return on_master_disconnect_calls_;
  }

  // |embedder::SlaveProcessDelegate| implementation:
  void OnShutdownComplete() override { NOTREACHED(); }

  void OnMasterDisconnect() override {
    CHECK(thread_checker_.IsCreationThreadCurrent());
    on_master_disconnect_calls_++;
    DVLOG(1) << "Disconnected from master process";

    if (current_message_loop_)
      current_message_loop_->QuitNow();
  }

 private:
  ThreadChecker thread_checker_;
  MessageLoop* current_message_loop_;

  unsigned on_master_disconnect_calls_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MockSlaveProcessDelegate);
};

class ConnectionManagerTest : public testing::Test {
 protected:
  ConnectionManagerTest()
      : platform_support_(embedder::CreateSimplePlatformSupport()),
        message_loop_(CreateTestMessageLoop()) {}
  ~ConnectionManagerTest() override {}

  embedder::PlatformSupport* platform_support() {
    return platform_support_.get();
  }
  MessageLoop* message_loop() { return message_loop_.get(); }
  const RefPtr<TaskRunner>& task_runner() {
    return message_loop_->GetTaskRunner();
  }
  MockMasterProcessDelegate& master_process_delegate() {
    return master_process_delegate_;
  }

  // Connects the given |slave| (with the given |slave_process_delegate|) to the
  // given master, creating and using a |TestSlaveInfo| with the given
  // |slave_name|, and returns the process identifier for the slave.
  ProcessIdentifier ConnectSlave(
      MasterConnectionManager* master,
      embedder::SlaveProcessDelegate* slave_process_delegate,
      SlaveConnectionManager* slave,
      const std::string& slave_name) {
    PlatformPipe platform_pipe;
    ProcessIdentifier slave_process_identifier = master->AddSlave(
        new TestSlaveInfo(slave_name), platform_pipe.handle0.Pass());
    slave->Init(task_runner().Clone(), slave_process_delegate,
                platform_pipe.handle1.Pass());
    return slave_process_identifier;
  }

 private:
  std::unique_ptr<embedder::PlatformSupport> platform_support_;
  std::unique_ptr<MessageLoop> message_loop_;
  MockMasterProcessDelegate master_process_delegate_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ConnectionManagerTest);
};

TEST_F(ConnectionManagerTest, BasicConnectSlaves) {
  MasterConnectionManager master(platform_support());
  master.Init(task_runner().Clone(), &master_process_delegate());

  MockSlaveProcessDelegate slave1_process_delegate;
  SlaveConnectionManager slave1(platform_support());
  ProcessIdentifier slave1_id =
      ConnectSlave(&master, &slave1_process_delegate, &slave1, "slave1");
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave1_id));

  MockSlaveProcessDelegate slave2_process_delegate;
  SlaveConnectionManager slave2(platform_support());
  ProcessIdentifier slave2_id =
      ConnectSlave(&master, &slave2_process_delegate, &slave2, "slave2");
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave2_id));
  // TODO(vtl): If/when I add the ability to get one's own process identifier,
  // there'll be more we can check.
  EXPECT_NE(slave1_id, slave2_id);

  ConnectionIdentifier connection_id = master.GenerateConnectionIdentifier();
  EXPECT_TRUE(slave1.AllowConnect(connection_id));
  EXPECT_TRUE(slave2.AllowConnect(connection_id));

  ProcessIdentifier peer1 = kInvalidProcessIdentifier;
  bool is_first = false;
  ScopedPlatformHandle h1;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_NEW_CONNECTION,
            slave1.Connect(connection_id, &peer1, &is_first, &h1));
  EXPECT_EQ(slave2_id, peer1);
  EXPECT_TRUE(is_first);
  EXPECT_TRUE(h1.is_valid());
  ProcessIdentifier peer2 = kInvalidProcessIdentifier;
  ScopedPlatformHandle h2;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_NEW_CONNECTION,
            slave2.Connect(connection_id, &peer2, &is_first, &h2));
  EXPECT_EQ(slave1_id, peer2);
  EXPECT_FALSE(is_first);
  EXPECT_TRUE(h2.is_valid());

  EXPECT_TRUE(ArePlatformHandlesConnected(h1.get(), h2.get()));

  // The process manager shouldn't have gotten any notifications yet. (Spin the
  // message loop to make sure none were enqueued.)
  message_loop()->RunUntilIdle();
  EXPECT_EQ(0u, master_process_delegate().on_slave_disconnect_calls());

  slave1.Shutdown();

  // |OnSlaveDisconnect()| should be called once.
  master_process_delegate().RunUntilNotified(message_loop());
  EXPECT_EQ(1u, master_process_delegate().on_slave_disconnect_calls());
  EXPECT_EQ("slave1", master_process_delegate().last_slave_disconnect_name());

  slave2.Shutdown();

  // |OnSlaveDisconnect()| should be called again.
  master_process_delegate().RunUntilNotified(message_loop());
  EXPECT_EQ(2u, master_process_delegate().on_slave_disconnect_calls());
  EXPECT_EQ("slave2", master_process_delegate().last_slave_disconnect_name());

  master.Shutdown();

  // None of the above should result in |OnMasterDisconnect()| being called.
  message_loop()->RunUntilIdle();
  EXPECT_EQ(0u, slave1_process_delegate.on_master_disconnect_calls());
  EXPECT_EQ(0u, slave2_process_delegate.on_master_disconnect_calls());
}

TEST_F(ConnectionManagerTest, ShutdownMasterBeforeSlave) {
  MasterConnectionManager master(platform_support());
  master.Init(task_runner().Clone(), &master_process_delegate());

  MockSlaveProcessDelegate slave_process_delegate;
  SlaveConnectionManager slave(platform_support());
  ProcessIdentifier slave_id =
      ConnectSlave(&master, &slave_process_delegate, &slave, "slave");
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave_id));

  // The process manager shouldn't have gotten any notifications yet. (Spin the
  // message loop to make sure none were enqueued.)
  message_loop()->RunUntilIdle();
  EXPECT_EQ(0u, master_process_delegate().on_slave_disconnect_calls());

  master.Shutdown();

  // |OnSlaveDisconnect()| should be called.
  master_process_delegate().RunUntilNotified(message_loop());
  EXPECT_EQ(1u, master_process_delegate().on_slave_disconnect_calls());
  EXPECT_EQ("slave", master_process_delegate().last_slave_disconnect_name());

  // |OnMasterDisconnect()| should also be (or have been) called.
  slave_process_delegate.RunUntilNotified(message_loop());
  EXPECT_EQ(1u, slave_process_delegate.on_master_disconnect_calls());

  slave.Shutdown();
}

TEST_F(ConnectionManagerTest, SlaveCancelConnect) {
  MasterConnectionManager master(platform_support());
  master.Init(task_runner().Clone(), &master_process_delegate());

  MockSlaveProcessDelegate slave1_process_delegate;
  SlaveConnectionManager slave1(platform_support());
  ProcessIdentifier slave1_id =
      ConnectSlave(&master, &slave1_process_delegate, &slave1, "slave1");
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave1_id));

  MockSlaveProcessDelegate slave2_process_delegate;
  SlaveConnectionManager slave2(platform_support());
  ProcessIdentifier slave2_id =
      ConnectSlave(&master, &slave2_process_delegate, &slave2, "slave2");
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave2_id));
  EXPECT_NE(slave1_id, slave2_id);

  ConnectionIdentifier connection_id = master.GenerateConnectionIdentifier();
  EXPECT_TRUE(slave1.AllowConnect(connection_id));
  EXPECT_TRUE(slave2.AllowConnect(connection_id));

  EXPECT_TRUE(slave1.CancelConnect(connection_id));
  ProcessIdentifier peer2 = kInvalidProcessIdentifier;
  bool is_first = false;
  ScopedPlatformHandle h2;
  EXPECT_EQ(ConnectionManager::Result::FAILURE,
            slave2.Connect(connection_id, &peer2, &is_first, &h2));
  EXPECT_EQ(kInvalidProcessIdentifier, peer2);
  EXPECT_FALSE(is_first);
  EXPECT_FALSE(h2.is_valid());

  slave1.Shutdown();
  slave2.Shutdown();
  master.Shutdown();
}

// Tests that pending connections are removed on error.
TEST_F(ConnectionManagerTest, ErrorRemovePending) {
  MasterConnectionManager master(platform_support());
  master.Init(task_runner().Clone(), &master_process_delegate());

  MockSlaveProcessDelegate slave1_process_delegate;
  SlaveConnectionManager slave1(platform_support());
  ProcessIdentifier slave1_id =
      ConnectSlave(&master, &slave1_process_delegate, &slave1, "slave1");
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave1_id));

  MockSlaveProcessDelegate slave2_process_delegate;
  SlaveConnectionManager slave2(platform_support());
  ProcessIdentifier slave2_id =
      ConnectSlave(&master, &slave2_process_delegate, &slave2, "slave2");
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave2_id));
  EXPECT_NE(slave1_id, slave2_id);

  ConnectionIdentifier connection_id = master.GenerateConnectionIdentifier();
  EXPECT_TRUE(slave1.AllowConnect(connection_id));
  EXPECT_TRUE(slave2.AllowConnect(connection_id));

  slave1.Shutdown();

  // |OnSlaveDisconnect()| should be called. After it's called, this means that
  // the disconnect has been detected and handled, including the removal of the
  // pending connection.
  master_process_delegate().RunUntilNotified(message_loop());
  EXPECT_EQ(1u, master_process_delegate().on_slave_disconnect_calls());

  ProcessIdentifier peer2 = kInvalidProcessIdentifier;
  bool is_first = false;
  ScopedPlatformHandle h2;
  EXPECT_EQ(ConnectionManager::Result::FAILURE,
            slave2.Connect(connection_id, &peer2, &is_first, &h2));
  EXPECT_EQ(kInvalidProcessIdentifier, peer2);
  EXPECT_FALSE(is_first);
  EXPECT_FALSE(h2.is_valid());

  slave2.Shutdown();
  master.Shutdown();
}

TEST_F(ConnectionManagerTest, ConnectSlaveToSelf) {
  MasterConnectionManager master(platform_support());
  master.Init(task_runner().Clone(), &master_process_delegate());

  MockSlaveProcessDelegate slave_process_delegate;
  SlaveConnectionManager slave(platform_support());
  ProcessIdentifier slave_id =
      ConnectSlave(&master, &slave_process_delegate, &slave, "slave");
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave_id));

  ConnectionIdentifier connection_id = master.GenerateConnectionIdentifier();
  EXPECT_TRUE(slave.AllowConnect(connection_id));
  EXPECT_TRUE(slave.AllowConnect(connection_id));

  ProcessIdentifier peer1 = kInvalidProcessIdentifier;
  bool is_first = false;
  ScopedPlatformHandle h1;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_SAME_PROCESS,
            slave.Connect(connection_id, &peer1, &is_first, &h1));
  EXPECT_EQ(slave_id, peer1);
  EXPECT_TRUE(is_first);
  EXPECT_FALSE(h1.is_valid());
  ProcessIdentifier peer2 = kInvalidProcessIdentifier;
  ScopedPlatformHandle h2;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_SAME_PROCESS,
            slave.Connect(connection_id, &peer2, &is_first, &h2));
  EXPECT_EQ(slave_id, peer2);
  EXPECT_FALSE(is_first);
  EXPECT_FALSE(h2.is_valid());

  slave.Shutdown();
  master.Shutdown();
}

TEST_F(ConnectionManagerTest, ConnectSlavesTwice) {
  MasterConnectionManager master(platform_support());
  master.Init(task_runner().Clone(), &master_process_delegate());

  MockSlaveProcessDelegate slave1_process_delegate;
  SlaveConnectionManager slave1(platform_support());
  ProcessIdentifier slave1_id =
      ConnectSlave(&master, &slave1_process_delegate, &slave1, "slave1");
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave1_id));

  MockSlaveProcessDelegate slave2_process_delegate;
  SlaveConnectionManager slave2(platform_support());
  ProcessIdentifier slave2_id =
      ConnectSlave(&master, &slave2_process_delegate, &slave2, "slave2");
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave2_id));
  EXPECT_NE(slave1_id, slave2_id);

  ConnectionIdentifier connection_id = master.GenerateConnectionIdentifier();
  EXPECT_TRUE(slave1.AllowConnect(connection_id));
  EXPECT_TRUE(slave2.AllowConnect(connection_id));

  ProcessIdentifier peer1 = kInvalidProcessIdentifier;
  bool is_first = false;
  ScopedPlatformHandle h1;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_NEW_CONNECTION,
            slave1.Connect(connection_id, &peer1, &is_first, &h1));
  EXPECT_EQ(slave2_id, peer1);
  EXPECT_TRUE(is_first);
  ProcessIdentifier peer2 = kInvalidProcessIdentifier;
  ScopedPlatformHandle h2;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_NEW_CONNECTION,
            slave2.Connect(connection_id, &peer2, &is_first, &h2));
  EXPECT_EQ(slave1_id, peer2);
  EXPECT_FALSE(is_first);

  EXPECT_TRUE(ArePlatformHandlesConnected(h1.get(), h2.get()));

  // TODO(vtl): Currently, the master doesn't detect the case of connecting a
  // pair of slaves that are already connected. (Doing so would require more
  // careful tracking and is prone to races -- especially if we want slaves to
  // be able to tear down no-longer-needed connections.) But the slaves should
  // be able to do the tracking themselves (using the peer process identifiers).
  connection_id = master.GenerateConnectionIdentifier();
  EXPECT_TRUE(slave1.AllowConnect(connection_id));
  EXPECT_TRUE(slave2.AllowConnect(connection_id));

  h1.reset();
  h2.reset();
  ProcessIdentifier second_peer2 = kInvalidProcessIdentifier;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_REUSE_CONNECTION,
            slave2.Connect(connection_id, &second_peer2, &is_first, &h2));
  EXPECT_EQ(peer2, second_peer2);
  EXPECT_TRUE(is_first);
  EXPECT_FALSE(h2.is_valid());
  ProcessIdentifier second_peer1 = kInvalidProcessIdentifier;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_REUSE_CONNECTION,
            slave1.Connect(connection_id, &second_peer1, &is_first, &h1));
  EXPECT_EQ(peer1, second_peer1);
  EXPECT_FALSE(is_first);
  EXPECT_FALSE(h1.is_valid());

  slave2.Shutdown();
  slave1.Shutdown();
  master.Shutdown();
}

TEST_F(ConnectionManagerTest, OverlappingSlaveConnects) {
  MasterConnectionManager master(platform_support());
  master.Init(task_runner().Clone(), &master_process_delegate());

  MockSlaveProcessDelegate slave1_process_delegate;
  SlaveConnectionManager slave1(platform_support());
  ProcessIdentifier slave1_id =
      ConnectSlave(&master, &slave1_process_delegate, &slave1, "slave1");
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave1_id));

  MockSlaveProcessDelegate slave2_process_delegate;
  SlaveConnectionManager slave2(platform_support());
  ProcessIdentifier slave2_id =
      ConnectSlave(&master, &slave2_process_delegate, &slave2, "slave2");
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave2_id));
  EXPECT_NE(slave1_id, slave2_id);

  ConnectionIdentifier connection_id1 = master.GenerateConnectionIdentifier();
  EXPECT_TRUE(slave1.AllowConnect(connection_id1));
  EXPECT_TRUE(slave2.AllowConnect(connection_id1));

  ConnectionIdentifier connection_id2 = master.GenerateConnectionIdentifier();
  EXPECT_TRUE(slave1.AllowConnect(connection_id2));
  EXPECT_TRUE(slave2.AllowConnect(connection_id2));

  ProcessIdentifier peer1 = kInvalidProcessIdentifier;
  bool is_first = false;
  ScopedPlatformHandle h1;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_NEW_CONNECTION,
            slave1.Connect(connection_id1, &peer1, &is_first, &h1));
  EXPECT_EQ(slave2_id, peer1);
  EXPECT_TRUE(is_first);
  ProcessIdentifier peer2 = kInvalidProcessIdentifier;
  ScopedPlatformHandle h2;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_NEW_CONNECTION,
            slave2.Connect(connection_id2, &peer2, &is_first, &h2));
  EXPECT_EQ(slave1_id, peer2);
  EXPECT_TRUE(is_first);

  EXPECT_TRUE(ArePlatformHandlesConnected(h1.get(), h2.get()));

  h1.reset();
  h2.reset();
  ProcessIdentifier second_peer1 = kInvalidProcessIdentifier;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_REUSE_CONNECTION,
            slave1.Connect(connection_id2, &second_peer1, &is_first, &h1));
  EXPECT_EQ(peer1, second_peer1);
  EXPECT_FALSE(is_first);
  EXPECT_FALSE(h1.is_valid());
  ProcessIdentifier second_peer2 = kInvalidProcessIdentifier;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_REUSE_CONNECTION,
            slave2.Connect(connection_id1, &second_peer2, &is_first, &h2));
  EXPECT_EQ(peer2, second_peer2);
  EXPECT_FALSE(is_first);
  EXPECT_FALSE(h2.is_valid());

  slave2.Shutdown();
  slave1.Shutdown();
  master.Shutdown();
}

TEST_F(ConnectionManagerTest, ConnectMasterToSlave) {
  MasterConnectionManager master(platform_support());
  master.Init(task_runner().Clone(), &master_process_delegate());

  MockSlaveProcessDelegate slave_process_delegate;
  SlaveConnectionManager slave(platform_support());
  ProcessIdentifier slave_id =
      ConnectSlave(&master, &slave_process_delegate, &slave, "slave");
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave_id));

  ConnectionIdentifier connection_id = master.GenerateConnectionIdentifier();
  EXPECT_TRUE(master.AllowConnect(connection_id));
  EXPECT_TRUE(slave.AllowConnect(connection_id));

  ProcessIdentifier master_peer = kInvalidProcessIdentifier;
  bool is_first = false;
  ScopedPlatformHandle master_h;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_NEW_CONNECTION,
            master.Connect(connection_id, &master_peer, &is_first, &master_h));
  EXPECT_EQ(slave_id, master_peer);
  EXPECT_TRUE(is_first);
  EXPECT_TRUE(master_h.is_valid());
  ProcessIdentifier slave_peer = kInvalidProcessIdentifier;
  ScopedPlatformHandle slave_h;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_NEW_CONNECTION,
            slave.Connect(connection_id, &slave_peer, &is_first, &slave_h));
  EXPECT_EQ(kMasterProcessIdentifier, slave_peer);
  EXPECT_FALSE(is_first);
  EXPECT_TRUE(slave_h.is_valid());

  EXPECT_TRUE(ArePlatformHandlesConnected(master_h.get(), slave_h.get()));

  slave.Shutdown();
  master.Shutdown();
}

TEST_F(ConnectionManagerTest, ConnectMasterToSelf) {
  MasterConnectionManager master(platform_support());
  master.Init(task_runner().Clone(), &master_process_delegate());

  ConnectionIdentifier connection_id = master.GenerateConnectionIdentifier();
  EXPECT_TRUE(master.AllowConnect(connection_id));
  EXPECT_TRUE(master.AllowConnect(connection_id));

  ProcessIdentifier peer1 = kInvalidProcessIdentifier;
  bool is_first = false;
  ScopedPlatformHandle h1;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_SAME_PROCESS,
            master.Connect(connection_id, &peer1, &is_first, &h1));
  EXPECT_EQ(kMasterProcessIdentifier, peer1);
  EXPECT_TRUE(is_first);
  EXPECT_FALSE(h1.is_valid());
  ProcessIdentifier peer2 = kInvalidProcessIdentifier;
  ScopedPlatformHandle h2;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_SAME_PROCESS,
            master.Connect(connection_id, &peer2, &is_first, &h2));
  EXPECT_EQ(kMasterProcessIdentifier, peer2);
  EXPECT_FALSE(is_first);
  EXPECT_FALSE(h2.is_valid());

  EXPECT_EQ(peer1, peer2);

  master.Shutdown();
}

TEST_F(ConnectionManagerTest, MasterCancelConnect) {
  MasterConnectionManager master(platform_support());
  master.Init(task_runner().Clone(), &master_process_delegate());

  MockSlaveProcessDelegate slave_process_delegate;
  SlaveConnectionManager slave(platform_support());
  ProcessIdentifier slave_id =
      ConnectSlave(&master, &slave_process_delegate, &slave, "slave");
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave_id));

  ConnectionIdentifier connection_id = master.GenerateConnectionIdentifier();
  EXPECT_TRUE(master.AllowConnect(connection_id));
  EXPECT_TRUE(slave.AllowConnect(connection_id));

  EXPECT_TRUE(master.CancelConnect(connection_id));
  ProcessIdentifier peer = kInvalidProcessIdentifier;
  bool is_first = false;
  ScopedPlatformHandle h;
  EXPECT_EQ(ConnectionManager::Result::FAILURE,
            slave.Connect(connection_id, &peer, &is_first, &h));
  EXPECT_EQ(kInvalidProcessIdentifier, peer);
  EXPECT_FALSE(is_first);
  EXPECT_FALSE(h.is_valid());

  slave.Shutdown();
  master.Shutdown();
}

TEST_F(ConnectionManagerTest, AddSlaveThenImmediateShutdown) {
  MasterConnectionManager master(platform_support());
  master.Init(task_runner().Clone(), &master_process_delegate());

  MockSlaveProcessDelegate slave_process_delegate;
  SlaveConnectionManager slave(platform_support());
  PlatformPipe platform_pipe;
  ProcessIdentifier slave_id =
      master.AddSlave(new TestSlaveInfo("slave"), platform_pipe.handle0.Pass());
  master.Shutdown();
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave_id));
  // Since we never initialized |slave|, we don't have to shut it down.
}

TEST_F(ConnectionManagerTest, AddSlaveAndBootstrap) {
  MasterConnectionManager master(platform_support());
  master.Init(task_runner().Clone(), &master_process_delegate());

  PlatformPipe platform_pipe;
  ConnectionIdentifier connection_id = master.GenerateConnectionIdentifier();
  ProcessIdentifier slave_id = master.AddSlaveAndBootstrap(
      new TestSlaveInfo("slave"), platform_pipe.handle0.Pass(), connection_id);
  EXPECT_TRUE(IsValidSlaveProcessIdentifier(slave_id));

  ScopedPlatformHandle h1;
  ProcessIdentifier master_peer = kInvalidProcessIdentifier;
  bool is_first = false;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_NEW_CONNECTION,
            master.Connect(connection_id, &master_peer, &is_first, &h1));
  EXPECT_EQ(slave_id, master_peer);
  EXPECT_TRUE(is_first);
  EXPECT_TRUE(h1.is_valid());

  // We can delay creating/initializing |slave| for quite a while.
  MockSlaveProcessDelegate slave_process_delegate;
  SlaveConnectionManager slave(platform_support());
  slave.Init(task_runner().Clone(), &slave_process_delegate,
             platform_pipe.handle1.Pass());

  ProcessIdentifier slave_peer = kInvalidProcessIdentifier;
  ScopedPlatformHandle h2;
  EXPECT_EQ(ConnectionManager::Result::SUCCESS_CONNECT_NEW_CONNECTION,
            slave.Connect(connection_id, &slave_peer, &is_first, &h2));
  EXPECT_EQ(kMasterProcessIdentifier, slave_peer);
  EXPECT_FALSE(is_first);

  EXPECT_TRUE(ArePlatformHandlesConnected(h1.get(), h2.get()));

  slave.Shutdown();
  master.Shutdown();
}

// TODO(vtl): More shutdown cases for |AddSlaveAndBootstrap()|?

}  // namespace
}  // namespace system
}  // namespace mojo
