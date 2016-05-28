// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_ICU_ICU_H_
#define MOJO_ICU_ICU_H_

namespace mojo {
class ApplicationConnector;

namespace icu {

void Initialize(ApplicationConnector* application_connector);

}  // namespace icu
}  // namespace mojo

#endif  // MOJO_ICU_ICU_H_
