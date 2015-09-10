// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_MANIFEST_H_
#define SKY_SHELL_MANIFEST_H_

#include <string>

#include "base/memory/scoped_ptr.h"
#include "base/version.h"
#include "url/gurl.h"

namespace sky {
namespace shell {

struct Manifest {
 public:
  static scoped_ptr<Manifest> Parse(const std::string& manifest_data);

  bool IsValid() const { return version_.IsValid(); }

  const GURL& update_url() const { return update_url_; }
  const base::Version& version() const { return version_; }

 private:
  GURL update_url_;
  base::Version version_;
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_MANIFEST_H_
