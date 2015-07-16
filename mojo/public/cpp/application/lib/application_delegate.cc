// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/application/application_delegate.h"

namespace mojo {

ApplicationDelegate::ApplicationDelegate() {
}
ApplicationDelegate::~ApplicationDelegate() {
}

void ApplicationDelegate::Initialize(ApplicationImpl* app) {
}

bool ApplicationDelegate::ConfigureIncomingConnection(
    ApplicationConnection* connection) {
  return true;
}

bool ApplicationDelegate::ConfigureOutgoingConnection(
    ApplicationConnection* connection) {
  return true;
}

void ApplicationDelegate::Quit() {
}

}  // namespace mojo
