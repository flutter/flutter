// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file specifies a recursive data storage class called Value intended for
// storing settings and other persistable data.
//
// A Value represents something that can be stored in JSON or passed to/from
// JavaScript. As such, it is NOT a generalized variant type, since only the
// types supported by JavaScript/JSON are supported.
//
// IN PARTICULAR this means that there is no support for int64 or unsigned
// numbers. Writing JSON with such types would violate the spec. If you need
// something like this, either use a double or make a string value containing
// the number you want.

#ifndef BASE_VALUES_H_
#define BASE_VALUES_H_

#include <stddef.h>

#include <iosfwd>
#include <map>
#include <string>
#include <utility>
#include <vector>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string16.h"
#include "base/strings/string_piece.h"

namespace base {

class BinaryValue;
class DictionaryValue;
class FundamentalValue;
class ListValue;
class StringValue;
class Value;

typedef std::vector<Value*> ValueVector;
typedef std::map<std::string, Value*> ValueMap;

// The Value class is the base class for Values. A Value can be instantiated
// via the Create*Value() factory methods, or by directly creating instances of
// the subclasses.
//
// See the file-level comment above for more information.
class BASE_EXPORT Value {
 public:
  enum Type {
    TYPE_NULL = 0,
    TYPE_BOOLEAN,
    TYPE_INTEGER,
    TYPE_DOUBLE,
    TYPE_STRING,
    TYPE_BINARY,
    TYPE_DICTIONARY,
    TYPE_LIST
    // Note: Do not add more types. See the file-level comment above for why.
  };

  virtual ~Value();

  static scoped_ptr<Value> CreateNullValue();

  // Returns the type of the value stored by the current Value object.
  // Each type will be implemented by only one subclass of Value, so it's
  // safe to use the Type to determine whether you can cast from
  // Value* to (Implementing Class)*.  Also, a Value object never changes
  // its type after construction.
  Type GetType() const { return type_; }

  // Returns true if the current object represents a given type.
  bool IsType(Type type) const { return type == type_; }

  // These methods allow the convenient retrieval of the contents of the Value.
  // If the current object can be converted into the given type, the value is
  // returned through the |out_value| parameter and true is returned;
  // otherwise, false is returned and |out_value| is unchanged.
  virtual bool GetAsBoolean(bool* out_value) const;
  virtual bool GetAsInteger(int* out_value) const;
  virtual bool GetAsDouble(double* out_value) const;
  virtual bool GetAsString(std::string* out_value) const;
  virtual bool GetAsString(string16* out_value) const;
  virtual bool GetAsString(const StringValue** out_value) const;
  virtual bool GetAsBinary(const BinaryValue** out_value) const;
  virtual bool GetAsList(ListValue** out_value);
  virtual bool GetAsList(const ListValue** out_value) const;
  virtual bool GetAsDictionary(DictionaryValue** out_value);
  virtual bool GetAsDictionary(const DictionaryValue** out_value) const;
  // Note: Do not add more types. See the file-level comment above for why.

  // This creates a deep copy of the entire Value tree, and returns a pointer
  // to the copy.  The caller gets ownership of the copy, of course.
  //
  // Subclasses return their own type directly in their overrides;
  // this works because C++ supports covariant return types.
  virtual Value* DeepCopy() const;
  // Preferred version of DeepCopy. TODO(estade): remove the above.
  scoped_ptr<Value> CreateDeepCopy() const;

  // Compares if two Value objects have equal contents.
  virtual bool Equals(const Value* other) const;

  // Compares if two Value objects have equal contents. Can handle NULLs.
  // NULLs are considered equal but different from Value::CreateNullValue().
  static bool Equals(const Value* a, const Value* b);

 protected:
  // These aren't safe for end-users, but they are useful for subclasses.
  explicit Value(Type type);
  Value(const Value& that);
  Value& operator=(const Value& that);

 private:
  Type type_;
};

// FundamentalValue represents the simple fundamental types of values.
class BASE_EXPORT FundamentalValue : public Value {
 public:
  explicit FundamentalValue(bool in_value);
  explicit FundamentalValue(int in_value);
  explicit FundamentalValue(double in_value);
  ~FundamentalValue() override;

