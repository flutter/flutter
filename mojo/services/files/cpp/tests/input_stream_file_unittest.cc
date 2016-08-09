// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/cpp/input_stream_file.h"

#include <string.h>

#include <string>
#include <utility>

#include "files/interfaces/files.mojom.h"
#include "files/interfaces/types.mojom.h"
#include "mojo/public/cpp/application/application_test_base.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/environment/logging.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/cpp/utility/run_loop.h"

namespace files_impl {
namespace {

using InputStreamFileTest = mojo::test::ApplicationTestBase;

void QuitMessageLoop() {
  mojo::RunLoop::current()->Quit();
}

void RunMessageLoop() {
  mojo::RunLoop::current()->Run();
}

void RunMessageLoopUntilIdle() {
  mojo::RunLoop::current()->RunUntilIdle();
}

void PostTaskToMessageLoop(const mojo::Closure& task) {
  mojo::RunLoop::current()->PostDelayedTask(task, 0);
}

// Converts a string to a |mojo::Array<uint8_t>|.
mojo::Array<uint8_t> StringToArray(const std::string& s) {
  auto rv = mojo::Array<uint8_t>::New(s.size());
  if (s.size())
    memcpy(&rv[0], &s[0], s.size());
  return rv;
}

// Converts a |mojo::Array<uint8_t>| to a string. If the array is null, returns
// the string "ARRAY_IS_NULL".
std::string ArrayToString(const mojo::Array<uint8_t>& a) {
  if (a.is_null())
    return std::string("ARRAY_IS_NULL");
  return a.size() ? std::string(reinterpret_cast<const char*>(&a[0]), a.size())
                  : std::string();
}

class TestClient : public InputStreamFile::Client {
 public:
  TestClient() { Reset(); }
  ~TestClient() override {}

  // Note: This doesn't reset |callback_|.
  void Reset() {
    data_ = StringToArray("OOPS");
    complete_synchronously_ = true;
    got_request_data_ = false;
    got_on_closed_ = false;
  }

  // Completes a pending callback. Note: |RequestData()| may be called again
  // "inside" this (i.e., "inside" the callback).
  void RunRequestDataCallback(mojo::Array<uint8_t> data) {
    MOJO_CHECK(!callback_.is_null());
    RequestDataCallback callback;
    std::swap(callback, callback_);
    callback.Run(mojo::files::Error::OK, data.Pass());
  }

  void set_data(mojo::Array<uint8_t> data) {
    MOJO_CHECK(!data.is_null());
    data_ = data.Pass();
  }
  void set_complete_synchronously(bool complete_synchronously) {
    complete_synchronously_ = complete_synchronously;
  }

  bool got_request_data() const { return got_request_data_; }
  bool got_on_closed() const { return got_on_closed_; }

 private:
  // |InputStreamFile::Client|:
  bool RequestData(size_t max_num_bytes,
                   mojo::files::Error* error,
                   mojo::Array<uint8_t>* data,
                   const RequestDataCallback& callback) override {
    MOJO_CHECK(max_num_bytes);
    MOJO_CHECK(error);
    MOJO_CHECK(data);
    MOJO_CHECK(!callback.is_null());

    // This shouldn't be called while a callback is pending.
    MOJO_CHECK(callback_.is_null());

    got_request_data_ = true;
    QuitMessageLoop();

    if (!complete_synchronously_) {
      callback_ = callback;
      return false;
    }

    *error = mojo::files::Error::OK;
    *data = data_.Clone();
    return true;
  }
  void OnClosed() override {
    got_on_closed_ = true;
    QuitMessageLoop();
  }

  mojo::Array<uint8_t> data_;
  bool complete_synchronously_;

  bool got_request_data_;
  bool got_on_closed_;

