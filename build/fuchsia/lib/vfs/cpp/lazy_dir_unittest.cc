// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/vfs/cpp/lazy_dir.h>

#include <fuchsia/io/cpp/fidl.h>
#include <lib/async/dispatcher.h>
#include <lib/gtest/real_loop_fixture.h>
#include <lib/vfs/cpp/pseudo_file.h>
#include <lib/vfs/cpp/testing/dir_test_util.h>
#include <zircon/system/public/zircon/errors.h>
#include <memory>

namespace {

using vfs_tests::Dirent;

class TestLazyDir : public vfs::LazyDir {
 public:
  struct TestContent {
   public:
    TestContent(std::string name, std::unique_ptr<vfs::Node> node)
        : name_(std::move(name)), node_(std::move(node)) {}
    std::string name_;
    std::unique_ptr<vfs::Node> node_;
  };

  TestLazyDir()
      : next_id_(GetStartingId()), loop_(&kAsyncLoopConfigNoAttachToThread) {
    loop_.StartThread("vfs test thread");
  }

  void AddContent(TestContent content) {
    contents_.emplace(next_id_++, std::move(content));
  }

  void ClearContent() {
    contents_.clear();
    next_id_ = GetStartingId();
  }

  fuchsia::io::DirectorySyncPtr ServeForTest(
      int flags = fuchsia::io::OPEN_RIGHT_READABLE) {
    fuchsia::io::DirectorySyncPtr ptr;
    Serve(flags, ptr.NewRequest().TakeChannel(), loop_.dispatcher());
    return ptr;
  }

  async_dispatcher_t* dispatcher() { return loop_.dispatcher(); }

 protected:
  void GetContents(LazyEntryVector* out_vector) const override {
    out_vector->reserve(contents_.size());
    for (const auto& content : contents_) {
      out_vector->push_back(
          {content.first, content.second.name_, fuchsia::io::MODE_TYPE_FILE});
    }
  }

  zx_status_t GetFile(Node** out_node, uint64_t id,
                      std::string name) const override {
    auto search = contents_.find(id);
    if (search != contents_.end()) {
      *out_node = search->second.node_.get();
      return ZX_OK;
    }

    return ZX_ERR_NOT_FOUND;
  }

 private:
  uint64_t next_id_;
  std::map<uint64_t, TestContent> contents_;
  async::Loop loop_;
};

class LazyDirConnection : public vfs_tests::DirConnection {
 protected:
  vfs::Directory* GetDirectoryNode() override { return &dir_; }

  TestLazyDir::TestContent CreateTestFile(std::string name,
                                          std::string content) {
    auto file = std::make_unique<vfs::BufferedPseudoFile>(
        [content = std::move(content)](std::vector<uint8_t>* output) {
          output->resize(content.length());
          std::copy(content.begin(), content.end(), output->begin());
          return ZX_OK;
        });
    return TestLazyDir::TestContent(std::move(name), std::move(file));
  }

  TestLazyDir dir_;
};

TEST_F(LazyDirConnection, ReadDirEmpty) {
  auto ptr = dir_.ServeForTest();

  std::vector<Dirent> expected_dirents = {
      Dirent::DirentForDot(),
  };
  AssertReadDirents(ptr, 1024, expected_dirents);
}

TEST_F(LazyDirConnection, ReadSimple) {
  auto ptr = dir_.ServeForTest();

  dir_.AddContent(CreateTestFile("file1", "file1"));

  std::vector<Dirent> expected_dirents = {Dirent::DirentForDot(),
                                          Dirent::DirentForFile("file1")};
  AssertReadDirents(ptr, 1024, expected_dirents);
}

TEST_F(LazyDirConnection, DynamicRead) {
  auto ptr = dir_.ServeForTest();

  dir_.AddContent(CreateTestFile("file1", "file1"));
  dir_.AddContent(CreateTestFile("file2", "file2"));

  std::vector<Dirent> expected_dirents = {Dirent::DirentForDot(),
                                          Dirent::DirentForFile("file1"),
                                          Dirent::DirentForFile("file2")};
  AssertReadDirents(ptr, 1024, expected_dirents);

  dir_.ClearContent();

  dir_.AddContent(CreateTestFile("file3", "file3"));

  // should not get any dirent before we rewind.
  expected_dirents = {};
  AssertReadDirents(ptr, 1024, expected_dirents);

  AssertRewind(ptr);

  expected_dirents = {Dirent::DirentForDot(), Dirent::DirentForFile("file3")};
  AssertReadDirents(ptr, 1024, expected_dirents);
}

TEST_F(LazyDirConnection, MultipleReads) {
  auto ptr = dir_.ServeForTest();

  dir_.AddContent(CreateTestFile("file1", "file1"));
  dir_.AddContent(CreateTestFile("file2", "file2"));
  dir_.AddContent(CreateTestFile("file3", "file3"));
  dir_.AddContent(CreateTestFile("file4", "file4"));

  std::vector<Dirent> expected_dirents = {Dirent::DirentForDot(),
                                          Dirent::DirentForFile("file1"),
                                          Dirent::DirentForFile("file2")};
  AssertReadDirents(ptr, 3 * sizeof(vdirent_t) + 15, expected_dirents);

  expected_dirents = {Dirent::DirentForFile("file3"),
                      Dirent::DirentForFile("file4")};

  AssertReadDirents(ptr, 1024, expected_dirents);
  expected_dirents = {};
  AssertReadDirents(ptr, 1024, expected_dirents);
}

TEST_F(LazyDirConnection, LookupWorks) {
  dir_.AddContent(CreateTestFile("file1", "file1"));
  dir_.AddContent(CreateTestFile("file2", "file2"));
  dir_.AddContent(CreateTestFile("file3", "file3"));
  dir_.AddContent(CreateTestFile("file4", "file4"));
  vfs::Node* n;
  ASSERT_EQ(ZX_OK, dir_.Lookup("file3", &n));
  fuchsia::io::FileSyncPtr file_ptr;
  n->Serve(fuchsia::io::OPEN_RIGHT_READABLE,
           file_ptr.NewRequest().TakeChannel(), dir_.dispatcher());
  zx_status_t status;
  std::vector<uint8_t> data;
  file_ptr->Read(20, &status, &data);
  ASSERT_EQ(ZX_OK, status);
  std::string str = "file3";
  std::vector<uint8_t> expected_data(str.begin(), str.end());
  ASSERT_EQ(expected_data, data);
}

TEST_F(LazyDirConnection, LookupReturnsNotFound) {
  dir_.AddContent(CreateTestFile("file1", "file1"));
  dir_.AddContent(CreateTestFile("file2", "file2"));
  dir_.AddContent(CreateTestFile("file3", "file3"));
  dir_.AddContent(CreateTestFile("file4", "file4"));
  vfs::Node* n;
  ASSERT_EQ(ZX_ERR_NOT_FOUND, dir_.Lookup("file5", &n));
}

}  // namespace
