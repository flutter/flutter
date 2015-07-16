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
// Interface for manipulating databases of descriptors.

#ifndef GOOGLE_PROTOBUF_DESCRIPTOR_DATABASE_H__
#define GOOGLE_PROTOBUF_DESCRIPTOR_DATABASE_H__

#include <map>
#include <string>
#include <utility>
#include <vector>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/descriptor.h>

namespace google {
namespace protobuf {

// Defined in this file.
class DescriptorDatabase;
class SimpleDescriptorDatabase;
class EncodedDescriptorDatabase;
class DescriptorPoolDatabase;
class MergedDescriptorDatabase;

// Abstract interface for a database of descriptors.
//
// This is useful if you want to create a DescriptorPool which loads
// descriptors on-demand from some sort of large database.  If the database
// is large, it may be inefficient to enumerate every .proto file inside it
// calling DescriptorPool::BuildFile() for each one.  Instead, a DescriptorPool
// can be created which wraps a DescriptorDatabase and only builds particular
// descriptors when they are needed.
class LIBPROTOBUF_EXPORT DescriptorDatabase {
 public:
  inline DescriptorDatabase() {}
  virtual ~DescriptorDatabase();

  // Find a file by file name.  Fills in in *output and returns true if found.
  // Otherwise, returns false, leaving the contents of *output undefined.
  virtual bool FindFileByName(const string& filename,
                              FileDescriptorProto* output) = 0;

  // Find the file that declares the given fully-qualified symbol name.
  // If found, fills in *output and returns true, otherwise returns false
  // and leaves *output undefined.
  virtual bool FindFileContainingSymbol(const string& symbol_name,
                                        FileDescriptorProto* output) = 0;

  // Find the file which defines an extension extending the given message type
  // with the given field number.  If found, fills in *output and returns true,
  // otherwise returns false and leaves *output undefined.  containing_type
  // must be a fully-qualified type name.
  virtual bool FindFileContainingExtension(const string& containing_type,
                                           int field_number,
                                           FileDescriptorProto* output) = 0;

  // Finds the tag numbers used by all known extensions of
  // extendee_type, and appends them to output in an undefined
  // order. This method is best-effort: it's not guaranteed that the
  // database will find all extensions, and it's not guaranteed that
  // FindFileContainingExtension will return true on all of the found
  // numbers. Returns true if the search was successful, otherwise
  // returns false and leaves output unchanged.
  //
  // This method has a default implementation that always returns
  // false.
  virtual bool FindAllExtensionNumbers(const string& extendee_type,
                                       vector<int>* output) {
    return false;
  }

 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(DescriptorDatabase);
};

// A DescriptorDatabase into which you can insert files manually.
//
// FindFileContainingSymbol() is fully-implemented.  When you add a file, its
// symbols will be indexed for this purpose.  Note that the implementation
// may return false positives, but only if it isn't possible for the symbol
// to be defined in any other file.  In particular, if a file defines a symbol
// "Foo", then searching for "Foo.[anything]" will match that file.  This way,
// the database does not need to aggressively index all children of a symbol.
//
// FindFileContainingExtension() is mostly-implemented.  It works if and only
// if the original FieldDescriptorProto defining the extension has a
// fully-qualified type name in its "extendee" field (i.e. starts with a '.').
// If the extendee is a relative name, SimpleDescriptorDatabase will not
// attempt to resolve the type, so it will not know what type the extension is
// extending.  Therefore, calling FindFileContainingExtension() with the
// extension's containing type will never actually find that extension.  Note
// that this is an unlikely problem, as all FileDescriptorProtos created by the
// protocol compiler (as well as ones created by calling
// FileDescriptor::CopyTo()) will always use fully-qualified names for all
// types.  You only need to worry if you are constructing FileDescriptorProtos
// yourself, or are calling compiler::Parser directly.
class LIBPROTOBUF_EXPORT SimpleDescriptorDatabase : public DescriptorDatabase {
 public:
  SimpleDescriptorDatabase();
  ~SimpleDescriptorDatabase();

  // Adds the FileDescriptorProto to the database, making a copy.  The object
  // can be deleted after Add() returns.  Returns false if the file conflicted
  // with a file already in the database, in which case an error will have
  // been written to GOOGLE_LOG(ERROR).
  bool Add(const FileDescriptorProto& file);

  // Adds the FileDescriptorProto to the database and takes ownership of it.
  bool AddAndOwn(const FileDescriptorProto* file);

