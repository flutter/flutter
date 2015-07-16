// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/prefs/default_pref_store.h"
#include "testing/gtest/include/gtest/gtest.h"

using base::StringValue;
using base::Value;

namespace {

class MockPrefStoreObserver : public PrefStore::Observer {
 public:
  explicit MockPrefStoreObserver(DefaultPrefStore* pref_store);
  ~MockPrefStoreObserver() override;

  int change_count() {
    return change_count_;
  }

  // PrefStore::Observer implementation:
  void OnPrefValueChanged(const std::string& key) override;
  void OnInitializationCompleted(bool succeeded) override {}

 private:
  DefaultPrefStore* pref_store_;

  int change_count_;

  DISALLOW_COPY_AND_ASSIGN(MockPrefStoreObserver);
};

MockPrefStoreObserver::MockPrefStoreObserver(DefaultPrefStore* pref_store)
    : pref_store_(pref_store), change_count_(0) {
  pref_store_->AddObserver(this);
}

MockPrefStoreObserver::~MockPrefStoreObserver() {
  pref_store_->RemoveObserver(this);
}

void MockPrefStoreObserver::OnPrefValueChanged(const std::string& key) {
  change_count_++;
}

}  // namespace

TEST(DefaultPrefStoreTest, NotifyPrefValueChanged) {
  scoped_refptr<DefaultPrefStore> pref_store(new DefaultPrefStore);
  MockPrefStoreObserver observer(pref_store.get());
  std::string kPrefKey("pref_key");

  // Setting a default value shouldn't send a change notification.
  pref_store->SetDefaultValue(kPrefKey,
                              scoped_ptr<Value>(new StringValue("foo")));
  EXPECT_EQ(0, observer.change_count());

  // Replacing the default value should send a change notification...
  pref_store->ReplaceDefaultValue(kPrefKey,
                                  scoped_ptr<Value>(new StringValue("bar")));
  EXPECT_EQ(1, observer.change_count());

  // But only if the value actually changed.
  pref_store->ReplaceDefaultValue(kPrefKey,
                                  scoped_ptr<Value>(new StringValue("bar")));
  EXPECT_EQ(1, observer.change_count());
}

