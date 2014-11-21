// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_V8_INSPECTOR_INSPECTOR_HOST_H_
#define SKY_ENGINE_V8_INSPECTOR_INSPECTOR_HOST_H_

namespace mojo {
class Shell;
}
namespace v8 {
class Isolate;
class Context;
template <class T>
class Local;
}

namespace inspector {

class InspectorHost {
 public:
  virtual mojo::Shell* GetShell() = 0;
  virtual v8::Isolate* GetIsolate() = 0;
  virtual v8::Local<v8::Context> GetContext() = 0;
};

}  // namespace inspector

#endif  // SKY_ENGINE_V8_INSPECTOR_INSPECTOR_HOST_H_