  // implements DescriptorDatabase -----------------------------------
  bool FindFileByName(const string& filename,
                      FileDescriptorProto* output);
  bool FindFileContainingSymbol(const string& symbol_name,
                                FileDescriptorProto* output);
  bool FindFileContainingExtension(const string& containing_type,
                                   int field_number,
                                   FileDescriptorProto* output);
  bool FindAllExtensionNumbers(const string& extendee_type,
                               vector<int>* output);

 private:
  // So that it can use DescriptorIndex.
  friend class EncodedDescriptorDatabase;

  // An index mapping file names, symbol names, and extension numbers to
  // some sort of values.
  template <typename Value>
  class DescriptorIndex {
   public:
    // Helpers to recursively add particular descriptors and all their contents
    // to the index.
    bool AddFile(const FileDescriptorProto& file,
                 Value value);
    bool AddSymbol(const string& name, Value value);
    bool AddNestedExtensions(const DescriptorProto& message_type,
                             Value value);
    bool AddExtension(const FieldDescriptorProto& field,
                      Value value);

    Value FindFile(const string& filename);
    Value FindSymbol(const string& name);
    Value FindExtension(const string& containing_type, int field_number);
    bool FindAllExtensionNumbers(const string& containing_type,
                                 vector<int>* output);

   private:
    map<string, Value> by_name_;
    map<string, Value> by_symbol_;
    map<pair<string, int>, Value> by_extension_;

    // Invariant:  The by_symbol_ map does not contain any symbols which are
    // prefixes of other symbols in the map.  For example, "foo.bar" is a
    // prefix of "foo.bar.baz" (but is not a prefix of "foo.barbaz").
    //
    // This invariant is important because it means that given a symbol name,
    // we can find a key in the map which is a prefix of the symbol in O(lg n)
    // time, and we know that there is at most one such key.
    //
    // The prefix lookup algorithm works like so:
    // 1) Find the last key in the map which is less than or equal to the
    //    search key.
    // 2) If the found key is a prefix of the search key, then return it.
    //    Otherwise, there is no match.
    //
    // I am sure this algorithm has been described elsewhere, but since I
    // wasn't able to find it quickly I will instead prove that it works
    // myself.  The key to the algorithm is that if a match exists, step (1)
    // will find it.  Proof:
    // 1) Define the "search key" to be the key we are looking for, the "found
    //    key" to be the key found in step (1), and the "match key" to be the
    //    key which actually matches the serach key (i.e. the key we're trying
    //    to find).
    // 2) The found key must be less than or equal to the search key by
    //    definition.
    // 3) The match key must also be less than or equal to the search key
    //    (because it is a prefix).
    // 4) The match key cannot be greater than the found key, because if it
    //    were, then step (1) of the algorithm would have returned the match
    //    key instead (since it finds the *greatest* key which is less than or
    //    equal to the search key).
    // 5) Therefore, the found key must be between the match key and the search
    //    key, inclusive.
    // 6) Since the search key must be a sub-symbol of the match key, if it is
    //    not equal to the match key, then search_key[match_key.size()] must
    //    be '.'.
    // 7) Since '.' sorts before any other character that is valid in a symbol
    //    name, then if the found key is not equal to the match key, then
    //    found_key[match_key.size()] must also be '.', because any other value
    //    would make it sort after the search key.
    // 8) Therefore, if the found key is not equal to the match key, then the
    //    found key must be a sub-symbol of the match key.  However, this would
    //    contradict our map invariant which says that no symbol in the map is
    //    a sub-symbol of any other.
    // 9) Therefore, the found key must match the match key.
    //
    // The above proof assumes the match key exists.  In the case that the
    // match key does not exist, then step (1) will return some other symbol.
    // That symbol cannot be a super-symbol of the search key since if it were,
    // then it would be a match, and we're assuming the match key doesn't exist.
    // Therefore, step 2 will correctly return no match.

    // Find the last entry in the by_symbol_ map whose key is less than or
    // equal to the given name.
    typename map<string, Value>::iterator FindLastLessOrEqual(
        const string& name);

    // True if either the arguments are equal or super_symbol identifies a
    // parent symbol of sub_symbol (e.g. "foo.bar" is a parent of
    // "foo.bar.baz", but not a parent of "foo.barbaz").
    bool IsSubSymbol(const string& sub_symbol, const string& super_symbol);

    // Returns true if and only if all characters in the name are alphanumerics,
    // underscores, or periods.
    bool ValidateSymbolName(const string& name);
  };


  DescriptorIndex<const FileDescriptorProto*> index_;
  vector<const FileDescriptorProto*> files_to_delete_;

