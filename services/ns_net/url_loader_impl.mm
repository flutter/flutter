// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "url_loader_impl.h"
#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/logging.h"
#include "base/mac/scoped_nsautorelease_pool.h"
#include "mojo/data_pipe_utils/data_pipe_drainer.h"

#import <Foundation/Foundation.h>

static mojo::URLResponsePtr MojoErrorResponse(NSURL* url, NSString* message) {
  mojo::URLResponsePtr response = mojo::URLResponse::New();
  response->url = url.absoluteString.UTF8String;
  response->error = mojo::NetworkError::New();
  response->error->description = message.UTF8String;
  return response;
}

static mojo::URLResponsePtr MojoNetworkResponse(
    NSURL* url,
    NSHTTPURLResponse* response,
    mojo::ScopedDataPipeConsumerHandle response_data) {
  mojo::URLResponsePtr mojo_response = mojo::URLResponse::New();
  mojo_response->status_code = static_cast<uint32_t>(response.statusCode);
  mojo_response->url = url.absoluteString.UTF8String;

  NSDictionary* headers = response.allHeaderFields;

  if (headers.count > 0) {
    mojo_response->headers = mojo::Array<mojo::HttpHeaderPtr>::New(0);

    for (NSString* key in headers.allKeys) {
      auto mojo_header = mojo::HttpHeader::New();

      mojo_header->name = key.UTF8String;
      mojo_header->value = [headers[key] UTF8String];

      mojo_response->headers.push_back(mojo_header.Pass());
    }
  }

  mojo_response->body = response_data.Pass();

  return mojo_response;
}

@interface URLLoaderConnectionDelegate : NSObject<NSURLConnectionDataDelegate>

@end

@implementation URLLoaderConnectionDelegate {
  mojo::DataPipe _pipe;
  mojo::URLLoader::StartCallback _startCallback;
}

- (instancetype)initWithStartCallback:
    (mojo::URLLoader::StartCallback)startCallback {
  self = [super init];
  if (self) {
    _startCallback = startCallback;
  }
  return self;
}

- (void)invokeStartCallback:(mojo::URLResponsePtr)response {
  if (!_startCallback.is_null()) {
    _startCallback.Run(response.Pass());
    _startCallback.reset();
  }
}

- (void)connection:(NSURLConnection*)connection
    didReceiveResponse:(NSHTTPURLResponse*)response {
  auto mojo_response = MojoNetworkResponse(
      connection.originalRequest.URL, response, _pipe.consumer_handle.Pass());
  [self invokeStartCallback:mojo_response.Pass()];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
  uint32_t length = data.length;
  // TODO(eseidel): This can't work. The data pipe could be full, we need to
  // write an async writter for filling the pipe and use it here.
  MojoResult result = WriteDataRaw(_pipe.producer_handle.get(), data.bytes,
                                   &length, MOJO_WRITE_DATA_FLAG_ALL_OR_NONE);
  // FIXME(csg): Handle buffers in case of failures
  DCHECK(result == MOJO_RESULT_OK);
  DCHECK(length == data.length);
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
  _pipe.producer_handle.reset();
}

- (void)connection:(NSURLConnection*)connection
    didFailWithError:(NSError*)error {
  // We are not going to be sending any more data.
  _pipe.producer_handle.reset();
  auto mojo_error_response = MojoErrorResponse(connection.originalRequest.URL,
                                               error.localizedDescription);
  [self invokeStartCallback:mojo_error_response.Pass()];
}

- (NSCachedURLResponse*)connection:(NSURLConnection*)connection
                 willCacheResponse:(NSCachedURLResponse*)cachedResponse {
  return nil;
}

- (void)dealloc {
  if (!_startCallback.is_null()) {
    mojo::URLResponsePtr cancelled = mojo::URLResponse::New();
    cancelled->error = mojo::NetworkError::New();
    cancelled->error->description = "Cancelled";
    _startCallback.Run(cancelled.Pass());
  }

  [super dealloc];
}

@end

namespace mojo {

class AsyncNSDataDrainer : common::DataPipeDrainer::Client {
 public:
  using CompletionCallback = base::Callback<void(NSData* /* transfer-none */)>;

