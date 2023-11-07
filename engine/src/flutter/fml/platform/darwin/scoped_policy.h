// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_DARWIN_SCOPED_POLICY_H_
#define FLUTTER_FML_PLATFORM_DARWIN_SCOPED_POLICY_H_

namespace fml {
namespace scoped_policy {

// Defines the ownership policy for a scoped object.
enum OwnershipPolicy {
  // The scoped object takes ownership of an object by taking over an existing
  // ownership claim.
  kAssume,

  // The scoped object will retain the the object and any initial ownership is
  // not changed.
  kRetain
};

}  // namespace scoped_policy
}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_DARWIN_SCOPED_POLICY_H_
