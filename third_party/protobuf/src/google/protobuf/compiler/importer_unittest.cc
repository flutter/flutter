// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Author: kenton@google.com (Kenton Varda)
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.

#include <google/protobuf/stubs/hash.h>

#include <google/protobuf/compiler/importer.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>

#include <google/protobuf/stubs/map-util.h>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/testing/file.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/stubs/substitute.h>
#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>

namespace google {
namespace protobuf {
namespace compiler {

namespace {

#define EXPECT_SUBSTRING(needle, haystack) \
  EXPECT_PRED_FORMAT2(testing::IsSubstring, (needle), (haystack))

class MockErrorCollector : public MultiFileErrorCollector {
 public:
  MockErrorCollector() {}
  ~MockErrorCollector() {}

  string text_;

  // implements ErrorCollector ---------------------------------------
  void AddError(const string& filename, int line, int column,
                const string& message) {
    strings::SubstituteAndAppend(&text_, "$0:$1:$2: $3\n",
                                 filename, line, column, message);
  }
};

// -------------------------------------------------------------------

// A dummy implementation of SourceTree backed by a simple map.
class MockSourceTree : public SourceTree {
 public:
  MockSourceTree() {}
  ~MockSourceTree() {}

  void AddFile(const string& name, const char* contents) {
    files_[name] = contents;
  }

  // implements SourceTree -------------------------------------------
  io::ZeroCopyInputStream* Open(const string& filename) {
    const char* contents = FindPtrOrNull(files_, filename);
    if (contents == NULL) {
      return NULL;
    } else {
      return new io::ArrayInputStream(contents, strlen(contents));
    }
  }

 private:
  hash_map<string, const char*> files_;
};

// ===================================================================

class ImporterTest : public testing::Test {
 protected:
  ImporterTest()
    : importer_(&source_tree_, &error_collector_) {}

  void AddFile(const string& filename, const char* text) {
    source_tree_.AddFile(filename, text);
  }

  // Return the collected error text
  string error() const { return error_collector_.text_; }

