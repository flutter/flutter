// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_WIN_REGISTRY_H_
#define BASE_WIN_REGISTRY_H_

#include <windows.h>
#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/stl_util.h"
#include "base/win/object_watcher.h"
#include "base/win/scoped_handle.h"

namespace base {
namespace win {

// Utility class to read, write and manipulate the Windows Registry.
// Registry vocabulary primer: a "key" is like a folder, in which there
// are "values", which are <name, data> pairs, with an associated data type.
//
// Note:
// ReadValue family of functions guarantee that the return arguments
// are not touched in case of failure.
class BASE_EXPORT RegKey {
 public:
  // Called from the MessageLoop when the key changes.
  typedef base::Callback<void()> ChangeCallback;

  RegKey();
  explicit RegKey(HKEY key);
  RegKey(HKEY rootkey, const wchar_t* subkey, REGSAM access);
  ~RegKey();

  LONG Create(HKEY rootkey, const wchar_t* subkey, REGSAM access);

  LONG CreateWithDisposition(HKEY rootkey, const wchar_t* subkey,
                             DWORD* disposition, REGSAM access);

  // Creates a subkey or open it if it already exists.
  LONG CreateKey(const wchar_t* name, REGSAM access);

  // Opens an existing reg key.
  LONG Open(HKEY rootkey, const wchar_t* subkey, REGSAM access);

  // Opens an existing reg key, given the relative key name.
  LONG OpenKey(const wchar_t* relative_key_name, REGSAM access);

  // Closes this reg key.
  void Close();

  // Replaces the handle of the registry key and takes ownership of the handle.
  void Set(HKEY key);

  // Transfers ownership away from this object.
  HKEY Take();

  // Returns false if this key does not have the specified value, or if an error
  // occurrs while attempting to access it.
  bool HasValue(const wchar_t* value_name) const;

  // Returns the number of values for this key, or 0 if the number cannot be
  // determined.
  DWORD GetValueCount() const;

  // Determine the nth value's name.
  LONG GetValueNameAt(int index, std::wstring* name) const;

  // True while the key is valid.
  bool Valid() const { return key_ != NULL; }

  // Kill a key and everything that live below it; please be careful when using
  // it.
  LONG DeleteKey(const wchar_t* name);

  // Deletes an empty subkey.  If the subkey has subkeys or values then this
  // will fail.
  LONG DeleteEmptyKey(const wchar_t* name);

  // Deletes a single value within the key.
  LONG DeleteValue(const wchar_t* name);

  // Getters:

  // Returns an int32 value. If |name| is NULL or empty, returns the default
  // value, if any.
  LONG ReadValueDW(const wchar_t* name, DWORD* out_value) const;

  // Returns an int64 value. If |name| is NULL or empty, returns the default
  // value, if any.
  LONG ReadInt64(const wchar_t* name, int64* out_value) const;

  // Returns a string value. If |name| is NULL or empty, returns the default
  // value, if any.
  LONG ReadValue(const wchar_t* name, std::wstring* out_value) const;

  // Reads a REG_MULTI_SZ registry field into a vector of strings. Clears
  // |values| initially and adds further strings to the list. Returns
  // ERROR_CANTREAD if type is not REG_MULTI_SZ.
  LONG ReadValues(const wchar_t* name, std::vector<std::wstring>* values);

  // Returns raw data. If |name| is NULL or empty, returns the default
  // value, if any.
  LONG ReadValue(const wchar_t* name,
                 void* data,
                 DWORD* dsize,
                 DWORD* dtype) const;

  // Setters:

  // Sets an int32 value.
  LONG WriteValue(const wchar_t* name, DWORD in_value);

  // Sets a string value.
  LONG WriteValue(const wchar_t* name, const wchar_t* in_value);

  // Sets raw data, including type.
  LONG WriteValue(const wchar_t* name,
                  const void* data,
                  DWORD dsize,
                  DWORD dtype);

  // Starts watching the key to see if any of its values have changed.
  // The key must have been opened with the KEY_NOTIFY access privilege.
  // Returns true on success.
  // To stop watching, delete this RegKey object. To continue watching the
  // object after the callback is invoked, call StartWatching again.
  bool StartWatching(const ChangeCallback& callback);

