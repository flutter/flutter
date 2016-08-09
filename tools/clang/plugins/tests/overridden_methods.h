// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OVERRIDDEN_METHODS_H_
#define OVERRIDDEN_METHODS_H_

// Should warn about overriding of methods.
class BaseClass {
 public:
  virtual ~BaseClass() {}
  virtual void SomeMethod() = 0;
  virtual void SomeOtherMethod() = 0;
  virtual void SomeInlineMethod() = 0;
  virtual void SomeConstMethod() const = 0;
  virtual void SomeMethodWithExceptionSpec() throw() = 0;
  virtual void SomeConstMethodWithExceptionSpec() const throw(int) = 0;
  virtual void SomeNonPureBaseMethod() {}
  virtual void SomeMethodWithComment() = 0;
  virtual void SomeMethodWithCommentAndBody() = 0;
};

class InterimClass : public BaseClass {
  // Should warn about pure virtual methods.
  virtual void SomeMethod() = 0;
};

namespace blink {
class WebKitObserver {
 public:
  virtual void WebKitModifiedSomething() {};
};
}  // namespace blink

namespace webkit_glue {
class WebKitObserverImpl : blink::WebKitObserver {
 public:
  virtual void WebKitModifiedSomething() {};
};
}  // namespace webkit_glue

class DerivedClass : public InterimClass,
                     public webkit_glue::WebKitObserverImpl {
 public:
  // Should warn about destructors.
  virtual ~DerivedClass() {}
  // Should warn.
  virtual void SomeMethod();
  // Should not warn if marked as override.
  void SomeOtherMethod() override;
  // Should warn for inline implementations.
  virtual void SomeInlineMethod() {}
  // Should not warn if overriding a method whose origin is blink.
  virtual void WebKitModifiedSomething();
  // Should warn with the insertion point after the const.
  virtual void SomeConstMethod() const {}
  // Should warn with the insertion point after the throw spec.
  virtual void SomeMethodWithExceptionSpec() throw() {}
  // Should warn with the insertion point after both the const and the throw
  // specifiers.
  virtual void SomeConstMethodWithExceptionSpec() const throw(int) {}
  // Should warn even if overridden method isn't pure.
  virtual void SomeNonPureBaseMethod() {}
  // Should warn and place correctly even when there is a comment.
  virtual void SomeMethodWithComment();  // This is a comment.
  // Should warn and place correctly even if there is a comment and body.
  virtual void SomeMethodWithCommentAndBody() {}  // This is a comment.
};

#endif  // OVERRIDDEN_METHODS_H_