  // Overridden from Value:
  bool GetAsBoolean(bool* out_value) const override;
  bool GetAsInteger(int* out_value) const override;
  // Values of both type TYPE_INTEGER and TYPE_DOUBLE can be obtained as
  // doubles.
  bool GetAsDouble(double* out_value) const override;
  FundamentalValue* DeepCopy() const override;
  bool Equals(const Value* other) const override;

 private:
  union {
    bool boolean_value_;
    int integer_value_;
    double double_value_;
  };
};

class BASE_EXPORT StringValue : public Value {
 public:
  // Initializes a StringValue with a UTF-8 narrow character string.
  explicit StringValue(const std::string& in_value);

  // Initializes a StringValue with a string16.
  explicit StringValue(const string16& in_value);

  ~StringValue() override;

  // Returns |value_| as a pointer or reference.
  std::string* GetString();
  const std::string& GetString() const;

  // Overridden from Value:
  bool GetAsString(std::string* out_value) const override;
  bool GetAsString(string16* out_value) const override;
  bool GetAsString(const StringValue** out_value) const override;
  StringValue* DeepCopy() const override;
  bool Equals(const Value* other) const override;

 private:
  std::string value_;
};

class BASE_EXPORT BinaryValue: public Value {
 public:
  // Creates a BinaryValue with a null buffer and size of 0.
  BinaryValue();

  // Creates a BinaryValue, taking ownership of the bytes pointed to by
  // |buffer|.
  BinaryValue(scoped_ptr<char[]> buffer, size_t size);

  ~BinaryValue() override;

  // For situations where you want to keep ownership of your buffer, this
  // factory method creates a new BinaryValue by copying the contents of the
  // buffer that's passed in.
  static BinaryValue* CreateWithCopiedBuffer(const char* buffer, size_t size);

  size_t GetSize() const { return size_; }

  // May return NULL.
  char* GetBuffer() { return buffer_.get(); }
  const char* GetBuffer() const { return buffer_.get(); }

  // Overridden from Value:
  bool GetAsBinary(const BinaryValue** out_value) const override;
  BinaryValue* DeepCopy() const override;
  bool Equals(const Value* other) const override;

 private:
  scoped_ptr<char[]> buffer_;
  size_t size_;

  DISALLOW_COPY_AND_ASSIGN(BinaryValue);
};

// DictionaryValue provides a key-value dictionary with (optional) "path"
// parsing for recursive access; see the comment at the top of the file. Keys
// are |std::string|s and should be UTF-8 encoded.
class BASE_EXPORT DictionaryValue : public Value {
 public:
  DictionaryValue();
  ~DictionaryValue() override;

  // Overridden from Value:
  bool GetAsDictionary(DictionaryValue** out_value) override;
  bool GetAsDictionary(const DictionaryValue** out_value) const override;

  // Returns true if the current dictionary has a value for the given key.
  bool HasKey(const std::string& key) const;

  // Returns the number of Values in this dictionary.
  size_t size() const { return dictionary_.size(); }

  // Returns whether the dictionary is empty.
  bool empty() const { return dictionary_.empty(); }

  // Clears any current contents of this dictionary.
  void Clear();

  // Sets the Value associated with the given path starting from this object.
  // A path has the form "<key>" or "<key>.<key>.[...]", where "." indexes
  // into the next DictionaryValue down.  Obviously, "." can't be used
  // within a key, but there are no other restrictions on keys.
  // If the key at any step of the way doesn't exist, or exists but isn't
  // a DictionaryValue, a new DictionaryValue will be created and attached
  // to the path in that location. |in_value| must be non-null.
  void Set(const std::string& path, scoped_ptr<Value> in_value);
  // Deprecated version of the above. TODO(estade): remove.
  void Set(const std::string& path, Value* in_value);

  // Convenience forms of Set().  These methods will replace any existing
  // value at that path, even if it has a different type.
  void SetBoolean(const std::string& path, bool in_value);
  void SetInteger(const std::string& path, int in_value);
  void SetDouble(const std::string& path, double in_value);
  void SetString(const std::string& path, const std::string& in_value);
  void SetString(const std::string& path, const string16& in_value);

  // Like Set(), but without special treatment of '.'.  This allows e.g. URLs to
  // be used as paths.
  void SetWithoutPathExpansion(const std::string& key,
                               scoped_ptr<Value> in_value);
  // Deprecated version of the above. TODO(estade): remove.
  void SetWithoutPathExpansion(const std::string& key, Value* in_value);

