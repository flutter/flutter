// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "url_loader_impl.h"
#include "base/logging.h"
#include "base/mac/scoped_nsautorelease_pool.h"

#import <Foundation/Foundation.h>

@interface URLLoaderConnectionDelegate : NSObject<NSURLConnectionDataDelegate>

@property(nonatomic) mojo::URLLoaderImpl::StartCallback startCallback;

@end

@implementation URLLoaderConnectionDelegate {
  mojo::URLResponsePtr _response;
  mojo::ScopedDataPipeProducerHandle _producer;
}

@synthesize startCallback = _startCallback;

- (void)connection:(NSURLConnection*)connection
    didReceiveResponse:(NSHTTPURLResponse*)response {
  _response = mojo::URLResponse::New();
  _response->status_code = response.statusCode;
  _response->url =
      mojo::String(connection.originalRequest.URL.absoluteString.UTF8String);
  mojo::DataPipe pipe;
  _response->body = pipe.consumer_handle.Pass();
  _producer = pipe.producer_handle.Pass();
  [self.class updateDelegate:self asPending:YES];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
  if (!_startCallback.is_null()) {
    DCHECK(_response);
    _startCallback.Run(_response.Pass());
    _startCallback.reset();
    _response.reset();
  }
  uint32_t length = data.length;
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
  [self.class updateDelegate:self asPending:NO];
}

- (void)connection:(NSURLConnection*)connection
    didFailWithError:(NSError*)error {
  if (!_startCallback.is_null()) {
    if (_response.is_null()) {
      _response = mojo::URLResponse::New();
      _response->url = mojo::String(
          connection.originalRequest.URL.absoluteString.UTF8String);
    }

    _response->error = mojo::NetworkError::New();
    _response->error->description =
        mojo::String(error.localizedDescription.UTF8String);

    _startCallback.Run(_response.Pass());
    _startCallback.reset();
  }

  _response.reset();
  _producer.reset();
  [self.class updateDelegate:self asPending:NO];
}

// Since the only reference to the producer end of a data pipe is held by the
// delegate, which itself has no strong reference, we put the in-flight requests
// in a collection that references these delegates while they are active.
+ (void)updateDelegate:(URLLoaderConnectionDelegate*)delegate
             asPending:(BOOL)pending {
  static NSMutableSet* pendingConnections = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pendingConnections = [[NSMutableSet alloc] init];
  });
  if (pending) {
    [pendingConnections addObject:delegate];
  } else {
    [pendingConnections removeObject:delegate];
  }
}

- (void)dealloc {
  DCHECK(_response.is_null());
  DCHECK(_startCallback.is_null());
  _producer.reset();
  [super dealloc];
}

@end

namespace mojo {

URLLoaderImpl::URLLoaderImpl(InterfaceRequest<URLLoader> request)
    : binding_(this, request.Pass()),
      connection_delegate_(nullptr),
      pending_connection_(nullptr) {
  connection_delegate_ = [[URLLoaderConnectionDelegate alloc] init];
}

URLLoaderImpl::~URLLoaderImpl() {
  [(id)connection_delegate_ release];

  [(id)pending_connection_ cancel];
  [(id)pending_connection_ release];
}

void URLLoaderImpl::Start(URLRequestPtr request,
                          const StartCallback& callback) {
  base::mac::ScopedNSAutoreleasePool pool;

  NSURL* url = [NSURL URLWithString:@(request->url.data())];
  NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];

  req.HTTPMethod = @(request->method.data());

  if (request->bypass_cache) {
    req.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
  }

  URLLoaderConnectionDelegate* delegate =
      (URLLoaderConnectionDelegate*)connection_delegate_;

  NSURLConnection* connection =
      [NSURLConnection connectionWithRequest:req delegate:delegate];

  delegate.startCallback = callback;

  [connection start];

  pending_connection_ = [connection retain];
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