  MockErrorCollector error_collector_;
  MockSourceTree source_tree_;
  Importer importer_;
};

TEST_F(ImporterTest, Import) {
  // Test normal importing.
  AddFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  const FileDescriptor* file = importer_.Import("foo.proto");
  EXPECT_EQ("", error_collector_.text_);
  ASSERT_TRUE(file != NULL);

  ASSERT_EQ(1, file->message_type_count());
  EXPECT_EQ("Foo", file->message_type(0)->name());

  // Importing again should return same object.
  EXPECT_EQ(file, importer_.Import("foo.proto"));
}

TEST_F(ImporterTest, ImportNested) {
  // Test that importing a file which imports another file works.
  AddFile("foo.proto",
    "syntax = \"proto2\";\n"
    "import \"bar.proto\";\n"
    "message Foo {\n"
    "  optional Bar bar = 1;\n"
    "}\n");
  AddFile("bar.proto",
    "syntax = \"proto2\";\n"
    "message Bar {}\n");

  // Note that both files are actually parsed by the first call to Import()
  // here, since foo.proto imports bar.proto.  The second call just returns
  // the same ProtoFile for bar.proto which was constructed while importing
  // foo.proto.  We test that this is the case below by checking that bar
  // is among foo's dependencies (by pointer).
  const FileDescriptor* foo = importer_.Import("foo.proto");
  const FileDescriptor* bar = importer_.Import("bar.proto");
  EXPECT_EQ("", error_collector_.text_);
  ASSERT_TRUE(foo != NULL);
  ASSERT_TRUE(bar != NULL);

  // Check that foo's dependency is the same object as bar.
  ASSERT_EQ(1, foo->dependency_count());
  EXPECT_EQ(bar, foo->dependency(0));

  // Check that foo properly cross-links bar.
  ASSERT_EQ(1, foo->message_type_count());
  ASSERT_EQ(1, bar->message_type_count());
  ASSERT_EQ(1, foo->message_type(0)->field_count());
  ASSERT_EQ(FieldDescriptor::TYPE_MESSAGE,
            foo->message_type(0)->field(0)->type());
  EXPECT_EQ(bar->message_type(0),
            foo->message_type(0)->field(0)->message_type());
}

TEST_F(ImporterTest, FileNotFound) {
  // Error:  Parsing a file that doesn't exist.
  EXPECT_TRUE(importer_.Import("foo.proto") == NULL);
  EXPECT_EQ(
    "foo.proto:-1:0: File not found.\n",
    error_collector_.text_);
}

TEST_F(ImporterTest, ImportNotFound) {
  // Error:  Importing a file that doesn't exist.
  AddFile("foo.proto",
    "syntax = \"proto2\";\n"
    "import \"bar.proto\";\n");

  EXPECT_TRUE(importer_.Import("foo.proto") == NULL);
  EXPECT_EQ(
    "bar.proto:-1:0: File not found.\n"
    "foo.proto:-1:0: Import \"bar.proto\" was not found or had errors.\n",
    error_collector_.text_);
}

TEST_F(ImporterTest, RecursiveImport) {
  // Error:  Recursive import.
  AddFile("recursive1.proto",
    "syntax = \"proto2\";\n"
    "import \"recursive2.proto\";\n");
  AddFile("recursive2.proto",
    "syntax = \"proto2\";\n"
    "import \"recursive1.proto\";\n");

  EXPECT_TRUE(importer_.Import("recursive1.proto") == NULL);
  EXPECT_EQ(
    "recursive1.proto:-1:0: File recursively imports itself: recursive1.proto "
      "-> recursive2.proto -> recursive1.proto\n"
    "recursive2.proto:-1:0: Import \"recursive1.proto\" was not found "
      "or had errors.\n"
    "recursive1.proto:-1:0: Import \"recursive2.proto\" was not found "
      "or had errors.\n",
    error_collector_.text_);
}

// TODO(sanjay): The MapField tests below more properly belong in
// descriptor_unittest, but are more convenient to test here.
TEST_F(ImporterTest, MapFieldValid) {
  AddFile(
      "map.proto",
      "syntax = \"proto2\";\n"
      "message Item {\n"
      "  required string key = 1;\n"
      "}\n"
      "message Map {\n"
      "  repeated Item items = 1 [experimental_map_key = \"key\"];\n"
      "}\n"
      );
  const FileDescriptor* file = importer_.Import("map.proto");
  ASSERT_TRUE(file != NULL) << error_collector_.text_;
  EXPECT_EQ("", error_collector_.text_);

  // Check that Map::items points to Item::key
  const Descriptor* item_type = file->FindMessageTypeByName("Item");
  ASSERT_TRUE(item_type != NULL);
  const Descriptor* map_type = file->FindMessageTypeByName("Map");
  ASSERT_TRUE(map_type != NULL);
  const FieldDescriptor* key_field = item_type->FindFieldByName("key");
  ASSERT_TRUE(key_field != NULL);
  const FieldDescriptor* items_field = map_type->FindFieldByName("items");
  ASSERT_TRUE(items_field != NULL);
  EXPECT_EQ(items_field->experimental_map_key(), key_field);
}

TEST_F(ImporterTest, MapFieldNotRepeated) {
  AddFile(
      "map.proto",
      "syntax = \"proto2\";\n"
      "message Item {\n"
      "  required string key = 1;\n"
      "}\n"
      "message Map {\n"
      "  required Item items = 1 [experimental_map_key = \"key\"];\n"
      "}\n"
      );
  EXPECT_TRUE(importer_.Import("map.proto") == NULL);
  EXPECT_SUBSTRING("only allowed for repeated fields", error());
}

TEST_F(ImporterTest, MapFieldNotMessageType) {
  AddFile(
      "map.proto",
      "syntax = \"proto2\";\n"
      "message Map {\n"
      "  repeated int32 items = 1 [experimental_map_key = \"key\"];\n"
      "}\n"
      );
  EXPECT_TRUE(importer_.Import("map.proto") == NULL);
  EXPECT_SUBSTRING("only allowed for fields with a message type", error());
}

TEST_F(ImporterTest, MapFieldTypeNotFound) {
  AddFile(
      "map.proto",
      "syntax = \"proto2\";\n"
      "message Map {\n"
      "  repeated Unknown items = 1 [experimental_map_key = \"key\"];\n"
      "}\n"
      );
  EXPECT_TRUE(importer_.Import("map.proto") == NULL);
  EXPECT_SUBSTRING("not defined", error());
}

TEST_F(ImporterTest, MapFieldKeyNotFound) {
  AddFile(
      "map.proto",
      "syntax = \"proto2\";\n"
      "message Item {\n"
      "  required string key = 1;\n"
      "}\n"
      "message Map {\n"
      "  repeated Item items = 1 [experimental_map_key = \"badkey\"];\n"
      "}\n"
      );
  EXPECT_TRUE(importer_.Import("map.proto") == NULL);
  EXPECT_SUBSTRING("Could not find field", error());
}

TEST_F(ImporterTest, MapFieldKeyRepeated) {
  AddFile(
      "map.proto",
      "syntax = \"proto2\";\n"
      "message Item {\n"
      "  repeated string key = 1;\n"
      "}\n"
      "message Map {\n"
      "  repeated Item items = 1 [experimental_map_key = \"key\"];\n"
      "}\n"
      );
  EXPECT_TRUE(importer_.Import("map.proto") == NULL);
  EXPECT_SUBSTRING("must not name a repeated field", error());
}

TEST_F(ImporterTest, MapFieldKeyNotScalar) {
  AddFile(
      "map.proto",
      "syntax = \"proto2\";\n"
      "message ItemKey { }\n"
      "message Item {\n"
      "  required ItemKey key = 1;\n"
      "}\n"
      "message Map {\n"
      "  repeated Item items = 1 [experimental_map_key = \"key\"];\n"
      "}\n"
      );
  EXPECT_TRUE(importer_.Import("map.proto") == NULL);
  EXPECT_SUBSTRING("must name a scalar or string", error());
}

// ===================================================================

class DiskSourceTreeTest : public testing::Test {
 protected:
  virtual void SetUp() {
    dirnames_.push_back(TestTempDir() + "/test_proto2_import_path_1");
    dirnames_.push_back(TestTempDir() + "/test_proto2_import_path_2");

    for (int i = 0; i < dirnames_.size(); i++) {
      if (File::Exists(dirnames_[i])) {
        File::DeleteRecursively(dirnames_[i], NULL, NULL);
      }
      GOOGLE_CHECK(File::CreateDir(dirnames_[i].c_str(), DEFAULT_FILE_MODE));
    }
  }

