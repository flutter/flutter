// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Functions to help with verifying various |Mojo...Options| structs from the
// (public, C) API. These are "extensible" structs, which all have |struct_size|
// as their first member. All fields (other than |struct_size|) are optional,
// but any |flags| specified must be known to the system (otherwise, an error of
// |MOJO_RESULT_UNIMPLEMENTED| should be returned).

#ifndef MOJO_EDK_SYSTEM_OPTIONS_VALIDATION_H_
#define MOJO_EDK_SYSTEM_OPTIONS_VALIDATION_H_

#include <stddef.h>
#include <stdint.h>

#include <type_traits>

#include "base/logging.h"
#include "mojo/edk/system/memory.h"
#include "mojo/public/c/system/types.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

template <class Options>
class UserOptionsReader {
 public:
  static_assert(offsetof(Options, struct_size) == 0,
                "struct_size not first member of Options");
  static_assert(std::is_same<decltype(Options::struct_size), uint32_t>::value,
                "Options::struct_size not a uint32_t");

  // Constructor from a |UserPointer<const Options>| (which it checks -- this
  // constructor has side effects!).
  // Note: We initialize |options_reader_| without checking, since we do a check
  // in |GetSizeForReader()|.
  explicit UserOptionsReader(UserPointer<const Options> options)
      : options_reader_(options, GetSizeForReader(options)) {}

  bool is_valid() const {
    return options_reader_.GetPointer()->struct_size >= sizeof(uint32_t);
  }

  const Options& options() const {
    DCHECK(is_valid());
    return *options_reader_.GetPointer();
  }

  // Checks that the given (variable-size) |options| passed to the constructor
  // (plausibly) has a member at the given offset with the given size. You
  // probably want to use |OPTIONS_STRUCT_HAS_MEMBER()| instead.
  bool HasMember(size_t offset, size_t size) const {
    DCHECK(is_valid());
    // We assume that |offset| and |size| are reasonable, since they should come
    // from |offsetof(Options, some_member)| and |sizeof(Options::some_member)|,
    // respectively.
    return options().struct_size >= offset + size;
  }

 private:
  static inline size_t GetSizeForReader(UserPointer<const Options> options) {
    uint32_t struct_size =
        options.template ReinterpretCast<const uint32_t>().Get();
    // Note: |PartialReader| will clear memory, so |is_valid()| will return
    // false in this case.
    if (struct_size < sizeof(uint32_t))
      return 0;

    // |PartialReader|'s constructor will automatically limit the amount copied
    // to |sizeof(Options)|.
    return struct_size;
  }

  typename UserPointer<const Options>::PartialReader options_reader_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(UserOptionsReader);
};

// Macro to invoke |UserOptionsReader<Options>::HasMember()| parametrized by
// member name instead of offset and size.
//
// (We can't just give |HasMember()| a member pointer template argument instead,
// since there's no good/strictly-correct way to get an offset from that.)
//
// TODO(vtl): Can we pull out the type |Options| from |reader| instead of
// requiring a parameter? (E.g., we could give |UserOptionsReader| a type alias
// for |Options|. Or maybe there's a clever way to use |decltype|.)
#define OPTIONS_STRUCT_HAS_MEMBER(Options, member, reader) \
  reader.HasMember(offsetof(Options, member), sizeof(Options::member))

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_OPTIONS_VALIDATION_H_
