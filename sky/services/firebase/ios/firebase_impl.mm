// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/firebase/ios/firebase_impl.h"
#include "base/logging.h"
#include "base/strings/sys_string_conversions.h"

#import <Firebase.h>

namespace sky {
namespace services {
namespace firebase {

::firebase::DataSnapshotPtr toMojoSnapshot(FDataSnapshot* snapshot) {
  ::firebase::DataSnapshotPtr mojoSnapshot(::firebase::DataSnapshot::New());
  mojoSnapshot->key = base::SysNSStringToUTF8(snapshot.key);
  mojoSnapshot->value = base::SysNSStringToUTF8(snapshot.value);
  return mojoSnapshot.Pass();
}

::firebase::ErrorPtr toMojoError(NSError* error) {
  ::firebase::ErrorPtr mojoError(::firebase::Error::New());
  mojoError->code = error.code;
  mojoError->message = base::SysNSStringToUTF8(error.description);
  return mojoError.Pass();
}

FirebaseImpl::FirebaseImpl(mojo::InterfaceRequest<::firebase::Firebase> request)
    : binding_(this, request.Pass()) {}

FirebaseImpl::~FirebaseImpl() {
  [client_ release];
}

void FirebaseImpl::InitWithUrl(const mojo::String& url) {
  client_ = [[[::Firebase alloc] initWithUrl:@(url.data())] retain];
}

void FirebaseImpl::GetRoot(mojo::InterfaceRequest<::firebase::Firebase> request) {
  FirebaseImpl *root = new FirebaseImpl(request.Pass());
  root->client_ = [[client_ root] retain];
}

void FirebaseImpl::GetChild(
    const mojo::String& path,
    mojo::InterfaceRequest<Firebase> request) {
  FirebaseImpl *child = new FirebaseImpl(request.Pass());
  child->client_ = [[client_ childByAppendingPath:@(path.data())] retain];
}

void FirebaseImpl::AddValueEventListener(::firebase::ValueEventListenerPtr ptr) {
  ::firebase::ValueEventListener *listener = ptr.get();
  FirebaseHandle handle = [client_ observeEventType:FEventTypeValue
                                          withBlock:^(FDataSnapshot *snapshot) {
    listener->OnDataChange(toMojoSnapshot(snapshot));
  } withCancelBlock:^(NSError *error) {
    listener->OnCancelled(toMojoError(error));
  }];
  ptr.set_connection_error_handler([this, handle, listener]() {
    [client_ removeObserverWithHandle:handle];
    auto it = std::find_if(value_event_listeners_.begin(),
                           value_event_listeners_.end(),
                           [listener](const ::firebase::ValueEventListenerPtr& p) {
                             return (p.get() == listener);
                           });
    DCHECK(it != value_event_listeners_.end());
    value_event_listeners_.erase(it);
  });
  value_event_listeners_.emplace_back(ptr.Pass());
}

void FirebaseImpl::AddChildEventListener(::firebase::ChildEventListenerPtr ptr) {
  ::firebase::ChildEventListener *listener = ptr.get();
  void (^cancelBlock)(NSError *) = ^(NSError *error) {
    listener->OnCancelled(toMojoError(error));
  };

  void (^addedBlock)(FDataSnapshot *, NSString *) = ^(FDataSnapshot *snapshot, NSString *prevKey) {
    listener->OnChildAdded(toMojoSnapshot(snapshot), base::SysNSStringToUTF8(prevKey));
  };
  FirebaseHandle addedHandle = [client_ observeEventType:FEventTypeChildAdded
                          andPreviousSiblingKeyWithBlock:addedBlock
                                         withCancelBlock:cancelBlock];

  void (^changedBlock)(FDataSnapshot *, NSString *) = ^(FDataSnapshot *snapshot, NSString *prevKey) {
    listener->OnChildChanged(toMojoSnapshot(snapshot), base::SysNSStringToUTF8(prevKey));
  };
  FirebaseHandle changedHandle = [client_ observeEventType:FEventTypeChildChanged
                            andPreviousSiblingKeyWithBlock:changedBlock
                                           withCancelBlock:cancelBlock];

  void (^movedBlock)(FDataSnapshot *, NSString *) = ^(FDataSnapshot *snapshot, NSString *prevKey) {
    listener->OnChildMoved(toMojoSnapshot(snapshot), base::SysNSStringToUTF8(prevKey));
  };
  FirebaseHandle movedHandle = [client_ observeEventType:FEventTypeChildMoved
                          andPreviousSiblingKeyWithBlock:movedBlock
                                         withCancelBlock:cancelBlock];

  void (^removedBlock)(FDataSnapshot *snapshot) = ^(FDataSnapshot *snapshot) {
    listener->OnChildRemoved(toMojoSnapshot(snapshot));
  };
  FirebaseHandle removedHandle = [client_ observeEventType:FEventTypeChildRemoved
                                                 withBlock:removedBlock
                                           withCancelBlock:cancelBlock];

  ptr.set_connection_error_handler(
    [this, addedHandle, changedHandle, movedHandle, removedHandle, listener]() {
      [client_ removeObserverWithHandle:addedHandle];
      [client_ removeObserverWithHandle:changedHandle];
      [client_ removeObserverWithHandle:movedHandle];
      [client_ removeObserverWithHandle:removedHandle];
      auto it = std::find_if(child_event_listeners_.begin(),
                             child_event_listeners_.end(),
                             [listener](const ::firebase::ChildEventListenerPtr& p) {
                               return (p.get() == listener);
                             });
      DCHECK(it != child_event_listeners_.end());
      child_event_listeners_.erase(it);
    }
  );
  child_event_listeners_.emplace_back(ptr.Pass());
}

void FirebaseImpl::ObserveSingleEventOfType(
    ::firebase::EventType eventType,
    const ObserveSingleEventOfTypeCallback& callback) {
  ObserveSingleEventOfTypeCallback *copyCallback =
    new ObserveSingleEventOfTypeCallback(callback);
  [client_ observeSingleEventOfType:static_cast<FEventType>(eventType)
                          withBlock:^(FDataSnapshot *snapshot) {
    copyCallback->Run(toMojoSnapshot(snapshot));
    delete copyCallback;
  }];
}

void FirebaseImpl::AuthWithOAuthToken(
  const mojo::String& provider,
  const mojo::String& credentials,
  const AuthWithOAuthTokenCallback& callback) {
  AuthWithOAuthTokenCallback *copyCallback =
    new AuthWithOAuthTokenCallback(callback);
  [client_ authWithOAuthProvider:@(provider.data())
                           token:@(credentials.data())
             withCompletionBlock:^(NSError *error, FAuthData *authData) {
    ::firebase::ErrorPtr mojoError;
    ::firebase::AuthDataPtr mojoAuthData;
    if (error == nullptr) {
      mojoAuthData = ::firebase::AuthData::New();
      mojoAuthData->uid = base::SysNSStringToUTF8(authData.uid);
      mojoAuthData->provider = base::SysNSStringToUTF8(authData.provider);
      mojoAuthData->token = base::SysNSStringToUTF8(authData.token);
    } else {
      mojoError = ::firebase::Error::New();
      mojoError->code = error.code;
      mojoError->message = base::SysNSStringToUTF8(error.description);
    }
    copyCallback->Run(mojoError.Pass(), mojoAuthData.Pass());
  }];
}

void FirebaseImpl::SetValue(const mojo::String& url) {
  [client_ setValue:@(url.data())];
}

void FirebaseFactory::Create(
    mojo::ApplicationConnection* connection,
    mojo::InterfaceRequest<::firebase::Firebase> request) {
  new FirebaseImpl(request.Pass());
}

}  // namespace firebase
}  // namespace services
}  // namespace sky
