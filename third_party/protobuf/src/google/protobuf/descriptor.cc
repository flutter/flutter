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
#include <map>
#include <set>
#include <vector>
#include <algorithm>
#include <limits>

#include <google/protobuf/descriptor.h>
#include <google/protobuf/descriptor_database.h>
#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/dynamic_message.h>
#include <google/protobuf/text_format.h>
#include <google/protobuf/unknown_field_set.h>
#include <google/protobuf/wire_format.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/io/tokenizer.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/once.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/stubs/substitute.h>
#include <google/protobuf/stubs/map-util.h>
#include <google/protobuf/stubs/stl_util.h>

#undef PACKAGE  // autoheader #defines this.  :(

namespace google {
namespace protobuf {

const FieldDescriptor::CppType
FieldDescriptor::kTypeToCppTypeMap[MAX_TYPE + 1] = {
  static_cast<CppType>(0),  // 0 is reserved for errors

  CPPTYPE_DOUBLE,   // TYPE_DOUBLE
  CPPTYPE_FLOAT,    // TYPE_FLOAT
  CPPTYPE_INT64,    // TYPE_INT64
  CPPTYPE_UINT64,   // TYPE_UINT64
  CPPTYPE_INT32,    // TYPE_INT32
  CPPTYPE_UINT64,   // TYPE_FIXED64
  CPPTYPE_UINT32,   // TYPE_FIXED32
  CPPTYPE_BOOL,     // TYPE_BOOL
  CPPTYPE_STRING,   // TYPE_STRING
  CPPTYPE_MESSAGE,  // TYPE_GROUP
  CPPTYPE_MESSAGE,  // TYPE_MESSAGE
  CPPTYPE_STRING,   // TYPE_BYTES
  CPPTYPE_UINT32,   // TYPE_UINT32
  CPPTYPE_ENUM,     // TYPE_ENUM
  CPPTYPE_INT32,    // TYPE_SFIXED32
  CPPTYPE_INT64,    // TYPE_SFIXED64
  CPPTYPE_INT32,    // TYPE_SINT32
  CPPTYPE_INT64,    // TYPE_SINT64
};

const char * const FieldDescriptor::kTypeToName[MAX_TYPE + 1] = {
  "ERROR",     // 0 is reserved for errors

  "double",    // TYPE_DOUBLE
  "float",     // TYPE_FLOAT
  "int64",     // TYPE_INT64
  "uint64",    // TYPE_UINT64
  "int32",     // TYPE_INT32
  "fixed64",   // TYPE_FIXED64
  "fixed32",   // TYPE_FIXED32
  "bool",      // TYPE_BOOL
  "string",    // TYPE_STRING
  "group",     // TYPE_GROUP
  "message",   // TYPE_MESSAGE
  "bytes",     // TYPE_BYTES
  "uint32",    // TYPE_UINT32
  "enum",      // TYPE_ENUM
  "sfixed32",  // TYPE_SFIXED32
  "sfixed64",  // TYPE_SFIXED64
  "sint32",    // TYPE_SINT32
  "sint64",    // TYPE_SINT64
};

const char * const FieldDescriptor::kCppTypeToName[MAX_CPPTYPE + 1] = {
  "ERROR",     // 0 is reserved for errors

  "int32",     // CPPTYPE_INT32
  "int64",     // CPPTYPE_INT64
  "uint32",    // CPPTYPE_UINT32
  "uint64",    // CPPTYPE_UINT64
  "double",    // CPPTYPE_DOUBLE
  "float",     // CPPTYPE_FLOAT
  "bool",      // CPPTYPE_BOOL
  "enum",      // CPPTYPE_ENUM
  "string",    // CPPTYPE_STRING
  "message",   // CPPTYPE_MESSAGE
};

const char * const FieldDescriptor::kLabelToName[MAX_LABEL + 1] = {
  "ERROR",     // 0 is reserved for errors

  "optional",  // LABEL_OPTIONAL
  "required",  // LABEL_REQUIRED
  "repeated",  // LABEL_REPEATED
};

#ifndef _MSC_VER  // MSVC doesn't need these and won't even accept them.
const int FieldDescriptor::kMaxNumber;
const int FieldDescriptor::kFirstReservedNumber;
const int FieldDescriptor::kLastReservedNumber;
#endif

namespace {

string ToCamelCase(const string& input) {
  bool capitalize_next = false;
  string result;
  result.reserve(input.size());

  for (int i = 0; i < input.size(); i++) {
    if (input[i] == '_') {
      capitalize_next = true;
    } else if (capitalize_next) {
      // Note:  I distrust ctype.h due to locales.
      if ('a' <= input[i] && input[i] <= 'z') {
        result.push_back(input[i] - 'a' + 'A');
      } else {
        result.push_back(input[i]);
      }
      capitalize_next = false;
    } else {
      result.push_back(input[i]);
    }
  }

  // Lower-case the first letter.
  if (!result.empty() && 'A' <= result[0] && result[0] <= 'Z') {
    result[0] = result[0] - 'A' + 'a';
  }

  return result;
}

// A DescriptorPool contains a bunch of hash_maps to implement the
// various Find*By*() methods.  Since hashtable lookups are O(1), it's
// most efficient to construct a fixed set of large hash_maps used by
// all objects in the pool rather than construct one or more small
// hash_maps for each object.
//
// The keys to these hash_maps are (parent, name) or (parent, number)
// pairs.  Unfortunately STL doesn't provide hash functions for pair<>,
// so we must invent our own.
//
// TODO(kenton):  Use StringPiece rather than const char* in keys?  It would
//   be a lot cleaner but we'd just have to convert it back to const char*
//   for the open source release.

typedef pair<const void*, const char*> PointerStringPair;

struct PointerStringPairEqual {
  inline bool operator()(const PointerStringPair& a,
                         const PointerStringPair& b) const {
    return a.first == b.first && strcmp(a.second, b.second) == 0;
  }
};

template<typename PairType>
struct PointerIntegerPairHash {
  size_t operator()(const PairType& p) const {
    // FIXME(kenton):  What is the best way to compute this hash?  I have
    // no idea!  This seems a bit better than an XOR.
    return reinterpret_cast<intptr_t>(p.first) * ((1 << 16) - 1) + p.second;
  }

  // Used only by MSVC and platforms where hash_map is not available.
  static const size_t bucket_size = 4;
  static const size_t min_buckets = 8;
  inline bool operator()(const PairType& a, const PairType& b) const {
    return a.first < b.first ||
          (a.first == b.first && a.second < b.second);
  }
};

typedef pair<const Descriptor*, int> DescriptorIntPair;
typedef pair<const EnumDescriptor*, int> EnumIntPair;

struct PointerStringPairHash {
  size_t operator()(const PointerStringPair& p) const {
    // FIXME(kenton):  What is the best way to compute this hash?  I have
    // no idea!  This seems a bit better than an XOR.
    hash<const char*> cstring_hash;
    return reinterpret_cast<intptr_t>(p.first) * ((1 << 16) - 1) +
           cstring_hash(p.second);
  }

  // Used only by MSVC and platforms where hash_map is not available.
  static const size_t bucket_size = 4;
  static const size_t min_buckets = 8;
  inline bool operator()(const PointerStringPair& a,
                         const PointerStringPair& b) const {
    if (a.first < b.first) return true;
    if (a.first > b.first) return false;
    return strcmp(a.second, b.second) < 0;
  }
};


struct Symbol {
  enum Type {
    NULL_SYMBOL, MESSAGE, FIELD, ENUM, ENUM_VALUE, SERVICE, METHOD,
    PACKAGE
  };
  Type type;
  union {
    const Descriptor* descriptor;
    const FieldDescriptor* field_descriptor;
    const EnumDescriptor* enum_descriptor;
    const EnumValueDescriptor* enum_value_descriptor;
    const ServiceDescriptor* service_descriptor;
    const MethodDescriptor* method_descriptor;
    const FileDescriptor* package_file_descriptor;
  };

  inline Symbol() : type(NULL_SYMBOL) { descriptor = NULL; }
  inline bool IsNull() const { return type == NULL_SYMBOL; }
  inline bool IsType() const {
    return type == MESSAGE || type == ENUM;
  }
  inline bool IsAggregate() const {
    return type == MESSAGE || type == PACKAGE
        || type == ENUM || type == SERVICE;
  }

#define CONSTRUCTOR(TYPE, TYPE_CONSTANT, FIELD)  \
  inline explicit Symbol(const TYPE* value) {    \
    type = TYPE_CONSTANT;                        \
    this->FIELD = value;                         \
  }

  CONSTRUCTOR(Descriptor         , MESSAGE   , descriptor             )
  CONSTRUCTOR(FieldDescriptor    , FIELD     , field_descriptor       )
  CONSTRUCTOR(EnumDescriptor     , ENUM      , enum_descriptor        )
  CONSTRUCTOR(EnumValueDescriptor, ENUM_VALUE, enum_value_descriptor  )
  CONSTRUCTOR(ServiceDescriptor  , SERVICE   , service_descriptor     )
  CONSTRUCTOR(MethodDescriptor   , METHOD    , method_descriptor      )
  CONSTRUCTOR(FileDescriptor     , PACKAGE   , package_file_descriptor)
#undef CONSTRUCTOR

  const FileDescriptor* GetFile() const {
    switch (type) {
      case NULL_SYMBOL: return NULL;
      case MESSAGE    : return descriptor           ->file();
      case FIELD      : return field_descriptor     ->file();
      case ENUM       : return enum_descriptor      ->file();
      case ENUM_VALUE : return enum_value_descriptor->type()->file();
      case SERVICE    : return service_descriptor   ->file();
      case METHOD     : return method_descriptor    ->service()->file();
      case PACKAGE    : return package_file_descriptor;
    }
    return NULL;
  }
};

const Symbol kNullSymbol;

typedef hash_map<const char*, Symbol,
                 hash<const char*>, streq>
  SymbolsByNameMap;
typedef hash_map<PointerStringPair, Symbol,
                 PointerStringPairHash, PointerStringPairEqual>
  SymbolsByParentMap;
typedef hash_map<const char*, const FileDescriptor*,
                 hash<const char*>, streq>
  FilesByNameMap;
typedef hash_map<PointerStringPair, const FieldDescriptor*,
                 PointerStringPairHash, PointerStringPairEqual>
  FieldsByNameMap;
typedef hash_map<DescriptorIntPair, const FieldDescriptor*,
                 PointerIntegerPairHash<DescriptorIntPair> >
  FieldsByNumberMap;
typedef hash_map<EnumIntPair, const EnumValueDescriptor*,
                 PointerIntegerPairHash<EnumIntPair> >
  EnumValuesByNumberMap;
// This is a map rather than a hash_map, since we use it to iterate
// through all the extensions that extend a given Descriptor, and an
// ordered data structure that implements lower_bound is convenient
// for that.
typedef map<DescriptorIntPair, const FieldDescriptor*>
  ExtensionsGroupedByDescriptorMap;

}  // anonymous namespace

// ===================================================================
// DescriptorPool::Tables

class DescriptorPool::Tables {
 public:
  Tables();
  ~Tables();

  // Record the current state of the tables to the stack of checkpoints.
  // Each call to AddCheckpoint() must be paired with exactly one call to either
  // ClearLastCheckpoint() or RollbackToLastCheckpoint().
  //
  // This is used when building files, since some kinds of validation errors
  // cannot be detected until the file's descriptors have already been added to
  // the tables.
  //
  // This supports recursive checkpoints, since building a file may trigger
  // recursive building of other files. Note that recursive checkpoints are not
  // normally necessary; explicit dependencies are built prior to checkpointing.
  // So although we recursively build transitive imports, there is at most one
  // checkpoint in the stack during dependency building.
  //
  // Recursive checkpoints only arise during cross-linking of the descriptors.
  // Symbol references must be resolved, via DescriptorBuilder::FindSymbol and
  // friends. If the pending file references an unknown symbol
  // (e.g., it is not defined in the pending file's explicit dependencies), and
  // the pool is using a fallback database, and that database contains a file
  // defining that symbol, and that file has not yet been built by the pool,
  // the pool builds the file during cross-linking, leading to another
  // checkpoint.
  void AddCheckpoint();

  // Mark the last checkpoint as having cleared successfully, removing it from
  // the stack. If the stack is empty, all pending symbols will be committed.
  //
  // Note that this does not guarantee that the symbols added since the last
  // checkpoint won't be rolled back: if a checkpoint gets rolled back,
  // everything past that point gets rolled back, including symbols added after
  // checkpoints that were pushed onto the stack after it and marked as cleared.
  void ClearLastCheckpoint();

  // Roll back the Tables to the state of the checkpoint at the top of the
  // stack, removing everything that was added after that point.
  void RollbackToLastCheckpoint();

  // The stack of files which are currently being built.  Used to detect
  // cyclic dependencies when loading files from a DescriptorDatabase.  Not
  // used when fallback_database_ == NULL.
  vector<string> pending_files_;

  // A set of files which we have tried to load from the fallback database
  // and encountered errors.  We will not attempt to load them again.
  // Not used when fallback_database_ == NULL.
  hash_set<string> known_bad_files_;

  // The set of descriptors for which we've already loaded the full
  // set of extensions numbers from fallback_database_.
  hash_set<const Descriptor*> extensions_loaded_from_db_;

  // -----------------------------------------------------------------
  // Finding items.

  // Find symbols.  This returns a null Symbol (symbol.IsNull() is true)
  // if not found.
  inline Symbol FindSymbol(const string& key) const;

  // This implements the body of DescriptorPool::Find*ByName().  It should
  // really be a private method of DescriptorPool, but that would require
  // declaring Symbol in descriptor.h, which would drag all kinds of other
  // stuff into the header.  Yay C++.
  Symbol FindByNameHelper(
    const DescriptorPool* pool, const string& name) const;

  // These return NULL if not found.
  inline const FileDescriptor* FindFile(const string& key) const;
  inline const FieldDescriptor* FindExtension(const Descriptor* extendee,
                                              int number);
  inline void FindAllExtensions(const Descriptor* extendee,
                                vector<const FieldDescriptor*>* out) const;

  // -----------------------------------------------------------------
  // Adding items.

  // These add items to the corresponding tables.  They return false if
  // the key already exists in the table.  For AddSymbol(), the string passed
  // in must be one that was constructed using AllocateString(), as it will
  // be used as a key in the symbols_by_name_ map without copying.
  bool AddSymbol(const string& full_name, Symbol symbol);
  bool AddFile(const FileDescriptor* file);
  bool AddExtension(const FieldDescriptor* field);

  // -----------------------------------------------------------------
  // Allocating memory.

  // Allocate an object which will be reclaimed when the pool is
  // destroyed.  Note that the object's destructor will never be called,
  // so its fields must be plain old data (primitive data types and
  // pointers).  All of the descriptor types are such objects.
  template<typename Type> Type* Allocate();

  // Allocate an array of objects which will be reclaimed when the
  // pool in destroyed.  Again, destructors are never called.
  template<typename Type> Type* AllocateArray(int count);

  // Allocate a string which will be destroyed when the pool is destroyed.
  // The string is initialized to the given value for convenience.
  string* AllocateString(const string& value);

  // Allocate a protocol message object.  Some older versions of GCC have
  // trouble understanding explicit template instantiations in some cases, so
  // in those cases we have to pass a dummy pointer of the right type as the
  // parameter instead of specifying the type explicitly.
  template<typename Type> Type* AllocateMessage(Type* dummy = NULL);

  // Allocate a FileDescriptorTables object.
  FileDescriptorTables* AllocateFileTables();

 private:
  vector<string*> strings_;    // All strings in the pool.
  vector<Message*> messages_;  // All messages in the pool.
  vector<FileDescriptorTables*> file_tables_;  // All file tables in the pool.
  vector<void*> allocations_;  // All other memory allocated in the pool.

  SymbolsByNameMap      symbols_by_name_;
  FilesByNameMap        files_by_name_;
  ExtensionsGroupedByDescriptorMap extensions_;

  struct CheckPoint {
    explicit CheckPoint(const Tables* tables)
      : strings_before_checkpoint(tables->strings_.size()),
        messages_before_checkpoint(tables->messages_.size()),
        file_tables_before_checkpoint(tables->file_tables_.size()),
        allocations_before_checkpoint(tables->allocations_.size()),
        pending_symbols_before_checkpoint(
            tables->symbols_after_checkpoint_.size()),
        pending_files_before_checkpoint(
            tables->files_after_checkpoint_.size()),
        pending_extensions_before_checkpoint(
            tables->extensions_after_checkpoint_.size()) {
    }
    int strings_before_checkpoint;
    int messages_before_checkpoint;
    int file_tables_before_checkpoint;
    int allocations_before_checkpoint;
    int pending_symbols_before_checkpoint;
    int pending_files_before_checkpoint;
    int pending_extensions_before_checkpoint;
  };
  vector<CheckPoint> checkpoints_;
  vector<const char*      > symbols_after_checkpoint_;
  vector<const char*      > files_after_checkpoint_;
  vector<DescriptorIntPair> extensions_after_checkpoint_;

  // Allocate some bytes which will be reclaimed when the pool is
  // destroyed.
  void* AllocateBytes(int size);
};

// Contains tables specific to a particular file.  These tables are not
// modified once the file has been constructed, so they need not be
// protected by a mutex.  This makes operations that depend only on the
// contents of a single file -- e.g. Descriptor::FindFieldByName() --
// lock-free.
//
// For historical reasons, the definitions of the methods of
// FileDescriptorTables and DescriptorPool::Tables are interleaved below.
// These used to be a single class.
class FileDescriptorTables {
 public:
  FileDescriptorTables();
  ~FileDescriptorTables();

  // Empty table, used with placeholder files.
  static const FileDescriptorTables kEmpty;

  // -----------------------------------------------------------------
  // Finding items.

  // Find symbols.  These return a null Symbol (symbol.IsNull() is true)
  // if not found.
  inline Symbol FindNestedSymbol(const void* parent,
                                 const string& name) const;
  inline Symbol FindNestedSymbolOfType(const void* parent,
                                       const string& name,
                                       const Symbol::Type type) const;

  // These return NULL if not found.
  inline const FieldDescriptor* FindFieldByNumber(
    const Descriptor* parent, int number) const;
  inline const FieldDescriptor* FindFieldByLowercaseName(
    const void* parent, const string& lowercase_name) const;
  inline const FieldDescriptor* FindFieldByCamelcaseName(
    const void* parent, const string& camelcase_name) const;
  inline const EnumValueDescriptor* FindEnumValueByNumber(
    const EnumDescriptor* parent, int number) const;

  // -----------------------------------------------------------------
  // Adding items.

  // These add items to the corresponding tables.  They return false if
  // the key already exists in the table.  For AddAliasUnderParent(), the
  // string passed in must be one that was constructed using AllocateString(),
  // as it will be used as a key in the symbols_by_parent_ map without copying.
  bool AddAliasUnderParent(const void* parent, const string& name,
                           Symbol symbol);
  bool AddFieldByNumber(const FieldDescriptor* field);
  bool AddEnumValueByNumber(const EnumValueDescriptor* value);

  // Adds the field to the lowercase_name and camelcase_name maps.  Never
  // fails because we allow duplicates; the first field by the name wins.
  void AddFieldByStylizedNames(const FieldDescriptor* field);

