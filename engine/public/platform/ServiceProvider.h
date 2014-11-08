// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PUBLIC_PLATFORM_SERVICES_H_
#define SKY_ENGINE_PUBLIC_PLATFORM_SERVICES_H_

namespace mojo {
class NavigatorHost;
}

namespace blink {

class ServiceProvider {
 public:
  virtual mojo::NavigatorHost* NavigatorHost() = 0;

 protected:
  virtual ~ServiceProvider();
};

} // namespace blink

#endif