  RequestDataCallback callback_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestClient);
};

void TestReadSync(mojo::files::File* file,
                  TestClient* client,
                  const std::string& s) {
  bool read_cb_called = false;
  mojo::files::Error error = mojo::files::Error::INTERNAL;
  mojo::Array<uint8_t> data;
  file->Read(100u, 0, mojo::files::Whence::FROM_CURRENT,
             [&read_cb_called, &error, &data](mojo::files::Error e,
                                              mojo::Array<uint8_t> d) {
               read_cb_called = true;
               error = e;
               data = d.Pass();
               QuitMessageLoop();
             });
  if (client) {
    // If there's a client, since we're running everything on one thread, the
    // impl (which will call the client, which will quit the message loop) will
    // get called before the callback.
    client->Reset();
    client->set_data(StringToArray(s));
    RunMessageLoop();
    EXPECT_TRUE(client->got_request_data());
    EXPECT_FALSE(client->got_on_closed());
    EXPECT_FALSE(read_cb_called);
    // Spin the message loop again to get the callback.
    client->Reset();
    RunMessageLoop();
    EXPECT_FALSE(client->got_request_data());
    EXPECT_FALSE(client->got_on_closed());
    EXPECT_TRUE(read_cb_called);
    EXPECT_EQ(mojo::files::Error::OK, error);
    EXPECT_EQ(s, ArrayToString(data));
  } else {
    // Otherwise, only the read callback will be called and quit the message
    // loop.
    RunMessageLoop();
    EXPECT_TRUE(read_cb_called);
    EXPECT_EQ(mojo::files::Error::UNAVAILABLE, error);
    EXPECT_TRUE(data.is_null());
  }
}

void TestReadAsync(mojo::files::File* file,
                   TestClient* client,
                   const std::string& s) {
  MOJO_CHECK(client);

  bool read_cb_called = false;
  mojo::files::Error error = mojo::files::Error::INTERNAL;
  mojo::Array<uint8_t> data;
  file->Read(100u, 0, mojo::files::Whence::FROM_CURRENT,
             [&read_cb_called, &error, &data](mojo::files::Error e,
                                              mojo::Array<uint8_t> d) {
               read_cb_called = true;
               error = e;
               data = d.Pass();
               QuitMessageLoop();
             });
  client->Reset();
  client->set_complete_synchronously(false);
  RunMessageLoop();
  EXPECT_TRUE(client->got_request_data());
  EXPECT_FALSE(client->got_on_closed());
  EXPECT_FALSE(read_cb_called);
  // The read callback won't get called until we tell the client to run its
  // callback.
  client->Reset();
  client->RunRequestDataCallback(StringToArray(s));
  EXPECT_FALSE(client->got_request_data());
  EXPECT_FALSE(client->got_on_closed());
  EXPECT_FALSE(read_cb_called);
  // Spin the message loop again to get the read callback.
  client->Reset();
  RunMessageLoop();
  EXPECT_FALSE(client->got_request_data());
  EXPECT_FALSE(client->got_on_closed());
  EXPECT_TRUE(read_cb_called);
  EXPECT_EQ(mojo::files::Error::OK, error);
  EXPECT_EQ(s, ArrayToString(data));
}

void TestClose(mojo::files::File* file, TestClient* client) {
  bool close_cb_called = false;
  mojo::files::Error error = mojo::files::Error::INTERNAL;
  file->Close([&close_cb_called, &error](mojo::files::Error e) {
    close_cb_called = true;
    error = e;
    QuitMessageLoop();
  });
  if (client) {
    // (This is analogous to |TestReadSync()|.)
    client->Reset();
    RunMessageLoop();
    EXPECT_FALSE(client->got_request_data());
    EXPECT_TRUE(client->got_on_closed());
    EXPECT_FALSE(close_cb_called);
    client->Reset();
    RunMessageLoop();
    EXPECT_FALSE(client->got_request_data());
    EXPECT_FALSE(client->got_on_closed());
  } else {
    RunMessageLoop();
  }
  EXPECT_TRUE(close_cb_called);
  EXPECT_EQ(mojo::files::Error::OK, error);
}

TEST_F(InputStreamFileTest, BasicSync) {
  mojo::files::FilePtr file;
  TestClient client;
  std::unique_ptr<InputStreamFile> file_impl =
      InputStreamFile::Create(&client, GetProxy(&file));

  TestReadSync(file.get(), &client, "hello");
  TestReadSync(file.get(), &client, "world");
  TestClose(file.get(), &client);
}

TEST_F(InputStreamFileTest, BasicAsync) {
  mojo::files::FilePtr file;
  TestClient client;
  std::unique_ptr<InputStreamFile> file_impl =
      InputStreamFile::Create(&client, GetProxy(&file));

  TestReadAsync(file.get(), &client, "hello");
  TestReadAsync(file.get(), &client, "world");
  TestClose(file.get(), &client);
}

TEST_F(InputStreamFileTest, SetClient) {
  mojo::files::FilePtr file;
  TestClient client1;
  std::unique_ptr<InputStreamFile> file_impl =
      InputStreamFile::Create(&client1, GetProxy(&file));

  TestReadSync(file.get(), &client1, "hello");

  TestClient client2;
  file_impl->set_client(&client2);
  TestReadSync(file.get(), &client2, "world");

  file_impl->set_client(&client1);
  TestReadAsync(file.get(), &client1, "!");
  TestClose(file.get(), &client1);
}

TEST_F(InputStreamFileTest, NullClient) {
  mojo::files::FilePtr file;
  std::unique_ptr<InputStreamFile> file_impl =
      InputStreamFile::Create(nullptr, GetProxy(&file));

  TestReadSync(file.get(), nullptr, "hello");
  TestClose(file.get(), nullptr);
}

TEST_F(InputStreamFileTest, SetNullClient) {
  mojo::files::FilePtr file;
  TestClient client;
  std::unique_ptr<InputStreamFile> file_impl =
      InputStreamFile::Create(&client, GetProxy(&file));

  TestReadSync(file.get(), &client, "hello");

  file_impl->set_client(nullptr);
  client.Reset();
  TestReadSync(file.get(), nullptr, "hello");
  TestClose(file.get(), nullptr);
  EXPECT_FALSE(client.got_request_data());
  EXPECT_FALSE(client.got_on_closed());
}

TEST_F(InputStreamFileTest, ImplOnlyClosesMessagePipeOnDestruction) {
  mojo::files::FilePtr file;
  std::unique_ptr<InputStreamFile> file_impl =
      InputStreamFile::Create(nullptr, GetProxy(&file));
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

TEST_F(InputStreamFileTest, ClosingMessagePipeCausesOnClosed) {
  mojo::files::FilePtr file;
  TestClient client;
  std::unique_ptr<InputStreamFile> file_impl =
      InputStreamFile::Create(&client, GetProxy(&file));

  file.reset();
  RunMessageLoop();
  EXPECT_FALSE(client.got_request_data());
  EXPECT_TRUE(client.got_on_closed());
}

// Clients may own the impl (and this is a typical pattern). This client will
// own/destroy its impl on any |Client| call (and we'll test that this doesn't
// result in any additional calls to the client).
class TestClientDestroysImplClient : public InputStreamFile::Client {
 public:
  explicit TestClientDestroysImplClient(
      mojo::InterfaceRequest<mojo::files::File> request)
      : file_impl_(InputStreamFile::Create(this, request.Pass())) {}
  ~TestClientDestroysImplClient() override {}

 private:
  // InputStreamFile::Client|:
  bool RequestData(size_t /*max_num_bytes*/,
                   mojo::files::Error* /*error*/,
                   mojo::Array<uint8_t>* /*data*/,
                   const RequestDataCallback& /*callback*/) override {
    // We reset the impl on any call, and afterwards it shouldn't call us.
    EXPECT_TRUE(file_impl_);
    file_impl_.reset();
    return true;
  }
  void OnClosed() override {
    // We reset the impl on any call, and afterwards it shouldn't call us.
    EXPECT_TRUE(file_impl_);
    file_impl_.reset();
  }

  std::unique_ptr<InputStreamFile> file_impl_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestClientDestroysImplClient);
};

TEST_F(InputStreamFileTest, ClientDestroysImpl) {
  // Test destruction due to reading.
  {
    mojo::files::FilePtr file;
    TestClientDestroysImplClient client(GetProxy(&file));
    bool got_connection_error = false;
    file.set_connection_error_handler([&got_connection_error]() {
      got_connection_error = true;
      QuitMessageLoop();
    });
    // If the impl is destroyed while trying to answer a read, it doesn't
    // respond.
    // TODO(vtl): I'm not sure if this is the best behavior. Maybe it should
    // respond with an error?
    file->Read(100u, 0, mojo::files::Whence::FROM_CURRENT,
               [](mojo::files::Error, mojo::Array<uint8_t>) {
                 MOJO_CHECK(false) << "Not reached";
               });
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

// This responds synchronously to any (non-zero-byte) read with a single byte,
// starting with 0 and incrementing each time.
class TestClientFifoSync : public InputStreamFile::Client {
 public:
  explicit TestClientFifoSync(mojo::InterfaceRequest<mojo::files::File> request)
      : file_impl_(InputStreamFile::Create(this, request.Pass())),
        next_byte_(0u) {}
  ~TestClientFifoSync() override {}

 private:
  // InputStreamFile::Client|:
  bool RequestData(size_t max_num_bytes,
                   mojo::files::Error* error,
                   mojo::Array<uint8_t>* data,
                   const RequestDataCallback& callback) override {
    *error = mojo::files::Error::OK;
    data->resize(1);
    (*data)[0] = next_byte_++;
    return true;
  }
  void OnClosed() override {}

  std::unique_ptr<InputStreamFile> file_impl_;
  uint8_t next_byte_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestClientFifoSync);
};

// Like |TestClientFifoSync|, but asynchronous.
class TestClientFifoAsync : public InputStreamFile::Client {
 public:
  explicit TestClientFifoAsync(
      mojo::InterfaceRequest<mojo::files::File> request)
      : file_impl_(InputStreamFile::Create(this, request.Pass())),
        next_byte_(0u) {}
  ~TestClientFifoAsync() override {}

 private:
  // InputStreamFile::Client|:
  bool RequestData(size_t max_num_bytes,
                   mojo::files::Error* error,
                   mojo::Array<uint8_t>* data,
                   const RequestDataCallback& callback) override {
    PostTaskToMessageLoop([this, callback]() {
      mojo::Array<uint8_t> data;
      data.push_back(next_byte_++);
      callback.Run(mojo::files::Error::OK, data.Pass());
    });
    return false;
  }
  void OnClosed() override {}

  std::unique_ptr<InputStreamFile> file_impl_;
  uint8_t next_byte_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestClientFifoAsync);
};

void TestFifo(mojo::files::File* file) {
  int expect_callback = 0;
  uint8_t expect_byte = 0;

  // Test a couple of zero-byte reads.
  file->Read(0u, 0, mojo::files::Whence::FROM_CURRENT,
             [&expect_callback](mojo::files::Error e, mojo::Array<uint8_t> a) {
               EXPECT_EQ(0, expect_callback++);
               EXPECT_EQ(mojo::files::Error::OK, e);
               EXPECT_EQ(0u, a.size());
             });
  file->Read(0u, 0, mojo::files::Whence::FROM_CURRENT,
             [&expect_callback](mojo::files::Error e, mojo::Array<uint8_t> a) {
               EXPECT_EQ(1, expect_callback++);
               EXPECT_EQ(mojo::files::Error::OK, e);
               EXPECT_EQ(0u, a.size());
             });

  // Test a couple of non-zero-byte reads.
  file->Read(100u, 0, mojo::files::Whence::FROM_CURRENT,
             [&expect_callback, &expect_byte](mojo::files::Error e,
                                              mojo::Array<uint8_t> a) {
               EXPECT_EQ(2, expect_callback++);
               EXPECT_EQ(mojo::files::Error::OK, e);
               EXPECT_EQ(1u, a.size());
               EXPECT_EQ(expect_byte++, a[0]);
             });
  file->Read(100u, 0, mojo::files::Whence::FROM_CURRENT,
             [&expect_callback, &expect_byte](mojo::files::Error e,
                                              mojo::Array<uint8_t> a) {
               EXPECT_EQ(3, expect_callback++);
               EXPECT_EQ(mojo::files::Error::OK, e);
               EXPECT_EQ(1u, a.size());
               EXPECT_EQ(expect_byte++, a[0]);
             });
  // Throw in a zero-byte read.
  file->Read(0u, 0, mojo::files::Whence::FROM_CURRENT,
             [&expect_callback](mojo::files::Error e, mojo::Array<uint8_t> a) {
               EXPECT_EQ(4, expect_callback++);
               EXPECT_EQ(mojo::files::Error::OK, e);
               EXPECT_EQ(0u, a.size());
             });
  // And a final non-zero-byte read (we'll quit the message loop).
  file->Read(100u, 0, mojo::files::Whence::FROM_CURRENT,
             [&expect_callback, &expect_byte](mojo::files::Error e,
                                              mojo::Array<uint8_t> a) {
               EXPECT_EQ(5, expect_callback++);
               EXPECT_EQ(mojo::files::Error::OK, e);
               EXPECT_EQ(1u, a.size());
               EXPECT_EQ(expect_byte++, a[0]);
               QuitMessageLoop();
             });
  RunMessageLoop();

  // Check that all the callbacks ran.
  EXPECT_EQ(6, expect_callback);
  EXPECT_EQ(3u, expect_byte);
}

// Tests that if multiple reads are sent, they are completed in FIFO order. This
// tests the synchronous completion path.
TEST_F(InputStreamFileTest, FifoSync) {
  mojo::files::FilePtr file;
  TestClientFifoSync client(GetProxy(&file));
  TestFifo(file.get());
}

// Like |InputStreamFileTest.FifoSync|, but asynchronous.
TEST_F(InputStreamFileTest, FifoAsync) {
  mojo::files::FilePtr file;
  TestClientFifoAsync client(GetProxy(&file));
  TestFifo(file.get());
}

}  // namespace
}  // namespace files_impl
