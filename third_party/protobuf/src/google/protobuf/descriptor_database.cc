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

#include <google/protobuf/descriptor_database.h>

#include <set>

#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/wire_format_lite_inl.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/stubs/stl_util.h>
#include <google/protobuf/stubs/map-util.h>

namespace google {
namespace protobuf {

DescriptorDatabase::~DescriptorDatabase() {}

// ===================================================================

template <typename Value>
bool SimpleDescriptorDatabase::DescriptorIndex<Value>::AddFile(
    const FileDescriptorProto& file,
    Value value) {
  if (!InsertIfNotPresent(&by_name_, file.name(), value)) {
    GOOGLE_LOG(ERROR) << "File already exists in database: " << file.name();
    return false;
  }

  // We must be careful here -- calling file.package() if file.has_package() is
  // false could access an uninitialized static-storage variable if we are being
  // run at startup time.
  string path = file.has_package() ? file.package() : string();
  if (!path.empty()) path += '.';

  for (int i = 0; i < file.message_type_size(); i++) {
    if (!AddSymbol(path + file.message_type(i).name(), value)) return false;
    if (!AddNestedExtensions(file.message_type(i), value)) return false;
  }
  for (int i = 0; i < file.enum_type_size(); i++) {
    if (!AddSymbol(path + file.enum_type(i).name(), value)) return false;
  }
  for (int i = 0; i < file.extension_size(); i++) {
    if (!AddSymbol(path + file.extension(i).name(), value)) return false;
    if (!AddExtension(file.extension(i), value)) return false;
  }
  for (int i = 0; i < file.service_size(); i++) {
    if (!AddSymbol(path + file.service(i).name(), value)) return false;
  }

  return true;
}

template <typename Value>
bool SimpleDescriptorDatabase::DescriptorIndex<Value>::AddSymbol(
    const string& name, Value value) {
  // We need to make sure not to violate our map invariant.

  // If the symbol name is invalid it could break our lookup algorithm (which
  // relies on the fact that '.' sorts before all other characters that are
  // valid in symbol names).
  if (!ValidateSymbolName(name)) {
    GOOGLE_LOG(ERROR) << "Invalid symbol name: " << name;
    return false;
  }

  // Try to look up the symbol to make sure a super-symbol doesn't already
  // exist.
  typename map<string, Value>::iterator iter = FindLastLessOrEqual(name);

  if (iter == by_symbol_.end()) {
    // Apparently the map is currently empty.  Just insert and be done with it.
    by_symbol_.insert(typename map<string, Value>::value_type(name, value));
    return true;
  }

  if (IsSubSymbol(iter->first, name)) {
    GOOGLE_LOG(ERROR) << "Symbol name \"" << name << "\" conflicts with the existing "
                  "symbol \"" << iter->first << "\".";
    return false;
  }

  // OK, that worked.  Now we have to make sure that no symbol in the map is
  // a sub-symbol of the one we are inserting.  The only symbol which could
  // be so is the first symbol that is greater than the new symbol.  Since
  // |iter| points at the last symbol that is less than or equal, we just have
  // to increment it.
  ++iter;

  if (iter != by_symbol_.end() && IsSubSymbol(name, iter->first)) {
    GOOGLE_LOG(ERROR) << "Symbol name \"" << name << "\" conflicts with the existing "
                  "symbol \"" << iter->first << "\".";
    return false;
  }

  // OK, no conflicts.

  // Insert the new symbol using the iterator as a hint, the new entry will
  // appear immediately before the one the iterator is pointing at.
  by_symbol_.insert(iter, typename map<string, Value>::value_type(name, value));

  return true;
}

template <typename Value>
bool SimpleDescriptorDatabase::DescriptorIndex<Value>::AddNestedExtensions(
    const DescriptorProto& message_type,
    Value value) {
  for (int i = 0; i < message_type.nested_type_size(); i++) {
    if (!AddNestedExtensions(message_type.nested_type(i), value)) return false;
  }
  for (int i = 0; i < message_type.extension_size(); i++) {
    if (!AddExtension(message_type.extension(i), value)) return false;
  }
  return true;
}

template <typename Value>
bool SimpleDescriptorDatabase::DescriptorIndex<Value>::AddExtension(
    const FieldDescriptorProto& field,
    Value value) {
  if (!field.extendee().empty() && field.extendee()[0] == '.') {
    // The extension is fully-qualified.  We can use it as a lookup key in
    // the by_symbol_ table.
    if (!InsertIfNotPresent(&by_extension_,
                            make_pair(field.extendee().substr(1),
                                      field.number()),
                            value)) {
      GOOGLE_LOG(ERROR) << "Extension conflicts with extension already in database: "
                    "extend " << field.extendee() << " { "
                 << field.name() << " = " << field.number() << " }";
      return false;
    }
  } else {
    // Not fully-qualified.  We can't really do anything here, unfortunately.
    // We don't consider this an error, though, because the descriptor is
    // valid.
  }
  return true;
}

template <typename Value>
Value SimpleDescriptorDatabase::DescriptorIndex<Value>::FindFile(
    const string& filename) {
  return FindWithDefault(by_name_, filename, Value());
}

template <typename Value>
Value SimpleDescriptorDatabase::DescriptorIndex<Value>::FindSymbol(
    const string& name) {
  typename map<string, Value>::iterator iter = FindLastLessOrEqual(name);

  return (iter != by_symbol_.end() && IsSubSymbol(iter->first, name)) ?
         iter->second : Value();
}

template <typename Value>
Value SimpleDescriptorDatabase::DescriptorIndex<Value>::FindExtension(
    const string& containing_type,
    int field_number) {
  return FindWithDefault(by_extension_,
                         make_pair(containing_type, field_number),
                         Value());
}

template <typename Value>
bool SimpleDescriptorDatabase::DescriptorIndex<Value>::FindAllExtensionNumbers(
    const string& containing_type,
    vector<int>* output) {
  typename map<pair<string, int>, Value >::const_iterator it =
      by_extension_.lower_bound(make_pair(containing_type, 0));
  bool success = false;

  for (; it != by_extension_.end() && it->first.first == containing_type;
       ++it) {
    output->push_back(it->first.second);
    success = true;
  }

  return success;
}

template <typename Value>
typename map<string, Value>::iterator
SimpleDescriptorDatabase::DescriptorIndex<Value>::FindLastLessOrEqual(
    const string& name) {
  // Find the last key in the map which sorts less than or equal to the
  // symbol name.  Since upper_bound() returns the *first* key that sorts
  // *greater* than the input, we want the element immediately before that.
  typename map<string, Value>::iterator iter = by_symbol_.upper_bound(name);
  if (iter != by_symbol_.begin()) --iter;
  return iter;
}

template <typename Value>
bool SimpleDescriptorDatabase::DescriptorIndex<Value>::IsSubSymbol(
    const string& sub_symbol, const string& super_symbol) {
  return sub_symbol == super_symbol ||
         (HasPrefixString(super_symbol, sub_symbol) &&
             super_symbol[sub_symbol.size()] == '.');
}

template <typename Value>
bool SimpleDescriptorDatabase::DescriptorIndex<Value>::ValidateSymbolName(
    const string& name) {
  for (int i = 0; i < name.size(); i++) {
    // I don't trust ctype.h due to locales.  :(
    if (name[i] != '.' && name[i] != '_' &&
        (name[i] < '0' || name[i] > '9') &&
        (name[i] < 'A' || name[i] > 'Z') &&
        (name[i] < 'a' || name[i] > 'z')) {
      return false;
    }
  }
  return true;
}

// -------------------------------------------------------------------

SimpleDescriptorDatabase::SimpleDescriptorDatabase() {}
SimpleDescriptorDatabase::~SimpleDescriptorDatabase() {
  STLDeleteElements(&files_to_delete_);
}

bool SimpleDescriptorDatabase::Add(const FileDescriptorProto& file) {
  FileDescriptorProto* new_file = new FileDescriptorProto;
  new_file->CopyFrom(file);
  return AddAndOwn(new_file);
}

bool SimpleDescriptorDatabase::AddAndOwn(const FileDescriptorProto* file) {
  files_to_delete_.push_back(file);
  return index_.AddFile(*file, file);
}

bool SimpleDescriptorDatabase::FindFileByName(
    const string& filename,
    FileDescriptorProto* output) {
  return MaybeCopy(index_.FindFile(filename), output);
}

bool SimpleDescriptorDatabase::FindFileContainingSymbol(
    const string& symbol_name,
    FileDescriptorProto* output) {
  return MaybeCopy(index_.FindSymbol(symbol_name), output);
}

bool SimpleDescriptorDatabase::FindFileContainingExtension(
    const string& containing_type,
    int field_number,
    FileDescriptorProto* output) {
  return MaybeCopy(index_.FindExtension(containing_type, field_number), output);
}

bool SimpleDescriptorDatabase::FindAllExtensionNumbers(
    const string& extendee_type,
    vector<int>* output) {
  return index_.FindAllExtensionNumbers(extendee_type, output);
}

bool SimpleDescriptorDatabase::MaybeCopy(const FileDescriptorProto* file,
                                         FileDescriptorProto* output) {
  if (file == NULL) return false;
  output->CopyFrom(*file);
  return true;
}

// -------------------------------------------------------------------

EncodedDescriptorDatabase::EncodedDescriptorDatabase() {}
EncodedDescriptorDatabase::~EncodedDescriptorDatabase() {
  for (int i = 0; i < files_to_delete_.size(); i++) {
    operator delete(files_to_delete_[i]);
  }
}

bool EncodedDescriptorDatabase::Add(
    const void* encoded_file_descriptor, int size) {
  FileDescriptorProto file;
  if (file.ParseFromArray(encoded_file_descriptor, size)) {
    return index_.AddFile(file, make_pair(encoded_file_descriptor, size));
  } else {
    GOOGLE_LOG(ERROR) << "Invalid file descriptor data passed to "
                  "EncodedDescriptorDatabase::Add().";
    return false;
  }
}

bool EncodedDescriptorDatabase::AddCopy(
    const void* encoded_file_descriptor, int size) {
  void* copy = operator new(size);
  memcpy(copy, encoded_file_descriptor, size);
  files_to_delete_.push_back(copy);
  return Add(copy, size);
}

bool EncodedDescriptorDatabase::FindFileByName(
    const string& filename,
    FileDescriptorProto* output) {
  return MaybeParse(index_.FindFile(filename), output);
}

bool EncodedDescriptorDatabase::FindFileContainingSymbol(
    const string& symbol_name,
    FileDescriptorProto* output) {
  return MaybeParse(index_.FindSymbol(symbol_name), output);
}

bool EncodedDescriptorDatabase::FindNameOfFileContainingSymbol(
    const string& symbol_name,
    string* output) {
  pair<const void*, int> encoded_file = index_.FindSymbol(symbol_name);
  if (encoded_file.first == NULL) return false;

  // Optimization:  The name should be the first field in the encoded message.
  //   Try to just read it directly.
  io::CodedInputStream input(reinterpret_cast<const uint8*>(encoded_file.first),
                             encoded_file.second);

  const uint32 kNameTag = internal::WireFormatLite::MakeTag(
      FileDescriptorProto::kNameFieldNumber,
      internal::WireFormatLite::WIRETYPE_LENGTH_DELIMITED);

  if (input.ReadTag() == kNameTag) {
    // Success!
    return internal::WireFormatLite::ReadString(&input, output);
  } else {
    // Slow path.  Parse whole message.
    FileDescriptorProto file_proto;
    if (!file_proto.ParseFromArray(encoded_file.first, encoded_file.second)) {
      return false;
    }
    *output = file_proto.name();
    return true;
  }
}

bool EncodedDescriptorDatabase::FindFileContainingExtension(
    const string& containing_type,
    int field_number,
    FileDescriptorProto* output) {
  return MaybeParse(index_.FindExtension(containing_type, field_number),
                    output);
}

bool EncodedDescriptorDatabase::FindAllExtensionNumbers(
    const string& extendee_type,
    vector<int>* output) {
  return index_.FindAllExtensionNumbers(extendee_type, output);
}

bool EncodedDescriptorDatabase::MaybeParse(
    pair<const void*, int> encoded_file,
    FileDescriptorProto* output) {
  if (encoded_file.first == NULL) return false;
  return output->ParseFromArray(encoded_file.first, encoded_file.second);
}

// ===================================================================

DescriptorPoolDatabase::DescriptorPoolDatabase(const DescriptorPool& pool)
  : pool_(pool) {}
DescriptorPoolDatabase::~DescriptorPoolDatabase() {}

bool DescriptorPoolDatabase::FindFileByName(
    const string& filename,
    FileDescriptorProto* output) {
  const FileDescriptor* file = pool_.FindFileByName(filename);
  if (file == NULL) return false;
  output->Clear();
  file->CopyTo(output);
  return true;
}

bool DescriptorPoolDatabase::FindFileContainingSymbol(
    const string& symbol_name,
    FileDescriptorProto* output) {
  const FileDescriptor* file = pool_.FindFileContainingSymbol(symbol_name);
  if (file == NULL) return false;
  output->Clear();
  file->CopyTo(output);
  return true;
}

bool DescriptorPoolDatabase::FindFileContainingExtension(
    const string& containing_type,
    int field_number,
    FileDescriptorProto* output) {
  const Descriptor* extendee = pool_.FindMessageTypeByName(containing_type);
  if (extendee == NULL) return false;

  const FieldDescriptor* extension =
    pool_.FindExtensionByNumber(extendee, field_number);
  if (extension == NULL) return false;

  output->Clear();
  extension->file()->CopyTo(output);
  return true;
}

bool DescriptorPoolDatabase::FindAllExtensionNumbers(
    const string& extendee_type,
    vector<int>* output) {
  const Descriptor* extendee = pool_.FindMessageTypeByName(extendee_type);
  if (extendee == NULL) return false;

  vector<const FieldDescriptor*> extensions;
  pool_.FindAllExtensions(extendee, &extensions);

  for (int i = 0; i < extensions.size(); ++i) {
    output->push_back(extensions[i]->number());
  }

  return true;
}

// ===================================================================

MergedDescriptorDatabase::MergedDescriptorDatabase(
    DescriptorDatabase* source1,
    DescriptorDatabase* source2) {
  sources_.push_back(source1);
  sources_.push_back(source2);
}
MergedDescriptorDatabase::MergedDescriptorDatabase(
    const vector<DescriptorDatabase*>& sources)
  : sources_(sources) {}
MergedDescriptorDatabase::~MergedDescriptorDatabase() {}

bool MergedDescriptorDatabase::FindFileByName(
    const string& filename,
    FileDescriptorProto* output) {
  for (int i = 0; i < sources_.size(); i++) {
    if (sources_[i]->FindFileByName(filename, output)) {
      return true;
    }
  }
  return false;
}

bool MergedDescriptorDatabase::FindFileContainingSymbol(
    const string& symbol_name,
    FileDescriptorProto* output) {
  for (int i = 0; i < sources_.size(); i++) {
    if (sources_[i]->FindFileContainingSymbol(symbol_name, output)) {
      // The symbol was found in source i.  However, if one of the previous
      // sources defines a file with the same name (which presumably doesn't
      // contain the symbol, since it wasn't found in that source), then we
      // must hide it from the caller.
      FileDescriptorProto temp;
      for (int j = 0; j < i; j++) {
        if (sources_[j]->FindFileByName(output->name(), &temp)) {
          // Found conflicting file in a previous source.
          return false;
        }
      }
      return true;
    }
  }
  return false;
}

bool MergedDescriptorDatabase::FindFileContainingExtension(
    const string& containing_type,
    int field_number,
    FileDescriptorProto* output) {
  for (int i = 0; i < sources_.size(); i++) {
    if (sources_[i]->FindFileContainingExtension(
          containing_type, field_number, output)) {
      // The symbol was found in source i.  However, if one of the previous
      // sources defines a file with the same name (which presumably doesn't
      // contain the symbol, since it wasn't found in that source), then we
      // must hide it from the caller.
      FileDescriptorProto temp;
      for (int j = 0; j < i; j++) {
        if (sources_[j]->FindFileByName(output->name(), &temp)) {
          // Found conflicting file in a previous source.
          return false;
        }
      }
      return true;
    }
  }
  return false;
}

bool MergedDescriptorDatabase::FindAllExtensionNumbers(
    const string& extendee_type,
    vector<int>* output) {
  set<int> merged_results;
  vector<int> results;
  bool success = false;

  for (int i = 0; i < sources_.size(); i++) {
    if (sources_[i]->FindAllExtensionNumbers(extendee_type, &results)) {
      copy(results.begin(), results.end(),
           insert_iterator<set<int> >(merged_results, merged_results.begin()));
      success = true;
    }
    results.clear();
  }

  copy(merged_results.begin(), merged_results.end(),
       insert_iterator<vector<int> >(*output, output->end()));

  return success;
}

}  // namespace protobuf
}  // namespace google
