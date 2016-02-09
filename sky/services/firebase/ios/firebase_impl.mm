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
  NSDictionary *valueDictionary = @{@"value": snapshot.value};
  NSData *data = [NSJSONSerialization dataWithJSONObject:valueDictionary
                                                 options:0
                                                   error:nil];
  if (data != nil) {
    NSString *jsonValue = [[NSString alloc] initWithData:data
                                                encoding:NSUTF8StringEncoding];
    mojoSnapshot->jsonValue = base::SysNSStringToUTF8(jsonValue);
  }
  return mojoSnapshot.Pass();
}

::firebase::ErrorPtr toMojoError(NSError* error) {
  ::firebase::ErrorPtr mojoError(::firebase::Error::New());
  mojoError->code = error.code;
  mojoError->message = base::SysNSStringToUTF8(error.description);
  return mojoError.Pass();
}

::firebase::AuthDataPtr toMojoAuthData(FAuthData* authData) {
  ::firebase::AuthDataPtr mojoAuthData(::firebase::AuthData::New());
  mojoAuthData->uid = base::SysNSStringToUTF8(authData.uid);
  mojoAuthData->provider = base::SysNSStringToUTF8(authData.provider);
  mojoAuthData->token = base::SysNSStringToUTF8(authData.token);
  return mojoAuthData.Pass();
}

FirebaseImpl::FirebaseImpl(mojo::InterfaceRequest<::firebase::Firebase> request)
    : binding_(this, request.Pass()) {}

FirebaseImpl::~FirebaseImpl() {
  [client_ release];
}

void FirebaseImpl::InitWithUrl(const mojo::String& url) {
  client_ = [[[::Firebase alloc] initWithUrl:@(url.data())] retain];
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

void FirebaseImpl::AuthWithCustomToken(
  const mojo::String& token,
  const AuthWithCustomTokenCallback& callback) {
}

void FirebaseImpl::AuthAnonymously(
  const AuthAnonymouslyCallback& callback) {
  AuthAnonymouslyCallback *copyCallback =
    new AuthAnonymouslyCallback(callback);
  [client_ authAnonymouslyWithCompletionBlock:^(NSError *error, FAuthData *authData) {
    copyCallback->Run(toMojoError(error), toMojoAuthData(authData));
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
    copyCallback->Run(toMojoError(error), toMojoAuthData(authData));
    delete copyCallback;
  }];
}

void FirebaseImpl::AuthWithPassword(
  const mojo::String& email,
  const mojo::String& password,
  const AuthWithPasswordCallback& callback) {
  AuthWithPasswordCallback *copyCallback =
    new AuthWithPasswordCallback(callback);
  [client_      authUser:@(email.data())
                password:@(password.data())
     withCompletionBlock:^(NSError *error, FAuthData *authData) {
    copyCallback->Run(toMojoError(error), toMojoAuthData(authData));
    delete copyCallback;
  }];
}

void FirebaseImpl::Unauth(const UnauthCallback& callback) {
  [client_ unauth];
  callback.Run(toMojoError(nullptr));
}

void FirebaseImpl::GetChild(
    const mojo::String& path,
    mojo::InterfaceRequest<Firebase> request) {
  FirebaseImpl *child = new FirebaseImpl(request.Pass());
  child->client_ = [[client_ childByAppendingPath:@(path.data())] retain];
}

void FirebaseImpl::GetParent(mojo::InterfaceRequest<Firebase> request) {
  FirebaseImpl *parent = new FirebaseImpl(request.Pass());
  parent->client_ = [[client_ parent] retain];
}

void FirebaseImpl::GetRoot(mojo::InterfaceRequest<::firebase::Firebase> request) {
  FirebaseImpl *root = new FirebaseImpl(request.Pass());
  root->client_ = [[client_ root] retain];
}

void FirebaseImpl::SetValue(const mojo::String& jsonValue,
    int32_t priority,
    bool hasPriority,
    const SetValueCallback& callback) {
  SetValueCallback *copyCallback =
    new SetValueCallback(callback);
  NSData *data = [@(jsonValue.data()) dataUsingEncoding:NSUTF8StringEncoding];
  NSError *error;
  NSDictionary *valueDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                  options:0
                                                                    error:&error];
  id value = [valueDictionary valueForKey:@"value"];
  void (^completionBlock)(NSError *, ::Firebase* ref) = ^(NSError* error, ::Firebase* ref) {
    copyCallback->Run(toMojoError(error));
    delete copyCallback;
  };
  if (valueDictionary != nil) {
    if (hasPriority) {
      [client_     setValue:value
                andPriority:@(priority)
        withCompletionBlock:completionBlock];
    } else {
      [client_ setValue:value withCompletionBlock:completionBlock];
    }
  } else {
    completionBlock(error, client_);
  }
}

