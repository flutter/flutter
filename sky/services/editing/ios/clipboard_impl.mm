// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/editing/ios/clipboard_impl.h"

#include "base/logging.h"
#include "base/strings/sys_string_conversions.h"
#include "base/strings/utf_string_conversions.h"
#include <UIKit/UIKit.h>
#include <unicode/utf16.h>

namespace {

static const char kTextPlainFormat[] = "text/plain";

}  // namespace

namespace sky {
namespace services {
namespace editing {

ClipboardImpl::ClipboardImpl(
    mojo::InterfaceRequest<::editing::Clipboard> request)
    : binding_(this, request.Pass()) {}

ClipboardImpl::~ClipboardImpl() {
}

void ClipboardImpl::SetClipboardData(::editing::ClipboardDataPtr clip) {
  UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
  pasteboard.string = @(clip->text.data());
}

void ClipboardImpl::GetClipboardData(
    const mojo::String& format,
    const ::editing::Clipboard::GetClipboardDataCallback& callback) {
  ::editing::ClipboardDataPtr clip;

  UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
  if ((format.is_null() || format == kTextPlainFormat) && pasteboard.string) {
    clip = ::editing::ClipboardData::New();
    clip->text = pasteboard.string.UTF8String;
  }

  callback.Run(clip.Pass());
}

}  // namespace editing
}  // namespace services
}  // namespace sky