 private:
  SymbolsByParentMap    symbols_by_parent_;
  FieldsByNameMap       fields_by_lowercase_name_;
  FieldsByNameMap       fields_by_camelcase_name_;
  FieldsByNumberMap     fields_by_number_;       // Not including extensions.
  EnumValuesByNumberMap enum_values_by_number_;
};

DescriptorPool::Tables::Tables()
    // Start some hash_map and hash_set objects with a small # of buckets
    : known_bad_files_(3),
      extensions_loaded_from_db_(3),
      symbols_by_name_(3),
      files_by_name_(3) {}


DescriptorPool::Tables::~Tables() {
  GOOGLE_DCHECK(checkpoints_.empty());
  // Note that the deletion order is important, since the destructors of some
  // messages may refer to objects in allocations_.
  STLDeleteElements(&messages_);
  for (int i = 0; i < allocations_.size(); i++) {
    operator delete(allocations_[i]);
  }
  STLDeleteElements(&strings_);
  STLDeleteElements(&file_tables_);
}

FileDescriptorTables::FileDescriptorTables()
    // Initialize all the hash tables to start out with a small # of buckets
    : symbols_by_parent_(3),
      fields_by_lowercase_name_(3),
      fields_by_camelcase_name_(3),
      fields_by_number_(3),
      enum_values_by_number_(3) {
}

FileDescriptorTables::~FileDescriptorTables() {}

const FileDescriptorTables FileDescriptorTables::kEmpty;

void DescriptorPool::Tables::AddCheckpoint() {
  checkpoints_.push_back(CheckPoint(this));
}

void DescriptorPool::Tables::ClearLastCheckpoint() {
  GOOGLE_DCHECK(!checkpoints_.empty());
  checkpoints_.pop_back();
  if (checkpoints_.empty()) {
    // All checkpoints have been cleared: we can now commit all of the pending
    // data.
    symbols_after_checkpoint_.clear();
    files_after_checkpoint_.clear();
    extensions_after_checkpoint_.clear();
  }
}

void DescriptorPool::Tables::RollbackToLastCheckpoint() {
  GOOGLE_DCHECK(!checkpoints_.empty());
  const CheckPoint& checkpoint = checkpoints_.back();

  for (int i = checkpoint.pending_symbols_before_checkpoint;
       i < symbols_after_checkpoint_.size();
       i++) {
    symbols_by_name_.erase(symbols_after_checkpoint_[i]);
  }
  for (int i = checkpoint.pending_files_before_checkpoint;
       i < files_after_checkpoint_.size();
       i++) {
    files_by_name_.erase(files_after_checkpoint_[i]);
  }
  for (int i = checkpoint.pending_extensions_before_checkpoint;
       i < extensions_after_checkpoint_.size();
       i++) {
    extensions_.erase(extensions_after_checkpoint_[i]);
  }

  symbols_after_checkpoint_.resize(
      checkpoint.pending_symbols_before_checkpoint);
  files_after_checkpoint_.resize(checkpoint.pending_files_before_checkpoint);
  extensions_after_checkpoint_.resize(
      checkpoint.pending_extensions_before_checkpoint);

  STLDeleteContainerPointers(
      strings_.begin() + checkpoint.strings_before_checkpoint, strings_.end());
  STLDeleteContainerPointers(
      messages_.begin() + checkpoint.messages_before_checkpoint,
      messages_.end());
  STLDeleteContainerPointers(
      file_tables_.begin() + checkpoint.file_tables_before_checkpoint,
      file_tables_.end());
  for (int i = checkpoint.allocations_before_checkpoint;
       i < allocations_.size();
       i++) {
    operator delete(allocations_[i]);
  }

  strings_.resize(checkpoint.strings_before_checkpoint);
  messages_.resize(checkpoint.messages_before_checkpoint);
  file_tables_.resize(checkpoint.file_tables_before_checkpoint);
  allocations_.resize(checkpoint.allocations_before_checkpoint);
  checkpoints_.pop_back();
}

// -------------------------------------------------------------------

inline Symbol DescriptorPool::Tables::FindSymbol(const string& key) const {
  const Symbol* result = FindOrNull(symbols_by_name_, key.c_str());
  if (result == NULL) {
    return kNullSymbol;
  } else {
    return *result;
  }
}

inline Symbol FileDescriptorTables::FindNestedSymbol(
    const void* parent, const string& name) const {
  const Symbol* result =
    FindOrNull(symbols_by_parent_, PointerStringPair(parent, name.c_str()));
  if (result == NULL) {
    return kNullSymbol;
  } else {
    return *result;
  }
}

inline Symbol FileDescriptorTables::FindNestedSymbolOfType(
    const void* parent, const string& name, const Symbol::Type type) const {
  Symbol result = FindNestedSymbol(parent, name);
  if (result.type != type) return kNullSymbol;
  return result;
}

Symbol DescriptorPool::Tables::FindByNameHelper(
    const DescriptorPool* pool, const string& name) const {
  MutexLockMaybe lock(pool->mutex_);
  Symbol result = FindSymbol(name);

  if (result.IsNull() && pool->underlay_ != NULL) {
    // Symbol not found; check the underlay.
    result =
      pool->underlay_->tables_->FindByNameHelper(pool->underlay_, name);
  }

  if (result.IsNull()) {
    // Symbol still not found, so check fallback database.
    if (pool->TryFindSymbolInFallbackDatabase(name)) {
      result = FindSymbol(name);
    }
  }

  return result;
}

inline const FileDescriptor* DescriptorPool::Tables::FindFile(
    const string& key) const {
  return FindPtrOrNull(files_by_name_, key.c_str());
}

inline const FieldDescriptor* FileDescriptorTables::FindFieldByNumber(
    const Descriptor* parent, int number) const {
  return FindPtrOrNull(fields_by_number_, make_pair(parent, number));
}

inline const FieldDescriptor* FileDescriptorTables::FindFieldByLowercaseName(
    const void* parent, const string& lowercase_name) const {
  return FindPtrOrNull(fields_by_lowercase_name_,
                       PointerStringPair(parent, lowercase_name.c_str()));
}

inline const FieldDescriptor* FileDescriptorTables::FindFieldByCamelcaseName(
    const void* parent, const string& camelcase_name) const {
  return FindPtrOrNull(fields_by_camelcase_name_,
                       PointerStringPair(parent, camelcase_name.c_str()));
}

inline const EnumValueDescriptor* FileDescriptorTables::FindEnumValueByNumber(
    const EnumDescriptor* parent, int number) const {
  return FindPtrOrNull(enum_values_by_number_, make_pair(parent, number));
}

inline const FieldDescriptor* DescriptorPool::Tables::FindExtension(
    const Descriptor* extendee, int number) {
  return FindPtrOrNull(extensions_, make_pair(extendee, number));
}

inline void DescriptorPool::Tables::FindAllExtensions(
    const Descriptor* extendee, vector<const FieldDescriptor*>* out) const {
  ExtensionsGroupedByDescriptorMap::const_iterator it =
      extensions_.lower_bound(make_pair(extendee, 0));
  for (; it != extensions_.end() && it->first.first == extendee; ++it) {
    out->push_back(it->second);
  }
}

// -------------------------------------------------------------------

bool DescriptorPool::Tables::AddSymbol(
    const string& full_name, Symbol symbol) {
  if (InsertIfNotPresent(&symbols_by_name_, full_name.c_str(), symbol)) {
    symbols_after_checkpoint_.push_back(full_name.c_str());
    return true;
  } else {
    return false;
  }
}

bool FileDescriptorTables::AddAliasUnderParent(
    const void* parent, const string& name, Symbol symbol) {
  PointerStringPair by_parent_key(parent, name.c_str());
  return InsertIfNotPresent(&symbols_by_parent_, by_parent_key, symbol);
}

bool DescriptorPool::Tables::AddFile(const FileDescriptor* file) {
  if (InsertIfNotPresent(&files_by_name_, file->name().c_str(), file)) {
    files_after_checkpoint_.push_back(file->name().c_str());
    return true;
  } else {
    return false;
  }
}

void FileDescriptorTables::AddFieldByStylizedNames(
    const FieldDescriptor* field) {
  const void* parent;
  if (field->is_extension()) {
    if (field->extension_scope() == NULL) {
      parent = field->file();
    } else {
      parent = field->extension_scope();
    }
  } else {
    parent = field->containing_type();
  }

  PointerStringPair lowercase_key(parent, field->lowercase_name().c_str());
  InsertIfNotPresent(&fields_by_lowercase_name_, lowercase_key, field);

  PointerStringPair camelcase_key(parent, field->camelcase_name().c_str());
  InsertIfNotPresent(&fields_by_camelcase_name_, camelcase_key, field);
}

bool FileDescriptorTables::AddFieldByNumber(const FieldDescriptor* field) {
  DescriptorIntPair key(field->containing_type(), field->number());
  return InsertIfNotPresent(&fields_by_number_, key, field);
}

bool FileDescriptorTables::AddEnumValueByNumber(
    const EnumValueDescriptor* value) {
  EnumIntPair key(value->type(), value->number());
  return InsertIfNotPresent(&enum_values_by_number_, key, value);
}

bool DescriptorPool::Tables::AddExtension(const FieldDescriptor* field) {
  DescriptorIntPair key(field->containing_type(), field->number());
  if (InsertIfNotPresent(&extensions_, key, field)) {
    extensions_after_checkpoint_.push_back(key);
    return true;
  } else {
    return false;
  }
}

// -------------------------------------------------------------------

template<typename Type>
Type* DescriptorPool::Tables::Allocate() {
  return reinterpret_cast<Type*>(AllocateBytes(sizeof(Type)));
}

template<typename Type>
Type* DescriptorPool::Tables::AllocateArray(int count) {
  return reinterpret_cast<Type*>(AllocateBytes(sizeof(Type) * count));
}

string* DescriptorPool::Tables::AllocateString(const string& value) {
  string* result = new string(value);
  strings_.push_back(result);
  return result;
}

template<typename Type>
Type* DescriptorPool::Tables::AllocateMessage(Type* dummy) {
  Type* result = new Type;
  messages_.push_back(result);
  return result;
}

FileDescriptorTables* DescriptorPool::Tables::AllocateFileTables() {
  FileDescriptorTables* result = new FileDescriptorTables;
  file_tables_.push_back(result);
  return result;
}

void* DescriptorPool::Tables::AllocateBytes(int size) {
  // TODO(kenton):  Would it be worthwhile to implement this in some more
  // sophisticated way?  Probably not for the open source release, but for
  // internal use we could easily plug in one of our existing memory pool
  // allocators...
  if (size == 0) return NULL;

  void* result = operator new(size);
  allocations_.push_back(result);
  return result;
}

// ===================================================================
// DescriptorPool

DescriptorPool::ErrorCollector::~ErrorCollector() {}

DescriptorPool::DescriptorPool()
  : mutex_(NULL),
    fallback_database_(NULL),
    default_error_collector_(NULL),
    underlay_(NULL),
    tables_(new Tables),
    enforce_dependencies_(true),
    allow_unknown_(false) {}

DescriptorPool::DescriptorPool(DescriptorDatabase* fallback_database,
                               ErrorCollector* error_collector)
  : mutex_(new Mutex),
    fallback_database_(fallback_database),
    default_error_collector_(error_collector),
    underlay_(NULL),
    tables_(new Tables),
    enforce_dependencies_(true),
    allow_unknown_(false) {
}

DescriptorPool::DescriptorPool(const DescriptorPool* underlay)
  : mutex_(NULL),
    fallback_database_(NULL),
    default_error_collector_(NULL),
    underlay_(underlay),
    tables_(new Tables),
    enforce_dependencies_(true),
    allow_unknown_(false) {}

DescriptorPool::~DescriptorPool() {
  if (mutex_ != NULL) delete mutex_;
}

// DescriptorPool::BuildFile() defined later.
// DescriptorPool::BuildFileCollectingErrors() defined later.

void DescriptorPool::InternalDontEnforceDependencies() {
  enforce_dependencies_ = false;
}

bool DescriptorPool::InternalIsFileLoaded(const string& filename) const {
  MutexLockMaybe lock(mutex_);
  return tables_->FindFile(filename) != NULL;
}

// generated_pool ====================================================

namespace {


EncodedDescriptorDatabase* generated_database_ = NULL;
DescriptorPool* generated_pool_ = NULL;
GOOGLE_PROTOBUF_DECLARE_ONCE(generated_pool_init_);

void DeleteGeneratedPool() {
  delete generated_database_;
  generated_database_ = NULL;
  delete generated_pool_;
  generated_pool_ = NULL;
}

static void InitGeneratedPool() {
  generated_database_ = new EncodedDescriptorDatabase;
  generated_pool_ = new DescriptorPool(generated_database_);

  internal::OnShutdown(&DeleteGeneratedPool);
}

inline void InitGeneratedPoolOnce() {
  ::google::protobuf::GoogleOnceInit(&generated_pool_init_, &InitGeneratedPool);
}

}  // anonymous namespace

const DescriptorPool* DescriptorPool::generated_pool() {
  InitGeneratedPoolOnce();
  return generated_pool_;
}

DescriptorPool* DescriptorPool::internal_generated_pool() {
  InitGeneratedPoolOnce();
  return generated_pool_;
}

void DescriptorPool::InternalAddGeneratedFile(
    const void* encoded_file_descriptor, int size) {
  // So, this function is called in the process of initializing the
  // descriptors for generated proto classes.  Each generated .pb.cc file
  // has an internal procedure called AddDescriptors() which is called at
  // process startup, and that function calls this one in order to register
  // the raw bytes of the FileDescriptorProto representing the file.
  //
  // We do not actually construct the descriptor objects right away.  We just
  // hang on to the bytes until they are actually needed.  We actually construct
  // the descriptor the first time one of the following things happens:
  // * Someone calls a method like descriptor(), GetDescriptor(), or
  //   GetReflection() on the generated types, which requires returning the
  //   descriptor or an object based on it.
  // * Someone looks up the descriptor in DescriptorPool::generated_pool().
  //
  // Once one of these happens, the DescriptorPool actually parses the
  // FileDescriptorProto and generates a FileDescriptor (and all its children)
  // based on it.
  //
  // Note that FileDescriptorProto is itself a generated protocol message.
  // Therefore, when we parse one, we have to be very careful to avoid using
  // any descriptor-based operations, since this might cause infinite recursion
  // or deadlock.
  InitGeneratedPoolOnce();
  GOOGLE_CHECK(generated_database_->Add(encoded_file_descriptor, size));
}


// Find*By* methods ==================================================

// TODO(kenton):  There's a lot of repeated code here, but I'm not sure if
//   there's any good way to factor it out.  Think about this some time when
//   there's nothing more important to do (read: never).

const FileDescriptor* DescriptorPool::FindFileByName(const string& name) const {
  MutexLockMaybe lock(mutex_);
  const FileDescriptor* result = tables_->FindFile(name);
  if (result != NULL) return result;
  if (underlay_ != NULL) {
    result = underlay_->FindFileByName(name);
    if (result != NULL) return result;
  }
  if (TryFindFileInFallbackDatabase(name)) {
    result = tables_->FindFile(name);
    if (result != NULL) return result;
  }
  return NULL;
}

const FileDescriptor* DescriptorPool::FindFileContainingSymbol(
    const string& symbol_name) const {
  MutexLockMaybe lock(mutex_);
  Symbol result = tables_->FindSymbol(symbol_name);
  if (!result.IsNull()) return result.GetFile();
  if (underlay_ != NULL) {
    const FileDescriptor* file_result =
      underlay_->FindFileContainingSymbol(symbol_name);
    if (file_result != NULL) return file_result;
  }
  if (TryFindSymbolInFallbackDatabase(symbol_name)) {
    result = tables_->FindSymbol(symbol_name);
    if (!result.IsNull()) return result.GetFile();
  }
  return NULL;
}

const Descriptor* DescriptorPool::FindMessageTypeByName(
    const string& name) const {
  Symbol result = tables_->FindByNameHelper(this, name);
  return (result.type == Symbol::MESSAGE) ? result.descriptor : NULL;
}

const FieldDescriptor* DescriptorPool::FindFieldByName(
    const string& name) const {
  Symbol result = tables_->FindByNameHelper(this, name);
  if (result.type == Symbol::FIELD &&
      !result.field_descriptor->is_extension()) {
    return result.field_descriptor;
  } else {
    return NULL;
  }
}

const FieldDescriptor* DescriptorPool::FindExtensionByName(
    const string& name) const {
  Symbol result = tables_->FindByNameHelper(this, name);
  if (result.type == Symbol::FIELD &&
      result.field_descriptor->is_extension()) {
    return result.field_descriptor;
  } else {
    return NULL;
  }
}

const EnumDescriptor* DescriptorPool::FindEnumTypeByName(
    const string& name) const {
  Symbol result = tables_->FindByNameHelper(this, name);
  return (result.type == Symbol::ENUM) ? result.enum_descriptor : NULL;
}

const EnumValueDescriptor* DescriptorPool::FindEnumValueByName(
    const string& name) const {
  Symbol result = tables_->FindByNameHelper(this, name);
  return (result.type == Symbol::ENUM_VALUE) ?
    result.enum_value_descriptor : NULL;
}

const ServiceDescriptor* DescriptorPool::FindServiceByName(
    const string& name) const {
  Symbol result = tables_->FindByNameHelper(this, name);
  return (result.type == Symbol::SERVICE) ? result.service_descriptor : NULL;
}

const MethodDescriptor* DescriptorPool::FindMethodByName(
    const string& name) const {
  Symbol result = tables_->FindByNameHelper(this, name);
  return (result.type == Symbol::METHOD) ? result.method_descriptor : NULL;
}

const FieldDescriptor* DescriptorPool::FindExtensionByNumber(
    const Descriptor* extendee, int number) const {
  MutexLockMaybe lock(mutex_);
  const FieldDescriptor* result = tables_->FindExtension(extendee, number);
  if (result != NULL) {
    return result;
  }
  if (underlay_ != NULL) {
    result = underlay_->FindExtensionByNumber(extendee, number);
    if (result != NULL) return result;
  }
  if (TryFindExtensionInFallbackDatabase(extendee, number)) {
    result = tables_->FindExtension(extendee, number);
    if (result != NULL) {
      return result;
    }
  }
  return NULL;
}

void DescriptorPool::FindAllExtensions(
    const Descriptor* extendee, vector<const FieldDescriptor*>* out) const {
  MutexLockMaybe lock(mutex_);

  // Initialize tables_->extensions_ from the fallback database first
  // (but do this only once per descriptor).
  if (fallback_database_ != NULL &&
      tables_->extensions_loaded_from_db_.count(extendee) == 0) {
    vector<int> numbers;
    if (fallback_database_->FindAllExtensionNumbers(extendee->full_name(),
                                                    &numbers)) {
      for (int i = 0; i < numbers.size(); ++i) {
        int number = numbers[i];
        if (tables_->FindExtension(extendee, number) == NULL) {
          TryFindExtensionInFallbackDatabase(extendee, number);
        }
      }
      tables_->extensions_loaded_from_db_.insert(extendee);
    }
  }

  tables_->FindAllExtensions(extendee, out);
  if (underlay_ != NULL) {
    underlay_->FindAllExtensions(extendee, out);
  }
}

// -------------------------------------------------------------------

const FieldDescriptor*
Descriptor::FindFieldByNumber(int key) const {
  const FieldDescriptor* result =
    file()->tables_->FindFieldByNumber(this, key);
  if (result == NULL || result->is_extension()) {
    return NULL;
  } else {
    return result;
  }
}

const FieldDescriptor*
Descriptor::FindFieldByLowercaseName(const string& key) const {
  const FieldDescriptor* result =
    file()->tables_->FindFieldByLowercaseName(this, key);
  if (result == NULL || result->is_extension()) {
    return NULL;
  } else {
    return result;
  }
}

const FieldDescriptor*
Descriptor::FindFieldByCamelcaseName(const string& key) const {
  const FieldDescriptor* result =
    file()->tables_->FindFieldByCamelcaseName(this, key);
  if (result == NULL || result->is_extension()) {
    return NULL;
  } else {
    return result;
  }
}

const FieldDescriptor*
Descriptor::FindFieldByName(const string& key) const {
  Symbol result =
    file()->tables_->FindNestedSymbolOfType(this, key, Symbol::FIELD);
  if (!result.IsNull() && !result.field_descriptor->is_extension()) {
    return result.field_descriptor;
  } else {
    return NULL;
  }
}

const FieldDescriptor*
Descriptor::FindExtensionByName(const string& key) const {
  Symbol result =
    file()->tables_->FindNestedSymbolOfType(this, key, Symbol::FIELD);
  if (!result.IsNull() && result.field_descriptor->is_extension()) {
    return result.field_descriptor;
  } else {
    return NULL;
  }
}

const FieldDescriptor*
Descriptor::FindExtensionByLowercaseName(const string& key) const {
  const FieldDescriptor* result =
    file()->tables_->FindFieldByLowercaseName(this, key);
  if (result == NULL || !result->is_extension()) {
    return NULL;
  } else {
    return result;
  }
}

const FieldDescriptor*
Descriptor::FindExtensionByCamelcaseName(const string& key) const {
  const FieldDescriptor* result =
    file()->tables_->FindFieldByCamelcaseName(this, key);
  if (result == NULL || !result->is_extension()) {
    return NULL;
  } else {
    return result;
  }
}

const Descriptor*
Descriptor::FindNestedTypeByName(const string& key) const {
  Symbol result =
    file()->tables_->FindNestedSymbolOfType(this, key, Symbol::MESSAGE);
  if (!result.IsNull()) {
    return result.descriptor;
  } else {
    return NULL;
  }
}

const EnumDescriptor*
Descriptor::FindEnumTypeByName(const string& key) const {
  Symbol result =
    file()->tables_->FindNestedSymbolOfType(this, key, Symbol::ENUM);
  if (!result.IsNull()) {
    return result.enum_descriptor;
  } else {
    return NULL;
  }
}

const EnumValueDescriptor*
Descriptor::FindEnumValueByName(const string& key) const {
  Symbol result =
    file()->tables_->FindNestedSymbolOfType(this, key, Symbol::ENUM_VALUE);
  if (!result.IsNull()) {
    return result.enum_value_descriptor;
  } else {
    return NULL;
  }
}

const EnumValueDescriptor*
EnumDescriptor::FindValueByName(const string& key) const {
  Symbol result =
    file()->tables_->FindNestedSymbolOfType(this, key, Symbol::ENUM_VALUE);
  if (!result.IsNull()) {
    return result.enum_value_descriptor;
  } else {
    return NULL;
  }
}

const EnumValueDescriptor*
EnumDescriptor::FindValueByNumber(int key) const {
  return file()->tables_->FindEnumValueByNumber(this, key);
}

const MethodDescriptor*
ServiceDescriptor::FindMethodByName(const string& key) const {
  Symbol result =
    file()->tables_->FindNestedSymbolOfType(this, key, Symbol::METHOD);
  if (!result.IsNull()) {
    return result.method_descriptor;
  } else {
    return NULL;
  }
}

const Descriptor*
FileDescriptor::FindMessageTypeByName(const string& key) const {
  Symbol result = tables_->FindNestedSymbolOfType(this, key, Symbol::MESSAGE);
  if (!result.IsNull()) {
    return result.descriptor;
  } else {
    return NULL;
  }
}

const EnumDescriptor*
FileDescriptor::FindEnumTypeByName(const string& key) const {
  Symbol result = tables_->FindNestedSymbolOfType(this, key, Symbol::ENUM);
  if (!result.IsNull()) {
    return result.enum_descriptor;
  } else {
    return NULL;
  }
}

const EnumValueDescriptor*
FileDescriptor::FindEnumValueByName(const string& key) const {
  Symbol result =
    tables_->FindNestedSymbolOfType(this, key, Symbol::ENUM_VALUE);
  if (!result.IsNull()) {
    return result.enum_value_descriptor;
  } else {
    return NULL;
  }
}

const ServiceDescriptor*
FileDescriptor::FindServiceByName(const string& key) const {
  Symbol result = tables_->FindNestedSymbolOfType(this, key, Symbol::SERVICE);
  if (!result.IsNull()) {
    return result.service_descriptor;
  } else {
    return NULL;
  }
}

const FieldDescriptor*
FileDescriptor::FindExtensionByName(const string& key) const {
  Symbol result = tables_->FindNestedSymbolOfType(this, key, Symbol::FIELD);
  if (!result.IsNull() && result.field_descriptor->is_extension()) {
    return result.field_descriptor;
  } else {
    return NULL;
  }
}

const FieldDescriptor*
FileDescriptor::FindExtensionByLowercaseName(const string& key) const {
  const FieldDescriptor* result = tables_->FindFieldByLowercaseName(this, key);
  if (result == NULL || !result->is_extension()) {
    return NULL;
  } else {
    return result;
  }
}

const FieldDescriptor*
FileDescriptor::FindExtensionByCamelcaseName(const string& key) const {
  const FieldDescriptor* result = tables_->FindFieldByCamelcaseName(this, key);
  if (result == NULL || !result->is_extension()) {
    return NULL;
  } else {
    return result;
  }
}

bool Descriptor::IsExtensionNumber(int number) const {
  // Linear search should be fine because we don't expect a message to have
  // more than a couple extension ranges.
  for (int i = 0; i < extension_range_count(); i++) {
    if (number >= extension_range(i)->start &&
        number <  extension_range(i)->end) {
      return true;
    }
  }
  return false;
}

// -------------------------------------------------------------------

bool DescriptorPool::TryFindFileInFallbackDatabase(const string& name) const {
  if (fallback_database_ == NULL) return false;

  if (tables_->known_bad_files_.count(name) > 0) return false;

  FileDescriptorProto file_proto;
  if (!fallback_database_->FindFileByName(name, &file_proto) ||
      BuildFileFromDatabase(file_proto) == NULL) {
    tables_->known_bad_files_.insert(name);
    return false;
  }

  return true;
}

bool DescriptorPool::IsSubSymbolOfBuiltType(const string& name) const {
  string prefix = name;
  for (;;) {
    string::size_type dot_pos = prefix.find_last_of('.');
    if (dot_pos == string::npos) {
      break;
    }
    prefix = prefix.substr(0, dot_pos);
    Symbol symbol = tables_->FindSymbol(prefix);
    // If the symbol type is anything other than PACKAGE, then its complete
    // definition is already known.
    if (!symbol.IsNull() && symbol.type != Symbol::PACKAGE) {
      return true;
    }
  }
  if (underlay_ != NULL) {
    // Check to see if any prefix of this symbol exists in the underlay.
    return underlay_->IsSubSymbolOfBuiltType(name);
  }
  return false;
}

bool DescriptorPool::TryFindSymbolInFallbackDatabase(const string& name) const {
  if (fallback_database_ == NULL) return false;

  // We skip looking in the fallback database if the name is a sub-symbol of
  // any descriptor that already exists in the descriptor pool (except for
  // package descriptors).  This is valid because all symbols except for
  // packages are defined in a single file, so if the symbol exists then we
  // should already have its definition.
  //
  // The other reason to do this is to support "overriding" type definitions
  // by merging two databases that define the same type.  (Yes, people do
  // this.)  The main difficulty with making this work is that
  // FindFileContainingSymbol() is allowed to return both false positives
  // (e.g., SimpleDescriptorDatabase, UpgradedDescriptorDatabase) and false
  // negatives (e.g. ProtoFileParser, SourceTreeDescriptorDatabase).  When two
  // such databases are merged, looking up a non-existent sub-symbol of a type
  // that already exists in the descriptor pool can result in an attempt to
  // load multiple definitions of the same type.  The check below avoids this.
  if (IsSubSymbolOfBuiltType(name)) return false;

  FileDescriptorProto file_proto;
  if (!fallback_database_->FindFileContainingSymbol(name, &file_proto)) {
    return false;
  }

  if (tables_->FindFile(file_proto.name()) != NULL) {
    // We've already loaded this file, and it apparently doesn't contain the
    // symbol we're looking for.  Some DescriptorDatabases return false
    // positives.
    return false;
  }

  if (BuildFileFromDatabase(file_proto) == NULL) {
    return false;
  }

  return true;
}

bool DescriptorPool::TryFindExtensionInFallbackDatabase(
    const Descriptor* containing_type, int field_number) const {
  if (fallback_database_ == NULL) return false;

  FileDescriptorProto file_proto;
  if (!fallback_database_->FindFileContainingExtension(
        containing_type->full_name(), field_number, &file_proto)) {
    return false;
  }

  if (tables_->FindFile(file_proto.name()) != NULL) {
    // We've already loaded this file, and it apparently doesn't contain the
    // extension we're looking for.  Some DescriptorDatabases return false
    // positives.
    return false;
  }

  if (BuildFileFromDatabase(file_proto) == NULL) {
    return false;
  }

  return true;
}

// ===================================================================

string FieldDescriptor::DefaultValueAsString(bool quote_string_type) const {
  GOOGLE_CHECK(has_default_value()) << "No default value";
  switch (cpp_type()) {
    case CPPTYPE_INT32:
      return SimpleItoa(default_value_int32());
      break;
    case CPPTYPE_INT64:
      return SimpleItoa(default_value_int64());
      break;
    case CPPTYPE_UINT32:
      return SimpleItoa(default_value_uint32());
      break;
    case CPPTYPE_UINT64:
      return SimpleItoa(default_value_uint64());
      break;
    case CPPTYPE_FLOAT:
      return SimpleFtoa(default_value_float());
      break;
    case CPPTYPE_DOUBLE:
      return SimpleDtoa(default_value_double());
      break;
    case CPPTYPE_BOOL:
      return default_value_bool() ? "true" : "false";
      break;
    case CPPTYPE_STRING:
      if (quote_string_type) {
        return "\"" + CEscape(default_value_string()) + "\"";
      } else {
        if (type() == TYPE_BYTES) {
          return CEscape(default_value_string());
        } else {
          return default_value_string();
        }
      }
      break;
    case CPPTYPE_ENUM:
      return default_value_enum()->name();
      break;
    case CPPTYPE_MESSAGE:
      GOOGLE_LOG(DFATAL) << "Messages can't have default values!";
      break;
  }
  GOOGLE_LOG(FATAL) << "Can't get here: failed to get default value as string";
  return "";
}

// CopyTo methods ====================================================

void FileDescriptor::CopyTo(FileDescriptorProto* proto) const {
  proto->set_name(name());
  if (!package().empty()) proto->set_package(package());

  for (int i = 0; i < dependency_count(); i++) {
    proto->add_dependency(dependency(i)->name());
  }

  for (int i = 0; i < public_dependency_count(); i++) {
    proto->add_public_dependency(public_dependencies_[i]);
  }

  for (int i = 0; i < weak_dependency_count(); i++) {
    proto->add_weak_dependency(weak_dependencies_[i]);
  }

  for (int i = 0; i < message_type_count(); i++) {
    message_type(i)->CopyTo(proto->add_message_type());
  }
  for (int i = 0; i < enum_type_count(); i++) {
    enum_type(i)->CopyTo(proto->add_enum_type());
  }
  for (int i = 0; i < service_count(); i++) {
    service(i)->CopyTo(proto->add_service());
  }
  for (int i = 0; i < extension_count(); i++) {
    extension(i)->CopyTo(proto->add_extension());
  }

  if (&options() != &FileOptions::default_instance()) {
    proto->mutable_options()->CopyFrom(options());
  }
}

void FileDescriptor::CopySourceCodeInfoTo(FileDescriptorProto* proto) const {
  if (source_code_info_ != &SourceCodeInfo::default_instance()) {
    proto->mutable_source_code_info()->CopyFrom(*source_code_info_);
  }
}

void Descriptor::CopyTo(DescriptorProto* proto) const {
  proto->set_name(name());

  for (int i = 0; i < field_count(); i++) {
    field(i)->CopyTo(proto->add_field());
  }
  for (int i = 0; i < nested_type_count(); i++) {
    nested_type(i)->CopyTo(proto->add_nested_type());
  }
  for (int i = 0; i < enum_type_count(); i++) {
    enum_type(i)->CopyTo(proto->add_enum_type());
  }
  for (int i = 0; i < extension_range_count(); i++) {
    DescriptorProto::ExtensionRange* range = proto->add_extension_range();
    range->set_start(extension_range(i)->start);
    range->set_end(extension_range(i)->end);
  }
  for (int i = 0; i < extension_count(); i++) {
    extension(i)->CopyTo(proto->add_extension());
  }

  if (&options() != &MessageOptions::default_instance()) {
    proto->mutable_options()->CopyFrom(options());
  }
}

void FieldDescriptor::CopyTo(FieldDescriptorProto* proto) const {
  proto->set_name(name());
  proto->set_number(number());

  // Some compilers do not allow static_cast directly between two enum types,
  // so we must cast to int first.
  proto->set_label(static_cast<FieldDescriptorProto::Label>(
                     implicit_cast<int>(label())));
  proto->set_type(static_cast<FieldDescriptorProto::Type>(
                    implicit_cast<int>(type())));

  if (is_extension()) {
    if (!containing_type()->is_unqualified_placeholder_) {
      proto->set_extendee(".");
    }
    proto->mutable_extendee()->append(containing_type()->full_name());
  }

  if (cpp_type() == CPPTYPE_MESSAGE) {
    if (message_type()->is_placeholder_) {
      // We don't actually know if the type is a message type.  It could be
      // an enum.
      proto->clear_type();
    }

    if (!message_type()->is_unqualified_placeholder_) {
      proto->set_type_name(".");
    }
    proto->mutable_type_name()->append(message_type()->full_name());
  } else if (cpp_type() == CPPTYPE_ENUM) {
    if (!enum_type()->is_unqualified_placeholder_) {
      proto->set_type_name(".");
    }
    proto->mutable_type_name()->append(enum_type()->full_name());
  }

  if (has_default_value()) {
    proto->set_default_value(DefaultValueAsString(false));
  }

  if (&options() != &FieldOptions::default_instance()) {
    proto->mutable_options()->CopyFrom(options());
  }
}

void EnumDescriptor::CopyTo(EnumDescriptorProto* proto) const {
  proto->set_name(name());

  for (int i = 0; i < value_count(); i++) {
    value(i)->CopyTo(proto->add_value());
  }

  if (&options() != &EnumOptions::default_instance()) {
    proto->mutable_options()->CopyFrom(options());
  }
}

void EnumValueDescriptor::CopyTo(EnumValueDescriptorProto* proto) const {
  proto->set_name(name());
  proto->set_number(number());

  if (&options() != &EnumValueOptions::default_instance()) {
    proto->mutable_options()->CopyFrom(options());
  }
}

void ServiceDescriptor::CopyTo(ServiceDescriptorProto* proto) const {
  proto->set_name(name());

  for (int i = 0; i < method_count(); i++) {
    method(i)->CopyTo(proto->add_method());
  }

  if (&options() != &ServiceOptions::default_instance()) {
    proto->mutable_options()->CopyFrom(options());
  }
}

void MethodDescriptor::CopyTo(MethodDescriptorProto* proto) const {
  proto->set_name(name());

  if (!input_type()->is_unqualified_placeholder_) {
    proto->set_input_type(".");
  }
  proto->mutable_input_type()->append(input_type()->full_name());

  if (!output_type()->is_unqualified_placeholder_) {
    proto->set_output_type(".");
  }
  proto->mutable_output_type()->append(output_type()->full_name());

  if (&options() != &MethodOptions::default_instance()) {
    proto->mutable_options()->CopyFrom(options());
  }
}

// DebugString methods ===============================================

namespace {

// Used by each of the option formatters.
bool RetrieveOptions(int depth,
                     const Message &options,
                     vector<string> *option_entries) {
  option_entries->clear();
  const Reflection* reflection = options.GetReflection();
  vector<const FieldDescriptor*> fields;
  reflection->ListFields(options, &fields);
  for (int i = 0; i < fields.size(); i++) {
    int count = 1;
    bool repeated = false;
    if (fields[i]->is_repeated()) {
      count = reflection->FieldSize(options, fields[i]);
      repeated = true;
    }
    for (int j = 0; j < count; j++) {
      string fieldval;
      if (fields[i]->cpp_type() == FieldDescriptor::CPPTYPE_MESSAGE) {
        string tmp;
        TextFormat::Printer printer;
        printer.SetInitialIndentLevel(depth + 1);
        printer.PrintFieldValueToString(options, fields[i],
                                        repeated ? j : -1, &tmp);
        fieldval.append("{\n");
        fieldval.append(tmp);
        fieldval.append(depth * 2, ' ');
        fieldval.append("}");
      } else {
        TextFormat::PrintFieldValueToString(options, fields[i],
                                            repeated ? j : -1, &fieldval);
      }
      string name;
      if (fields[i]->is_extension()) {
        name = "(." + fields[i]->full_name() + ")";
      } else {
        name = fields[i]->name();
      }
      option_entries->push_back(name + " = " + fieldval);
    }
  }
  return !option_entries->empty();
}

// Formats options that all appear together in brackets. Does not include
// brackets.
bool FormatBracketedOptions(int depth, const Message &options, string *output) {
  vector<string> all_options;
  if (RetrieveOptions(depth, options, &all_options)) {
    output->append(JoinStrings(all_options, ", "));
  }
  return !all_options.empty();
}

// Formats options one per line
bool FormatLineOptions(int depth, const Message &options, string *output) {
  string prefix(depth * 2, ' ');
  vector<string> all_options;
  if (RetrieveOptions(depth, options, &all_options)) {
    for (int i = 0; i < all_options.size(); i++) {
      strings::SubstituteAndAppend(output, "$0option $1;\n",
                                   prefix, all_options[i]);
    }
  }
  return !all_options.empty();
}

}  // anonymous namespace

string FileDescriptor::DebugString() const {
  string contents = "syntax = \"proto2\";\n\n";

  set<int> public_dependencies;
  set<int> weak_dependencies;
  public_dependencies.insert(public_dependencies_,
                             public_dependencies_ + public_dependency_count_);
  weak_dependencies.insert(weak_dependencies_,
                           weak_dependencies_ + weak_dependency_count_);

  for (int i = 0; i < dependency_count(); i++) {
    if (public_dependencies.count(i) > 0) {
      strings::SubstituteAndAppend(&contents, "import public \"$0\";\n",
                                   dependency(i)->name());
    } else if (weak_dependencies.count(i) > 0) {
      strings::SubstituteAndAppend(&contents, "import weak \"$0\";\n",
                                   dependency(i)->name());
    } else {
      strings::SubstituteAndAppend(&contents, "import \"$0\";\n",
                                   dependency(i)->name());
    }
  }

  if (!package().empty()) {
    strings::SubstituteAndAppend(&contents, "package $0;\n\n", package());
  }

  if (FormatLineOptions(0, options(), &contents)) {
    contents.append("\n");  // add some space if we had options
  }

  for (int i = 0; i < enum_type_count(); i++) {
    enum_type(i)->DebugString(0, &contents);
    contents.append("\n");
  }

  // Find all the 'group' type extensions; we will not output their nested
  // definitions (those will be done with their group field descriptor).
  set<const Descriptor*> groups;
  for (int i = 0; i < extension_count(); i++) {
    if (extension(i)->type() == FieldDescriptor::TYPE_GROUP) {
      groups.insert(extension(i)->message_type());
    }
  }

  for (int i = 0; i < message_type_count(); i++) {
    if (groups.count(message_type(i)) == 0) {
      strings::SubstituteAndAppend(&contents, "message $0",
                                   message_type(i)->name());
      message_type(i)->DebugString(0, &contents);
      contents.append("\n");
    }
  }

  for (int i = 0; i < service_count(); i++) {
    service(i)->DebugString(&contents);
    contents.append("\n");
  }

  const Descriptor* containing_type = NULL;
  for (int i = 0; i < extension_count(); i++) {
    if (extension(i)->containing_type() != containing_type) {
      if (i > 0) contents.append("}\n\n");
      containing_type = extension(i)->containing_type();
      strings::SubstituteAndAppend(&contents, "extend .$0 {\n",
                                   containing_type->full_name());
    }
    extension(i)->DebugString(1, &contents);
  }
  if (extension_count() > 0) contents.append("}\n\n");

  return contents;
}

string Descriptor::DebugString() const {
  string contents;
  strings::SubstituteAndAppend(&contents, "message $0", name());
  DebugString(0, &contents);
  return contents;
}

void Descriptor::DebugString(int depth, string *contents) const {
  string prefix(depth * 2, ' ');
  ++depth;
  contents->append(" {\n");

  FormatLineOptions(depth, options(), contents);

  // Find all the 'group' types for fields and extensions; we will not output
  // their nested definitions (those will be done with their group field
  // descriptor).
  set<const Descriptor*> groups;
  for (int i = 0; i < field_count(); i++) {
    if (field(i)->type() == FieldDescriptor::TYPE_GROUP) {
      groups.insert(field(i)->message_type());
    }
  }
  for (int i = 0; i < extension_count(); i++) {
    if (extension(i)->type() == FieldDescriptor::TYPE_GROUP) {
      groups.insert(extension(i)->message_type());
    }
  }

  for (int i = 0; i < nested_type_count(); i++) {
    if (groups.count(nested_type(i)) == 0) {
      strings::SubstituteAndAppend(contents, "$0  message $1",
                                   prefix, nested_type(i)->name());
      nested_type(i)->DebugString(depth, contents);
    }
  }
  for (int i = 0; i < enum_type_count(); i++) {
    enum_type(i)->DebugString(depth, contents);
  }
  for (int i = 0; i < field_count(); i++) {
    field(i)->DebugString(depth, contents);
  }

  for (int i = 0; i < extension_range_count(); i++) {
    strings::SubstituteAndAppend(contents, "$0  extensions $1 to $2;\n",
                                 prefix,
                                 extension_range(i)->start,
                                 extension_range(i)->end - 1);
  }

  // Group extensions by what they extend, so they can be printed out together.
  const Descriptor* containing_type = NULL;
  for (int i = 0; i < extension_count(); i++) {
    if (extension(i)->containing_type() != containing_type) {
      if (i > 0) strings::SubstituteAndAppend(contents, "$0  }\n", prefix);
      containing_type = extension(i)->containing_type();
      strings::SubstituteAndAppend(contents, "$0  extend .$1 {\n",
                                   prefix, containing_type->full_name());
    }
    extension(i)->DebugString(depth + 1, contents);
  }
  if (extension_count() > 0)
    strings::SubstituteAndAppend(contents, "$0  }\n", prefix);

  strings::SubstituteAndAppend(contents, "$0}\n", prefix);
}

string FieldDescriptor::DebugString() const {
  string contents;
  int depth = 0;
  if (is_extension()) {
    strings::SubstituteAndAppend(&contents, "extend .$0 {\n",
                                 containing_type()->full_name());
    depth = 1;
  }
  DebugString(depth, &contents);
  if (is_extension()) {
     contents.append("}\n");
  }
  return contents;
}

void FieldDescriptor::DebugString(int depth, string *contents) const {
  string prefix(depth * 2, ' ');
  string field_type;
  switch (type()) {
    case TYPE_MESSAGE:
      field_type = "." + message_type()->full_name();
      break;
    case TYPE_ENUM:
      field_type = "." + enum_type()->full_name();
      break;
    default:
      field_type = kTypeToName[type()];
  }

  strings::SubstituteAndAppend(contents, "$0$1 $2 $3 = $4",
                               prefix,
                               kLabelToName[label()],
                               field_type,
                               type() == TYPE_GROUP ? message_type()->name() :
                                                      name(),
                               number());

  bool bracketed = false;
  if (has_default_value()) {
    bracketed = true;
    strings::SubstituteAndAppend(contents, " [default = $0",
                                 DefaultValueAsString(true));
  }

  string formatted_options;
  if (FormatBracketedOptions(depth, options(), &formatted_options)) {
    contents->append(bracketed ? ", " : " [");
    bracketed = true;
    contents->append(formatted_options);
  }

  if (bracketed) {
    contents->append("]");
  }

  if (type() == TYPE_GROUP) {
    message_type()->DebugString(depth, contents);
  } else {
    contents->append(";\n");
  }
}

string EnumDescriptor::DebugString() const {
  string contents;
  DebugString(0, &contents);
  return contents;
}

void EnumDescriptor::DebugString(int depth, string *contents) const {
  string prefix(depth * 2, ' ');
  ++depth;
  strings::SubstituteAndAppend(contents, "$0enum $1 {\n",
                               prefix, name());

  FormatLineOptions(depth, options(), contents);

  for (int i = 0; i < value_count(); i++) {
    value(i)->DebugString(depth, contents);
  }
  strings::SubstituteAndAppend(contents, "$0}\n", prefix);
}

string EnumValueDescriptor::DebugString() const {
  string contents;
  DebugString(0, &contents);
  return contents;
}

void EnumValueDescriptor::DebugString(int depth, string *contents) const {
  string prefix(depth * 2, ' ');
  strings::SubstituteAndAppend(contents, "$0$1 = $2",
                               prefix, name(), number());

  string formatted_options;
  if (FormatBracketedOptions(depth, options(), &formatted_options)) {
    strings::SubstituteAndAppend(contents, " [$0]", formatted_options);
  }
  contents->append(";\n");
}

string ServiceDescriptor::DebugString() const {
  string contents;
  DebugString(&contents);
  return contents;
}

void ServiceDescriptor::DebugString(string *contents) const {
  strings::SubstituteAndAppend(contents, "service $0 {\n", name());

  FormatLineOptions(1, options(), contents);

  for (int i = 0; i < method_count(); i++) {
    method(i)->DebugString(1, contents);
  }

  contents->append("}\n");
}

string MethodDescriptor::DebugString() const {
  string contents;
  DebugString(0, &contents);
  return contents;
}

void MethodDescriptor::DebugString(int depth, string *contents) const {
  string prefix(depth * 2, ' ');
  ++depth;
  strings::SubstituteAndAppend(contents, "$0rpc $1(.$2) returns (.$3)",
                               prefix, name(),
                               input_type()->full_name(),
                               output_type()->full_name());

  string formatted_options;
  if (FormatLineOptions(depth, options(), &formatted_options)) {
    strings::SubstituteAndAppend(contents, " {\n$0$1}\n",
                                 formatted_options, prefix);
  } else {
    contents->append(";\n");
  }
}


// Location methods ===============================================

static bool PathsEqual(const vector<int>& x, const RepeatedField<int32>& y) {
  if (x.size() != y.size()) return false;
  for (int i = 0; i < x.size(); ++i) {
    if (x[i] != y.Get(i)) return false;
  }
  return true;
}

bool FileDescriptor::GetSourceLocation(const vector<int>& path,
                                       SourceLocation* out_location) const {
  GOOGLE_CHECK_NOTNULL(out_location);
  const SourceCodeInfo* info = source_code_info_;
  for (int i = 0; info && i < info->location_size(); ++i) {
    if (PathsEqual(path, info->location(i).path())) {
      const RepeatedField<int32>& span = info->location(i).span();
      if (span.size() == 3 || span.size() == 4) {
        out_location->start_line   = span.Get(0);
        out_location->start_column = span.Get(1);
        out_location->end_line     = span.Get(span.size() == 3 ? 0 : 2);
        out_location->end_column   = span.Get(span.size() - 1);

        out_location->leading_comments = info->location(i).leading_comments();
        out_location->trailing_comments = info->location(i).trailing_comments();
        return true;
      }
    }
  }
  return false;
}

bool FieldDescriptor::is_packed() const {
  return is_packable() && (options_ != NULL) && options_->packed();
}

bool Descriptor::GetSourceLocation(SourceLocation* out_location) const {
  vector<int> path;
  GetLocationPath(&path);
  return file()->GetSourceLocation(path, out_location);
}

bool FieldDescriptor::GetSourceLocation(SourceLocation* out_location) const {
  vector<int> path;
  GetLocationPath(&path);
  return file()->GetSourceLocation(path, out_location);
}

bool EnumDescriptor::GetSourceLocation(SourceLocation* out_location) const {
  vector<int> path;
  GetLocationPath(&path);
  return file()->GetSourceLocation(path, out_location);
}

bool MethodDescriptor::GetSourceLocation(SourceLocation* out_location) const {
  vector<int> path;
  GetLocationPath(&path);
  return service()->file()->GetSourceLocation(path, out_location);
}

bool ServiceDescriptor::GetSourceLocation(SourceLocation* out_location) const {
  vector<int> path;
  GetLocationPath(&path);
  return file()->GetSourceLocation(path, out_location);
}

bool EnumValueDescriptor::GetSourceLocation(
    SourceLocation* out_location) const {
  vector<int> path;
  GetLocationPath(&path);
  return type()->file()->GetSourceLocation(path, out_location);
}

void Descriptor::GetLocationPath(vector<int>* output) const {
  if (containing_type()) {
    containing_type()->GetLocationPath(output);
    output->push_back(DescriptorProto::kNestedTypeFieldNumber);
    output->push_back(index());
  } else {
    output->push_back(FileDescriptorProto::kMessageTypeFieldNumber);
    output->push_back(index());
  }
}

void FieldDescriptor::GetLocationPath(vector<int>* output) const {
  containing_type()->GetLocationPath(output);
  output->push_back(DescriptorProto::kFieldFieldNumber);
  output->push_back(index());
}

void EnumDescriptor::GetLocationPath(vector<int>* output) const {
  if (containing_type()) {
    containing_type()->GetLocationPath(output);
    output->push_back(DescriptorProto::kEnumTypeFieldNumber);
    output->push_back(index());
  } else {
    output->push_back(FileDescriptorProto::kEnumTypeFieldNumber);
    output->push_back(index());
  }
}

void EnumValueDescriptor::GetLocationPath(vector<int>* output) const {
  type()->GetLocationPath(output);
  output->push_back(EnumDescriptorProto::kValueFieldNumber);
  output->push_back(index());
}

void ServiceDescriptor::GetLocationPath(vector<int>* output) const {
  output->push_back(FileDescriptorProto::kServiceFieldNumber);
  output->push_back(index());
}

void MethodDescriptor::GetLocationPath(vector<int>* output) const {
  service()->GetLocationPath(output);
  output->push_back(ServiceDescriptorProto::kMethodFieldNumber);
  output->push_back(index());
}

// ===================================================================

namespace {

// Represents an options message to interpret. Extension names in the option
// name are respolved relative to name_scope. element_name and orig_opt are
// used only for error reporting (since the parser records locations against
// pointers in the original options, not the mutable copy). The Message must be
// one of the Options messages in descriptor.proto.
struct OptionsToInterpret {
  OptionsToInterpret(const string& ns,
                     const string& el,
                     const Message* orig_opt,
                     Message* opt)
      : name_scope(ns),
        element_name(el),
        original_options(orig_opt),
        options(opt) {
  }
  string name_scope;
  string element_name;
  const Message* original_options;
  Message* options;
};

}  // namespace

class DescriptorBuilder {
 public:
  DescriptorBuilder(const DescriptorPool* pool,
                    DescriptorPool::Tables* tables,
                    DescriptorPool::ErrorCollector* error_collector);
  ~DescriptorBuilder();

