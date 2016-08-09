// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/cpp/output_stream_file.h"

#include <string.h>

#include <memory>
#include <string>

#include "files/interfaces/files.mojom.h"
#include "files/interfaces/types.mojom.h"
#include "mojo/public/cpp/application/application_test_base.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/cpp/utility/run_loop.h"

namespace files_impl {
namespace {

using OutputStreamFileTest = mojo::test::ApplicationTestBase;

void QuitMessageLoop() {
  mojo::RunLoop::current()->Quit();
}

void RunMessageLoop() {
  mojo::RunLoop::current()->Run();
}

void RunMessageLoopUntilIdle() {
  mojo::RunLoop::current()->RunUntilIdle();
}

// Converts a string to a |mojo::Array<uint8_t>|.
mojo::Array<uint8_t> StringToArray(const std::string& s) {
  auto rv = mojo::Array<uint8_t>::New(s.size());
  if (s.size())
    memcpy(&rv[0], &s[0], s.size());
  return rv;
}

class TestClient : public OutputStreamFile::Client {
 public:
  TestClient() { Reset(); }
  ~TestClient() override {}

  void Reset() {
    got_on_data_received_ = false;
    data_ = std::string();
    got_on_closed_ = false;
  }

  bool got_on_data_received() const { return got_on_data_received_; }
  const std::string& data() const { return data_; }
  bool got_on_closed() const { return got_on_closed_; }

 private:
  // |OutputStreamFile::Client|:
  void OnDataReceived(const void* bytes, size_t num_bytes) override {
    got_on_data_received_ = true;
    data_ = std::string(static_cast<const char*>(bytes), num_bytes);
    QuitMessageLoop();
  }
  void OnClosed() override {
    got_on_closed_ = true;
    QuitMessageLoop();
  }

  bool got_on_data_received_;
  std::string data_;
  bool got_on_closed_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestClient);
};

void TestWrite(mojo::files::File* file,
               TestClient* client,
               const std::string& s) {
  bool write_cb_called = false;
  mojo::files::Error error = mojo::files::Error::INTERNAL;
  uint32_t num_bytes_written = 0;
  file->Write(StringToArray(s), 0, mojo::files::Whence::FROM_CURRENT,
              [&write_cb_called, &error, &num_bytes_written](
                  mojo::files::Error e, uint32_t n) {
                write_cb_called = true;
                error = e;
                num_bytes_written = n;
                QuitMessageLoop();
              });
  if (client) {
    // If there's a client, since we're running everything on one thread, the
    // impl (which will call the client, which will quit the message loop) will
    // get called before the callback.
    client->Reset();
    RunMessageLoop();
    EXPECT_TRUE(client->got_on_data_received());
    EXPECT_EQ(s, client->data());
    EXPECT_FALSE(client->got_on_closed());
    EXPECT_FALSE(write_cb_called);
    // Spin the message loop again to get the callback.
    client->Reset();
    RunMessageLoop();
    EXPECT_FALSE(client->got_on_data_received());
    EXPECT_FALSE(client->got_on_closed());
  } else {
    // Otherwise, only the write callback will be called and quit the message
    // loop.
    RunMessageLoop();
  }
  EXPECT_TRUE(write_cb_called);
  EXPECT_EQ(mojo::files::Error::OK, error);
  EXPECT_EQ(s.size(), num_bytes_written);
}

void TestClose(mojo::files::File* file, TestClient* client) {
  bool close_cb_called = false;
  mojo::files::Error error = mojo::files::Error::INTERNAL;
  file->Close([&close_cb_called, &error](mojo::files::Error e) {
    close_cb_called = true;
    error = e;
    QuitMessageLoop();
  });
  // (This is analogous to |TestWrite()|.)
  if (client) {
    client->Reset();
    RunMessageLoop();
    EXPECT_FALSE(client->got_on_data_received());
    EXPECT_TRUE(client->got_on_closed());
    EXPECT_FALSE(close_cb_called);
    client->Reset();
    RunMessageLoop();
    EXPECT_FALSE(client->got_on_data_received());
    EXPECT_FALSE(client->got_on_closed());
  } else {
    RunMessageLoop();
  }
  EXPECT_TRUE(close_cb_called);
  EXPECT_EQ(mojo::files::Error::OK, error);
}

TEST_F(OutputStreamFileTest, Basic) {
  mojo::files::FilePtr file;
  TestClient client;
  std::unique_ptr<OutputStreamFile> file_impl =
      OutputStreamFile::Create(&client, GetProxy(&file));

  TestWrite(file.get(), &client, "hello");
  TestWrite(file.get(), &client, "world");
  TestClose(file.get(), &client);
}

TEST_F(OutputStreamFileTest, SetClient) {
  mojo::files::FilePtr file;
  TestClient client1;
  std::unique_ptr<OutputStreamFile> file_impl =
      OutputStreamFile::Create(&client1, GetProxy(&file));

  TestWrite(file.get(), &client1, "hello");

  TestClient client2;
  file_impl->set_client(&client2);
  TestWrite(file.get(), &client2, "world");

  file_impl->set_client(&client1);
  TestWrite(file.get(), &client1, "!");
  TestClose(file.get(), &client1);
}

TEST_F(OutputStreamFileTest, NullClient) {
  mojo::files::FilePtr file;
  std::unique_ptr<OutputStreamFile> file_impl =
      OutputStreamFile::Create(nullptr, GetProxy(&file));

  TestWrite(file.get(), nullptr, "hello");

  TestClient client;
  file_impl->set_client(&client);
  TestWrite(file.get(), &client, "world");

  file_impl->set_client(nullptr);
  client.Reset();
  TestWrite(file.get(), nullptr, "!");
  TestClose(file.get(), nullptr);
  EXPECT_FALSE(client.got_on_data_received());
  EXPECT_FALSE(client.got_on_closed());
}

TEST_F(OutputStreamFileTest, ImplOnlyClosesMessagePipeOnDestruction) {
  mojo::files::FilePtr file;
  std::unique_ptr<OutputStreamFile> file_impl =
      OutputStreamFile::Create(nullptr, GetProxy(&file));
  bool got_connection_error = false;
  file.set_connection_error_handler([&got_connection_error]() {
    got_connection_error = true;
    QuitMessageLoop();
  });

  TestClose(file.get(), nullptr);
  // The impl should only close its end when it's destroyed (even if |Close()|
  // has been called).
  RunMessageLoopUntilIdle();
  EXPECT_FALSE(got_connection_error);
  file_impl.reset();
  RunMessageLoop();
  EXPECT_TRUE(got_connection_error);
}

TEST_F(OutputStreamFileTest, ClosingMessagePipeCausesOnClosed) {
  mojo::files::FilePtr file;
  TestClient client;
  std::unique_ptr<OutputStreamFile> file_impl =
      OutputStreamFile::Create(&client, GetProxy(&file));

  file.reset();
  RunMessageLoop();
  EXPECT_FALSE(client.got_on_data_received());
  EXPECT_TRUE(client.got_on_closed());
}

// Clients may own the impl (and this is a typical pattern). This client will
// own/destroy its impl on any |Client| call (and we'll test that this doesn't
// result in any additional calls to the client).
class TestClientDestroysImplClient : public OutputStreamFile::Client {
 public:
  explicit TestClientDestroysImplClient(
      mojo::InterfaceRequest<mojo::files::File> request)
      : file_impl_(OutputStreamFile::Create(this, request.Pass())) {}
  ~TestClientDestroysImplClient() override {}

