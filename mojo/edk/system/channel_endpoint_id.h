// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_CHANNEL_ENDPOINT_ID_H_
#define MOJO_EDK_SYSTEM_CHANNEL_ENDPOINT_ID_H_

#include <stddef.h>
#include <stdint.h>

#include <functional>
#include <ostream>

#include "mojo/edk/util/gtest_prod_utils.h"
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
class ChannelEndpointId {
 public:
  ChannelEndpointId() : value_(0) {
    // This wrapper should add no overhead. (Put this here, since |value_| is
    // private and we also need the class to be fully defined.)
    static_assert(sizeof(ChannelEndpointId) == sizeof(value_),
                  "ChannelEndpointId has incorrect size");
  }
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

// So logging macros and |DCHECK_EQ()|, etc. work.
inline std::ostream& operator<<(std::ostream& out,
                                const ChannelEndpointId& channel_endpoint_id) {
  return out << channel_endpoint_id.value();
}

// LocalChannelEndpointIdGenerator ---------------------------------------------

// A generator for "new" local |ChannelEndpointId|s. It does not track
// used/existing IDs; that must be done separately. (This class is not
// thread-safe.)
class LocalChannelEndpointIdGenerator {
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
class RemoteChannelEndpointIdGenerator {
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

namespace std {

// Specialization of |std::hash<>| for |ChannelEndpointId|s, so they can be used
// in unordered sets/maps.
template <>
struct hash<mojo::system::ChannelEndpointId> {
  size_t operator()(mojo::system::ChannelEndpointId channel_endpoint_id) const {
    return static_cast<size_t>(channel_endpoint_id.value());
  }
};

}  // namespace std

#endif  // MOJO_EDK_SYSTEM_CHANNEL_ENDPOINT_ID_H_
