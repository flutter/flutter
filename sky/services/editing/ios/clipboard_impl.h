// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_CLIPBOARD_IOS_CLIPBOARD_SERVICE_IMPL_H_
#define SKY_SERVICES_CLIPBOARD_IOS_CLIPBOARD_SERVICE_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/application/interface_factory.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "sky/services/editing/editing.mojom.h"

namespace sky {
namespace services {
namespace editing {

class ClipboardImpl : public ::editing::Clipboard {
 public:
  explicit ClipboardImpl(mojo::InterfaceRequest<::editing::Clipboard> request);
  ~ClipboardImpl() override;
  void SetClipboardData(::editing::ClipboardDataPtr clip) override;
  void GetClipboardData(
      const mojo::String& format,
      const ::editing::Clipboard::GetClipboardDataCallback& callback) override;

 private:
  mojo::StrongBinding<::editing::Clipboard> binding_;

  DISALLOW_COPY_AND_ASSIGN(ClipboardImpl);
};

class ClipboardFactory
    : public mojo::InterfaceFactory<::editing::Clipboard> {
 public:
  void Create(
      mojo::ApplicationConnection* connection,
      mojo::InterfaceRequest<::editing::Clipboard> request) override;
};

}  // namespace editing
}  // namespace services
}  // namespace sky

#endif /* defined(SKY_SERVICES_CLIPBOARD_IOS_CLIPBOARD_SERVICE_IMPL_H__) */