  HKEY Handle() const { return key_; }

 private:
  class Watcher;

  // Calls RegDeleteKeyEx on supported platforms, alternatively falls back to
  // RegDeleteKey.
  static LONG RegDeleteKeyExWrapper(HKEY hKey,
                                    const wchar_t* lpSubKey,
                                    REGSAM samDesired,
                                    DWORD Reserved);

  // Recursively deletes a key and all of its subkeys.
  static LONG RegDelRecurse(HKEY root_key,
                            const std::wstring& name,
                            REGSAM access);

  HKEY key_;  // The registry key being iterated.
  REGSAM wow64access_;
  scoped_ptr<Watcher> key_watcher_;

  DISALLOW_COPY_AND_ASSIGN(RegKey);
};

// Iterates the entries found in a particular folder on the registry.
class BASE_EXPORT RegistryValueIterator {
 public:
  // Construct a Registry Value Iterator with default WOW64 access.
  RegistryValueIterator(HKEY root_key, const wchar_t* folder_key);

  // Construct a Registry Key Iterator with specific WOW64 access, one of
  // KEY_WOW64_32KEY or KEY_WOW64_64KEY, or 0.
  // Note: |wow64access| should be the same access used to open |root_key|
  // previously, or a predefined key (e.g. HKEY_LOCAL_MACHINE).
  // See http://msdn.microsoft.com/en-us/library/windows/desktop/aa384129.aspx.
  RegistryValueIterator(HKEY root_key,
                        const wchar_t* folder_key,
                        REGSAM wow64access);

  ~RegistryValueIterator();

  DWORD ValueCount() const;

  // True while the iterator is valid.
  bool Valid() const;

  // Advances to the next registry entry.
  void operator++();

  const wchar_t* Name() const { return name_.c_str(); }
  const wchar_t* Value() const { return vector_as_array(&value_); }
  // ValueSize() is in bytes.
  DWORD ValueSize() const { return value_size_; }
  DWORD Type() const { return type_; }

  int Index() const { return index_; }

 private:
  // Read in the current values.
  bool Read();

  void Initialize(HKEY root_key, const wchar_t* folder_key, REGSAM wow64access);

  // The registry key being iterated.
  HKEY key_;

  // Current index of the iteration.
  int index_;

  // Current values.
  std::wstring name_;
  std::vector<wchar_t> value_;
  DWORD value_size_;
  DWORD type_;

  DISALLOW_COPY_AND_ASSIGN(RegistryValueIterator);
};

class BASE_EXPORT RegistryKeyIterator {
 public:
  // Construct a Registry Key Iterator with default WOW64 access.
  RegistryKeyIterator(HKEY root_key, const wchar_t* folder_key);

  // Construct a Registry Value Iterator with specific WOW64 access, one of
  // KEY_WOW64_32KEY or KEY_WOW64_64KEY, or 0.
  // Note: |wow64access| should be the same access used to open |root_key|
  // previously, or a predefined key (e.g. HKEY_LOCAL_MACHINE).
  // See http://msdn.microsoft.com/en-us/library/windows/desktop/aa384129.aspx.
  RegistryKeyIterator(HKEY root_key,
                      const wchar_t* folder_key,
                      REGSAM wow64access);

  ~RegistryKeyIterator();

  DWORD SubkeyCount() const;

  // True while the iterator is valid.
  bool Valid() const;

  // Advances to the next entry in the folder.
  void operator++();

  const wchar_t* Name() const { return name_; }

  int Index() const { return index_; }

 private:
  // Read in the current values.
  bool Read();

  void Initialize(HKEY root_key, const wchar_t* folder_key, REGSAM wow64access);

  // The registry key being iterated.
  HKEY key_;

  // Current index of the iteration.
  int index_;

  wchar_t name_[MAX_PATH];

  DISALLOW_COPY_AND_ASSIGN(RegistryKeyIterator);
};

}  // namespace win
}  // namespace base

#endif  // BASE_WIN_REGISTRY_H_