  virtual void TearDown() {
    for (int i = 0; i < dirnames_.size(); i++) {
      File::DeleteRecursively(dirnames_[i], NULL, NULL);
    }
  }

  void AddFile(const string& filename, const char* contents) {
    File::WriteStringToFileOrDie(contents, filename);
  }

  void AddSubdir(const string& dirname) {
    GOOGLE_CHECK(File::CreateDir(dirname.c_str(), DEFAULT_FILE_MODE));
  }

  void ExpectFileContents(const string& filename,
                          const char* expected_contents) {
    scoped_ptr<io::ZeroCopyInputStream> input(source_tree_.Open(filename));

    ASSERT_FALSE(input == NULL);

    // Read all the data from the file.
    string file_contents;
    const void* data;
    int size;
    while (input->Next(&data, &size)) {
      file_contents.append(reinterpret_cast<const char*>(data), size);
    }

    EXPECT_EQ(expected_contents, file_contents);
  }

  void ExpectFileNotFound(const string& filename) {
    scoped_ptr<io::ZeroCopyInputStream> input(source_tree_.Open(filename));
    EXPECT_TRUE(input == NULL);
  }

  DiskSourceTree source_tree_;

  // Paths of two on-disk directories to use during the test.
  vector<string> dirnames_;
};

TEST_F(DiskSourceTreeTest, MapRoot) {
  // Test opening a file in a directory that is mapped to the root of the
  // source tree.
  AddFile(dirnames_[0] + "/foo", "Hello World!");
  source_tree_.MapPath("", dirnames_[0]);

  ExpectFileContents("foo", "Hello World!");
  ExpectFileNotFound("bar");
}

TEST_F(DiskSourceTreeTest, MapDirectory) {
  // Test opening a file in a directory that is mapped to somewhere other
  // than the root of the source tree.

  AddFile(dirnames_[0] + "/foo", "Hello World!");
  source_tree_.MapPath("baz", dirnames_[0]);

  ExpectFileContents("baz/foo", "Hello World!");
  ExpectFileNotFound("baz/bar");
  ExpectFileNotFound("foo");
  ExpectFileNotFound("bar");

  // Non-canonical file names should not work.
  ExpectFileNotFound("baz//foo");
  ExpectFileNotFound("baz/../baz/foo");
  ExpectFileNotFound("baz/./foo");
  ExpectFileNotFound("baz/foo/");
}

TEST_F(DiskSourceTreeTest, NoParent) {
  // Test that we cannot open files in a parent of a mapped directory.

  AddFile(dirnames_[0] + "/foo", "Hello World!");
  AddSubdir(dirnames_[0] + "/bar");
  AddFile(dirnames_[0] + "/bar/baz", "Blah.");
  source_tree_.MapPath("", dirnames_[0] + "/bar");

  ExpectFileContents("baz", "Blah.");
  ExpectFileNotFound("../foo");
  ExpectFileNotFound("../bar/baz");
}

TEST_F(DiskSourceTreeTest, MapFile) {
  // Test opening a file that is mapped directly into the source tree.

  AddFile(dirnames_[0] + "/foo", "Hello World!");
  source_tree_.MapPath("foo", dirnames_[0] + "/foo");

  ExpectFileContents("foo", "Hello World!");
  ExpectFileNotFound("bar");
}

TEST_F(DiskSourceTreeTest, SearchMultipleDirectories) {
  // Test mapping and searching multiple directories.

  AddFile(dirnames_[0] + "/foo", "Hello World!");
  AddFile(dirnames_[1] + "/foo", "This file should be hidden.");
  AddFile(dirnames_[1] + "/bar", "Goodbye World!");
  source_tree_.MapPath("", dirnames_[0]);
  source_tree_.MapPath("", dirnames_[1]);

  ExpectFileContents("foo", "Hello World!");
  ExpectFileContents("bar", "Goodbye World!");
  ExpectFileNotFound("baz");
}

TEST_F(DiskSourceTreeTest, OrderingTrumpsSpecificity) {
  // Test that directories are always searched in order, even when a latter
  // directory is more-specific than a former one.

  // Create the "bar" directory so we can put a file in it.
  ASSERT_TRUE(File::CreateDir((dirnames_[0] + "/bar").c_str(),
                              DEFAULT_FILE_MODE));

  // Add files and map paths.
  AddFile(dirnames_[0] + "/bar/foo", "Hello World!");
  AddFile(dirnames_[1] + "/foo", "This file should be hidden.");
  source_tree_.MapPath("", dirnames_[0]);
  source_tree_.MapPath("bar", dirnames_[1]);

  // Check.
  ExpectFileContents("bar/foo", "Hello World!");
}

TEST_F(DiskSourceTreeTest, DiskFileToVirtualFile) {
  // Test DiskFileToVirtualFile.

  AddFile(dirnames_[0] + "/foo", "Hello World!");
  AddFile(dirnames_[1] + "/foo", "This file should be hidden.");
  source_tree_.MapPath("bar", dirnames_[0]);
  source_tree_.MapPath("bar", dirnames_[1]);

  string virtual_file;
  string shadowing_disk_file;

  EXPECT_EQ(DiskSourceTree::NO_MAPPING,
    source_tree_.DiskFileToVirtualFile(
      "/foo", &virtual_file, &shadowing_disk_file));

  EXPECT_EQ(DiskSourceTree::SHADOWED,
    source_tree_.DiskFileToVirtualFile(
      dirnames_[1] + "/foo", &virtual_file, &shadowing_disk_file));
  EXPECT_EQ("bar/foo", virtual_file);
  EXPECT_EQ(dirnames_[0] + "/foo", shadowing_disk_file);

  EXPECT_EQ(DiskSourceTree::CANNOT_OPEN,
    source_tree_.DiskFileToVirtualFile(
      dirnames_[1] + "/baz", &virtual_file, &shadowing_disk_file));
  EXPECT_EQ("bar/baz", virtual_file);

  EXPECT_EQ(DiskSourceTree::SUCCESS,
    source_tree_.DiskFileToVirtualFile(
      dirnames_[0] + "/foo", &virtual_file, &shadowing_disk_file));
  EXPECT_EQ("bar/foo", virtual_file);
}

TEST_F(DiskSourceTreeTest, DiskFileToVirtualFileCanonicalization) {
  // Test handling of "..", ".", etc. in DiskFileToVirtualFile().

  source_tree_.MapPath("dir1", "..");
  source_tree_.MapPath("dir2", "../../foo");
  source_tree_.MapPath("dir3", "./foo/bar/.");
  source_tree_.MapPath("dir4", ".");
  source_tree_.MapPath("", "/qux");
  source_tree_.MapPath("dir5", "/quux/");

  string virtual_file;
  string shadowing_disk_file;

  // "../.." should not be considered to be under "..".
  EXPECT_EQ(DiskSourceTree::NO_MAPPING,
    source_tree_.DiskFileToVirtualFile(
      "../../baz", &virtual_file, &shadowing_disk_file));

  // "/foo" is not mapped (it should not be misintepreted as being under ".").
  EXPECT_EQ(DiskSourceTree::NO_MAPPING,
    source_tree_.DiskFileToVirtualFile(
      "/foo", &virtual_file, &shadowing_disk_file));

#ifdef WIN32
  // "C:\foo" is not mapped (it should not be misintepreted as being under ".").
  EXPECT_EQ(DiskSourceTree::NO_MAPPING,
    source_tree_.DiskFileToVirtualFile(
      "C:\\foo", &virtual_file, &shadowing_disk_file));
#endif  // WIN32

  // But "../baz" should be.
  EXPECT_EQ(DiskSourceTree::CANNOT_OPEN,
    source_tree_.DiskFileToVirtualFile(
      "../baz", &virtual_file, &shadowing_disk_file));
  EXPECT_EQ("dir1/baz", virtual_file);

  // "../../foo/baz" is under "../../foo".
  EXPECT_EQ(DiskSourceTree::CANNOT_OPEN,
    source_tree_.DiskFileToVirtualFile(
      "../../foo/baz", &virtual_file, &shadowing_disk_file));
  EXPECT_EQ("dir2/baz", virtual_file);

  // "foo/./bar/baz" is under "./foo/bar/.".
  EXPECT_EQ(DiskSourceTree::CANNOT_OPEN,
    source_tree_.DiskFileToVirtualFile(
      "foo/bar/baz", &virtual_file, &shadowing_disk_file));
  EXPECT_EQ("dir3/baz", virtual_file);

  // "bar" is under ".".
  EXPECT_EQ(DiskSourceTree::CANNOT_OPEN,
    source_tree_.DiskFileToVirtualFile(
      "bar", &virtual_file, &shadowing_disk_file));
  EXPECT_EQ("dir4/bar", virtual_file);

  // "/qux/baz" is under "/qux".
  EXPECT_EQ(DiskSourceTree::CANNOT_OPEN,
    source_tree_.DiskFileToVirtualFile(
      "/qux/baz", &virtual_file, &shadowing_disk_file));
  EXPECT_EQ("baz", virtual_file);

  // "/quux/bar" is under "/quux".
  EXPECT_EQ(DiskSourceTree::CANNOT_OPEN,
    source_tree_.DiskFileToVirtualFile(
      "/quux/bar", &virtual_file, &shadowing_disk_file));
  EXPECT_EQ("dir5/bar", virtual_file);
}

TEST_F(DiskSourceTreeTest, VirtualFileToDiskFile) {
  // Test VirtualFileToDiskFile.

  AddFile(dirnames_[0] + "/foo", "Hello World!");
  AddFile(dirnames_[1] + "/foo", "This file should be hidden.");
  AddFile(dirnames_[1] + "/quux", "This file should not be hidden.");
  source_tree_.MapPath("bar", dirnames_[0]);
  source_tree_.MapPath("bar", dirnames_[1]);

  // Existent files, shadowed and non-shadowed case.
  string disk_file;
  EXPECT_TRUE(source_tree_.VirtualFileToDiskFile("bar/foo", &disk_file));
  EXPECT_EQ(dirnames_[0] + "/foo", disk_file);
  EXPECT_TRUE(source_tree_.VirtualFileToDiskFile("bar/quux", &disk_file));
  EXPECT_EQ(dirnames_[1] + "/quux", disk_file);

  // Nonexistent file in existent directory and vice versa.
  string not_touched = "not touched";
  EXPECT_FALSE(source_tree_.VirtualFileToDiskFile("bar/baz", &not_touched));
  EXPECT_EQ("not touched", not_touched);
  EXPECT_FALSE(source_tree_.VirtualFileToDiskFile("baz/foo", &not_touched));
  EXPECT_EQ("not touched", not_touched);

  // Accept NULL as output parameter.
  EXPECT_TRUE(source_tree_.VirtualFileToDiskFile("bar/foo", NULL));
  EXPECT_FALSE(source_tree_.VirtualFileToDiskFile("baz/foo", NULL));
}

}  // namespace

}  // namespace compiler
}  // namespace protobuf
}  // namespace google