  // Convenience forms of SetWithoutPathExpansion().
  void SetBooleanWithoutPathExpansion(const std::string& path, bool in_value);
  void SetIntegerWithoutPathExpansion(const std::string& path, int in_value);
  void SetDoubleWithoutPathExpansion(const std::string& path, double in_value);
  void SetStringWithoutPathExpansion(const std::string& path,
                                     const std::string& in_value);
  void SetStringWithoutPathExpansion(const std::string& path,
                                     const string16& in_value);

  // Gets the Value associated with the given path starting from this object.
  // A path has the form "<key>" or "<key>.<key>.[...]", where "." indexes
  // into the next DictionaryValue down.  If the path can be resolved
  // successfully, the value for the last key in the path will be returned
  // through the |out_value| parameter, and the function will return true.
  // Otherwise, it will return false and |out_value| will be untouched.
  // Note that the dictionary always owns the value that's returned.
  // |out_value| is optional and will only be set if non-NULL.
  bool Get(StringPiece path, const Value** out_value) const;
  bool Get(StringPiece path, Value** out_value);

  // These are convenience forms of Get().  The value will be retrieved
  // and the return value will be true if the path is valid and the value at
  // the end of the path can be returned in the form specified.
  // |out_value| is optional and will only be set if non-NULL.
  bool GetBoolean(const std::string& path, bool* out_value) const;
  bool GetInteger(const std::string& path, int* out_value) const;
  // Values of both type TYPE_INTEGER and TYPE_DOUBLE can be obtained as
  // doubles.
  bool GetDouble(const std::string& path, double* out_value) const;
  bool GetString(const std::string& path, std::string* out_value) const;
  bool GetString(const std::string& path, string16* out_value) const;
  bool GetStringASCII(const std::string& path, std::string* out_value) const;
  bool GetBinary(const std::string& path, const BinaryValue** out_value) const;
  bool GetBinary(const std::string& path, BinaryValue** out_value);
  bool GetDictionary(StringPiece path,
                     const DictionaryValue** out_value) const;
  bool GetDictionary(StringPiece path, DictionaryValue** out_value);
  bool GetList(const std::string& path, const ListValue** out_value) const;
  bool GetList(const std::string& path, ListValue** out_value);

  // Like Get(), but without special treatment of '.'.  This allows e.g. URLs to
  // be used as paths.
  bool GetWithoutPathExpansion(const std::string& key,
                               const Value** out_value) const;
  bool GetWithoutPathExpansion(const std::string& key, Value** out_value);
  bool GetBooleanWithoutPathExpansion(const std::string& key,
                                      bool* out_value) const;
  bool GetIntegerWithoutPathExpansion(const std::string& key,
                                      int* out_value) const;
  bool GetDoubleWithoutPathExpansion(const std::string& key,
                                     double* out_value) const;
  bool GetStringWithoutPathExpansion(const std::string& key,
                                     std::string* out_value) const;
  bool GetStringWithoutPathExpansion(const std::string& key,
                                     string16* out_value) const;
  bool GetDictionaryWithoutPathExpansion(
      const std::string& key,
      const DictionaryValue** out_value) const;
  bool GetDictionaryWithoutPathExpansion(const std::string& key,
                                         DictionaryValue** out_value);
  bool GetListWithoutPathExpansion(const std::string& key,
                                   const ListValue** out_value) const;
  bool GetListWithoutPathExpansion(const std::string& key,
                                   ListValue** out_value);

  // Removes the Value with the specified path from this dictionary (or one
  // of its child dictionaries, if the path is more than just a local key).
  // If |out_value| is non-NULL, the removed Value will be passed out via
  // |out_value|.  If |out_value| is NULL, the removed value will be deleted.
  // This method returns true if |path| is a valid path; otherwise it will
  // return false and the DictionaryValue object will be unchanged.
  virtual bool Remove(const std::string& path, scoped_ptr<Value>* out_value);

  // Like Remove(), but without special treatment of '.'.  This allows e.g. URLs
  // to be used as paths.
  virtual bool RemoveWithoutPathExpansion(const std::string& key,
                                          scoped_ptr<Value>* out_value);