  const FileDescriptor* BuildFile(const FileDescriptorProto& proto);

 private:
  friend class OptionInterpreter;

  const DescriptorPool* pool_;
  DescriptorPool::Tables* tables_;  // for convenience
  DescriptorPool::ErrorCollector* error_collector_;

  // As we build descriptors we store copies of the options messages in
  // them. We put pointers to those copies in this vector, as we build, so we
  // can later (after cross-linking) interpret those options.
  vector<OptionsToInterpret> options_to_interpret_;

  bool had_errors_;
  string filename_;
  FileDescriptor* file_;
  FileDescriptorTables* file_tables_;
  set<const FileDescriptor*> dependencies_;

  // If LookupSymbol() finds a symbol that is in a file which is not a declared
  // dependency of this file, it will fail, but will set
  // possible_undeclared_dependency_ to point at that file.  This is only used
  // by AddNotDefinedError() to report a more useful error message.
  // possible_undeclared_dependency_name_ is the name of the symbol that was
  // actually found in possible_undeclared_dependency_, which may be a parent
  // of the symbol actually looked for.
  const FileDescriptor* possible_undeclared_dependency_;
  string possible_undeclared_dependency_name_;

  void AddError(const string& element_name,
                const Message& descriptor,
                DescriptorPool::ErrorCollector::ErrorLocation location,
                const string& error);