  AsyncNSDataDrainer()
      : data_([[NSMutableData alloc] init]), draining_(false) {}

  void StartWithCompletionCallback(ScopedDataPipeConsumerHandle source,
                                   CompletionCallback callback) {
    DCHECK(!draining_)
        << "A instance of an AsyncNSDataDrainer can only be used to drain once";
    DCHECK(drainer_ == nullptr);

    draining_ = true;
    callback_ = callback;

    // There is no "Start" method on a data pipe drainer. Instantiating
    // an instance automatically starts the drain.
    drainer_ = std::unique_ptr<common::DataPipeDrainer>(
        new common::DataPipeDrainer(this, source.Pass()));
  }

  ~AsyncNSDataDrainer() override { [data_ release]; }

 private:
  CompletionCallback callback_;
  NSMutableData* data_;
  std::unique_ptr<common::DataPipeDrainer> drainer_;
  bool draining_;

  void OnDataAvailable(const void* data, size_t num_bytes) override {
    [data_ appendBytes:data length:num_bytes];
  }

  void OnDataComplete() override {
    auto callback = callback_;
    NSMutableData* data = data_;

    [data retain];
    // The owner of this NSData drainer may cause its collection in the callback
    // If this is the first thing that happens in the callback, the final
    // data_ reference may be released (in dtor) before the callback accesses
    // that data further along in the same callback. So make sure we keep an
    // extra reference for the duration of the callback.
    callback.Run(data);
    [data release];
  }

  DISALLOW_COPY_AND_ASSIGN(AsyncNSDataDrainer);
};

URLLoaderImpl::URLLoaderImpl(InterfaceRequest<URLLoader> request)
    : binding_(this, request.Pass()), weak_factory_(this) {}

URLLoaderImpl::~URLLoaderImpl() {
  [pending_connection_.get() cancel];
  [pending_connection_.get() unscheduleFromRunLoop:[NSRunLoop mainRunLoop]
                                           forMode:NSRunLoopCommonModes];
}

void URLLoaderImpl::Start(URLRequestPtr request,
                          const StartCallback& callback) {
  if (request->body.size() == 1) {
    // If the body has request data, try to drain that
    request_data_drainer_ =
        std::unique_ptr<AsyncNSDataDrainer>(new AsyncNSDataDrainer());

    request_data_drainer_->StartWithCompletionCallback(
        request->body[0].Pass(),  // handle
        base::Bind(&URLLoaderImpl::StartNow, weak_factory_.GetWeakPtr(),
                   base::Passed(&request), callback));
  } else {
    StartNow(request.Pass(), callback, nullptr);
  }
}

void URLLoaderImpl::StartNow(URLRequestPtr request,
                             const StartCallback& callback,
                             NSData* body_data) {
  base::mac::ScopedNSAutoreleasePool pool;

  request_data_drainer_.reset();

  // Create the URL Request.

  NSURL* url = [NSURL URLWithString:@(request->url.data())];
  NSMutableURLRequest* url_request = [NSMutableURLRequest requestWithURL:url];

  url_request.HTTPMethod = @(request->method.data());
  url_request.HTTPBody = body_data;  // by copy

  for (const auto& header : request->headers) {
    [url_request addValue:@(header->value.data())
        forHTTPHeaderField:@(header->name.data())];
  };

  // Create the connection and its delegate.

  connection_delegate_.reset(
      [[URLLoaderConnectionDelegate alloc] initWithStartCallback:callback]);

  pending_connection_.reset([[NSURLConnection alloc]
       initWithRequest:url_request
              delegate:connection_delegate_
      startImmediately:NO]);

  // Schedule the connection on the main run loop.

  [pending_connection_ scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                 forMode:NSRunLoopCommonModes];

  // Start the connection.

  [pending_connection_ start];
}

void URLLoaderImpl::FollowRedirect(const FollowRedirectCallback& callback) {
  DCHECK(false);
}

void URLLoaderImpl::QueryStatus(const QueryStatusCallback& callback) {
  DCHECK(false);
}

}  // namespace mojo
