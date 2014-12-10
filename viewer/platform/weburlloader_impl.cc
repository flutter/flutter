// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/platform/weburlloader_impl.h"

#include "base/bind.h"
#include "base/logging.h"
#include "base/strings/string_util.h"
#include "base/thread_task_runner_handle.h"
#include "mojo/common/common_type_converters.h"
#include "mojo/services/network/public/interfaces/network_service.mojom.h"
#include "net/base/net_errors.h"
#include "sky/engine/public/platform/WebURLError.h"
#include "sky/engine/public/platform/WebURLLoadTiming.h"
#include "sky/engine/public/platform/WebURLLoaderClient.h"
#include "sky/engine/public/platform/WebURLResponse.h"
#include "sky/viewer/converters/url_request_types.h"

namespace sky {
namespace {

static blink::WebURLResponse::HTTPVersion StatusLineToHTTPVersion(
    const mojo::String& status_line) {
  if (status_line.is_null())
    return blink::WebURLResponse::HTTP_0_9;

  if (StartsWithASCII(status_line, "HTTP/1.0", true))
    return blink::WebURLResponse::HTTP_1_0;

  if (StartsWithASCII(status_line, "HTTP/1.1", true))
    return blink::WebURLResponse::HTTP_1_1;

  return blink::WebURLResponse::Unknown;
}

blink::WebURLResponse ToWebURLResponse(const mojo::URLResponsePtr& url_response) {
  blink::WebURLResponse result;
  result.initialize();
  result.setURL(GURL(url_response->url));
  result.setMIMEType(blink::WebString::fromUTF8(url_response->mime_type));
  result.setTextEncodingName(blink::WebString::fromUTF8(url_response->charset));
  result.setHTTPVersion(StatusLineToHTTPVersion(url_response->status_line));
  result.setHTTPStatusCode(url_response->status_code);

  // TODO(darin): Initialize timing properly.
  blink::WebURLLoadTiming timing;
  timing.initialize();
  result.setLoadTiming(timing);

  for (size_t i = 0; i < url_response->headers.size(); ++i) {
    const std::string& header_line = url_response->headers[i];
    size_t first_colon = header_line.find(":");

    if (first_colon == std::string::npos || first_colon == 0)
      continue;

    std::string value;
    TrimWhitespaceASCII(header_line.substr(first_colon + 1),
                        base::TRIM_LEADING,
                        &value);
    result.setHTTPHeaderField(
        blink::WebString::fromUTF8(header_line.substr(0, first_colon)),
        blink::WebString::fromUTF8(value));
  }

  return result;
}

}  // namespace

WebURLLoaderImpl::WebURLLoaderImpl(mojo::NetworkService* network_service)
    : client_(NULL),
      weak_factory_(this) {
  network_service->CreateURLLoader(GetProxy(&url_loader_));
}

WebURLLoaderImpl::~WebURLLoaderImpl() {
}

void WebURLLoaderImpl::loadAsynchronously(const blink::WebURLRequest& request,
                                          blink::WebURLLoaderClient* client) {
  client_ = client;
  url_ = request.url();

  mojo::URLRequestPtr url_request = mojo::URLRequest::From(request);
  url_request->auto_follow_redirects = false;
  url_loader_->Start(url_request.Pass(),
                     base::Bind(&WebURLLoaderImpl::OnReceivedResponse,
                                weak_factory_.GetWeakPtr()));
}

void WebURLLoaderImpl::cancel() {
  url_loader_.reset();
  response_body_stream_.reset();

  mojo::URLResponsePtr failed_response(mojo::URLResponse::New());
  failed_response->url = mojo::String::From(url_);
  failed_response->error = mojo::NetworkError::New();
  failed_response->error->code = net::ERR_ABORTED;

  base::ThreadTaskRunnerHandle::Get()->PostTask(
      FROM_HERE,
      base::Bind(&WebURLLoaderImpl::OnReceivedResponse,
                 weak_factory_.GetWeakPtr(),
                 base::Passed(&failed_response)));
}

void WebURLLoaderImpl::OnReceivedResponse(mojo::URLResponsePtr url_response) {
  url_ = GURL(url_response->url);

  if (url_response->error) {
    OnReceivedError(url_response.Pass());
  } else if (url_response->redirect_url) {
    OnReceivedRedirect(url_response.Pass());
  } else {
    base::WeakPtr<WebURLLoaderImpl> self(weak_factory_.GetWeakPtr());
    client_->didReceiveResponse(this, ToWebURLResponse(url_response));

    // We may have been deleted during didReceiveResponse.
    if (!self)
      return;

    // Start streaming data
    response_body_stream_ = url_response->body.Pass();
    ReadMore();
  }
}

void WebURLLoaderImpl::OnReceivedError(mojo::URLResponsePtr url_response) {
  blink::WebURLError web_error;
  web_error.domain = blink::WebString::fromUTF8(net::kErrorDomain);
  web_error.reason = url_response->error->code;
  web_error.unreachableURL = GURL(url_response->url);
  web_error.staleCopyInCache = false;
  web_error.isCancellation =
      url_response->error->code == net::ERR_ABORTED ? true : false;

  client_->didFail(this, web_error);
}

void WebURLLoaderImpl::OnReceivedRedirect(mojo::URLResponsePtr url_response) {
  blink::WebURLRequest new_request;
  new_request.initialize();
  new_request.setURL(GURL(url_response->redirect_url));
  new_request.setHTTPMethod(
      blink::WebString::fromUTF8(url_response->redirect_method));

  client_->willSendRequest(this, new_request, ToWebURLResponse(url_response));
  // TODO(darin): Check if new_request was rejected.

  url_loader_->FollowRedirect(
      base::Bind(&WebURLLoaderImpl::OnReceivedResponse,
                 weak_factory_.GetWeakPtr()));
}

void WebURLLoaderImpl::ReadMore() {
  const void* buf;
  uint32_t buf_size;
  MojoResult rv = mojo::BeginReadDataRaw(response_body_stream_.get(),
                                         &buf,
                                         &buf_size,
                                         MOJO_READ_DATA_FLAG_NONE);
  if (rv == MOJO_RESULT_OK) {
    client_->didReceiveData(this, static_cast<const char*>(buf), buf_size, -1);
    EndReadDataRaw(response_body_stream_.get(), buf_size);
    WaitToReadMore();
  } else if (rv == MOJO_RESULT_SHOULD_WAIT) {
    WaitToReadMore();
  } else if (rv == MOJO_RESULT_FAILED_PRECONDITION) {
    // We reached end-of-file.
    double finish_time = base::Time::Now().ToDoubleT();
    client_->didFinishLoading(
        this,
        finish_time,
        blink::WebURLLoaderClient::kUnknownEncodedDataLength);
  } else {
    // TODO(darin): Oops!
  }
}

void WebURLLoaderImpl::WaitToReadMore() {
  handle_watcher_.Start(
      response_body_stream_.get(),
      MOJO_HANDLE_SIGNAL_READABLE,
      MOJO_DEADLINE_INDEFINITE,
      base::Bind(&WebURLLoaderImpl::OnResponseBodyStreamReady,
                 weak_factory_.GetWeakPtr()));
}

void WebURLLoaderImpl::OnResponseBodyStreamReady(MojoResult result) {
  ReadMore();
}

}  // namespace sky
