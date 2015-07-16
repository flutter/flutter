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
//
// This file is the public interface to the .proto file parser.

#ifndef GOOGLE_PROTOBUF_COMPILER_IMPORTER_H__
#define GOOGLE_PROTOBUF_COMPILER_IMPORTER_H__

#include <string>
#include <vector>
#include <set>
#include <utility>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/descriptor_database.h>
#include <google/protobuf/compiler/parser.h>

namespace google {
namespace protobuf {

namespace io { class ZeroCopyInputStream; }

namespace compiler {

// Defined in this file.
class Importer;
class MultiFileErrorCollector;
class SourceTree;
class DiskSourceTree;

// TODO(kenton):  Move all SourceTree stuff to a separate file?

// An implementation of DescriptorDatabase which loads files from a SourceTree
// and parses them.
//
// Note:  This class is not thread-safe since it maintains a table of source
//   code locations for error reporting.  However, when a DescriptorPool wraps
//   a DescriptorDatabase, it uses mutex locking to make sure only one method
//   of the database is called at a time, even if the DescriptorPool is used
//   from multiple threads.  Therefore, there is only a problem if you create
//   multiple DescriptorPools wrapping the same SourceTreeDescriptorDatabase
//   and use them from multiple threads.
//
// Note:  This class does not implement FindFileContainingSymbol() or
//   FindFileContainingExtension(); these will always return false.
class LIBPROTOBUF_EXPORT SourceTreeDescriptorDatabase : public DescriptorDatabase {
 public:
  SourceTreeDescriptorDatabase(SourceTree* source_tree);
  ~SourceTreeDescriptorDatabase();

  // Instructs the SourceTreeDescriptorDatabase to report any parse errors
  // to the given MultiFileErrorCollector.  This should be called before
  // parsing.  error_collector must remain valid until either this method
  // is called again or the SourceTreeDescriptorDatabase is destroyed.
  void RecordErrorsTo(MultiFileErrorCollector* error_collector) {
    error_collector_ = error_collector;
  }

  // Gets a DescriptorPool::ErrorCollector which records errors to the
  // MultiFileErrorCollector specified with RecordErrorsTo().  This collector
  // has the ability to determine exact line and column numbers of errors
  // from the information given to it by the DescriptorPool.
  DescriptorPool::ErrorCollector* GetValidationErrorCollector() {
    using_validation_error_collector_ = true;
    return &validation_error_collector_;
  }

  // implements DescriptorDatabase -----------------------------------
  bool FindFileByName(const string& filename, FileDescriptorProto* output);
  bool FindFileContainingSymbol(const string& symbol_name,
                                FileDescriptorProto* output);
  bool FindFileContainingExtension(const string& containing_type,
                                   int field_number,
                                   FileDescriptorProto* output);

 private:
  class SingleFileErrorCollector;

  SourceTree* source_tree_;
  MultiFileErrorCollector* error_collector_;

  class LIBPROTOBUF_EXPORT ValidationErrorCollector : public DescriptorPool::ErrorCollector {
   public:
    ValidationErrorCollector(SourceTreeDescriptorDatabase* owner);
    ~ValidationErrorCollector();

    // implements ErrorCollector ---------------------------------------
    void AddError(const string& filename,
                  const string& element_name,
                  const Message* descriptor,
                  ErrorLocation location,
                  const string& message);

   private:
    SourceTreeDescriptorDatabase* owner_;
  };
  friend class ValidationErrorCollector;

  bool using_validation_error_collector_;
  SourceLocationTable source_locations_;
  ValidationErrorCollector validation_error_collector_;
};

// Simple interface for parsing .proto files.  This wraps the process
// of opening the file, parsing it with a Parser, recursively parsing all its
// imports, and then cross-linking the results to produce a FileDescriptor.
//
// This is really just a thin wrapper around SourceTreeDescriptorDatabase.
// You may find that SourceTreeDescriptorDatabase is more flexible.
//
// TODO(kenton):  I feel like this class is not well-named.
class LIBPROTOBUF_EXPORT Importer {
 public:
  Importer(SourceTree* source_tree,
           MultiFileErrorCollector* error_collector);
  ~Importer();

  // Import the given file and build a FileDescriptor representing it.  If
  // the file is already in the DescriptorPool, the existing FileDescriptor
  // will be returned.  The FileDescriptor is property of the DescriptorPool,
  // and will remain valid until it is destroyed.  If any errors occur, they
  // will be reported using the error collector and Import() will return NULL.
  //
  // A particular Importer object will only report errors for a particular
  // file once.  All future attempts to import the same file will return NULL
  // without reporting any errors.  The idea is that you might want to import
  // a lot of files without seeing the same errors over and over again.  If
  // you want to see errors for the same files repeatedly, you can use a
  // separate Importer object to import each one (but use the same
  // DescriptorPool so that they can be cross-linked).
  const FileDescriptor* Import(const string& filename);

  // The DescriptorPool in which all imported FileDescriptors and their
  // contents are stored.
  inline const DescriptorPool* pool() const {
    return &pool_;
  }

