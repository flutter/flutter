// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/lib/fd_table.h"

#include <errno.h>

#include <memory>

#include "files/public/c/lib/fd_impl.h"
#include "files/public/c/tests/mock_errno_impl.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojio {
namespace {

class TestFDImpl : public FDImpl {
 public:
  TestFDImpl() : FDImpl(nullptr) {}
  ~TestFDImpl() override {}

  // |FDImpl| implementation:
  bool Close() override { return false; }
  std::unique_ptr<FDImpl> Dup() override { return nullptr; }
  bool Ftruncate(mojio_off_t) override { return false; }
  mojio_off_t Lseek(mojio_off_t, int) override { return -1; }
  mojio_ssize_t Read(void*, size_t) override { return -1; }
  mojio_ssize_t Write(const void*, size_t) override { return -1; }
  bool Fstat(struct mojio_stat*) override { return false; }

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestFDImpl);
};

TEST(FDTableTest, AddGetRemove) {
  const int kLastErrorSentinel = -12345;
  test::MockErrnoImpl errno_impl(kLastErrorSentinel);

  FDTable fd_table(&errno_impl, 100);

  EXPECT_EQ(&errno_impl, fd_table.errno_impl());
  EXPECT_EQ(100u, fd_table.max_num_fds());

  // Keep these as raw pointers, so we'll be able to check identity.
  FDImpl* impl0 = new TestFDImpl();
  EXPECT_EQ(0, fd_table.Add(std::unique_ptr<FDImpl>(impl0)));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Should be able to get it.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(impl0, fd_table.Get(0));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Add a couple more. (FDs are allocated in order.)
  errno_impl.Reset(kLastErrorSentinel);
  FDImpl* impl1 = new TestFDImpl();
  EXPECT_EQ(1, fd_table.Add(std::unique_ptr<FDImpl>(impl1)));
  FDImpl* impl2 = new TestFDImpl();
  EXPECT_EQ(2, fd_table.Add(std::unique_ptr<FDImpl>(impl2)));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Should still be able to get everything.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(impl0, fd_table.Get(0));
  EXPECT_EQ(impl1, fd_table.Get(1));
  EXPECT_EQ(impl2, fd_table.Get(2));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Remove 1.
  errno_impl.Reset(kLastErrorSentinel);
  std::unique_ptr<FDImpl> removed_impl1 = fd_table.Remove(1);
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(impl1, removed_impl1.get());
  // Note: Don't deallocate |impl1|/|removed_impl1|, so that |new_impl1| (below)
  // definitely won't be allocated at the same address.

  // The next FD should be from the newly-vacated spot.
  errno_impl.Reset(kLastErrorSentinel);
  FDImpl* new_impl1 = new TestFDImpl();
  EXPECT_EQ(1, fd_table.Add(std::unique_ptr<FDImpl>(new_impl1)));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(new_impl1, fd_table.Get(1));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Remove 0 and 2.
  errno_impl.Reset(kLastErrorSentinel);
  std::unique_ptr<FDImpl> removed_impl0 = fd_table.Remove(0);
  std::unique_ptr<FDImpl> removed_impl2 = fd_table.Remove(2);
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(impl0, removed_impl0.get());
  EXPECT_EQ(impl2, removed_impl2.get());

  // The next FD should be from the first vacant spot.
  errno_impl.Reset(kLastErrorSentinel);
  FDImpl* new_impl0 = new TestFDImpl();
  EXPECT_EQ(0, fd_table.Add(std::unique_ptr<FDImpl>(new_impl0)));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
}

TEST(FDTableTest, GetInvalid) {
  const int kLastErrorSentinel = -12345;
  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  FDTable fd_table(&errno_impl, 100);

  // Can't get 0 yet. Error should be EBADF.
  EXPECT_EQ(nullptr, fd_table.Get(0));
  EXPECT_EQ(EBADF, errno_impl.Get());

  // Add 0; should then be able to get 0.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(0, fd_table.Add(std::unique_ptr<FDImpl>(new TestFDImpl())));
  EXPECT_TRUE(fd_table.Get(0));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Can't get 1.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(nullptr, fd_table.Get(1));
  EXPECT_EQ(EBADF, errno_impl.Get());
}

TEST(FDTableTest, RemoveInvalid) {
  const int kLastErrorSentinel = -12345;
  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  FDTable fd_table(&errno_impl, 100);

  // Can't remove 0 yet. Error should be EBADF.
  EXPECT_EQ(nullptr, fd_table.Remove(0));
  EXPECT_EQ(EBADF, errno_impl.Get());

  // Add 0; should then be able to remove 0.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(0, fd_table.Add(std::unique_ptr<FDImpl>(new TestFDImpl())));
  EXPECT_TRUE(fd_table.Remove(0));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // But shouldn't be able to remove 0.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(nullptr, fd_table.Remove(0));
  EXPECT_EQ(EBADF, errno_impl.Get());

  // Nor 1.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(nullptr, fd_table.Remove(1));
  EXPECT_EQ(EBADF, errno_impl.Get());
}

TEST(FDTableTest, Full) {
  const int kLastErrorSentinel = -12345;
  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  FDTable fd_table(&errno_impl, 3);

  // Add 0, 1, 2.
  EXPECT_EQ(0, fd_table.Add(std::unique_ptr<FDImpl>(new TestFDImpl())));
  EXPECT_EQ(1, fd_table.Add(std::unique_ptr<FDImpl>(new TestFDImpl())));
  EXPECT_EQ(2, fd_table.Add(std::unique_ptr<FDImpl>(new TestFDImpl())));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Shouldn't be able to add another. Error should be EMFILE. (Note that this
  // is EMFILE, which is too many open files (in the current process) and not
  // ENFILE, which is too many open files in the system.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(-1, fd_table.Add(std::unique_ptr<FDImpl>(new TestFDImpl())));
  EXPECT_EQ(EMFILE, errno_impl.Get());

  // Remove 0.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(fd_table.Remove(0));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Now adding should be okay again.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(0, fd_table.Add(std::unique_ptr<FDImpl>(new TestFDImpl())));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
}

}  // namespace
}  // namespace mojio
