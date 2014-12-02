// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_INTERNALS_H_
#define SKY_VIEWER_INTERNALS_H_

#include "base/memory/weak_ptr.h"
#include "gin/handle.h"
#include "gin/object_template_builder.h"
#include "gin/wrappable.h"
#include "sky/services/testing/test_harness.mojom.h"

namespace sky {
class DocumentView;

class Internals : public gin::Wrappable<Internals> {
 public:
  static gin::WrapperInfo kWrapperInfo;
  static gin::Handle<Internals> Create(v8::Isolate*, DocumentView*);

  virtual ~Internals();

  virtual gin::ObjectTemplateBuilder GetObjectTemplateBuilder(
      v8::Isolate* isolate) override;

 private:
  explicit Internals(DocumentView* document_view);

  std::string RenderTreeAsText();
  std::string ContentAsText();
  void NotifyTestComplete(const std::string& test_result);

  mojo::Handle ConnectToService(
      const std::string& application_url, const std::string& interface_name);

  base::WeakPtr<DocumentView> document_view_;
  TestHarnessPtr test_harness_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Internals);
};

}  // namespace sky

#endif  // SKY_VIEWER_INTERNALS_H_
