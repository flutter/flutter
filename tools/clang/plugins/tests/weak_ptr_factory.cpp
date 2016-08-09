// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "weak_ptr_factory.h"

namespace should_succeed {

class OnlyMember {
  base::WeakPtrFactory<OnlyMember> factory_;
};

class FactoryLast {
  bool bool_member_;
  int int_member_;
  base::WeakPtrFactory<FactoryLast> factory_;
};

class FactoryRefersToOtherType {
  bool bool_member_;
  base::WeakPtrFactory<bool> bool_ptr_factory_;
};

class FirstFactoryRefersToOtherType {
  bool bool_member_;
  base::WeakPtrFactory<bool> bool_ptr_factory_;
  int int_member_;
  base::WeakPtrFactory<FirstFactoryRefersToOtherType> factory_;
};

class TwoFactories {
  bool bool_member_;
  int int_member_;
  base::WeakPtrFactory<TwoFactories> factory1_;
  base::WeakPtrFactory<TwoFactories> factory2_;
};

template <class T>
class ClassTemplate {
 public:
  ClassTemplate() : factory_(this) {}
 private:
  bool bool_member_;
  base::WeakPtrFactory<ClassTemplate> factory_;
};
// Make sure the template gets instantiated:
ClassTemplate<int> g_instance;

}  // namespace should_succeed

namespace should_fail {

class FactoryFirst {
  base::WeakPtrFactory<FactoryFirst> factory_;
  int int_member;
};

class FactoryMiddle {
  bool bool_member_;
  base::WeakPtrFactory<FactoryMiddle> factory_;
  int int_member_;
};

class TwoFactoriesOneBad {
  bool bool_member_;
  base::WeakPtrFactory<TwoFactoriesOneBad> factory1_;
  int int_member_;
  base::WeakPtrFactory<TwoFactoriesOneBad> factory2_;
};

template <class T>
class ClassTemplate {
 public:
  ClassTemplate() : factory_(this) {}
 private:
  base::WeakPtrFactory<ClassTemplate> factory_;
  bool bool_member_;
};
// Make sure the template gets instantiated:
ClassTemplate<int> g_instance;

}  // namespace should_fail

int main() {
}

