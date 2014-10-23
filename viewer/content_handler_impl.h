// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CONTENT_HANDLER_H_
#define SKY_VIEWER_CONTENT_HANDLER_H_

#include "base/message_loop/message_loop.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "mojo/services/public/interfaces/content_handler/content_handler.mojom.h"

namespace sky {
class DocumentView;

class ContentHandlerImpl : public mojo::InterfaceImpl<mojo::ContentHandler> {
 public:
  ContentHandlerImpl(mojo::Shell* shell,
                     scoped_refptr<base::MessageLoopProxy> compositor_thread);
  virtual ~ContentHandlerImpl();

 private:
  // Overridden from ContentHandler:
  virtual void OnConnect(
      const mojo::String& url,
      mojo::URLResponsePtr response,
      mojo::InterfaceRequest<mojo::ServiceProvider>
          servive_provider_request) override;

  mojo::Shell* shell_;
  scoped_refptr<base::MessageLoopProxy> compositor_thread_;

  DISALLOW_COPY_AND_ASSIGN(ContentHandlerImpl);
};

}  // namespace sky

#endif  // SKY_VIEWER_DOCUMENT_VIEW_H_