 private:
  SourceTreeDescriptorDatabase database_;
  DescriptorPool pool_;

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(Importer);
};

// If the importer encounters problems while trying to import the proto files,
// it reports them to a MultiFileErrorCollector.
class LIBPROTOBUF_EXPORT MultiFileErrorCollector {
 public:
  inline MultiFileErrorCollector() {}
  virtual ~MultiFileErrorCollector();

  // Line and column numbers are zero-based.  A line number of -1 indicates
  // an error with the entire file (e.g. "not found").
  virtual void AddError(const string& filename, int line, int column,
                        const string& message) = 0;

 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(MultiFileErrorCollector);
};

// Abstract interface which represents a directory tree containing proto files.
// Used by the default implementation of Importer to resolve import statements
// Most users will probably want to use the DiskSourceTree implementation,
// below.
class LIBPROTOBUF_EXPORT SourceTree {
 public:
  inline SourceTree() {}
  virtual ~SourceTree();

  // Open the given file and return a stream that reads it, or NULL if not
  // found.  The caller takes ownership of the returned object.  The filename
  // must be a path relative to the root of the source tree and must not
  // contain "." or ".." components.
  virtual io::ZeroCopyInputStream* Open(const string& filename) = 0;

 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(SourceTree);
};

// An implementation of SourceTree which loads files from locations on disk.
// Multiple mappings can be set up to map locations in the DiskSourceTree to
// locations in the physical filesystem.
class LIBPROTOBUF_EXPORT DiskSourceTree : public SourceTree {
 public:
  DiskSourceTree();
  ~DiskSourceTree();

  // Map a path on disk to a location in the SourceTree.  The path may be
  // either a file or a directory.  If it is a directory, the entire tree
  // under it will be mapped to the given virtual location.  To map a directory
  // to the root of the source tree, pass an empty string for virtual_path.
  //
  // If multiple mapped paths apply when opening a file, they will be searched
  // in order.  For example, if you do:
  //   MapPath("bar", "foo/bar");
  //   MapPath("", "baz");
  // and then you do:
  //   Open("bar/qux");
  // the DiskSourceTree will first try to open foo/bar/qux, then baz/bar/qux,
  // returning the first one that opens successfuly.
  //
  // disk_path may be an absolute path or relative to the current directory,
  // just like a path you'd pass to open().
  void MapPath(const string& virtual_path, const string& disk_path);

  // Return type for DiskFileToVirtualFile().
  enum DiskFileToVirtualFileResult {
    SUCCESS,
    SHADOWED,
    CANNOT_OPEN,
    NO_MAPPING
  };

  // Given a path to a file on disk, find a virtual path mapping to that
  // file.  The first mapping created with MapPath() whose disk_path contains
  // the filename is used.  However, that virtual path may not actually be
  // usable to open the given file.  Possible return values are:
  // * SUCCESS: The mapping was found.  *virtual_file is filled in so that
  //   calling Open(*virtual_file) will open the file named by disk_file.
  // * SHADOWED: A mapping was found, but using Open() to open this virtual
  //   path will end up returning some different file.  This is because some
  //   other mapping with a higher precedence also matches this virtual path
  //   and maps it to a different file that exists on disk.  *virtual_file
  //   is filled in as it would be in the SUCCESS case.  *shadowing_disk_file
  //   is filled in with the disk path of the file which would be opened if
  //   you were to call Open(*virtual_file).
  // * CANNOT_OPEN: The mapping was found and was not shadowed, but the
  //   file specified cannot be opened.  When this value is returned,
  //   errno will indicate the reason the file cannot be opened.  *virtual_file
  //   will be set to the virtual path as in the SUCCESS case, even though
  //   it is not useful.
  // * NO_MAPPING: Indicates that no mapping was found which contains this
  //   file.
  DiskFileToVirtualFileResult
    DiskFileToVirtualFile(const string& disk_file,
                          string* virtual_file,
                          string* shadowing_disk_file);

  // Given a virtual path, find the path to the file on disk.
  // Return true and update disk_file with the on-disk path if the file exists.
  // Return false and leave disk_file untouched if the file doesn't exist.
  bool VirtualFileToDiskFile(const string& virtual_file, string* disk_file);

  // implements SourceTree -------------------------------------------
  io::ZeroCopyInputStream* Open(const string& filename);

 private:
  struct Mapping {
    string virtual_path;
    string disk_path;

    inline Mapping(const string& virtual_path_param,
                   const string& disk_path_param)
      : virtual_path(virtual_path_param), disk_path(disk_path_param) {}
  };
  vector<Mapping> mappings_;

  // Like Open(), but returns the on-disk path in disk_file if disk_file is
  // non-NULL and the file could be successfully opened.
  io::ZeroCopyInputStream* OpenVirtualFile(const string& virtual_file,
                                           string* disk_file);

  // Like Open() but given the actual on-disk path.
  io::ZeroCopyInputStream* OpenDiskFile(const string& filename);

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(DiskSourceTree);
};

}  // namespace compiler
}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_COMPILER_IMPORTER_H__
