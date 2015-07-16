// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "base/sync_socket.h"
#include "base/threading/simple_thread.h"
#include "base/time/time.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

const int kReceiveTimeoutInMilliseconds = 750;

class HangingReceiveThread : public base::DelegateSimpleThread::Delegate {
 public:
  explicit HangingReceiveThread(base::SyncSocket* socket)
      : socket_(socket),
        thread_(this, "HangingReceiveThread") {
    thread_.Start();
  }

  ~HangingReceiveThread() override {}

  void Run() override {
    int data = 0;
    ASSERT_EQ(socket_->Peek(), 0u);

    // Use receive with timeout so we don't hang the test harness indefinitely.
    ASSERT_EQ(0u, socket_->ReceiveWithTimeout(
        &data, sizeof(data), base::TimeDelta::FromMilliseconds(
            kReceiveTimeoutInMilliseconds)));
  }

  void Stop() {
    thread_.Join();
  }

 private:
  base::SyncSocket* socket_;
  base::DelegateSimpleThread thread_;

  DISALLOW_COPY_AND_ASSIGN(HangingReceiveThread);
};

// Tests sending data between two SyncSockets.  Uses ASSERT() and thus will exit
// early upon failure.  Callers should use ASSERT_NO_FATAL_FAILURE() if testing
// continues after return.
void SendReceivePeek(base::SyncSocket* socket_a, base::SyncSocket* socket_b) {
  int received = 0;
  const int kSending = 123;
  COMPILE_ASSERT(sizeof(kSending) == sizeof(received), Invalid_Data_Size);

  ASSERT_EQ(0u, socket_a->Peek());
  ASSERT_EQ(0u, socket_b->Peek());

  // Verify |socket_a| can send to |socket_a| and |socket_a| can Receive from
  // |socket_a|.
  ASSERT_EQ(sizeof(kSending), socket_a->Send(&kSending, sizeof(kSending)));
  ASSERT_EQ(sizeof(kSending), socket_b->Peek());
  ASSERT_EQ(sizeof(kSending), socket_b->Receive(&received, sizeof(kSending)));
  ASSERT_EQ(kSending, received);

  ASSERT_EQ(0u, socket_a->Peek());
  ASSERT_EQ(0u, socket_b->Peek());

  // Now verify the reverse.
  received = 0;
  ASSERT_EQ(sizeof(kSending), socket_b->Send(&kSending, sizeof(kSending)));
  ASSERT_EQ(sizeof(kSending), socket_a->Peek());
  ASSERT_EQ(sizeof(kSending), socket_a->Receive(&received, sizeof(kSending)));
  ASSERT_EQ(kSending, received);

  ASSERT_EQ(0u, socket_a->Peek());
  ASSERT_EQ(0u, socket_b->Peek());

  ASSERT_TRUE(socket_a->Close());
  ASSERT_TRUE(socket_b->Close());
}

template <class SocketType>
void NormalSendReceivePeek() {
  SocketType socket_a, socket_b;
  ASSERT_TRUE(SocketType::CreatePair(&socket_a, &socket_b));
  SendReceivePeek(&socket_a, &socket_b);
}

template <class SocketType>
void ClonedSendReceivePeek() {
  SocketType socket_a, socket_b;
  ASSERT_TRUE(SocketType::CreatePair(&socket_a, &socket_b));

  // Create new SyncSockets from the paired handles.
  SocketType socket_c(socket_a.handle()), socket_d(socket_b.handle());
  SendReceivePeek(&socket_c, &socket_d);
}

}  // namespace

TEST(SyncSocket, NormalSendReceivePeek) {
  NormalSendReceivePeek<base::SyncSocket>();
}

TEST(SyncSocket, ClonedSendReceivePeek) {
  ClonedSendReceivePeek<base::SyncSocket>();
}

TEST(CancelableSyncSocket, NormalSendReceivePeek) {
  NormalSendReceivePeek<base::CancelableSyncSocket>();
}

TEST(CancelableSyncSocket, ClonedSendReceivePeek) {
  ClonedSendReceivePeek<base::CancelableSyncSocket>();
}

TEST(CancelableSyncSocket, CancelReceiveShutdown) {
  base::CancelableSyncSocket socket_a, socket_b;
  ASSERT_TRUE(base::CancelableSyncSocket::CreatePair(&socket_a, &socket_b));

  base::TimeTicks start = base::TimeTicks::Now();
  HangingReceiveThread thread(&socket_b);
  ASSERT_TRUE(socket_b.Shutdown());
  thread.Stop();

  // Ensure the receive didn't just timeout.
  ASSERT_LT((base::TimeTicks::Now() - start).InMilliseconds(),
            kReceiveTimeoutInMilliseconds);

  ASSERT_TRUE(socket_a.Close());
  ASSERT_TRUE(socket_b.Close());
}
