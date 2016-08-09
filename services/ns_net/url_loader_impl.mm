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

@interface URLLoaderConnectionDelegate : NSObject<NSURLConnectionDataDelegate>

@property(nonatomic) mojo::URLLoaderImpl::StartCallback startCallback;
@property(nonatomic, retain) NSURLRequest* originalRequest;

@end

@implementation URLLoaderConnectionDelegate {
  mojo::URLResponsePtr _response;
  mojo::ScopedDataPipeProducerHandle _producer;
}

@synthesize startCallback = _startCallback;
@synthesize originalRequest = _originalRequest;

- (void)connection:(NSURLConnection*)connection
didReceiveResponse:(NSHTTPURLResponse*)response {
  _response = mojo::URLResponse::New();
  _response->status_code = response.statusCode;
  _response->url =
      mojo::String(self.originalRequest.URL.absoluteString.UTF8String);
  NSUInteger headerCount = response.allHeaderFields.count;
  if (headerCount > 0) {
    _response->headers = mojo::Array<mojo::HttpHeaderPtr>::New(0);
    [response.allHeaderFields enumerateKeysAndObjectsUsingBlock:^(
                                  NSString* key, NSString* value, BOOL* stop) {
      auto header = mojo::HttpHeader::New();
      header->name = key.UTF8String;
      header->value = value.UTF8String;
      _response->headers.push_back(header.Pass());
    }];
  }
  mojo::DataPipe pipe;
  _response->body = pipe.consumer_handle.Pass();
  _producer = pipe.producer_handle.Pass();
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
  if (!_startCallback.is_null()) {
    DCHECK(_response);
    _startCallback.Run(_response.Pass());
    _startCallback.reset();
    _response.reset();
  }
  uint32_t length = data.length;
  // TODO(eseidel): This can't work. The data pipe could be full, we need to
  // write an async writter for filling the pipe and use it here.
  MojoResult result = WriteDataRaw(_producer.get(), data.bytes, &length,
                                   MOJO_WRITE_DATA_FLAG_ALL_OR_NONE);
  // FIXME(csg): Handle buffers in case of failures
  DCHECK(result == MOJO_RESULT_OK);
  DCHECK(length == data.length);
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
  DCHECK(_response.is_null());
  DCHECK(_startCallback.is_null());
  _producer.reset();
}

- (void)connection:(NSURLConnection*)connection
  didFailWithError:(NSError*)error {
  if (!_startCallback.is_null()) {
    if (_response.is_null()) {
      _response = mojo::URLResponse::New();
      _response->url =
          mojo::String(self.originalRequest.URL.absoluteString.UTF8String);
    }

    _response->error = mojo::NetworkError::New();
    _response->error->description =
        mojo::String(error.localizedDescription.UTF8String);

    _startCallback.Run(_response.Pass());
    _startCallback.reset();
  }

  _response.reset();
  _producer.reset();
}

- (NSCachedURLResponse*)connection:(NSURLConnection*)connection
                 willCacheResponse:(NSCachedURLResponse*)cachedResponse {
  return nil;
}

- (void)dealloc {
  [_originalRequest release];
  DCHECK(_response.is_null());
  DCHECK(_startCallback.is_null());
  _producer.reset();
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
    : binding_(this, request.Pass()), pending_connection_(nullptr) {}

URLLoaderImpl::~URLLoaderImpl() {
  [(id)pending_connection_ release];
}

void URLLoaderImpl::Start(URLRequestPtr request,
                          const StartCallback& callback) {
  if (request->body.size() == 1) {
    // If the body has request data, try to drain that
    request_data_drainer_ =
        std::unique_ptr<AsyncNSDataDrainer>(new AsyncNSDataDrainer());

    request_data_drainer_->StartWithCompletionCallback(
        request->body[0].Pass(),  // handle
        base::Bind(&URLLoaderImpl::StartNow, base::Unretained(this),
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

  NSURL* url = [NSURL URLWithString:@(request->url.data())];
  NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];

  req.HTTPMethod = @(request->method.data());
  req.HTTPBody = body_data;  // by copy

  for (const auto& header : request->headers) {
    NSString* name = @(header->name.data());
    NSString* value = @(header->value.data());
    [req addValue:value forHTTPHeaderField:name];
  };

  URLLoaderConnectionDelegate* delegate =
      [[URLLoaderConnectionDelegate alloc] init];

  NSURLConnection* connection =
      [[NSURLConnection alloc] initWithRequest:req
                                      delegate:delegate
                              startImmediately:NO];

  delegate.startCallback = callback;
  delegate.originalRequest = req;

  [delegate release];

  [connection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                        forMode:NSRunLoopCommonModes];
  [connection start];

  pending_connection_ = connection;
}

void URLLoaderImpl::FollowRedirect(const FollowRedirectCallback& callback) {
  base::mac::ScopedNSAutoreleasePool pool;
  DCHECK(false);
}

void URLLoaderImpl::QueryStatus(const QueryStatusCallback& callback) {
  base::mac::ScopedNSAutoreleasePool pool;
  DCHECK(false);
}

}  // namespace mojo