  // Adds an error indicating that undefined_symbol was not defined.  Must
  // only be called after LookupSymbol() fails.
  void AddNotDefinedError(
    const string& element_name,
    const Message& descriptor,
    DescriptorPool::ErrorCollector::ErrorLocation location,
    const string& undefined_symbol);

  // Silly helper which determines if the given file is in the given package.
  // I.e., either file->package() == package_name or file->package() is a
  // nested package within package_name.
  bool IsInPackage(const FileDescriptor* file, const string& package_name);

  // Helper function which finds all public dependencies of the given file, and
  // stores the them in the dependencies_ set in the builder.
  void RecordPublicDependencies(const FileDescriptor* file);

  // Like tables_->FindSymbol(), but additionally:
  // - Search the pool's underlay if not found in tables_.
  // - Insure that the resulting Symbol is from one of the file's declared
  //   dependencies.
  Symbol FindSymbol(const string& name);

  // Like FindSymbol() but does not require that the symbol is in one of the
  // file's declared dependencies.
  Symbol FindSymbolNotEnforcingDeps(const string& name);

  // This implements the body of FindSymbolNotEnforcingDeps().
  Symbol FindSymbolNotEnforcingDepsHelper(const DescriptorPool* pool,
                                          const string& name);

  // Like FindSymbol(), but looks up the name relative to some other symbol
  // name.  This first searches siblings of relative_to, then siblings of its
  // parents, etc.  For example, LookupSymbol("foo.bar", "baz.qux.corge") makes
  // the following calls, returning the first non-null result:
  // FindSymbol("baz.qux.foo.bar"), FindSymbol("baz.foo.bar"),
  // FindSymbol("foo.bar").  If AllowUnknownDependencies() has been called
  // on the DescriptorPool, this will generate a placeholder type if
  // the name is not found (unless the name itself is malformed).  The
  // placeholder_type parameter indicates what kind of placeholder should be
  // constructed in this case.  The resolve_mode parameter determines whether
  // any symbol is returned, or only symbols that are types.  Note, however,
  // that LookupSymbol may still return a non-type symbol in LOOKUP_TYPES mode,
  // if it believes that's all it could refer to.  The caller should always
  // check that it receives the type of symbol it was expecting.
  enum PlaceholderType {
    PLACEHOLDER_MESSAGE,
    PLACEHOLDER_ENUM,
    PLACEHOLDER_EXTENDABLE_MESSAGE
  };
  enum ResolveMode {
    LOOKUP_ALL, LOOKUP_TYPES
  };
  Symbol LookupSymbol(const string& name, const string& relative_to,
                      PlaceholderType placeholder_type = PLACEHOLDER_MESSAGE,
                      ResolveMode resolve_mode = LOOKUP_ALL);

  // Like LookupSymbol() but will not return a placeholder even if
  // AllowUnknownDependencies() has been used.
  Symbol LookupSymbolNoPlaceholder(const string& name,
                                   const string& relative_to,
                                   ResolveMode resolve_mode = LOOKUP_ALL);

  // Creates a placeholder type suitable for return from LookupSymbol().  May
  // return kNullSymbol if the name is not a valid type name.
  Symbol NewPlaceholder(const string& name, PlaceholderType placeholder_type);

  // Creates a placeholder file.  Never returns NULL.  This is used when an
  // import is not found and AllowUnknownDependencies() is enabled.
  const FileDescriptor* NewPlaceholderFile(const string& name);

  // Calls tables_->AddSymbol() and records an error if it fails.  Returns
  // true if successful or false if failed, though most callers can ignore
  // the return value since an error has already been recorded.
  bool AddSymbol(const string& full_name,
                 const void* parent, const string& name,
                 const Message& proto, Symbol symbol);

  // Like AddSymbol(), but succeeds if the symbol is already defined as long
  // as the existing definition is also a package (because it's OK to define
  // the same package in two different files).  Also adds all parents of the
  // packgae to the symbol table (e.g. AddPackage("foo.bar", ...) will add
  // "foo.bar" and "foo" to the table).
  void AddPackage(const string& name, const Message& proto,
                  const FileDescriptor* file);

  // Checks that the symbol name contains only alphanumeric characters and
  // underscores.  Records an error otherwise.
  void ValidateSymbolName(const string& name, const string& full_name,
                          const Message& proto);

  // Like ValidateSymbolName(), but the name is allowed to contain periods and
  // an error is indicated by returning false (not recording the error).
  bool ValidateQualifiedName(const string& name);

  // Used by BUILD_ARRAY macro (below) to avoid having to have the type
  // specified as a macro parameter.
  template <typename Type>
  inline void AllocateArray(int size, Type** output) {
    *output = tables_->AllocateArray<Type>(size);
  }

  // Allocates a copy of orig_options in tables_ and stores it in the
  // descriptor. Remembers its uninterpreted options, to be interpreted
  // later. DescriptorT must be one of the Descriptor messages from
  // descriptor.proto.
  template<class DescriptorT> void AllocateOptions(
      const typename DescriptorT::OptionsType& orig_options,
      DescriptorT* descriptor);
  // Specialization for FileOptions.
  void AllocateOptions(const FileOptions& orig_options,
                       FileDescriptor* descriptor);

  // Implementation for AllocateOptions(). Don't call this directly.
  template<class DescriptorT> void AllocateOptionsImpl(
      const string& name_scope,
      const string& element_name,
      const typename DescriptorT::OptionsType& orig_options,
      DescriptorT* descriptor);

  // These methods all have the same signature for the sake of the BUILD_ARRAY
  // macro, below.
  void BuildMessage(const DescriptorProto& proto,
                    const Descriptor* parent,
                    Descriptor* result);
  void BuildFieldOrExtension(const FieldDescriptorProto& proto,
                             const Descriptor* parent,
                             FieldDescriptor* result,
                             bool is_extension);
  void BuildField(const FieldDescriptorProto& proto,
                  const Descriptor* parent,
                  FieldDescriptor* result) {
    BuildFieldOrExtension(proto, parent, result, false);
  }
  void BuildExtension(const FieldDescriptorProto& proto,
                      const Descriptor* parent,
                      FieldDescriptor* result) {
    BuildFieldOrExtension(proto, parent, result, true);
  }
  void BuildExtensionRange(const DescriptorProto::ExtensionRange& proto,
                           const Descriptor* parent,
                           Descriptor::ExtensionRange* result);
  void BuildEnum(const EnumDescriptorProto& proto,
                 const Descriptor* parent,
                 EnumDescriptor* result);
  void BuildEnumValue(const EnumValueDescriptorProto& proto,
                      const EnumDescriptor* parent,
                      EnumValueDescriptor* result);
  void BuildService(const ServiceDescriptorProto& proto,
                    const void* dummy,
                    ServiceDescriptor* result);
  void BuildMethod(const MethodDescriptorProto& proto,
                   const ServiceDescriptor* parent,
                   MethodDescriptor* result);

  // Must be run only after building.
  //
  // NOTE: Options will not be available during cross-linking, as they
  // have not yet been interpreted. Defer any handling of options to the
  // Validate*Options methods.
  void CrossLinkFile(FileDescriptor* file, const FileDescriptorProto& proto);
  void CrossLinkMessage(Descriptor* message, const DescriptorProto& proto);
  void CrossLinkField(FieldDescriptor* field,
                      const FieldDescriptorProto& proto);
  void CrossLinkEnum(EnumDescriptor* enum_type,
                     const EnumDescriptorProto& proto);
  void CrossLinkEnumValue(EnumValueDescriptor* enum_value,
                          const EnumValueDescriptorProto& proto);
  void CrossLinkService(ServiceDescriptor* service,
                        const ServiceDescriptorProto& proto);
  void CrossLinkMethod(MethodDescriptor* method,
                       const MethodDescriptorProto& proto);

  // Must be run only after cross-linking.
  void InterpretOptions();

  // A helper class for interpreting options.
  class OptionInterpreter {
   public:
    // Creates an interpreter that operates in the context of the pool of the
    // specified builder, which must not be NULL. We don't take ownership of the
    // builder.
    explicit OptionInterpreter(DescriptorBuilder* builder);

    ~OptionInterpreter();

    // Interprets the uninterpreted options in the specified Options message.
    // On error, calls AddError() on the underlying builder and returns false.
    // Otherwise returns true.
    bool InterpretOptions(OptionsToInterpret* options_to_interpret);

    class AggregateOptionFinder;

   private:
    // Interprets uninterpreted_option_ on the specified message, which
    // must be the mutable copy of the original options message to which
    // uninterpreted_option_ belongs.
    bool InterpretSingleOption(Message* options);

    // Adds the uninterpreted_option to the given options message verbatim.
    // Used when AllowUnknownDependencies() is in effect and we can't find
    // the option's definition.
    void AddWithoutInterpreting(const UninterpretedOption& uninterpreted_option,
                                Message* options);

    // A recursive helper function that drills into the intermediate fields
    // in unknown_fields to check if field innermost_field is set on the
    // innermost message. Returns false and sets an error if so.
    bool ExamineIfOptionIsSet(
        vector<const FieldDescriptor*>::const_iterator intermediate_fields_iter,
        vector<const FieldDescriptor*>::const_iterator intermediate_fields_end,
        const FieldDescriptor* innermost_field, const string& debug_msg_name,
        const UnknownFieldSet& unknown_fields);

    // Validates the value for the option field of the currently interpreted
    // option and then sets it on the unknown_field.
    bool SetOptionValue(const FieldDescriptor* option_field,
                        UnknownFieldSet* unknown_fields);

    // Parses an aggregate value for a CPPTYPE_MESSAGE option and
    // saves it into *unknown_fields.
    bool SetAggregateOption(const FieldDescriptor* option_field,
                            UnknownFieldSet* unknown_fields);

    // Convenience functions to set an int field the right way, depending on
    // its wire type (a single int CppType can represent multiple wire types).
    void SetInt32(int number, int32 value, FieldDescriptor::Type type,
                  UnknownFieldSet* unknown_fields);
    void SetInt64(int number, int64 value, FieldDescriptor::Type type,
                  UnknownFieldSet* unknown_fields);
    void SetUInt32(int number, uint32 value, FieldDescriptor::Type type,
                   UnknownFieldSet* unknown_fields);
    void SetUInt64(int number, uint64 value, FieldDescriptor::Type type,
                   UnknownFieldSet* unknown_fields);

    // A helper function that adds an error at the specified location of the
    // option we're currently interpreting, and returns false.
    bool AddOptionError(DescriptorPool::ErrorCollector::ErrorLocation location,
                        const string& msg) {
      builder_->AddError(options_to_interpret_->element_name,
                         *uninterpreted_option_, location, msg);
      return false;
    }

    // A helper function that adds an error at the location of the option name
    // and returns false.
    bool AddNameError(const string& msg) {
      return AddOptionError(DescriptorPool::ErrorCollector::OPTION_NAME, msg);
    }

    // A helper function that adds an error at the location of the option name
    // and returns false.
    bool AddValueError(const string& msg) {
      return AddOptionError(DescriptorPool::ErrorCollector::OPTION_VALUE, msg);
    }

    // We interpret against this builder's pool. Is never NULL. We don't own
    // this pointer.
    DescriptorBuilder* builder_;

    // The options we're currently interpreting, or NULL if we're not in a call
    // to InterpretOptions.
    const OptionsToInterpret* options_to_interpret_;

    // The option we're currently interpreting within options_to_interpret_, or
    // NULL if we're not in a call to InterpretOptions(). This points to a
    // submessage of the original option, not the mutable copy. Therefore we
    // can use it to find locations recorded by the parser.
    const UninterpretedOption* uninterpreted_option_;

    // Factory used to create the dynamic messages we need to parse
    // any aggregate option values we encounter.
    DynamicMessageFactory dynamic_factory_;

    GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(OptionInterpreter);
  };

  // Work-around for broken compilers:  According to the C++ standard,
  // OptionInterpreter should have access to the private members of any class
  // which has declared DescriptorBuilder as a friend.  Unfortunately some old
  // versions of GCC and other compilers do not implement this correctly.  So,
  // we have to have these intermediate methods to provide access.  We also
  // redundantly declare OptionInterpreter a friend just to make things extra
  // clear for these bad compilers.
  friend class OptionInterpreter;
  friend class OptionInterpreter::AggregateOptionFinder;

  static inline bool get_allow_unknown(const DescriptorPool* pool) {
    return pool->allow_unknown_;
  }
  static inline bool get_is_placeholder(const Descriptor* descriptor) {
    return descriptor->is_placeholder_;
  }
  static inline void assert_mutex_held(const DescriptorPool* pool) {
    if (pool->mutex_ != NULL) {
      pool->mutex_->AssertHeld();
    }
  }

  // Must be run only after options have been interpreted.
  //
  // NOTE: Validation code must only reference the options in the mutable
  // descriptors, which are the ones that have been interpreted. The const
  // proto references are passed in only so they can be provided to calls to
  // AddError(). Do not look at their options, which have not been interpreted.
  void ValidateFileOptions(FileDescriptor* file,
                           const FileDescriptorProto& proto);
  void ValidateMessageOptions(Descriptor* message,
                              const DescriptorProto& proto);
  void ValidateFieldOptions(FieldDescriptor* field,
                            const FieldDescriptorProto& proto);
  void ValidateEnumOptions(EnumDescriptor* enm,
                           const EnumDescriptorProto& proto);
  void ValidateEnumValueOptions(EnumValueDescriptor* enum_value,
                                const EnumValueDescriptorProto& proto);
  void ValidateServiceOptions(ServiceDescriptor* service,
                              const ServiceDescriptorProto& proto);
  void ValidateMethodOptions(MethodDescriptor* method,
                             const MethodDescriptorProto& proto);

