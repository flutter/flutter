// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/app/ModuleLoader.h"

#include "base/bind.h"
#include "sky/engine/core/app/Application.h"
#include "sky/engine/core/app/Module.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/DocumentParser.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

ModuleLoader::Client::~Client() {
}

ModuleLoader::ModuleLoader(Client* client,
                           Application* application,
                           const KURL& url)
    : state_(LOADING),
      client_(client),
      application_(application),
      fetcher_(adoptPtr(new MojoFetcher(this, url))),
      weak_factory_(this) {
}

ModuleLoader::~ModuleLoader() {
}

void ModuleLoader::OnReceivedResponse(mojo::URLResponsePtr response) {
  if (response->error || response->status_code >= 400) {
    String message = String::format(
        "Failed to load resource: Server responded with a status of %d (%s)",
        response->status_code, response->status_line.data());
    RefPtr<ConsoleMessage> consoleMessage = ConsoleMessage::create(
        NetworkMessageSource, ErrorMessageLevel, message, response->url.data());
    application_->document()->addMessage(consoleMessage);
    state_ = COMPLETE;
    client_->OnModuleLoadComplete(this, nullptr);
    return;
  }

  WeakPtr<Document> context = application_->document()->contextDocument();
  ASSERT(context.get());
  KURL url(ParsedURLString, String::fromUTF8(response->url));
  DocumentInit init = DocumentInit(url, 0, context, 0)
      .withRegistrationContext(context->registrationContext());

  RefPtr<Document> document = Document::create(init);
  document->startParsing()->parse(response->body.Pass(),
      base::Bind(&ModuleLoader::OnParsingComplete, weak_factory_.GetWeakPtr()));

  module_ = Module::create(
      context.get(), application_, document.release(), url.string());
}

void ModuleLoader::OnParsingComplete() {
  state_ = COMPLETE;
  client_->OnModuleLoadComplete(this, module_.get());
}

} // namespace blink
