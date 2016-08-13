// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/application_impl.h"

#include <utility>

#include "apps/dart_content_handler/zip/unzipper.h"
#include "flutter/content_handler/runtime_holder.h"
#include "lib/ftl/logging.h"
#include "mojo/public/cpp/application/connect.h"

namespace flutter_content_handler {
namespace {

constexpr char kSnapshotKey[] = "snapshot_blob.bin";

std::vector<char> ExtractSnapshot(std::vector<char> bundle) {
  zip::Unzipper unzipper(std::move(bundle));
  return unzipper.Extract(kSnapshotKey);
}

}  // namespace

ApplicationImpl::ApplicationImpl(
    mojo::InterfaceRequest<mojo::Application> application,
    mojo::URLResponsePtr response)
    : binding_(this, std::move(application)) {
  drainer_.reset(new glue::DrainDataPipeJob(
      std::move(response->body), [this](std::vector<char> bundle) {
        snapshot_ = ExtractSnapshot(std::move(bundle));
        StartRuntimeIfReady();
      }));
}

ApplicationImpl::~ApplicationImpl() {}

void ApplicationImpl::Initialize(mojo::InterfaceHandle<mojo::Shell> shell,
                                 mojo::Array<mojo::String> args,
                                 const mojo::String& url) {
  shell_ = mojo::ShellPtr::Create(shell.Pass());
  url_ = url;
  mojo::ApplicationConnectorPtr connector;
  shell_->CreateApplicationConnector(mojo::GetProxy(&connector));
  runtime_holder_.reset(new RuntimeHolder());
  runtime_holder_->Init(std::move(connector));
  StartRuntimeIfReady();
}

void ApplicationImpl::AcceptConnection(
    const mojo::String& requestor_url,
    const mojo::String& resolved_url,
    mojo::InterfaceRequest<mojo::ServiceProvider> services) {}

void ApplicationImpl::RequestQuit() {
  binding_.Close();
  delete this;
}

void ApplicationImpl::StartRuntimeIfReady() {
  if (!runtime_holder_ || snapshot_.empty())
    return;
  runtime_holder_->Run(url_, std::move(snapshot_));
}

}  // namespace flutter_content_handler