  // If file is non-NULL, copy it into *output and return true, otherwise
  // return false.
  bool MaybeCopy(const FileDescriptorProto* file,
                 FileDescriptorProto* output);

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(SimpleDescriptorDatabase);
};

// Very similar to SimpleDescriptorDatabase, but stores all the descriptors
// as raw bytes and generally tries to use as little memory as possible.
//
// The same caveats regarding FindFileContainingExtension() apply as with
// SimpleDescriptorDatabase.
class LIBPROTOBUF_EXPORT EncodedDescriptorDatabase : public DescriptorDatabase {
 public:
  EncodedDescriptorDatabase();
  ~EncodedDescriptorDatabase();

  // Adds the FileDescriptorProto to the database.  The descriptor is provided
  // in encoded form.  The database does not make a copy of the bytes, nor
  // does it take ownership; it's up to the caller to make sure the bytes
  // remain valid for the life of the database.  Returns false and logs an error
  // if the bytes are not a valid FileDescriptorProto or if the file conflicted
  // with a file already in the database.
  bool Add(const void* encoded_file_descriptor, int size);

  // Like Add(), but makes a copy of the data, so that the caller does not
  // need to keep it around.
  bool AddCopy(const void* encoded_file_descriptor, int size);

  // Like FindFileContainingSymbol but returns only the name of the file.
  bool FindNameOfFileContainingSymbol(const string& symbol_name,
                                      string* output);

  // implements DescriptorDatabase -----------------------------------
  bool FindFileByName(const string& filename,
                      FileDescriptorProto* output);
  bool FindFileContainingSymbol(const string& symbol_name,
                                FileDescriptorProto* output);
  bool FindFileContainingExtension(const string& containing_type,
                                   int field_number,
                                   FileDescriptorProto* output);
  bool FindAllExtensionNumbers(const string& extendee_type,
                               vector<int>* output);

 private:
  SimpleDescriptorDatabase::DescriptorIndex<pair<const void*, int> > index_;
  vector<void*> files_to_delete_;

  // If encoded_file.first is non-NULL, parse the data into *output and return
  // true, otherwise return false.
  bool MaybeParse(pair<const void*, int> encoded_file,
                  FileDescriptorProto* output);

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(EncodedDescriptorDatabase);
};

// A DescriptorDatabase that fetches files from a given pool.
class LIBPROTOBUF_EXPORT DescriptorPoolDatabase : public DescriptorDatabase {
 public:
  DescriptorPoolDatabase(const DescriptorPool& pool);
  ~DescriptorPoolDatabase();

  // implements DescriptorDatabase -----------------------------------
  bool FindFileByName(const string& filename,
                      FileDescriptorProto* output);
  bool FindFileContainingSymbol(const string& symbol_name,
                                FileDescriptorProto* output);
  bool FindFileContainingExtension(const string& containing_type,
                                   int field_number,
                                   FileDescriptorProto* output);
  bool FindAllExtensionNumbers(const string& extendee_type,
                               vector<int>* output);

 private:
  const DescriptorPool& pool_;
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(DescriptorPoolDatabase);
};

// A DescriptorDatabase that wraps two or more others.  It first searches the
// first database and, if that fails, tries the second, and so on.
class LIBPROTOBUF_EXPORT MergedDescriptorDatabase : public DescriptorDatabase {
 public:
  // Merge just two databases.  The sources remain property of the caller.
  MergedDescriptorDatabase(DescriptorDatabase* source1,
                           DescriptorDatabase* source2);
  // Merge more than two databases.  The sources remain property of the caller.
  // The vector may be deleted after the constructor returns but the
  // DescriptorDatabases need to stick around.
  MergedDescriptorDatabase(const vector<DescriptorDatabase*>& sources);
  ~MergedDescriptorDatabase();

  // implements DescriptorDatabase -----------------------------------
  bool FindFileByName(const string& filename,
                      FileDescriptorProto* output);
  bool FindFileContainingSymbol(const string& symbol_name,
                                FileDescriptorProto* output);
  bool FindFileContainingExtension(const string& containing_type,
                                   int field_number,
                                   FileDescriptorProto* output);
  // Merges the results of calling all databases. Returns true iff any
  // of the databases returned true.
  bool FindAllExtensionNumbers(const string& extendee_type,
                               vector<int>* output);

 private:
  vector<DescriptorDatabase*> sources_;
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(MergedDescriptorDatabase);
};

}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_DESCRIPTOR_DATABASE_H__