  // Removes a path, clearing out all dictionaries on |path| that remain empty
  // after removing the value at |path|.
  virtual bool RemovePath(const std::string& path,
                          scoped_ptr<Value>* out_value);

  // Makes a copy of |this| but doesn't include empty dictionaries and lists in
  // the copy.  This never returns NULL, even if |this| itself is empty.
  scoped_ptr<DictionaryValue> DeepCopyWithoutEmptyChildren() const;

  // Merge |dictionary| into this dictionary. This is done recursively, i.e. any
  // sub-dictionaries will be merged as well. In case of key collisions, the
  // passed in dictionary takes precedence and data already present will be
  // replaced. Values within |dictionary| are deep-copied, so |dictionary| may
  // be freed any time after this call.
  void MergeDictionary(const DictionaryValue* dictionary);

  // Swaps contents with the |other| dictionary.
  virtual void Swap(DictionaryValue* other);

  // This class provides an iterator over both keys and values in the
  // dictionary.  It can't be used to modify the dictionary.
  class BASE_EXPORT Iterator {
   public:
    explicit Iterator(const DictionaryValue& target);
    ~Iterator();

    bool IsAtEnd() const { return it_ == target_.dictionary_.end(); }
    void Advance() { ++it_; }

    const std::string& key() const { return it_->first; }
    const Value& value() const { return *it_->second; }

   private:
    const DictionaryValue& target_;
    ValueMap::const_iterator it_;
  };

  // Overridden from Value:
  DictionaryValue* DeepCopy() const override;
  // Preferred version of DeepCopy. TODO(estade): remove the above.
  scoped_ptr<DictionaryValue> CreateDeepCopy() const;
  bool Equals(const Value* other) const override;

 private:
  ValueMap dictionary_;

  DISALLOW_COPY_AND_ASSIGN(DictionaryValue);
};

// This type of Value represents a list of other Value values.
class BASE_EXPORT ListValue : public Value {
 public:
  typedef ValueVector::iterator iterator;
  typedef ValueVector::const_iterator const_iterator;

  ListValue();
  ~ListValue() override;

  // Clears the contents of this ListValue
  void Clear();

  // Returns the number of Values in this list.
  size_t GetSize() const { return list_.size(); }

  // Returns whether the list is empty.
  bool empty() const { return list_.empty(); }

  // Sets the list item at the given index to be the Value specified by
  // the value given.  If the index beyond the current end of the list, null
  // Values will be used to pad out the list.
  // Returns true if successful, or false if the index was negative or
  // the value is a null pointer.
  bool Set(size_t index, Value* in_value);
  // Preferred version of the above. TODO(estade): remove the above.
  bool Set(size_t index, scoped_ptr<Value> in_value);

  // Gets the Value at the given index.  Modifies |out_value| (and returns true)
  // only if the index falls within the current list range.
  // Note that the list always owns the Value passed out via |out_value|.
  // |out_value| is optional and will only be set if non-NULL.
  bool Get(size_t index, const Value** out_value) const;
  bool Get(size_t index, Value** out_value);

  // Convenience forms of Get().  Modifies |out_value| (and returns true)
  // only if the index is valid and the Value at that index can be returned
  // in the specified form.
  // |out_value| is optional and will only be set if non-NULL.
  bool GetBoolean(size_t index, bool* out_value) const;
  bool GetInteger(size_t index, int* out_value) const;
  // Values of both type TYPE_INTEGER and TYPE_DOUBLE can be obtained as
  // doubles.
  bool GetDouble(size_t index, double* out_value) const;
  bool GetString(size_t index, std::string* out_value) const;
  bool GetString(size_t index, string16* out_value) const;
  bool GetBinary(size_t index, const BinaryValue** out_value) const;
  bool GetBinary(size_t index, BinaryValue** out_value);
  bool GetDictionary(size_t index, const DictionaryValue** out_value) const;
  bool GetDictionary(size_t index, DictionaryValue** out_value);
  bool GetList(size_t index, const ListValue** out_value) const;
  bool GetList(size_t index, ListValue** out_value);

  // Removes the Value with the specified index from this list.
  // If |out_value| is non-NULL, the removed Value AND ITS OWNERSHIP will be
  // passed out via |out_value|.  If |out_value| is NULL, the removed value will
  // be deleted.  This method returns true if |index| is valid; otherwise
  // it will return false and the ListValue object will be unchanged.
  virtual bool Remove(size_t index, scoped_ptr<Value>* out_value);

