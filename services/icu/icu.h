// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SERVICES_ICU_ICU_H_
#define FLUTTER_SERVICES_ICU_ICU_H_

namespace mojo {
class ApplicationConnector;

namespace icu {

void Initialize(ApplicationConnector* application_connector);

}  // namespace icu
}  // namespace mojo

#endif  // FLUTTER_SERVICES_ICU_ICU_H_
