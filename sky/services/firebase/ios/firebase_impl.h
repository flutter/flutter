// Copyright 2015 Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_FIREBASE_IOS_FIREBASEIMPL_H_
#define SKY_SERVICES_FIREBASE_IOS_FIREBASEIMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/application/interface_factory.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "sky/services/firebase/firebase.mojom.h"

#if __OBJC__
@class Firebase;
#else   // __OBJC__
class Firebase;
#endif  // __OBJC__

namespace sky {
namespace services {
namespace firebase {

class FirebaseImpl : public ::firebase::Firebase {
 public:
  explicit FirebaseImpl(mojo::InterfaceRequest<Firebase> request);
  ~FirebaseImpl() override;

  void InitWithUrl(const mojo::String& url) override;
  void AddValueEventListener(
    ::firebase::ValueEventListenerPtr listener) override;
  void AddChildEventListener(
    ::firebase::ChildEventListenerPtr listener) override;
  void ObserveSingleEventOfType(
    ::firebase::EventType eventType,
    const ObserveSingleEventOfTypeCallback& callback) override;
  void AuthWithCustomToken(
    const mojo::String& token,
    const AuthWithCustomTokenCallback& callback) override;
  void AuthAnonymously(
    const AuthAnonymouslyCallback& callback) override;
  void AuthWithOAuthToken(
    const mojo::String& provider,
    const mojo::String& credentials,
    const AuthWithOAuthTokenCallback& callback) override;
  void AuthWithPassword(
    const mojo::String& email,
    const mojo::String& password,
    const AuthWithPasswordCallback& callback) override;
  void Unauth(const UnauthCallback& callback) override;
  void GetChild(
      const mojo::String& path,
      mojo::InterfaceRequest<Firebase> child) override;
  void GetParent(mojo::InterfaceRequest<Firebase> parent) override;
  void GetRoot(mojo::InterfaceRequest<Firebase> root) override;
  void RemoveValue(const RemoveValueCallback& callback) override;
  void SetValue(
    const mojo::String& jsonValue,
    int32_t priority,
    bool hasPriority,
    const SetValueCallback& callback) override;
  void Push(mojo::InterfaceRequest<Firebase> child,
    const PushCallback& callback) override;
  void SetPriority(int32_t priority,
    const SetPriorityCallback& callback) override;
  void CreateUser(const mojo::String& email,
    const mojo::String& password,
    const CreateUserCallback& callback) override;
  void ChangeEmail(const mojo::String& oldEmail,
    const mojo::String& password,
    const mojo::String& newEmail,
    const ChangeEmailCallback& callback) override;
  void ChangePassword(
    const mojo::String& newPassword,
    const mojo::String& email,
    const mojo::String& oldPassword,
    const ChangePasswordCallback& callback) override;
  void RemoveUser(const mojo::String& email,
    const mojo::String& password,
    const RemoveUserCallback& callback) override;
  void ResetPassword(const mojo::String& email,
    const ResetPasswordCallback& callback) override;
 private:
  mojo::StrongBinding<::firebase::Firebase> binding_;
  ::Firebase* client_;
  std::vector<::firebase::ValueEventListenerPtr> value_event_listeners_;
  std::vector<::firebase::ChildEventListenerPtr> child_event_listeners_;

  DISALLOW_COPY_AND_ASSIGN(FirebaseImpl);
};

class FirebaseFactory
    : public mojo::InterfaceFactory<::firebase::Firebase> {
 public:
  void Create(mojo::ApplicationConnection* connection,
              mojo::InterfaceRequest<::firebase::Firebase> request) override;
};

}  // namespace firebase
}  // namespace services
}  // namespace sky

#endif  // SKY_SERVICES_FIREBASE_IOS_FIREBASEIMPL_H_