void FirebaseImpl::RemoveValue(const RemoveValueCallback& callback) {
  RemoveValueCallback *copyCallback =
    new RemoveValueCallback(callback);
  [client_ removeValueWithCompletionBlock:^(NSError *error, ::Firebase *ref) {
    copyCallback->Run(toMojoError(error));
    delete copyCallback;
  }];
}

void FirebaseImpl::Push(mojo::InterfaceRequest<Firebase> request,
  const PushCallback& callback) {
  FirebaseImpl *child = new FirebaseImpl(request.Pass());
  child->client_ = [[client_ childByAutoId] retain];
  callback.Run(base::SysNSStringToUTF8(child->client_.key));
}

void FirebaseImpl::SetPriority(int32_t priority,
  const SetPriorityCallback& callback) {
  SetPriorityCallback *copyCallback =
    new SetPriorityCallback(callback);
  [client_  setPriority:@(priority)
    withCompletionBlock:^(NSError *error, ::Firebase *ref) {
    copyCallback->Run(toMojoError(error));
    delete copyCallback;
  }];
}

void FirebaseImpl::CreateUser(const mojo::String& email,
  const mojo::String& password,
  const CreateUserCallback& callback) {
  CreateUserCallback *copyCallback =
    new CreateUserCallback(callback);
  [client_   createUser:@(email.data())
               password:@(password.data())
    withValueCompletionBlock:^(NSError *error, NSDictionary *valueDictionary) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:valueDictionary
                                                   options:0
                                                     error:nil];
    if (data != nil) {
      NSString *jsonValue = [[NSString alloc] initWithData:data
                                                  encoding:NSUTF8StringEncoding];
      copyCallback->Run(toMojoError(error), base::SysNSStringToUTF8(jsonValue));
    } else {
      copyCallback->Run(toMojoError(error), nullptr);
    }
    delete copyCallback;
  }];
}

void FirebaseImpl::ChangeEmail(const mojo::String& oldEmail,
  const mojo::String& password,
  const mojo::String& newEmail,
  const ChangeEmailCallback& callback) {
  ChangeEmailCallback *copyCallback =
    new ChangeEmailCallback(callback);
  [client_ changeEmailForUser:@(oldEmail.data())
                     password:@(password.data())
                   toNewEmail:@(newEmail.data())
          withCompletionBlock:^(NSError *error) {
    copyCallback->Run(toMojoError(error));
    delete copyCallback;
  }];
}

void FirebaseImpl::ChangePassword(
  const mojo::String& newPassword,
  const mojo::String& email,
  const mojo::String& oldPassword,
  const ChangePasswordCallback& callback) {
  ChangePasswordCallback *copyCallback =
    new ChangePasswordCallback(callback);
  [client_ changePasswordForUser:@(email.data())
                         fromOld:@(oldPassword.data())
                           toNew:@(newPassword.data())
             withCompletionBlock:^(NSError *error) {
    copyCallback->Run(toMojoError(error));
    delete copyCallback;
  }];
}

void FirebaseImpl::RemoveUser(const mojo::String& email,
  const mojo::String& password,
  const RemoveUserCallback& callback) {
  RemoveUserCallback *copyCallback =
    new RemoveUserCallback(callback);
  [client_  removeUser:@(email.data())
               password:@(password.data())
    withCompletionBlock:^(NSError *error) {
    copyCallback->Run(toMojoError(error));
    delete copyCallback;
  }];
}

void FirebaseImpl::ResetPassword(const mojo::String& email,
  const ResetPasswordCallback& callback) {
  ResetPasswordCallback *copyCallback =
    new ResetPasswordCallback(callback);
  [client_  resetPasswordForUser:@(email.data())
             withCompletionBlock:^(NSError *error) {
    copyCallback->Run(toMojoError(error));
    delete copyCallback;
  }];
}

void FirebaseFactory::Create(
    mojo::ApplicationConnection* connection,
    mojo::InterfaceRequest<::firebase::Firebase> request) {
  new FirebaseImpl(request.Pass());
}

}  // namespace firebase
}  // namespace services
}  // namespace sky