  void ValidateMapKey(FieldDescriptor* field,
                      const FieldDescriptorProto& proto);

};

const FileDescriptor* DescriptorPool::BuildFile(
    const FileDescriptorProto& proto) {
  GOOGLE_CHECK(fallback_database_ == NULL)
    << "Cannot call BuildFile on a DescriptorPool that uses a "
       "DescriptorDatabase.  You must instead find a way to get your file "
       "into the underlying database.";
  GOOGLE_CHECK(mutex_ == NULL);   // Implied by the above GOOGLE_CHECK.
  return DescriptorBuilder(this, tables_.get(), NULL).BuildFile(proto);
}

const FileDescriptor* DescriptorPool::BuildFileCollectingErrors(
    const FileDescriptorProto& proto,
    ErrorCollector* error_collector) {
  GOOGLE_CHECK(fallback_database_ == NULL)
    << "Cannot call BuildFile on a DescriptorPool that uses a "
       "DescriptorDatabase.  You must instead find a way to get your file "
       "into the underlying database.";
  GOOGLE_CHECK(mutex_ == NULL);   // Implied by the above GOOGLE_CHECK.
  return DescriptorBuilder(this, tables_.get(),
                           error_collector).BuildFile(proto);
}

const FileDescriptor* DescriptorPool::BuildFileFromDatabase(
    const FileDescriptorProto& proto) const {
  mutex_->AssertHeld();
  return DescriptorBuilder(this, tables_.get(),
                           default_error_collector_).BuildFile(proto);
}

DescriptorBuilder::DescriptorBuilder(
    const DescriptorPool* pool,
    DescriptorPool::Tables* tables,
    DescriptorPool::ErrorCollector* error_collector)
  : pool_(pool),
    tables_(tables),
    error_collector_(error_collector),
    had_errors_(false),
    possible_undeclared_dependency_(NULL) {}

DescriptorBuilder::~DescriptorBuilder() {}

void DescriptorBuilder::AddError(
    const string& element_name,
    const Message& descriptor,
    DescriptorPool::ErrorCollector::ErrorLocation location,
    const string& error) {
  if (error_collector_ == NULL) {
    if (!had_errors_) {
      GOOGLE_LOG(ERROR) << "Invalid proto descriptor for file \"" << filename_
                 << "\":";
    }
    GOOGLE_LOG(ERROR) << "  " << element_name << ": " << error;
  } else {
    error_collector_->AddError(filename_, element_name,
                               &descriptor, location, error);
  }
  had_errors_ = true;
}

void DescriptorBuilder::AddNotDefinedError(
    const string& element_name,
    const Message& descriptor,
    DescriptorPool::ErrorCollector::ErrorLocation location,
    const string& undefined_symbol) {
  if (possible_undeclared_dependency_ == NULL) {
    AddError(element_name, descriptor, location,
             "\"" + undefined_symbol + "\" is not defined.");
  } else {
    AddError(element_name, descriptor, location,
             "\"" + possible_undeclared_dependency_name_ +
             "\" seems to be defined in \"" +
             possible_undeclared_dependency_->name() + "\", which is not "
             "imported by \"" + filename_ + "\".  To use it here, please "
             "add the necessary import.");
  }
}

bool DescriptorBuilder::IsInPackage(const FileDescriptor* file,
                                    const string& package_name) {
  return HasPrefixString(file->package(), package_name) &&
           (file->package().size() == package_name.size() ||
            file->package()[package_name.size()] == '.');
}

void DescriptorBuilder::RecordPublicDependencies(const FileDescriptor* file) {
  if (file == NULL || !dependencies_.insert(file).second) return;
  for (int i = 0; file != NULL && i < file->public_dependency_count(); i++) {
    RecordPublicDependencies(file->public_dependency(i));
  }
}

Symbol DescriptorBuilder::FindSymbolNotEnforcingDepsHelper(
    const DescriptorPool* pool, const string& name) {
  // If we are looking at an underlay, we must lock its mutex_, since we are
  // accessing the underlay's tables_ directly.
  MutexLockMaybe lock((pool == pool_) ? NULL : pool->mutex_);

  Symbol result = pool->tables_->FindSymbol(name);
  if (result.IsNull() && pool->underlay_ != NULL) {
    // Symbol not found; check the underlay.
    result = FindSymbolNotEnforcingDepsHelper(pool->underlay_, name);
  }

  if (result.IsNull()) {
    // In theory, we shouldn't need to check fallback_database_ because the
    // symbol should be in one of its file's direct dependencies, and we have
    // already loaded those by the time we get here.  But we check anyway so
    // that we can generate better error message when dependencies are missing
    // (i.e., "missing dependency" rather than "type is not defined").
    if (pool->TryFindSymbolInFallbackDatabase(name)) {
      result = pool->tables_->FindSymbol(name);
    }
  }

  return result;
}

Symbol DescriptorBuilder::FindSymbolNotEnforcingDeps(const string& name) {
  return FindSymbolNotEnforcingDepsHelper(pool_, name);
}

Symbol DescriptorBuilder::FindSymbol(const string& name) {
  Symbol result = FindSymbolNotEnforcingDeps(name);

  if (result.IsNull()) return result;

  if (!pool_->enforce_dependencies_) {
    // Hack for CompilerUpgrader.
    return result;
  }

  // Only find symbols which were defined in this file or one of its
  // dependencies.
  const FileDescriptor* file = result.GetFile();
  if (file == file_ || dependencies_.count(file) > 0) return result;

  if (result.type == Symbol::PACKAGE) {
    // Arg, this is overcomplicated.  The symbol is a package name.  It could
    // be that the package was defined in multiple files.  result.GetFile()
    // returns the first file we saw that used this package.  We've determined
    // that that file is not a direct dependency of the file we are currently
    // building, but it could be that some other file which *is* a direct
    // dependency also defines the same package.  We can't really rule out this
    // symbol unless none of the dependencies define it.
    if (IsInPackage(file_, name)) return result;
    for (set<const FileDescriptor*>::const_iterator it = dependencies_.begin();
         it != dependencies_.end(); ++it) {
      // Note:  A dependency may be NULL if it was not found or had errors.
      if (*it != NULL && IsInPackage(*it, name)) return result;
    }
  }

  possible_undeclared_dependency_ = file;
  possible_undeclared_dependency_name_ = name;
  return kNullSymbol;
}

Symbol DescriptorBuilder::LookupSymbolNoPlaceholder(
    const string& name, const string& relative_to, ResolveMode resolve_mode) {
  possible_undeclared_dependency_ = NULL;

  if (name.size() > 0 && name[0] == '.') {
    // Fully-qualified name.
    return FindSymbol(name.substr(1));
  }

  // If name is something like "Foo.Bar.baz", and symbols named "Foo" are
  // defined in multiple parent scopes, we only want to find "Bar.baz" in the
  // innermost one.  E.g., the following should produce an error:
  //   message Bar { message Baz {} }
  //   message Foo {
  //     message Bar {
  //     }
  //     optional Bar.Baz baz = 1;
  //   }
  // So, we look for just "Foo" first, then look for "Bar.baz" within it if
  // found.
  string::size_type name_dot_pos = name.find_first_of('.');
  string first_part_of_name;
  if (name_dot_pos == string::npos) {
    first_part_of_name = name;
  } else {
    first_part_of_name = name.substr(0, name_dot_pos);
  }

  string scope_to_try(relative_to);

  while (true) {
    // Chop off the last component of the scope.
    string::size_type dot_pos = scope_to_try.find_last_of('.');
    if (dot_pos == string::npos) {
      return FindSymbol(name);
    } else {
      scope_to_try.erase(dot_pos);
    }

    // Append ".first_part_of_name" and try to find.
    string::size_type old_size = scope_to_try.size();
    scope_to_try.append(1, '.');
    scope_to_try.append(first_part_of_name);
    Symbol result = FindSymbol(scope_to_try);
    if (!result.IsNull()) {
      if (first_part_of_name.size() < name.size()) {
        // name is a compound symbol, of which we only found the first part.
        // Now try to look up the rest of it.
        if (result.IsAggregate()) {
          scope_to_try.append(name, first_part_of_name.size(),
                              name.size() - first_part_of_name.size());
          return FindSymbol(scope_to_try);
        } else {
          // We found a symbol but it's not an aggregate.  Continue the loop.
        }
      } else {
        if (resolve_mode == LOOKUP_TYPES && !result.IsType()) {
          // We found a symbol but it's not a type.  Continue the loop.
        } else {
          return result;
        }
      }
    }

    // Not found.  Remove the name so we can try again.
    scope_to_try.erase(old_size);
  }
}

Symbol DescriptorBuilder::LookupSymbol(
    const string& name, const string& relative_to,
    PlaceholderType placeholder_type, ResolveMode resolve_mode) {
  Symbol result = LookupSymbolNoPlaceholder(
      name, relative_to, resolve_mode);
  if (result.IsNull() && pool_->allow_unknown_) {
    // Not found, but AllowUnknownDependencies() is enabled.  Return a
    // placeholder instead.
    result = NewPlaceholder(name, placeholder_type);
  }
  return result;
}

Symbol DescriptorBuilder::NewPlaceholder(const string& name,
                                         PlaceholderType placeholder_type) {
  // Compute names.
  const string* placeholder_full_name;
  const string* placeholder_name;
  const string* placeholder_package;

  if (!ValidateQualifiedName(name)) return kNullSymbol;
  if (name[0] == '.') {
    // Fully-qualified.
    placeholder_full_name = tables_->AllocateString(name.substr(1));
  } else {
    placeholder_full_name = tables_->AllocateString(name);
  }

  string::size_type dotpos = placeholder_full_name->find_last_of('.');
  if (dotpos != string::npos) {
    placeholder_package = tables_->AllocateString(
      placeholder_full_name->substr(0, dotpos));
    placeholder_name = tables_->AllocateString(
      placeholder_full_name->substr(dotpos + 1));
  } else {
    placeholder_package = &::google::protobuf::internal::GetEmptyString();
    placeholder_name = placeholder_full_name;
  }

  // Create the placeholders.
  FileDescriptor* placeholder_file = tables_->Allocate<FileDescriptor>();
  memset(placeholder_file, 0, sizeof(*placeholder_file));

  placeholder_file->source_code_info_ = &SourceCodeInfo::default_instance();

  placeholder_file->name_ =
    tables_->AllocateString(*placeholder_full_name + ".placeholder.proto");
  placeholder_file->package_ = placeholder_package;
  placeholder_file->pool_ = pool_;
  placeholder_file->options_ = &FileOptions::default_instance();
  placeholder_file->tables_ = &FileDescriptorTables::kEmpty;
  // All other fields are zero or NULL.

  if (placeholder_type == PLACEHOLDER_ENUM) {
    placeholder_file->enum_type_count_ = 1;
    placeholder_file->enum_types_ =
      tables_->AllocateArray<EnumDescriptor>(1);

    EnumDescriptor* placeholder_enum = &placeholder_file->enum_types_[0];
    memset(placeholder_enum, 0, sizeof(*placeholder_enum));

    placeholder_enum->full_name_ = placeholder_full_name;
    placeholder_enum->name_ = placeholder_name;
    placeholder_enum->file_ = placeholder_file;
    placeholder_enum->options_ = &EnumOptions::default_instance();
    placeholder_enum->is_placeholder_ = true;
    placeholder_enum->is_unqualified_placeholder_ = (name[0] != '.');

    // Enums must have at least one value.
    placeholder_enum->value_count_ = 1;
    placeholder_enum->values_ = tables_->AllocateArray<EnumValueDescriptor>(1);

    EnumValueDescriptor* placeholder_value = &placeholder_enum->values_[0];
    memset(placeholder_value, 0, sizeof(*placeholder_value));

    placeholder_value->name_ = tables_->AllocateString("PLACEHOLDER_VALUE");
    // Note that enum value names are siblings of their type, not children.
    placeholder_value->full_name_ =
      placeholder_package->empty() ? placeholder_value->name_ :
        tables_->AllocateString(*placeholder_package + ".PLACEHOLDER_VALUE");

    placeholder_value->number_ = 0;
    placeholder_value->type_ = placeholder_enum;
    placeholder_value->options_ = &EnumValueOptions::default_instance();

    return Symbol(placeholder_enum);
  } else {
    placeholder_file->message_type_count_ = 1;
    placeholder_file->message_types_ =
      tables_->AllocateArray<Descriptor>(1);

    Descriptor* placeholder_message = &placeholder_file->message_types_[0];
    memset(placeholder_message, 0, sizeof(*placeholder_message));

    placeholder_message->full_name_ = placeholder_full_name;
    placeholder_message->name_ = placeholder_name;
    placeholder_message->file_ = placeholder_file;
    placeholder_message->options_ = &MessageOptions::default_instance();
    placeholder_message->is_placeholder_ = true;
    placeholder_message->is_unqualified_placeholder_ = (name[0] != '.');

    if (placeholder_type == PLACEHOLDER_EXTENDABLE_MESSAGE) {
      placeholder_message->extension_range_count_ = 1;
      placeholder_message->extension_ranges_ =
        tables_->AllocateArray<Descriptor::ExtensionRange>(1);
      placeholder_message->extension_ranges_->start = 1;
      // kMaxNumber + 1 because ExtensionRange::end is exclusive.
      placeholder_message->extension_ranges_->end =
        FieldDescriptor::kMaxNumber + 1;
    }

    return Symbol(placeholder_message);
  }
}

const FileDescriptor* DescriptorBuilder::NewPlaceholderFile(
    const string& name) {
  FileDescriptor* placeholder = tables_->Allocate<FileDescriptor>();
  memset(placeholder, 0, sizeof(*placeholder));

  placeholder->name_ = tables_->AllocateString(name);
  placeholder->package_ = &::google::protobuf::internal::GetEmptyString();
  placeholder->pool_ = pool_;
  placeholder->options_ = &FileOptions::default_instance();
  placeholder->tables_ = &FileDescriptorTables::kEmpty;
  // All other fields are zero or NULL.

  return placeholder;
}

bool DescriptorBuilder::AddSymbol(
    const string& full_name, const void* parent, const string& name,
    const Message& proto, Symbol symbol) {
  // If the caller passed NULL for the parent, the symbol is at file scope.
  // Use its file as the parent instead.
  if (parent == NULL) parent = file_;

  if (tables_->AddSymbol(full_name, symbol)) {
    if (!file_tables_->AddAliasUnderParent(parent, name, symbol)) {
      GOOGLE_LOG(DFATAL) << "\"" << full_name << "\" not previously defined in "
                     "symbols_by_name_, but was defined in symbols_by_parent_; "
                     "this shouldn't be possible.";
      return false;
    }
    return true;
  } else {
    const FileDescriptor* other_file = tables_->FindSymbol(full_name).GetFile();
    if (other_file == file_) {
      string::size_type dot_pos = full_name.find_last_of('.');
      if (dot_pos == string::npos) {
        AddError(full_name, proto, DescriptorPool::ErrorCollector::NAME,
                 "\"" + full_name + "\" is already defined.");
      } else {
        AddError(full_name, proto, DescriptorPool::ErrorCollector::NAME,
                 "\"" + full_name.substr(dot_pos + 1) +
                 "\" is already defined in \"" +
                 full_name.substr(0, dot_pos) + "\".");
      }
    } else {
      // Symbol seems to have been defined in a different file.
      AddError(full_name, proto, DescriptorPool::ErrorCollector::NAME,
               "\"" + full_name + "\" is already defined in file \"" +
               other_file->name() + "\".");
    }
    return false;
  }
}

void DescriptorBuilder::AddPackage(
    const string& name, const Message& proto, const FileDescriptor* file) {
  if (tables_->AddSymbol(name, Symbol(file))) {
    // Success.  Also add parent package, if any.
    string::size_type dot_pos = name.find_last_of('.');
    if (dot_pos == string::npos) {
      // No parents.
      ValidateSymbolName(name, name, proto);
    } else {
      // Has parent.
      string* parent_name = tables_->AllocateString(name.substr(0, dot_pos));
      AddPackage(*parent_name, proto, file);
      ValidateSymbolName(name.substr(dot_pos + 1), name, proto);
    }
  } else {
    Symbol existing_symbol = tables_->FindSymbol(name);
    // It's OK to redefine a package.
    if (existing_symbol.type != Symbol::PACKAGE) {
      // Symbol seems to have been defined in a different file.
      AddError(name, proto, DescriptorPool::ErrorCollector::NAME,
               "\"" + name + "\" is already defined (as something other than "
               "a package) in file \"" + existing_symbol.GetFile()->name() +
               "\".");
    }
  }
}

void DescriptorBuilder::ValidateSymbolName(
    const string& name, const string& full_name, const Message& proto) {
  if (name.empty()) {
    AddError(full_name, proto, DescriptorPool::ErrorCollector::NAME,
             "Missing name.");
  } else {
    for (int i = 0; i < name.size(); i++) {
      // I don't trust isalnum() due to locales.  :(
      if ((name[i] < 'a' || 'z' < name[i]) &&
          (name[i] < 'A' || 'Z' < name[i]) &&
          (name[i] < '0' || '9' < name[i]) &&
          (name[i] != '_')) {
        AddError(full_name, proto, DescriptorPool::ErrorCollector::NAME,
                 "\"" + name + "\" is not a valid identifier.");
      }
    }
  }
}

bool DescriptorBuilder::ValidateQualifiedName(const string& name) {
  bool last_was_period = false;

  for (int i = 0; i < name.size(); i++) {
    // I don't trust isalnum() due to locales.  :(
    if (('a' <= name[i] && name[i] <= 'z') ||
        ('A' <= name[i] && name[i] <= 'Z') ||
        ('0' <= name[i] && name[i] <= '9') ||
        (name[i] == '_')) {
      last_was_period = false;
    } else if (name[i] == '.') {
      if (last_was_period) return false;
      last_was_period = true;
    } else {
      return false;
    }
  }

  return !name.empty() && !last_was_period;
}

// -------------------------------------------------------------------

// This generic implementation is good for all descriptors except
// FileDescriptor.
template<class DescriptorT> void DescriptorBuilder::AllocateOptions(
    const typename DescriptorT::OptionsType& orig_options,
    DescriptorT* descriptor) {
  AllocateOptionsImpl(descriptor->full_name(), descriptor->full_name(),
                      orig_options, descriptor);
}

// We specialize for FileDescriptor.
void DescriptorBuilder::AllocateOptions(const FileOptions& orig_options,
                                        FileDescriptor* descriptor) {
  // We add the dummy token so that LookupSymbol does the right thing.
  AllocateOptionsImpl(descriptor->package() + ".dummy", descriptor->name(),
                      orig_options, descriptor);
}

template<class DescriptorT> void DescriptorBuilder::AllocateOptionsImpl(
    const string& name_scope,
    const string& element_name,
    const typename DescriptorT::OptionsType& orig_options,
    DescriptorT* descriptor) {
  // We need to use a dummy pointer to work around a bug in older versions of
  // GCC.  Otherwise, the following two lines could be replaced with:
  //   typename DescriptorT::OptionsType* options =
  //       tables_->AllocateMessage<typename DescriptorT::OptionsType>();
  typename DescriptorT::OptionsType* const dummy = NULL;
  typename DescriptorT::OptionsType* options = tables_->AllocateMessage(dummy);
  // Avoid using MergeFrom()/CopyFrom() in this class to make it -fno-rtti
  // friendly. Without RTTI, MergeFrom() and CopyFrom() will fallback to the
  // reflection based method, which requires the Descriptor. However, we are in
  // the middle of building the descriptors, thus the deadlock.
  options->ParseFromString(orig_options.SerializeAsString());
  descriptor->options_ = options;

  // Don't add to options_to_interpret_ unless there were uninterpreted
  // options.  This not only avoids unnecessary work, but prevents a
  // bootstrapping problem when building descriptors for descriptor.proto.
  // descriptor.proto does not contain any uninterpreted options, but
  // attempting to interpret options anyway will cause
  // OptionsType::GetDescriptor() to be called which may then deadlock since
  // we're still trying to build it.
  if (options->uninterpreted_option_size() > 0) {
    options_to_interpret_.push_back(
        OptionsToInterpret(name_scope, element_name, &orig_options, options));
  }
}


// A common pattern:  We want to convert a repeated field in the descriptor
// to an array of values, calling some method to build each value.
#define BUILD_ARRAY(INPUT, OUTPUT, NAME, METHOD, PARENT)             \
  OUTPUT->NAME##_count_ = INPUT.NAME##_size();                       \
  AllocateArray(INPUT.NAME##_size(), &OUTPUT->NAME##s_);             \
  for (int i = 0; i < INPUT.NAME##_size(); i++) {                    \
    METHOD(INPUT.NAME(i), PARENT, OUTPUT->NAME##s_ + i);             \
  }

const FileDescriptor* DescriptorBuilder::BuildFile(
    const FileDescriptorProto& proto) {
  filename_ = proto.name();

  // Check if the file already exists and is identical to the one being built.
  // Note:  This only works if the input is canonical -- that is, it
  //   fully-qualifies all type names, has no UninterpretedOptions, etc.
  //   This is fine, because this idempotency "feature" really only exists to
  //   accomodate one hack in the proto1->proto2 migration layer.
  const FileDescriptor* existing_file = tables_->FindFile(filename_);
  if (existing_file != NULL) {
    // File already in pool.  Compare the existing one to the input.
    FileDescriptorProto existing_proto;
    existing_file->CopyTo(&existing_proto);
    if (existing_proto.SerializeAsString() == proto.SerializeAsString()) {
      // They're identical.  Return the existing descriptor.
      return existing_file;
    }

    // Not a match.  The error will be detected and handled later.
  }

  // Check to see if this file is already on the pending files list.
  // TODO(kenton):  Allow recursive imports?  It may not work with some
  //   (most?) programming languages.  E.g., in C++, a forward declaration
  //   of a type is not sufficient to allow it to be used even in a
  //   generated header file due to inlining.  This could perhaps be
  //   worked around using tricks involving inserting #include statements
  //   mid-file, but that's pretty ugly, and I'm pretty sure there are
  //   some languages out there that do not allow recursive dependencies
  //   at all.
  for (int i = 0; i < tables_->pending_files_.size(); i++) {
    if (tables_->pending_files_[i] == proto.name()) {
      string error_message("File recursively imports itself: ");
      for (; i < tables_->pending_files_.size(); i++) {
        error_message.append(tables_->pending_files_[i]);
        error_message.append(" -> ");
      }
      error_message.append(proto.name());

      AddError(proto.name(), proto, DescriptorPool::ErrorCollector::OTHER,
               error_message);
      return NULL;
    }
  }

  // If we have a fallback_database_, attempt to load all dependencies now,
  // before checkpointing tables_.  This avoids confusion with recursive
  // checkpoints.
  if (pool_->fallback_database_ != NULL) {
    tables_->pending_files_.push_back(proto.name());
    for (int i = 0; i < proto.dependency_size(); i++) {
      if (tables_->FindFile(proto.dependency(i)) == NULL &&
          (pool_->underlay_ == NULL ||
           pool_->underlay_->FindFileByName(proto.dependency(i)) == NULL)) {
        // We don't care what this returns since we'll find out below anyway.
        pool_->TryFindFileInFallbackDatabase(proto.dependency(i));
      }
    }
    tables_->pending_files_.pop_back();
  }

  // Checkpoint the tables so that we can roll back if something goes wrong.
  tables_->AddCheckpoint();

  FileDescriptor* result = tables_->Allocate<FileDescriptor>();
  file_ = result;

  if (proto.has_source_code_info()) {
    SourceCodeInfo *info = tables_->AllocateMessage<SourceCodeInfo>();
    info->CopyFrom(proto.source_code_info());
    result->source_code_info_ = info;
  } else {
    result->source_code_info_ = &SourceCodeInfo::default_instance();
  }

  file_tables_ = tables_->AllocateFileTables();
  file_->tables_ = file_tables_;

  if (!proto.has_name()) {
    AddError("", proto, DescriptorPool::ErrorCollector::OTHER,
             "Missing field: FileDescriptorProto.name.");
  }

  result->name_ = tables_->AllocateString(proto.name());
  if (proto.has_package()) {
    result->package_ = tables_->AllocateString(proto.package());
  } else {
    // We cannot rely on proto.package() returning a valid string if
    // proto.has_package() is false, because we might be running at static
    // initialization time, in which case default values have not yet been
    // initialized.
    result->package_ = tables_->AllocateString("");
  }
  result->pool_ = pool_;

  // Add to tables.
  if (!tables_->AddFile(result)) {
    AddError(proto.name(), proto, DescriptorPool::ErrorCollector::OTHER,
             "A file with this name is already in the pool.");
    // Bail out early so that if this is actually the exact same file, we
    // don't end up reporting that every single symbol is already defined.
    tables_->RollbackToLastCheckpoint();
    return NULL;
  }
  if (!result->package().empty()) {
    AddPackage(result->package(), proto, result);
  }

  // Make sure all dependencies are loaded.
  set<string> seen_dependencies;
  result->dependency_count_ = proto.dependency_size();
  result->dependencies_ =
    tables_->AllocateArray<const FileDescriptor*>(proto.dependency_size());
  for (int i = 0; i < proto.dependency_size(); i++) {
    if (!seen_dependencies.insert(proto.dependency(i)).second) {
      AddError(proto.name(), proto,
               DescriptorPool::ErrorCollector::OTHER,
               "Import \"" + proto.dependency(i) + "\" was listed twice.");
    }

    const FileDescriptor* dependency = tables_->FindFile(proto.dependency(i));
    if (dependency == NULL && pool_->underlay_ != NULL) {
      dependency = pool_->underlay_->FindFileByName(proto.dependency(i));
    }

    if (dependency == NULL) {
      if (pool_->allow_unknown_) {
        dependency = NewPlaceholderFile(proto.dependency(i));
      } else {
        string message;
        if (pool_->fallback_database_ == NULL) {
          message = "Import \"" + proto.dependency(i) +
                    "\" has not been loaded.";
        } else {
          message = "Import \"" + proto.dependency(i) +
                    "\" was not found or had errors.";
        }
        AddError(proto.name(), proto,
                 DescriptorPool::ErrorCollector::OTHER,
                 message);
      }
    }

    result->dependencies_[i] = dependency;
  }

  // Check public dependencies.
  int public_dependency_count = 0;
  result->public_dependencies_ = tables_->AllocateArray<int>(
      proto.public_dependency_size());
  for (int i = 0; i < proto.public_dependency_size(); i++) {
    // Only put valid public dependency indexes.
    int index = proto.public_dependency(i);
    if (index >= 0 && index < proto.dependency_size()) {
      result->public_dependencies_[public_dependency_count++] = index;
    } else {
      AddError(proto.name(), proto,
               DescriptorPool::ErrorCollector::OTHER,
               "Invalid public dependency index.");
    }
  }
  result->public_dependency_count_ = public_dependency_count;

  // Build dependency set
  dependencies_.clear();
  for (int i = 0; i < result->dependency_count(); i++) {
    RecordPublicDependencies(result->dependency(i));
  }

  // Check weak dependencies.
  int weak_dependency_count = 0;
  result->weak_dependencies_ = tables_->AllocateArray<int>(
      proto.weak_dependency_size());
  for (int i = 0; i < proto.weak_dependency_size(); i++) {
    int index = proto.weak_dependency(i);
    if (index >= 0 && index < proto.dependency_size()) {
      result->weak_dependencies_[weak_dependency_count++] = index;
    } else {
      AddError(proto.name(), proto,
               DescriptorPool::ErrorCollector::OTHER,
               "Invalid weak dependency index.");
    }
  }
  result->weak_dependency_count_ = weak_dependency_count;

  // Convert children.
  BUILD_ARRAY(proto, result, message_type, BuildMessage  , NULL);
  BUILD_ARRAY(proto, result, enum_type   , BuildEnum     , NULL);
  BUILD_ARRAY(proto, result, service     , BuildService  , NULL);
  BUILD_ARRAY(proto, result, extension   , BuildExtension, NULL);

  // Copy options.
  if (!proto.has_options()) {
    result->options_ = NULL;  // Will set to default_instance later.
  } else {
    AllocateOptions(proto.options(), result);
  }

  // Note that the following steps must occur in exactly the specified order.

  // Cross-link.
  CrossLinkFile(result, proto);

  // Interpret any remaining uninterpreted options gathered into
  // options_to_interpret_ during descriptor building.  Cross-linking has made
  // extension options known, so all interpretations should now succeed.
  if (!had_errors_) {
    OptionInterpreter option_interpreter(this);
    for (vector<OptionsToInterpret>::iterator iter =
             options_to_interpret_.begin();
         iter != options_to_interpret_.end(); ++iter) {
      option_interpreter.InterpretOptions(&(*iter));
    }
    options_to_interpret_.clear();
  }

  // Validate options.
  if (!had_errors_) {
    ValidateFileOptions(result, proto);
  }

  if (had_errors_) {
    tables_->RollbackToLastCheckpoint();
    return NULL;
  } else {
    tables_->ClearLastCheckpoint();
    return result;
  }
}

void DescriptorBuilder::BuildMessage(const DescriptorProto& proto,
                                     const Descriptor* parent,
                                     Descriptor* result) {
  const string& scope = (parent == NULL) ?
    file_->package() : parent->full_name();
  string* full_name = tables_->AllocateString(scope);
  if (!full_name->empty()) full_name->append(1, '.');
  full_name->append(proto.name());

  ValidateSymbolName(proto.name(), *full_name, proto);

  result->name_            = tables_->AllocateString(proto.name());
  result->full_name_       = full_name;
  result->file_            = file_;
  result->containing_type_ = parent;
  result->is_placeholder_  = false;
  result->is_unqualified_placeholder_ = false;

  BUILD_ARRAY(proto, result, field          , BuildField         , result);
  BUILD_ARRAY(proto, result, nested_type    , BuildMessage       , result);
  BUILD_ARRAY(proto, result, enum_type      , BuildEnum          , result);
  BUILD_ARRAY(proto, result, extension_range, BuildExtensionRange, result);
  BUILD_ARRAY(proto, result, extension      , BuildExtension     , result);

  // Copy options.
  if (!proto.has_options()) {
    result->options_ = NULL;  // Will set to default_instance later.
  } else {
    AllocateOptions(proto.options(), result);
  }

  AddSymbol(result->full_name(), parent, result->name(),
            proto, Symbol(result));

  // Check that no fields have numbers in extension ranges.
  for (int i = 0; i < result->field_count(); i++) {
    const FieldDescriptor* field = result->field(i);
    for (int j = 0; j < result->extension_range_count(); j++) {
      const Descriptor::ExtensionRange* range = result->extension_range(j);
      if (range->start <= field->number() && field->number() < range->end) {
        AddError(field->full_name(), proto.extension_range(j),
                 DescriptorPool::ErrorCollector::NUMBER,
                 strings::Substitute(
                   "Extension range $0 to $1 includes field \"$2\" ($3).",
                   range->start, range->end - 1,
                   field->name(), field->number()));
      }
    }
  }

  // Check that extension ranges don't overlap.
  for (int i = 0; i < result->extension_range_count(); i++) {
    const Descriptor::ExtensionRange* range1 = result->extension_range(i);
    for (int j = i + 1; j < result->extension_range_count(); j++) {
      const Descriptor::ExtensionRange* range2 = result->extension_range(j);
      if (range1->end > range2->start && range2->end > range1->start) {
        AddError(result->full_name(), proto.extension_range(j),
                 DescriptorPool::ErrorCollector::NUMBER,
                 strings::Substitute("Extension range $0 to $1 overlaps with "
                                     "already-defined range $2 to $3.",
                                     range2->start, range2->end - 1,
                                     range1->start, range1->end - 1));
      }
    }
  }
}

void DescriptorBuilder::BuildFieldOrExtension(const FieldDescriptorProto& proto,
                                              const Descriptor* parent,
                                              FieldDescriptor* result,
                                              bool is_extension) {
  const string& scope = (parent == NULL) ?
    file_->package() : parent->full_name();
  string* full_name = tables_->AllocateString(scope);
  if (!full_name->empty()) full_name->append(1, '.');
  full_name->append(proto.name());

  ValidateSymbolName(proto.name(), *full_name, proto);

  result->name_         = tables_->AllocateString(proto.name());
  result->full_name_    = full_name;
  result->file_         = file_;
  result->number_       = proto.number();
  result->is_extension_ = is_extension;

  // If .proto files follow the style guide then the name should already be
  // lower-cased.  If that's the case we can just reuse the string we already
  // allocated rather than allocate a new one.
  string lowercase_name(proto.name());
  LowerString(&lowercase_name);
  if (lowercase_name == proto.name()) {
    result->lowercase_name_ = result->name_;
  } else {
    result->lowercase_name_ = tables_->AllocateString(lowercase_name);
  }

  // Don't bother with the above optimization for camel-case names since
  // .proto files that follow the guide shouldn't be using names in this
  // format, so the optimization wouldn't help much.
  result->camelcase_name_ = tables_->AllocateString(ToCamelCase(proto.name()));

  // Some compilers do not allow static_cast directly between two enum types,
  // so we must cast to int first.
  result->type_  = static_cast<FieldDescriptor::Type>(
                     implicit_cast<int>(proto.type()));
  result->label_ = static_cast<FieldDescriptor::Label>(
                     implicit_cast<int>(proto.label()));

  // Some of these may be filled in when cross-linking.
  result->containing_type_ = NULL;
  result->extension_scope_ = NULL;
  result->experimental_map_key_ = NULL;
  result->message_type_ = NULL;
  result->enum_type_ = NULL;

  result->has_default_value_ = proto.has_default_value();
  if (proto.has_default_value() && result->is_repeated()) {
    AddError(result->full_name(), proto,
             DescriptorPool::ErrorCollector::DEFAULT_VALUE,
             "Repeated fields can't have default values.");
  }

  if (proto.has_type()) {
    if (proto.has_default_value()) {
      char* end_pos = NULL;
      switch (result->cpp_type()) {
        case FieldDescriptor::CPPTYPE_INT32:
          result->default_value_int32_ =
            strtol(proto.default_value().c_str(), &end_pos, 0);
          break;
        case FieldDescriptor::CPPTYPE_INT64:
          result->default_value_int64_ =
            strto64(proto.default_value().c_str(), &end_pos, 0);
          break;
        case FieldDescriptor::CPPTYPE_UINT32:
          result->default_value_uint32_ =
            strtoul(proto.default_value().c_str(), &end_pos, 0);
          break;
        case FieldDescriptor::CPPTYPE_UINT64:
          result->default_value_uint64_ =
            strtou64(proto.default_value().c_str(), &end_pos, 0);
          break;
        case FieldDescriptor::CPPTYPE_FLOAT:
          if (proto.default_value() == "inf") {
            result->default_value_float_ = numeric_limits<float>::infinity();
          } else if (proto.default_value() == "-inf") {
            result->default_value_float_ = -numeric_limits<float>::infinity();
          } else if (proto.default_value() == "nan") {
            result->default_value_float_ = numeric_limits<float>::quiet_NaN();
          } else  {
            result->default_value_float_ =
              NoLocaleStrtod(proto.default_value().c_str(), &end_pos);
          }
          break;
        case FieldDescriptor::CPPTYPE_DOUBLE:
          if (proto.default_value() == "inf") {
            result->default_value_double_ = numeric_limits<double>::infinity();
          } else if (proto.default_value() == "-inf") {
            result->default_value_double_ = -numeric_limits<double>::infinity();
          } else if (proto.default_value() == "nan") {
            result->default_value_double_ = numeric_limits<double>::quiet_NaN();
          } else  {
            result->default_value_double_ =
              NoLocaleStrtod(proto.default_value().c_str(), &end_pos);
          }
          break;
        case FieldDescriptor::CPPTYPE_BOOL:
          if (proto.default_value() == "true") {
            result->default_value_bool_ = true;
          } else if (proto.default_value() == "false") {
            result->default_value_bool_ = false;
          } else {
            AddError(result->full_name(), proto,
                     DescriptorPool::ErrorCollector::DEFAULT_VALUE,
                     "Boolean default must be true or false.");
          }
          break;
        case FieldDescriptor::CPPTYPE_ENUM:
          // This will be filled in when cross-linking.
          result->default_value_enum_ = NULL;
          break;
        case FieldDescriptor::CPPTYPE_STRING:
          if (result->type() == FieldDescriptor::TYPE_BYTES) {
            result->default_value_string_ = tables_->AllocateString(
              UnescapeCEscapeString(proto.default_value()));
          } else {
            result->default_value_string_ =
                tables_->AllocateString(proto.default_value());
          }
          break;
        case FieldDescriptor::CPPTYPE_MESSAGE:
          AddError(result->full_name(), proto,
                   DescriptorPool::ErrorCollector::DEFAULT_VALUE,
                   "Messages can't have default values.");
          result->has_default_value_ = false;
          break;
      }

      if (end_pos != NULL) {
        // end_pos is only set non-NULL by the parsers for numeric types, above.
        // This checks that the default was non-empty and had no extra junk
        // after the end of the number.
        if (proto.default_value().empty() || *end_pos != '\0') {
          AddError(result->full_name(), proto,
                   DescriptorPool::ErrorCollector::DEFAULT_VALUE,
                   "Couldn't parse default value.");
        }
      }
    } else {
      // No explicit default value
      switch (result->cpp_type()) {
        case FieldDescriptor::CPPTYPE_INT32:
          result->default_value_int32_ = 0;
          break;
        case FieldDescriptor::CPPTYPE_INT64:
          result->default_value_int64_ = 0;
          break;
        case FieldDescriptor::CPPTYPE_UINT32:
          result->default_value_uint32_ = 0;
          break;
        case FieldDescriptor::CPPTYPE_UINT64:
          result->default_value_uint64_ = 0;
          break;
        case FieldDescriptor::CPPTYPE_FLOAT:
          result->default_value_float_ = 0.0f;
          break;
        case FieldDescriptor::CPPTYPE_DOUBLE:
          result->default_value_double_ = 0.0;
          break;
        case FieldDescriptor::CPPTYPE_BOOL:
          result->default_value_bool_ = false;
          break;
        case FieldDescriptor::CPPTYPE_ENUM:
          // This will be filled in when cross-linking.
          result->default_value_enum_ = NULL;
          break;
        case FieldDescriptor::CPPTYPE_STRING:
          result->default_value_string_ = &::google::protobuf::internal::GetEmptyString();
          break;
        case FieldDescriptor::CPPTYPE_MESSAGE:
          break;
      }
    }
  }

  if (result->number() <= 0) {
    AddError(result->full_name(), proto, DescriptorPool::ErrorCollector::NUMBER,
             "Field numbers must be positive integers.");
  } else if (!is_extension && result->number() > FieldDescriptor::kMaxNumber) {
    // Only validate that the number is within the valid field range if it is
    // not an extension. Since extension numbers are validated with the
    // extendee's valid set of extension numbers, and those are in turn
    // validated against the max allowed number, the check is unnecessary for
    // extension fields.
    // This avoids cross-linking issues that arise when attempting to check if
    // the extendee is a message_set_wire_format message, which has a higher max
    // on extension numbers.
    AddError(result->full_name(), proto, DescriptorPool::ErrorCollector::NUMBER,
             strings::Substitute("Field numbers cannot be greater than $0.",
                                 FieldDescriptor::kMaxNumber));
  } else if (result->number() >= FieldDescriptor::kFirstReservedNumber &&
             result->number() <= FieldDescriptor::kLastReservedNumber) {
    AddError(result->full_name(), proto, DescriptorPool::ErrorCollector::NUMBER,
             strings::Substitute(
               "Field numbers $0 through $1 are reserved for the protocol "
               "buffer library implementation.",
               FieldDescriptor::kFirstReservedNumber,
               FieldDescriptor::kLastReservedNumber));
  }

  if (is_extension) {
    if (!proto.has_extendee()) {
      AddError(result->full_name(), proto,
               DescriptorPool::ErrorCollector::EXTENDEE,
               "FieldDescriptorProto.extendee not set for extension field.");
    }

    result->extension_scope_ = parent;
  } else {
    if (proto.has_extendee()) {
      AddError(result->full_name(), proto,
               DescriptorPool::ErrorCollector::EXTENDEE,
               "FieldDescriptorProto.extendee set for non-extension field.");
    }

    result->containing_type_ = parent;
  }

  // Copy options.
  if (!proto.has_options()) {
    result->options_ = NULL;  // Will set to default_instance later.
  } else {
    AllocateOptions(proto.options(), result);
  }

  AddSymbol(result->full_name(), parent, result->name(),
            proto, Symbol(result));
}

void DescriptorBuilder::BuildExtensionRange(
    const DescriptorProto::ExtensionRange& proto,
    const Descriptor* parent,
    Descriptor::ExtensionRange* result) {
  result->start = proto.start();
  result->end = proto.end();
  if (result->start <= 0) {
    AddError(parent->full_name(), proto,
             DescriptorPool::ErrorCollector::NUMBER,
             "Extension numbers must be positive integers.");
  }

  // Checking of the upper bound of the extension range is deferred until after
  // options interpreting. This allows messages with message_set_wire_format to
  // have extensions beyond FieldDescriptor::kMaxNumber, since the extension
  // numbers are actually used as int32s in the message_set_wire_format.

  if (result->start >= result->end) {
    AddError(parent->full_name(), proto,
             DescriptorPool::ErrorCollector::NUMBER,
             "Extension range end number must be greater than start number.");
  }
}

void DescriptorBuilder::BuildEnum(const EnumDescriptorProto& proto,
                                  const Descriptor* parent,
                                  EnumDescriptor* result) {
  const string& scope = (parent == NULL) ?
    file_->package() : parent->full_name();
  string* full_name = tables_->AllocateString(scope);
  if (!full_name->empty()) full_name->append(1, '.');
  full_name->append(proto.name());

  ValidateSymbolName(proto.name(), *full_name, proto);

  result->name_            = tables_->AllocateString(proto.name());
  result->full_name_       = full_name;
  result->file_            = file_;
  result->containing_type_ = parent;
  result->is_placeholder_  = false;
  result->is_unqualified_placeholder_ = false;

  if (proto.value_size() == 0) {
    // We cannot allow enums with no values because this would mean there
    // would be no valid default value for fields of this type.
    AddError(result->full_name(), proto,
             DescriptorPool::ErrorCollector::NAME,
             "Enums must contain at least one value.");
  }

  BUILD_ARRAY(proto, result, value, BuildEnumValue, result);

  // Copy options.
  if (!proto.has_options()) {
    result->options_ = NULL;  // Will set to default_instance later.
  } else {
    AllocateOptions(proto.options(), result);
  }

  AddSymbol(result->full_name(), parent, result->name(),
            proto, Symbol(result));
}

void DescriptorBuilder::BuildEnumValue(const EnumValueDescriptorProto& proto,
                                       const EnumDescriptor* parent,
                                       EnumValueDescriptor* result) {
  result->name_   = tables_->AllocateString(proto.name());
  result->number_ = proto.number();
  result->type_   = parent;

  // Note:  full_name for enum values is a sibling to the parent's name, not a
  //   child of it.
  string* full_name = tables_->AllocateString(*parent->full_name_);
  full_name->resize(full_name->size() - parent->name_->size());
  full_name->append(*result->name_);
  result->full_name_ = full_name;

  ValidateSymbolName(proto.name(), *full_name, proto);

  // Copy options.
  if (!proto.has_options()) {
    result->options_ = NULL;  // Will set to default_instance later.
  } else {
    AllocateOptions(proto.options(), result);
  }

  // Again, enum values are weird because we makes them appear as siblings
  // of the enum type instead of children of it.  So, we use
  // parent->containing_type() as the value's parent.
  bool added_to_outer_scope =
    AddSymbol(result->full_name(), parent->containing_type(), result->name(),
              proto, Symbol(result));

  // However, we also want to be able to search for values within a single
  // enum type, so we add it as a child of the enum type itself, too.
  // Note:  This could fail, but if it does, the error has already been
  //   reported by the above AddSymbol() call, so we ignore the return code.
  bool added_to_inner_scope =
    file_tables_->AddAliasUnderParent(parent, result->name(), Symbol(result));

  if (added_to_inner_scope && !added_to_outer_scope) {
    // This value did not conflict with any values defined in the same enum,
    // but it did conflict with some other symbol defined in the enum type's
    // scope.  Let's print an additional error to explain this.
    string outer_scope;
    if (parent->containing_type() == NULL) {
      outer_scope = file_->package();
    } else {
      outer_scope = parent->containing_type()->full_name();
    }

    if (outer_scope.empty()) {
      outer_scope = "the global scope";
    } else {
      outer_scope = "\"" + outer_scope + "\"";
    }

    AddError(result->full_name(), proto,
             DescriptorPool::ErrorCollector::NAME,
             "Note that enum values use C++ scoping rules, meaning that "
             "enum values are siblings of their type, not children of it.  "
             "Therefore, \"" + result->name() + "\" must be unique within "
             + outer_scope + ", not just within \"" + parent->name() + "\".");
  }

  // An enum is allowed to define two numbers that refer to the same value.
  // FindValueByNumber() should return the first such value, so we simply
  // ignore AddEnumValueByNumber()'s return code.
  file_tables_->AddEnumValueByNumber(result);
}

void DescriptorBuilder::BuildService(const ServiceDescriptorProto& proto,
                                     const void* dummy,
                                     ServiceDescriptor* result) {
  string* full_name = tables_->AllocateString(file_->package());
  if (!full_name->empty()) full_name->append(1, '.');
  full_name->append(proto.name());

  ValidateSymbolName(proto.name(), *full_name, proto);

  result->name_      = tables_->AllocateString(proto.name());
  result->full_name_ = full_name;
  result->file_      = file_;

  BUILD_ARRAY(proto, result, method, BuildMethod, result);

  // Copy options.
  if (!proto.has_options()) {
    result->options_ = NULL;  // Will set to default_instance later.
  } else {
    AllocateOptions(proto.options(), result);
  }

  AddSymbol(result->full_name(), NULL, result->name(),
            proto, Symbol(result));
}

void DescriptorBuilder::BuildMethod(const MethodDescriptorProto& proto,
                                    const ServiceDescriptor* parent,
                                    MethodDescriptor* result) {
  result->name_    = tables_->AllocateString(proto.name());
  result->service_ = parent;

  string* full_name = tables_->AllocateString(parent->full_name());
  full_name->append(1, '.');
  full_name->append(*result->name_);
  result->full_name_ = full_name;

  ValidateSymbolName(proto.name(), *full_name, proto);

  // These will be filled in when cross-linking.
  result->input_type_ = NULL;
  result->output_type_ = NULL;

  // Copy options.
  if (!proto.has_options()) {
    result->options_ = NULL;  // Will set to default_instance later.
  } else {
    AllocateOptions(proto.options(), result);
  }

  AddSymbol(result->full_name(), parent, result->name(),
            proto, Symbol(result));
}

#undef BUILD_ARRAY

// -------------------------------------------------------------------

void DescriptorBuilder::CrossLinkFile(
    FileDescriptor* file, const FileDescriptorProto& proto) {
  if (file->options_ == NULL) {
    file->options_ = &FileOptions::default_instance();
  }

  for (int i = 0; i < file->message_type_count(); i++) {
    CrossLinkMessage(&file->message_types_[i], proto.message_type(i));
  }

  for (int i = 0; i < file->extension_count(); i++) {
    CrossLinkField(&file->extensions_[i], proto.extension(i));
  }

  for (int i = 0; i < file->enum_type_count(); i++) {
    CrossLinkEnum(&file->enum_types_[i], proto.enum_type(i));
  }

  for (int i = 0; i < file->service_count(); i++) {
    CrossLinkService(&file->services_[i], proto.service(i));
  }
}

void DescriptorBuilder::CrossLinkMessage(
    Descriptor* message, const DescriptorProto& proto) {
  if (message->options_ == NULL) {
    message->options_ = &MessageOptions::default_instance();
  }

  for (int i = 0; i < message->nested_type_count(); i++) {
    CrossLinkMessage(&message->nested_types_[i], proto.nested_type(i));
  }

  for (int i = 0; i < message->enum_type_count(); i++) {
    CrossLinkEnum(&message->enum_types_[i], proto.enum_type(i));
  }

  for (int i = 0; i < message->field_count(); i++) {
    CrossLinkField(&message->fields_[i], proto.field(i));
  }

  for (int i = 0; i < message->extension_count(); i++) {
    CrossLinkField(&message->extensions_[i], proto.extension(i));
  }
}

void DescriptorBuilder::CrossLinkField(
    FieldDescriptor* field, const FieldDescriptorProto& proto) {
  if (field->options_ == NULL) {
    field->options_ = &FieldOptions::default_instance();
  }

  if (proto.has_extendee()) {
    Symbol extendee = LookupSymbol(proto.extendee(), field->full_name(),
                                   PLACEHOLDER_EXTENDABLE_MESSAGE);
    if (extendee.IsNull()) {
      AddNotDefinedError(field->full_name(), proto,
                         DescriptorPool::ErrorCollector::EXTENDEE,
                         proto.extendee());
      return;
    } else if (extendee.type != Symbol::MESSAGE) {
      AddError(field->full_name(), proto,
               DescriptorPool::ErrorCollector::EXTENDEE,
               "\"" + proto.extendee() + "\" is not a message type.");
      return;
    }
    field->containing_type_ = extendee.descriptor;

    if (!field->containing_type()->IsExtensionNumber(field->number())) {
      AddError(field->full_name(), proto,
               DescriptorPool::ErrorCollector::NUMBER,
               strings::Substitute("\"$0\" does not declare $1 as an "
                                   "extension number.",
                                   field->containing_type()->full_name(),
                                   field->number()));
    }
  }

  if (proto.has_type_name()) {
    // Assume we are expecting a message type unless the proto contains some
    // evidence that it expects an enum type.  This only makes a difference if
    // we end up creating a placeholder.
    bool expecting_enum = (proto.type() == FieldDescriptorProto::TYPE_ENUM) ||
                          proto.has_default_value();

    Symbol type =
      LookupSymbol(proto.type_name(), field->full_name(),
                   expecting_enum ? PLACEHOLDER_ENUM : PLACEHOLDER_MESSAGE,
                   LOOKUP_TYPES);

    if (type.IsNull()) {
      AddNotDefinedError(field->full_name(), proto,
                         DescriptorPool::ErrorCollector::TYPE,
                         proto.type_name());
      return;
    }

    if (!proto.has_type()) {
      // Choose field type based on symbol.
      if (type.type == Symbol::MESSAGE) {
        field->type_ = FieldDescriptor::TYPE_MESSAGE;
      } else if (type.type == Symbol::ENUM) {
        field->type_ = FieldDescriptor::TYPE_ENUM;
      } else {
        AddError(field->full_name(), proto,
                 DescriptorPool::ErrorCollector::TYPE,
                 "\"" + proto.type_name() + "\" is not a type.");
        return;
      }
    }

    if (field->cpp_type() == FieldDescriptor::CPPTYPE_MESSAGE) {
      if (type.type != Symbol::MESSAGE) {
        AddError(field->full_name(), proto,
                 DescriptorPool::ErrorCollector::TYPE,
                 "\"" + proto.type_name() + "\" is not a message type.");
        return;
      }
      field->message_type_ = type.descriptor;

      if (field->has_default_value()) {
        AddError(field->full_name(), proto,
                 DescriptorPool::ErrorCollector::DEFAULT_VALUE,
                 "Messages can't have default values.");
      }
    } else if (field->cpp_type() == FieldDescriptor::CPPTYPE_ENUM) {
      if (type.type != Symbol::ENUM) {
        AddError(field->full_name(), proto,
                 DescriptorPool::ErrorCollector::TYPE,
                 "\"" + proto.type_name() + "\" is not an enum type.");
        return;
      }
      field->enum_type_ = type.enum_descriptor;

      if (field->enum_type()->is_placeholder_) {
        // We can't look up default values for placeholder types.  We'll have
        // to just drop them.
        field->has_default_value_ = false;
      }

      if (field->has_default_value()) {
        // We can't just use field->enum_type()->FindValueByName() here
        // because that locks the pool's mutex, which we have already locked
        // at this point.
        Symbol default_value =
          LookupSymbolNoPlaceholder(proto.default_value(),
                                    field->enum_type()->full_name());

        if (default_value.type == Symbol::ENUM_VALUE &&
            default_value.enum_value_descriptor->type() == field->enum_type()) {
          field->default_value_enum_ = default_value.enum_value_descriptor;
        } else {
          AddError(field->full_name(), proto,
                   DescriptorPool::ErrorCollector::DEFAULT_VALUE,
                   "Enum type \"" + field->enum_type()->full_name() +
                   "\" has no value named \"" + proto.default_value() + "\".");
        }
      } else if (field->enum_type()->value_count() > 0) {
        // All enums must have at least one value, or we would have reported
        // an error elsewhere.  We use the first defined value as the default
        // if a default is not explicitly defined.
        field->default_value_enum_ = field->enum_type()->value(0);
      }
    } else {
      AddError(field->full_name(), proto, DescriptorPool::ErrorCollector::TYPE,
               "Field with primitive type has type_name.");
    }
  } else {
    if (field->cpp_type() == FieldDescriptor::CPPTYPE_MESSAGE ||
        field->cpp_type() == FieldDescriptor::CPPTYPE_ENUM) {
      AddError(field->full_name(), proto, DescriptorPool::ErrorCollector::TYPE,
               "Field with message or enum type missing type_name.");
    }
  }

  // Add the field to the fields-by-number table.
  // Note:  We have to do this *after* cross-linking because extensions do not
  //   know their containing type until now.
  if (!file_tables_->AddFieldByNumber(field)) {
    const FieldDescriptor* conflicting_field =
      file_tables_->FindFieldByNumber(field->containing_type(),
                                      field->number());
    if (field->is_extension()) {
      AddError(field->full_name(), proto,
               DescriptorPool::ErrorCollector::NUMBER,
               strings::Substitute("Extension number $0 has already been used "
                                   "in \"$1\" by extension \"$2\".",
                                   field->number(),
                                   field->containing_type()->full_name(),
                                   conflicting_field->full_name()));
    } else {
      AddError(field->full_name(), proto,
               DescriptorPool::ErrorCollector::NUMBER,
               strings::Substitute("Field number $0 has already been used in "
                                   "\"$1\" by field \"$2\".",
                                   field->number(),
                                   field->containing_type()->full_name(),
                                   conflicting_field->name()));
    }
  }

  if (field->is_extension()) {
    // No need for error checking: if the extension number collided,
    // we've already been informed of it by the if() above.
    tables_->AddExtension(field);
  }

  // Add the field to the lowercase-name and camelcase-name tables.
  file_tables_->AddFieldByStylizedNames(field);
}

void DescriptorBuilder::CrossLinkEnum(
    EnumDescriptor* enum_type, const EnumDescriptorProto& proto) {
  if (enum_type->options_ == NULL) {
    enum_type->options_ = &EnumOptions::default_instance();
  }

  for (int i = 0; i < enum_type->value_count(); i++) {
    CrossLinkEnumValue(&enum_type->values_[i], proto.value(i));
  }
}

void DescriptorBuilder::CrossLinkEnumValue(
    EnumValueDescriptor* enum_value, const EnumValueDescriptorProto& proto) {
  if (enum_value->options_ == NULL) {
    enum_value->options_ = &EnumValueOptions::default_instance();
  }
}

void DescriptorBuilder::CrossLinkService(
    ServiceDescriptor* service, const ServiceDescriptorProto& proto) {
  if (service->options_ == NULL) {
    service->options_ = &ServiceOptions::default_instance();
  }

  for (int i = 0; i < service->method_count(); i++) {
    CrossLinkMethod(&service->methods_[i], proto.method(i));
  }
}

void DescriptorBuilder::CrossLinkMethod(
    MethodDescriptor* method, const MethodDescriptorProto& proto) {
  if (method->options_ == NULL) {
    method->options_ = &MethodOptions::default_instance();
  }

  Symbol input_type = LookupSymbol(proto.input_type(), method->full_name());
  if (input_type.IsNull()) {
    AddNotDefinedError(method->full_name(), proto,
                       DescriptorPool::ErrorCollector::INPUT_TYPE,
                       proto.input_type());
  } else if (input_type.type != Symbol::MESSAGE) {
    AddError(method->full_name(), proto,
             DescriptorPool::ErrorCollector::INPUT_TYPE,
             "\"" + proto.input_type() + "\" is not a message type.");
  } else {
    method->input_type_ = input_type.descriptor;
  }

  Symbol output_type = LookupSymbol(proto.output_type(), method->full_name());
  if (output_type.IsNull()) {
    AddNotDefinedError(method->full_name(), proto,
                       DescriptorPool::ErrorCollector::OUTPUT_TYPE,
                       proto.output_type());
  } else if (output_type.type != Symbol::MESSAGE) {
    AddError(method->full_name(), proto,
             DescriptorPool::ErrorCollector::OUTPUT_TYPE,
             "\"" + proto.output_type() + "\" is not a message type.");
  } else {
    method->output_type_ = output_type.descriptor;
  }
}

// -------------------------------------------------------------------

#define VALIDATE_OPTIONS_FROM_ARRAY(descriptor, array_name, type)  \
  for (int i = 0; i < descriptor->array_name##_count(); ++i) {     \
    Validate##type##Options(descriptor->array_name##s_ + i,        \
                            proto.array_name(i));                  \
  }

// Determine if the file uses optimize_for = LITE_RUNTIME, being careful to
// avoid problems that exist at init time.
static bool IsLite(const FileDescriptor* file) {
  // TODO(kenton):  I don't even remember how many of these conditions are
  //   actually possible.  I'm just being super-safe.
  return file != NULL &&
         &file->options() != &FileOptions::default_instance() &&
         file->options().optimize_for() == FileOptions::LITE_RUNTIME;
}

void DescriptorBuilder::ValidateFileOptions(FileDescriptor* file,
                                            const FileDescriptorProto& proto) {
  VALIDATE_OPTIONS_FROM_ARRAY(file, message_type, Message);
  VALIDATE_OPTIONS_FROM_ARRAY(file, enum_type, Enum);
  VALIDATE_OPTIONS_FROM_ARRAY(file, service, Service);
  VALIDATE_OPTIONS_FROM_ARRAY(file, extension, Field);

  // Lite files can only be imported by other Lite files.
  if (!IsLite(file)) {
    for (int i = 0; i < file->dependency_count(); i++) {
      if (IsLite(file->dependency(i))) {
        AddError(
          file->name(), proto,
          DescriptorPool::ErrorCollector::OTHER,
          "Files that do not use optimize_for = LITE_RUNTIME cannot import "
          "files which do use this option.  This file is not lite, but it "
          "imports \"" + file->dependency(i)->name() + "\" which is.");
        break;
      }
    }
  }
}

void DescriptorBuilder::ValidateMessageOptions(Descriptor* message,
                                               const DescriptorProto& proto) {
  VALIDATE_OPTIONS_FROM_ARRAY(message, field, Field);
  VALIDATE_OPTIONS_FROM_ARRAY(message, nested_type, Message);
  VALIDATE_OPTIONS_FROM_ARRAY(message, enum_type, Enum);
  VALIDATE_OPTIONS_FROM_ARRAY(message, extension, Field);

  const int64 max_extension_range =
      static_cast<int64>(message->options().message_set_wire_format() ?
                         kint32max :
                         FieldDescriptor::kMaxNumber);
  for (int i = 0; i < message->extension_range_count(); ++i) {
    if (message->extension_range(i)->end > max_extension_range + 1) {
      AddError(
          message->full_name(), proto.extension_range(i),
          DescriptorPool::ErrorCollector::NUMBER,
          strings::Substitute("Extension numbers cannot be greater than $0.",
                              max_extension_range));
    }
  }
}

void DescriptorBuilder::ValidateFieldOptions(FieldDescriptor* field,
    const FieldDescriptorProto& proto) {
  if (field->options().has_experimental_map_key()) {
    ValidateMapKey(field, proto);
  }

  // Only message type fields may be lazy.
  if (field->options().lazy()) {
    if (field->type() != FieldDescriptor::TYPE_MESSAGE) {
      AddError(field->full_name(), proto,
               DescriptorPool::ErrorCollector::TYPE,
               "[lazy = true] can only be specified for submessage fields.");
    }
  }

  // Only repeated primitive fields may be packed.
  if (field->options().packed() && !field->is_packable()) {
    AddError(
      field->full_name(), proto,
      DescriptorPool::ErrorCollector::TYPE,
      "[packed = true] can only be specified for repeated primitive fields.");
  }

  // Note:  Default instance may not yet be initialized here, so we have to
  //   avoid reading from it.
  if (field->containing_type_ != NULL &&
      &field->containing_type()->options() !=
      &MessageOptions::default_instance() &&
      field->containing_type()->options().message_set_wire_format()) {
    if (field->is_extension()) {
      if (!field->is_optional() ||
          field->type() != FieldDescriptor::TYPE_MESSAGE) {
        AddError(field->full_name(), proto,
                 DescriptorPool::ErrorCollector::TYPE,
                 "Extensions of MessageSets must be optional messages.");
      }
    } else {
      AddError(field->full_name(), proto,
               DescriptorPool::ErrorCollector::NAME,
               "MessageSets cannot have fields, only extensions.");
    }
  }

  // Lite extensions can only be of Lite types.
  if (IsLite(field->file()) &&
      field->containing_type_ != NULL &&
      !IsLite(field->containing_type()->file())) {
    AddError(field->full_name(), proto,
             DescriptorPool::ErrorCollector::EXTENDEE,
             "Extensions to non-lite types can only be declared in non-lite "
             "files.  Note that you cannot extend a non-lite type to contain "
             "a lite type, but the reverse is allowed.");
  }

}

void DescriptorBuilder::ValidateEnumOptions(EnumDescriptor* enm,
                                            const EnumDescriptorProto& proto) {
  VALIDATE_OPTIONS_FROM_ARRAY(enm, value, EnumValue);
  if (!enm->options().has_allow_alias() || !enm->options().allow_alias()) {
    map<int, string> used_values;
    for (int i = 0; i < enm->value_count(); ++i) {
      const EnumValueDescriptor* enum_value = enm->value(i);
      if (used_values.find(enum_value->number()) != used_values.end()) {
        string error =
            "\"" + enum_value->full_name() +
            "\" uses the same enum value as \"" +
            used_values[enum_value->number()] + "\". If this is intended, set "
            "'option allow_alias = true;' to the enum definition.";
        if (!enm->options().allow_alias()) {
          // Generate error if duplicated enum values are explicitly disallowed.
          AddError(enm->full_name(), proto,
                   DescriptorPool::ErrorCollector::NUMBER,
                   error);
        } else {
          // Generate warning if duplicated values are found but the option
          // isn't set.
          GOOGLE_LOG(ERROR) << error;
        }
      } else {
        used_values[enum_value->number()] = enum_value->full_name();
      }
    }
  }
}

void DescriptorBuilder::ValidateEnumValueOptions(
    EnumValueDescriptor* enum_value, const EnumValueDescriptorProto& proto) {
  // Nothing to do so far.
}
void DescriptorBuilder::ValidateServiceOptions(ServiceDescriptor* service,
    const ServiceDescriptorProto& proto) {
  if (IsLite(service->file()) &&
      (service->file()->options().cc_generic_services() ||
       service->file()->options().java_generic_services())) {
    AddError(service->full_name(), proto,
             DescriptorPool::ErrorCollector::NAME,
             "Files with optimize_for = LITE_RUNTIME cannot define services "
             "unless you set both options cc_generic_services and "
             "java_generic_sevices to false.");
  }

  VALIDATE_OPTIONS_FROM_ARRAY(service, method, Method);
}

void DescriptorBuilder::ValidateMethodOptions(MethodDescriptor* method,
    const MethodDescriptorProto& proto) {
  // Nothing to do so far.
}

void DescriptorBuilder::ValidateMapKey(FieldDescriptor* field,
                                       const FieldDescriptorProto& proto) {
  if (!field->is_repeated()) {
    AddError(field->full_name(), proto, DescriptorPool::ErrorCollector::TYPE,
             "map type is only allowed for repeated fields.");
    return;
  }

  if (field->cpp_type() != FieldDescriptor::CPPTYPE_MESSAGE) {
    AddError(field->full_name(), proto, DescriptorPool::ErrorCollector::TYPE,
             "map type is only allowed for fields with a message type.");
    return;
  }

  const Descriptor* item_type = field->message_type();
  if (item_type == NULL) {
    AddError(field->full_name(), proto, DescriptorPool::ErrorCollector::TYPE,
             "Could not find field type.");
    return;
  }

  // Find the field in item_type named by "experimental_map_key"
  const string& key_name = field->options().experimental_map_key();
  const Symbol key_symbol = LookupSymbol(
      key_name,
      // We append ".key_name" to the containing type's name since
      // LookupSymbol() searches for peers of the supplied name, not
      // children of the supplied name.
      item_type->full_name() + "." + key_name);

  if (key_symbol.IsNull() || key_symbol.field_descriptor->is_extension()) {
    AddError(field->full_name(), proto, DescriptorPool::ErrorCollector::TYPE,
             "Could not find field named \"" + key_name + "\" in type \"" +
             item_type->full_name() + "\".");
    return;
  }
  const FieldDescriptor* key_field = key_symbol.field_descriptor;

  if (key_field->is_repeated()) {
    AddError(field->full_name(), proto, DescriptorPool::ErrorCollector::TYPE,
             "map_key must not name a repeated field.");
    return;
  }

  if (key_field->cpp_type() == FieldDescriptor::CPPTYPE_MESSAGE) {
    AddError(field->full_name(), proto, DescriptorPool::ErrorCollector::TYPE,
             "map key must name a scalar or string field.");
    return;
  }

  field->experimental_map_key_ = key_field;
}


#undef VALIDATE_OPTIONS_FROM_ARRAY

// -------------------------------------------------------------------

DescriptorBuilder::OptionInterpreter::OptionInterpreter(
    DescriptorBuilder* builder) : builder_(builder) {
  GOOGLE_CHECK(builder_);
}

DescriptorBuilder::OptionInterpreter::~OptionInterpreter() {
}

bool DescriptorBuilder::OptionInterpreter::InterpretOptions(
    OptionsToInterpret* options_to_interpret) {
  // Note that these may be in different pools, so we can't use the same
  // descriptor and reflection objects on both.
  Message* options = options_to_interpret->options;
  const Message* original_options = options_to_interpret->original_options;

  bool failed = false;
  options_to_interpret_ = options_to_interpret;

  // Find the uninterpreted_option field in the mutable copy of the options
  // and clear them, since we're about to interpret them.
  const FieldDescriptor* uninterpreted_options_field =
      options->GetDescriptor()->FindFieldByName("uninterpreted_option");
  GOOGLE_CHECK(uninterpreted_options_field != NULL)
      << "No field named \"uninterpreted_option\" in the Options proto.";
  options->GetReflection()->ClearField(options, uninterpreted_options_field);

  // Find the uninterpreted_option field in the original options.
  const FieldDescriptor* original_uninterpreted_options_field =
      original_options->GetDescriptor()->
          FindFieldByName("uninterpreted_option");
  GOOGLE_CHECK(original_uninterpreted_options_field != NULL)
      << "No field named \"uninterpreted_option\" in the Options proto.";

  const int num_uninterpreted_options = original_options->GetReflection()->
      FieldSize(*original_options, original_uninterpreted_options_field);
  for (int i = 0; i < num_uninterpreted_options; ++i) {
    uninterpreted_option_ = down_cast<const UninterpretedOption*>(
        &original_options->GetReflection()->GetRepeatedMessage(
            *original_options, original_uninterpreted_options_field, i));
    if (!InterpretSingleOption(options)) {
      // Error already added by InterpretSingleOption().
      failed = true;
      break;
    }
  }
  // Reset these, so we don't have any dangling pointers.
  uninterpreted_option_ = NULL;
  options_to_interpret_ = NULL;

  if (!failed) {
    // InterpretSingleOption() added the interpreted options in the
    // UnknownFieldSet, in case the option isn't yet known to us.  Now we
    // serialize the options message and deserialize it back.  That way, any
    // option fields that we do happen to know about will get moved from the
    // UnknownFieldSet into the real fields, and thus be available right away.
    // If they are not known, that's OK too. They will get reparsed into the
    // UnknownFieldSet and wait there until the message is parsed by something
    // that does know about the options.
    string buf;
    options->AppendToString(&buf);
    GOOGLE_CHECK(options->ParseFromString(buf))
        << "Protocol message serialized itself in invalid fashion.";
  }

  return !failed;
}

bool DescriptorBuilder::OptionInterpreter::InterpretSingleOption(
    Message* options) {
  // First do some basic validation.
  if (uninterpreted_option_->name_size() == 0) {
    // This should never happen unless the parser has gone seriously awry or
    // someone has manually created the uninterpreted option badly.
    return AddNameError("Option must have a name.");
  }
  if (uninterpreted_option_->name(0).name_part() == "uninterpreted_option") {
    return AddNameError("Option must not use reserved name "
                        "\"uninterpreted_option\".");
  }

  const Descriptor* options_descriptor = NULL;
  // Get the options message's descriptor from the builder's pool, so that we
  // get the version that knows about any extension options declared in the
  // file we're currently building. The descriptor should be there as long as
  // the file we're building imported "google/protobuf/descriptors.proto".

  // Note that we use DescriptorBuilder::FindSymbolNotEnforcingDeps(), not
  // DescriptorPool::FindMessageTypeByName() because we're already holding the
  // pool's mutex, and the latter method locks it again.  We don't use
  // FindSymbol() because files that use custom options only need to depend on
  // the file that defines the option, not descriptor.proto itself.
  Symbol symbol = builder_->FindSymbolNotEnforcingDeps(
    options->GetDescriptor()->full_name());
  if (!symbol.IsNull() && symbol.type == Symbol::MESSAGE) {
    options_descriptor = symbol.descriptor;
  } else {
    // The options message's descriptor was not in the builder's pool, so use
    // the standard version from the generated pool. We're not holding the
    // generated pool's mutex, so we can search it the straightforward way.
    options_descriptor = options->GetDescriptor();
  }
  GOOGLE_CHECK(options_descriptor);

  // We iterate over the name parts to drill into the submessages until we find
  // the leaf field for the option. As we drill down we remember the current
  // submessage's descriptor in |descriptor| and the next field in that
  // submessage in |field|. We also track the fields we're drilling down
  // through in |intermediate_fields|. As we go, we reconstruct the full option
  // name in |debug_msg_name|, for use in error messages.
  const Descriptor* descriptor = options_descriptor;
  const FieldDescriptor* field = NULL;
  vector<const FieldDescriptor*> intermediate_fields;
  string debug_msg_name = "";

  for (int i = 0; i < uninterpreted_option_->name_size(); ++i) {
    const string& name_part = uninterpreted_option_->name(i).name_part();
    if (debug_msg_name.size() > 0) {
      debug_msg_name += ".";
    }
    if (uninterpreted_option_->name(i).is_extension()) {
      debug_msg_name += "(" + name_part + ")";
      // Search for the extension's descriptor as an extension in the builder's
      // pool. Note that we use DescriptorBuilder::LookupSymbol(), not
      // DescriptorPool::FindExtensionByName(), for two reasons: 1) It allows
      // relative lookups, and 2) because we're already holding the pool's
      // mutex, and the latter method locks it again.
      symbol = builder_->LookupSymbol(name_part,
                                      options_to_interpret_->name_scope);
      if (!symbol.IsNull() && symbol.type == Symbol::FIELD) {
        field = symbol.field_descriptor;
      }
      // If we don't find the field then the field's descriptor was not in the
      // builder's pool, but there's no point in looking in the generated
      // pool. We require that you import the file that defines any extensions
      // you use, so they must be present in the builder's pool.
    } else {
      debug_msg_name += name_part;
      // Search for the field's descriptor as a regular field.
      field = descriptor->FindFieldByName(name_part);
    }

    if (field == NULL) {
      if (get_allow_unknown(builder_->pool_)) {
        // We can't find the option, but AllowUnknownDependencies() is enabled,
        // so we will just leave it as uninterpreted.
        AddWithoutInterpreting(*uninterpreted_option_, options);
        return true;
      } else {
        return AddNameError("Option \"" + debug_msg_name + "\" unknown.");
      }
    } else if (field->containing_type() != descriptor) {
      if (get_is_placeholder(field->containing_type())) {
        // The field is an extension of a placeholder type, so we can't
        // reliably verify whether it is a valid extension to use here (e.g.
        // we don't know if it is an extension of the correct *Options message,
        // or if it has a valid field number, etc.).  Just leave it as
        // uninterpreted instead.
        AddWithoutInterpreting(*uninterpreted_option_, options);
        return true;
      } else {
        // This can only happen if, due to some insane misconfiguration of the
        // pools, we find the options message in one pool but the field in
        // another. This would probably imply a hefty bug somewhere.
        return AddNameError("Option field \"" + debug_msg_name +
                            "\" is not a field or extension of message \"" +
                            descriptor->name() + "\".");
      }
    } else if (field->is_repeated()) {
      return AddNameError("Option field \"" + debug_msg_name +
                          "\" is repeated. Repeated options are not "
                          "supported.");
    } else if (i < uninterpreted_option_->name_size() - 1) {
      if (field->cpp_type() != FieldDescriptor::CPPTYPE_MESSAGE) {
        return AddNameError("Option \"" +  debug_msg_name +
                            "\" is an atomic type, not a message.");
      } else {
        // Drill down into the submessage.
        intermediate_fields.push_back(field);
        descriptor = field->message_type();
      }
    }
  }

  // We've found the leaf field. Now we use UnknownFieldSets to set its value
  // on the options message. We do so because the message may not yet know
  // about its extension fields, so we may not be able to set the fields
  // directly. But the UnknownFieldSets will serialize to the same wire-format
  // message, so reading that message back in once the extension fields are
  // known will populate them correctly.

  // First see if the option is already set.
  if (!ExamineIfOptionIsSet(
          intermediate_fields.begin(),
          intermediate_fields.end(),
          field, debug_msg_name,
          options->GetReflection()->GetUnknownFields(*options))) {
    return false;  // ExamineIfOptionIsSet() already added the error.
  }


  // First set the value on the UnknownFieldSet corresponding to the
  // innermost message.
  scoped_ptr<UnknownFieldSet> unknown_fields(new UnknownFieldSet());
  if (!SetOptionValue(field, unknown_fields.get())) {
    return false;  // SetOptionValue() already added the error.
  }

  // Now wrap the UnknownFieldSet with UnknownFieldSets corresponding to all
  // the intermediate messages.
  for (vector<const FieldDescriptor*>::reverse_iterator iter =
           intermediate_fields.rbegin();
       iter != intermediate_fields.rend(); ++iter) {
    scoped_ptr<UnknownFieldSet> parent_unknown_fields(new UnknownFieldSet());
    switch ((*iter)->type()) {
      case FieldDescriptor::TYPE_MESSAGE: {
        io::StringOutputStream outstr(
            parent_unknown_fields->AddLengthDelimited((*iter)->number()));
        io::CodedOutputStream out(&outstr);
        internal::WireFormatLite::SerializeUnknownFields(*unknown_fields, &out);
        GOOGLE_CHECK(!out.HadError())
            << "Unexpected failure while serializing option submessage "
            << debug_msg_name << "\".";
        break;
      }

      case FieldDescriptor::TYPE_GROUP: {
         parent_unknown_fields->AddGroup((*iter)->number())
                              ->MergeFrom(*unknown_fields);
        break;
      }

      default:
        GOOGLE_LOG(FATAL) << "Invalid wire type for CPPTYPE_MESSAGE: "
                   << (*iter)->type();
        return false;
    }
    unknown_fields.reset(parent_unknown_fields.release());
  }

  // Now merge the UnknownFieldSet corresponding to the top-level message into
  // the options message.
  options->GetReflection()->MutableUnknownFields(options)->MergeFrom(
      *unknown_fields);

  return true;
}

void DescriptorBuilder::OptionInterpreter::AddWithoutInterpreting(
    const UninterpretedOption& uninterpreted_option, Message* options) {
  const FieldDescriptor* field =
    options->GetDescriptor()->FindFieldByName("uninterpreted_option");
  GOOGLE_CHECK(field != NULL);

  options->GetReflection()->AddMessage(options, field)
    ->CopyFrom(uninterpreted_option);
}

bool DescriptorBuilder::OptionInterpreter::ExamineIfOptionIsSet(
    vector<const FieldDescriptor*>::const_iterator intermediate_fields_iter,
    vector<const FieldDescriptor*>::const_iterator intermediate_fields_end,
    const FieldDescriptor* innermost_field, const string& debug_msg_name,
    const UnknownFieldSet& unknown_fields) {
  // We do linear searches of the UnknownFieldSet and its sub-groups.  This
  // should be fine since it's unlikely that any one options structure will
  // contain more than a handful of options.

  if (intermediate_fields_iter == intermediate_fields_end) {
    // We're at the innermost submessage.
    for (int i = 0; i < unknown_fields.field_count(); i++) {
      if (unknown_fields.field(i).number() == innermost_field->number()) {
        return AddNameError("Option \"" + debug_msg_name +
                            "\" was already set.");
      }
    }
    return true;
  }

  for (int i = 0; i < unknown_fields.field_count(); i++) {
    if (unknown_fields.field(i).number() ==
        (*intermediate_fields_iter)->number()) {
      const UnknownField* unknown_field = &unknown_fields.field(i);
      FieldDescriptor::Type type = (*intermediate_fields_iter)->type();
      // Recurse into the next submessage.
      switch (type) {
        case FieldDescriptor::TYPE_MESSAGE:
          if (unknown_field->type() == UnknownField::TYPE_LENGTH_DELIMITED) {
            UnknownFieldSet intermediate_unknown_fields;
            if (intermediate_unknown_fields.ParseFromString(
                    unknown_field->length_delimited()) &&
                !ExamineIfOptionIsSet(intermediate_fields_iter + 1,
                                      intermediate_fields_end,
                                      innermost_field, debug_msg_name,
                                      intermediate_unknown_fields)) {
              return false;  // Error already added.
            }
          }
          break;

        case FieldDescriptor::TYPE_GROUP:
          if (unknown_field->type() == UnknownField::TYPE_GROUP) {
            if (!ExamineIfOptionIsSet(intermediate_fields_iter + 1,
                                      intermediate_fields_end,
                                      innermost_field, debug_msg_name,
                                      unknown_field->group())) {
              return false;  // Error already added.
            }
          }
          break;

        default:
          GOOGLE_LOG(FATAL) << "Invalid wire type for CPPTYPE_MESSAGE: " << type;
          return false;
      }
    }
  }
  return true;
}

bool DescriptorBuilder::OptionInterpreter::SetOptionValue(
    const FieldDescriptor* option_field,
    UnknownFieldSet* unknown_fields) {
  // We switch on the CppType to validate.
  switch (option_field->cpp_type()) {

    case FieldDescriptor::CPPTYPE_INT32:
      if (uninterpreted_option_->has_positive_int_value()) {
        if (uninterpreted_option_->positive_int_value() >
            static_cast<uint64>(kint32max)) {
          return AddValueError("Value out of range for int32 option \"" +
                               option_field->full_name() + "\".");
        } else {
          SetInt32(option_field->number(),
                   uninterpreted_option_->positive_int_value(),
                   option_field->type(), unknown_fields);
        }
      } else if (uninterpreted_option_->has_negative_int_value()) {
        if (uninterpreted_option_->negative_int_value() <
            static_cast<int64>(kint32min)) {
          return AddValueError("Value out of range for int32 option \"" +
                               option_field->full_name() + "\".");
        } else {
          SetInt32(option_field->number(),
                   uninterpreted_option_->negative_int_value(),
                   option_field->type(), unknown_fields);
        }
      } else {
        return AddValueError("Value must be integer for int32 option \"" +
                             option_field->full_name() + "\".");
      }
      break;

    case FieldDescriptor::CPPTYPE_INT64:
      if (uninterpreted_option_->has_positive_int_value()) {
        if (uninterpreted_option_->positive_int_value() >
            static_cast<uint64>(kint64max)) {
          return AddValueError("Value out of range for int64 option \"" +
                               option_field->full_name() + "\".");
        } else {
          SetInt64(option_field->number(),
                   uninterpreted_option_->positive_int_value(),
                   option_field->type(), unknown_fields);
        }
      } else if (uninterpreted_option_->has_negative_int_value()) {
        SetInt64(option_field->number(),
                 uninterpreted_option_->negative_int_value(),
                 option_field->type(), unknown_fields);
      } else {
        return AddValueError("Value must be integer for int64 option \"" +
                             option_field->full_name() + "\".");
      }
      break;

    case FieldDescriptor::CPPTYPE_UINT32:
      if (uninterpreted_option_->has_positive_int_value()) {
        if (uninterpreted_option_->positive_int_value() > kuint32max) {
          return AddValueError("Value out of range for uint32 option \"" +
                               option_field->name() + "\".");
        } else {
          SetUInt32(option_field->number(),
                    uninterpreted_option_->positive_int_value(),
                    option_field->type(), unknown_fields);
        }
      } else {
        return AddValueError("Value must be non-negative integer for uint32 "
                             "option \"" + option_field->full_name() + "\".");
      }
      break;

    case FieldDescriptor::CPPTYPE_UINT64:
      if (uninterpreted_option_->has_positive_int_value()) {
        SetUInt64(option_field->number(),
                  uninterpreted_option_->positive_int_value(),
                  option_field->type(), unknown_fields);
      } else {
        return AddValueError("Value must be non-negative integer for uint64 "
                             "option \"" + option_field->full_name() + "\".");
      }
      break;

    case FieldDescriptor::CPPTYPE_FLOAT: {
      float value;
      if (uninterpreted_option_->has_double_value()) {
        value = uninterpreted_option_->double_value();
      } else if (uninterpreted_option_->has_positive_int_value()) {
        value = uninterpreted_option_->positive_int_value();
      } else if (uninterpreted_option_->has_negative_int_value()) {
        value = uninterpreted_option_->negative_int_value();
      } else {
        return AddValueError("Value must be number for float option \"" +
                             option_field->full_name() + "\".");
      }
      unknown_fields->AddFixed32(option_field->number(),
          google::protobuf::internal::WireFormatLite::EncodeFloat(value));
      break;
    }

    case FieldDescriptor::CPPTYPE_DOUBLE: {
      double value;
      if (uninterpreted_option_->has_double_value()) {
        value = uninterpreted_option_->double_value();
      } else if (uninterpreted_option_->has_positive_int_value()) {
        value = uninterpreted_option_->positive_int_value();
      } else if (uninterpreted_option_->has_negative_int_value()) {
        value = uninterpreted_option_->negative_int_value();
      } else {
        return AddValueError("Value must be number for double option \"" +
                             option_field->full_name() + "\".");
      }
      unknown_fields->AddFixed64(option_field->number(),
          google::protobuf::internal::WireFormatLite::EncodeDouble(value));
      break;
    }

    case FieldDescriptor::CPPTYPE_BOOL:
      uint64 value;
      if (!uninterpreted_option_->has_identifier_value()) {
        return AddValueError("Value must be identifier for boolean option "
                             "\"" + option_field->full_name() + "\".");
      }
      if (uninterpreted_option_->identifier_value() == "true") {
        value = 1;
      } else if (uninterpreted_option_->identifier_value() == "false") {
        value = 0;
      } else {
        return AddValueError("Value must be \"true\" or \"false\" for boolean "
                             "option \"" + option_field->full_name() + "\".");
      }
      unknown_fields->AddVarint(option_field->number(), value);
      break;

    case FieldDescriptor::CPPTYPE_ENUM: {
      if (!uninterpreted_option_->has_identifier_value()) {
        return AddValueError("Value must be identifier for enum-valued option "
                             "\"" + option_field->full_name() + "\".");
      }
      const EnumDescriptor* enum_type = option_field->enum_type();
      const string& value_name = uninterpreted_option_->identifier_value();
      const EnumValueDescriptor* enum_value = NULL;

      if (enum_type->file()->pool() != DescriptorPool::generated_pool()) {
        // Note that the enum value's fully-qualified name is a sibling of the
        // enum's name, not a child of it.
        string fully_qualified_name = enum_type->full_name();
        fully_qualified_name.resize(fully_qualified_name.size() -
                                    enum_type->name().size());
        fully_qualified_name += value_name;

        // Search for the enum value's descriptor in the builder's pool. Note
        // that we use DescriptorBuilder::FindSymbolNotEnforcingDeps(), not
        // DescriptorPool::FindEnumValueByName() because we're already holding
        // the pool's mutex, and the latter method locks it again.
        Symbol symbol =
          builder_->FindSymbolNotEnforcingDeps(fully_qualified_name);
        if (!symbol.IsNull() && symbol.type == Symbol::ENUM_VALUE) {
          if (symbol.enum_value_descriptor->type() != enum_type) {
            return AddValueError("Enum type \"" + enum_type->full_name() +
                "\" has no value named \"" + value_name + "\" for option \"" +
                option_field->full_name() +
                "\". This appears to be a value from a sibling type.");
          } else {
            enum_value = symbol.enum_value_descriptor;
          }
        }
      } else {
        // The enum type is in the generated pool, so we can search for the
        // value there.
        enum_value = enum_type->FindValueByName(value_name);
      }

      if (enum_value == NULL) {
        return AddValueError("Enum type \"" +
                             option_field->enum_type()->full_name() +
                             "\" has no value named \"" + value_name + "\" for "
                             "option \"" + option_field->full_name() + "\".");
      } else {
        // Sign-extension is not a problem, since we cast directly from int32 to
        // uint64, without first going through uint32.
        unknown_fields->AddVarint(option_field->number(),
          static_cast<uint64>(static_cast<int64>(enum_value->number())));
      }
      break;
    }

    case FieldDescriptor::CPPTYPE_STRING:
      if (!uninterpreted_option_->has_string_value()) {
        return AddValueError("Value must be quoted string for string option "
                             "\"" + option_field->full_name() + "\".");
      }
      // The string has already been unquoted and unescaped by the parser.
      unknown_fields->AddLengthDelimited(option_field->number(),
          uninterpreted_option_->string_value());
      break;

    case FieldDescriptor::CPPTYPE_MESSAGE:
      if (!SetAggregateOption(option_field, unknown_fields)) {
        return false;
      }
      break;
  }

  return true;
}

class DescriptorBuilder::OptionInterpreter::AggregateOptionFinder
    : public TextFormat::Finder {
 public:
  DescriptorBuilder* builder_;

  virtual const FieldDescriptor* FindExtension(
      Message* message, const string& name) const {
    assert_mutex_held(builder_->pool_);
    const Descriptor* descriptor = message->GetDescriptor();
    Symbol result = builder_->LookupSymbolNoPlaceholder(
        name, descriptor->full_name());
    if (result.type == Symbol::FIELD &&
        result.field_descriptor->is_extension()) {
      return result.field_descriptor;
    } else if (result.type == Symbol::MESSAGE &&
               descriptor->options().message_set_wire_format()) {
      const Descriptor* foreign_type = result.descriptor;
      // The text format allows MessageSet items to be specified using
      // the type name, rather than the extension identifier. If the symbol
      // lookup returned a Message, and the enclosing Message has
      // message_set_wire_format = true, then return the message set
      // extension, if one exists.
      for (int i = 0; i < foreign_type->extension_count(); i++) {
        const FieldDescriptor* extension = foreign_type->extension(i);
        if (extension->containing_type() == descriptor &&
            extension->type() == FieldDescriptor::TYPE_MESSAGE &&
            extension->is_optional() &&
            extension->message_type() == foreign_type) {
          // Found it.
          return extension;
        }
      }
    }
    return NULL;
  }
};

// A custom error collector to record any text-format parsing errors
namespace {
class AggregateErrorCollector : public io::ErrorCollector {
 public:
  string error_;

  virtual void AddError(int line, int column, const string& message) {
    if (!error_.empty()) {
      error_ += "; ";
    }
    error_ += message;
  }

  virtual void AddWarning(int line, int column, const string& message) {
    // Ignore warnings
  }
};
}

// We construct a dynamic message of the type corresponding to
// option_field, parse the supplied text-format string into this
// message, and serialize the resulting message to produce the value.
bool DescriptorBuilder::OptionInterpreter::SetAggregateOption(
    const FieldDescriptor* option_field,
    UnknownFieldSet* unknown_fields) {
  if (!uninterpreted_option_->has_aggregate_value()) {
    return AddValueError("Option \"" + option_field->full_name() +
                         "\" is a message. To set the entire message, use "
                         "syntax like \"" + option_field->name() +
                         " = { <proto text format> }\". "
                         "To set fields within it, use "
                         "syntax like \"" + option_field->name() +
                         ".foo = value\".");
  }

  const Descriptor* type = option_field->message_type();
  scoped_ptr<Message> dynamic(dynamic_factory_.GetPrototype(type)->New());
  GOOGLE_CHECK(dynamic.get() != NULL)
      << "Could not create an instance of " << option_field->DebugString();

  AggregateErrorCollector collector;
  AggregateOptionFinder finder;
  finder.builder_ = builder_;
  TextFormat::Parser parser;
  parser.RecordErrorsTo(&collector);
  parser.SetFinder(&finder);
  if (!parser.ParseFromString(uninterpreted_option_->aggregate_value(),
                              dynamic.get())) {
    AddValueError("Error while parsing option value for \"" +
                  option_field->name() + "\": " + collector.error_);
    return false;
  } else {
    string serial;
    dynamic->SerializeToString(&serial);  // Never fails
    if (option_field->type() == FieldDescriptor::TYPE_MESSAGE) {
      unknown_fields->AddLengthDelimited(option_field->number(), serial);
    } else {
      GOOGLE_CHECK_EQ(option_field->type(),  FieldDescriptor::TYPE_GROUP);
      UnknownFieldSet* group = unknown_fields->AddGroup(option_field->number());
      group->ParseFromString(serial);
    }
    return true;
  }
}

void DescriptorBuilder::OptionInterpreter::SetInt32(int number, int32 value,
    FieldDescriptor::Type type, UnknownFieldSet* unknown_fields) {
  switch (type) {
    case FieldDescriptor::TYPE_INT32:
      unknown_fields->AddVarint(number,
        static_cast<uint64>(static_cast<int64>(value)));
      break;

    case FieldDescriptor::TYPE_SFIXED32:
      unknown_fields->AddFixed32(number, static_cast<uint32>(value));
      break;

    case FieldDescriptor::TYPE_SINT32:
      unknown_fields->AddVarint(number,
          google::protobuf::internal::WireFormatLite::ZigZagEncode32(value));
      break;

    default:
      GOOGLE_LOG(FATAL) << "Invalid wire type for CPPTYPE_INT32: " << type;
      break;
  }
}

void DescriptorBuilder::OptionInterpreter::SetInt64(int number, int64 value,
    FieldDescriptor::Type type, UnknownFieldSet* unknown_fields) {
  switch (type) {
    case FieldDescriptor::TYPE_INT64:
      unknown_fields->AddVarint(number, static_cast<uint64>(value));
      break;

    case FieldDescriptor::TYPE_SFIXED64:
      unknown_fields->AddFixed64(number, static_cast<uint64>(value));
      break;

    case FieldDescriptor::TYPE_SINT64:
      unknown_fields->AddVarint(number,
          google::protobuf::internal::WireFormatLite::ZigZagEncode64(value));
      break;

    default:
      GOOGLE_LOG(FATAL) << "Invalid wire type for CPPTYPE_INT64: " << type;
      break;
  }
}

void DescriptorBuilder::OptionInterpreter::SetUInt32(int number, uint32 value,
    FieldDescriptor::Type type, UnknownFieldSet* unknown_fields) {
  switch (type) {
    case FieldDescriptor::TYPE_UINT32:
      unknown_fields->AddVarint(number, static_cast<uint64>(value));
      break;

    case FieldDescriptor::TYPE_FIXED32:
      unknown_fields->AddFixed32(number, static_cast<uint32>(value));
      break;

    default:
      GOOGLE_LOG(FATAL) << "Invalid wire type for CPPTYPE_UINT32: " << type;
      break;
  }
}

void DescriptorBuilder::OptionInterpreter::SetUInt64(int number, uint64 value,
    FieldDescriptor::Type type, UnknownFieldSet* unknown_fields) {
  switch (type) {
    case FieldDescriptor::TYPE_UINT64:
      unknown_fields->AddVarint(number, value);
      break;

    case FieldDescriptor::TYPE_FIXED64:
      unknown_fields->AddFixed64(number, value);
      break;

    default:
      GOOGLE_LOG(FATAL) << "Invalid wire type for CPPTYPE_UINT64: " << type;
      break;
  }
}

}  // namespace protobuf
}  // namespace google