 private:
  // OutputStreamFile::Client|:
  void OnDataReceived(const void* /*bytes*/, size_t /*num_bytes*/) override {
    // We reset the impl on any call, and afterwards it shouldn't call us.
    EXPECT_TRUE(file_impl_);
    file_impl_.reset();
  }
  void OnClosed() override {
    // We reset the impl on any call, and afterwards it shouldn't call us.
    EXPECT_TRUE(file_impl_);
    file_impl_.reset();
  }

  std::unique_ptr<OutputStreamFile> file_impl_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestClientDestroysImplClient);
};

TEST_F(OutputStreamFileTest, ClientDestroysImpl) {
  // Test destruction due to writing.
  {
    mojo::files::FilePtr file;
    TestClientDestroysImplClient client(GetProxy(&file));
    bool got_connection_error = false;
    file.set_connection_error_handler([&got_connection_error]() {
      got_connection_error = true;
      QuitMessageLoop();
    });
    // |TestClientDestroysImplClient| doesn't quit the message loop, so it
    // behaves like a null client.
    TestWrite(file.get(), nullptr, "hello");
    // The connection error may be called immediately after the write callback,
    // in which case we have to spin the message loop again.
    if (!got_connection_error)
      RunMessageLoop();
    EXPECT_TRUE(got_connection_error);
  }

  // Test destruction due to closing.
  {
    mojo::files::FilePtr file;
    TestClientDestroysImplClient client(GetProxy(&file));
    bool got_connection_error = false;
    file.set_connection_error_handler([&got_connection_error]() {
      got_connection_error = true;
      QuitMessageLoop();
    });
    TestClose(file.get(), nullptr);
    if (!got_connection_error)
      RunMessageLoop();
    EXPECT_TRUE(got_connection_error);
  }
}

}  // namespace
}  // namespace files_impl
