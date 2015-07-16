// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_CHANNEL_ENDPOINT_ID_H_
#define MOJO_EDK_SYSTEM_CHANNEL_ENDPOINT_ID_H_

#include <stddef.h>
#include <stdint.h>

#include <ostream>

#include "base/containers/hash_tables.h"
#include "base/gtest_prod_util.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

// ChannelEndpointId -----------------------------------------------------------

class LocalChannelEndpointIdGenerator;
FORWARD_DECLARE_TEST(LocalChannelEndpointIdGeneratorTest, WrapAround);
FORWARD_DECLARE_TEST(RemoteChannelEndpointIdGeneratorTest, WrapAround);

// Represents an ID for an endpoint (i.e., one side of a message pipe) on a
// |Channel|. This class must be POD.
//
// Note: The terminology "remote" for a |ChannelEndpointId| means a destination
// ID that was actually allocated by the sender, or similarly a source ID that
// was allocated by the receiver.
//
// From the standpoint of the |Channel| with such a remote ID in its endpoint
// table, such an ID is a "remotely-allocated local ID". From the standpoint of
// the |Channel| allocating such a remote ID (for its peer |Channel|), it's a
// "locally-allocated remote ID".
class MOJO_SYSTEM_IMPL_EXPORT ChannelEndpointId {
 public:
  ChannelEndpointId() : value_(0) {}
  ChannelEndpointId(const ChannelEndpointId& other) : value_(other.value_) {}

  // Returns the local ID to use for the first message pipe endpoint on a
  // channel.
  static ChannelEndpointId GetBootstrap() { return ChannelEndpointId(1); }

  bool operator==(const ChannelEndpointId& other) const {
    return value_ == other.value_;
  }
  bool operator!=(const ChannelEndpointId& other) const {
    return !operator==(other);
  }
  // So that we can be used in |std::map|, etc.
  bool operator<(const ChannelEndpointId& other) const {
    return value_ < other.value_;
  }

  bool is_valid() const { return !!value_; }
  bool is_remote() const { return !!(value_ & kRemoteFlag); }
  const uint32_t& value() const { return value_; }

  // Flag set in |value()| if this is a remote ID.
  static const uint32_t kRemoteFlag = 0x80000000u;

 private:
  friend class LocalChannelEndpointIdGenerator;
  FRIEND_TEST_ALL_PREFIXES(LocalChannelEndpointIdGeneratorTest, WrapAround);
  friend class RemoteChannelEndpointIdGenerator;
  FRIEND_TEST_ALL_PREFIXES(RemoteChannelEndpointIdGeneratorTest, WrapAround);

  explicit ChannelEndpointId(uint32_t value) : value_(value) {}

  uint32_t value_;

  // Copying and assignment allowed.
};
// This wrapper should add no overhead.
// TODO(vtl): Rewrite |sizeof(uint32_t)| as |sizeof(ChannelEndpointId::value)|
// once we have sufficient C++11 support.
static_assert(sizeof(ChannelEndpointId) == sizeof(uint32_t),
              "ChannelEndpointId has incorrect size");

// So logging macros and |DCHECK_EQ()|, etc. work.
MOJO_SYSTEM_IMPL_EXPORT inline std::ostream& operator<<(
    std::ostream& out,
    const ChannelEndpointId& channel_endpoint_id) {
  return out << channel_endpoint_id.value();
}

// LocalChannelEndpointIdGenerator ---------------------------------------------

// A generator for "new" local |ChannelEndpointId|s. It does not track
// used/existing IDs; that must be done separately. (This class is not
// thread-safe.)
class MOJO_SYSTEM_IMPL_EXPORT LocalChannelEndpointIdGenerator {
 public:
  LocalChannelEndpointIdGenerator()
      : next_(ChannelEndpointId::GetBootstrap()) {}

  ChannelEndpointId GetNext();

 private:
  FRIEND_TEST_ALL_PREFIXES(LocalChannelEndpointIdGeneratorTest, WrapAround);

  ChannelEndpointId next_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(LocalChannelEndpointIdGenerator);
};

// RemoteChannelEndpointIdGenerator --------------------------------------------

// A generator for "new" remote |ChannelEndpointId|s, for |Channel|s to
// locally allocate remote IDs. (See the comment above |ChannelEndpointId| for
// an explanatory note.) It does not track used/existing IDs; that must be done
// separately. (This class is not thread-safe.)
class MOJO_SYSTEM_IMPL_EXPORT RemoteChannelEndpointIdGenerator {
 public:
  RemoteChannelEndpointIdGenerator() : next_(ChannelEndpointId::kRemoteFlag) {}

  ChannelEndpointId GetNext();

 private:
  FRIEND_TEST_ALL_PREFIXES(RemoteChannelEndpointIdGeneratorTest, WrapAround);

  ChannelEndpointId next_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(RemoteChannelEndpointIdGenerator);
};

}  // namespace system
}  // namespace mojo

// Define "hash" functions for |ChannelEndpointId|s, so they can be used in hash
// tables.
// TODO(vtl): Once we can use |std::unordered_{map,set}|, update this (and
// remove the base/containers/hash_tables.h include).
namespace BASE_HASH_NAMESPACE {

template <>
struct hash<mojo::system::ChannelEndpointId> {
  size_t operator()(mojo::system::ChannelEndpointId channel_endpoint_id) const {
    return static_cast<size_t>(channel_endpoint_id.value());
  }
};

}  // namespace BASE_HASH_NAMESPACE

#endif  // MOJO_EDK_SYSTEM_CHANNEL_ENDPOINT_ID_H_