  // Removes the first instance of |value| found in the list, if any, and
  // deletes it. |index| is the location where |value| was found. Returns false
  // if not found.
  bool Remove(const Value& value, size_t* index);

  // Removes the element at |iter|. If |out_value| is NULL, the value will be
  // deleted, otherwise ownership of the value is passed back to the caller.
  // Returns an iterator pointing to the location of the element that
  // followed the erased element.
  iterator Erase(iterator iter, scoped_ptr<Value>* out_value);

  // Appends a Value to the end of the list.
  void Append(scoped_ptr<Value> in_value);
  // Deprecated version of the above. TODO(estade): remove.
  void Append(Value* in_value);

  // Convenience forms of Append.
  void AppendBoolean(bool in_value);
  void AppendInteger(int in_value);
  void AppendDouble(double in_value);
  void AppendString(const std::string& in_value);
  void AppendString(const string16& in_value);
  void AppendStrings(const std::vector<std::string>& in_values);
  void AppendStrings(const std::vector<string16>& in_values);

  // Appends a Value if it's not already present. Takes ownership of the
  // |in_value|. Returns true if successful, or false if the value was already
  // present. If the value was already present the |in_value| is deleted.
  bool AppendIfNotPresent(Value* in_value);

  // Insert a Value at index.
  // Returns true if successful, or false if the index was out of range.
  bool Insert(size_t index, Value* in_value);

  // Searches for the first instance of |value| in the list using the Equals
  // method of the Value type.
  // Returns a const_iterator to the found item or to end() if none exists.
  const_iterator Find(const Value& value) const;

  // Swaps contents with the |other| list.
  virtual void Swap(ListValue* other);

  // Iteration.
  iterator begin() { return list_.begin(); }
  iterator end() { return list_.end(); }

  const_iterator begin() const { return list_.begin(); }
  const_iterator end() const { return list_.end(); }

  // Overridden from Value:
  bool GetAsList(ListValue** out_value) override;
  bool GetAsList(const ListValue** out_value) const override;
  ListValue* DeepCopy() const override;
  bool Equals(const Value* other) const override;

  // Preferred version of DeepCopy. TODO(estade): remove DeepCopy.
  scoped_ptr<ListValue> CreateDeepCopy() const;

 private:
  ValueVector list_;

  DISALLOW_COPY_AND_ASSIGN(ListValue);
};

// This interface is implemented by classes that know how to serialize
// Value objects.
class BASE_EXPORT ValueSerializer {
 public:
  virtual ~ValueSerializer();

  virtual bool Serialize(const Value& root) = 0;
};

// This interface is implemented by classes that know how to deserialize Value
// objects.
class BASE_EXPORT ValueDeserializer {
 public:
  virtual ~ValueDeserializer();

  // This method deserializes the subclass-specific format into a Value object.
  // If the return value is non-NULL, the caller takes ownership of returned
  // Value. If the return value is NULL, and if error_code is non-NULL,
  // error_code will be set with the underlying error.
  // If |error_message| is non-null, it will be filled in with a formatted
  // error message including the location of the error if appropriate.
  virtual Value* Deserialize(int* error_code, std::string* error_str) = 0;
};

// Stream operator so Values can be used in assertion statements.  In order that
// gtest uses this operator to print readable output on test failures, we must
// override each specific type. Otherwise, the default template implementation
// is preferred over an upcast.
BASE_EXPORT std::ostream& operator<<(std::ostream& out, const Value& value);

BASE_EXPORT inline std::ostream& operator<<(std::ostream& out,
                                            const FundamentalValue& value) {
  return out << static_cast<const Value&>(value);
}

BASE_EXPORT inline std::ostream& operator<<(std::ostream& out,
                                            const StringValue& value) {
  return out << static_cast<const Value&>(value);
}

BASE_EXPORT inline std::ostream& operator<<(std::ostream& out,
                                            const DictionaryValue& value) {
  return out << static_cast<const Value&>(value);
}

BASE_EXPORT inline std::ostream& operator<<(std::ostream& out,
                                            const ListValue& value) {
  return out << static_cast<const Value&>(value);
}

}  // namespace base

#endif  // BASE_VALUES_H_
