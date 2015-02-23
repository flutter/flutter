// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_INTERNALS_H_
#define SKY_VIEWER_INTERNALS_H_

#include "base/memory/weak_ptr.h"
#include "base/supports_user_data.h"
#include "dart/runtime/include/dart_api.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "sky/services/testing/test_harness.mojom.h"

namespace sky {
class DocumentView;

class Internals : public base::SupportsUserData::Data,
                  public mojo::Shell {
 public:
  virtual ~Internals();

  static void Create(Dart_Isolate isolate, DocumentView* document_view);

  // mojo::Shell method:
  void ConnectToApplication(
      const mojo::String& application_url,
      mojo::InterfaceRequest<mojo::ServiceProvider> services,
      mojo::ServiceProviderPtr exposed_services) override;

  std::string RenderTreeAsText();
  std::string ContentAsText();
  void NotifyTestComplete(const std::string& test_result);

  mojo::Handle TakeShellProxyHandle();
  mojo::Handle TakeServicesProvidedToEmbedder();
  mojo::Handle TakeServicesProvidedByEmbedder();

  void pauseAnimations(double pauseTime);

 private:
  explicit Internals(DocumentView* document_view);

  base::WeakPtr<DocumentView> document_view_;
  mojo::Binding<mojo::Shell> shell_binding_;
  TestHarnessPtr test_harness_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Internals);
};

}  // namespace sky

#endif  // SKY_VIEWER_INTERNALS_H_
