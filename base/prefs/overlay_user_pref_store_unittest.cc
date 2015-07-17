// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/prefs/overlay_user_pref_store.h"

#include "base/prefs/pref_store_observer_mock.h"
#include "base/prefs/testing_pref_store.h"
#include "base/values.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

using ::testing::Mock;
using ::testing::StrEq;

namespace base {
namespace {

const char kBrowserWindowPlacement[] = "browser.window_placement";
const char kShowBookmarkBar[] = "bookmark_bar.show_on_all_tabs";

const char* const overlay_key = kBrowserWindowPlacement;
const char* const regular_key = kShowBookmarkBar;
// With the removal of the kWebKitGlobalXXX prefs, we'll no longer have real
// prefs using the overlay pref store, so make up keys here.
const char mapped_overlay_key[] = "test.per_tab.javascript_enabled";
const char mapped_underlay_key[] = "test.per_profile.javascript_enabled";

}  // namespace

class OverlayUserPrefStoreTest : public testing::Test {
 protected:
  OverlayUserPrefStoreTest()
      : underlay_(new TestingPrefStore()),
        overlay_(new OverlayUserPrefStore(underlay_.get())) {
    overlay_->RegisterOverlayPref(overlay_key);
    overlay_->RegisterOverlayPref(mapped_overlay_key, mapped_underlay_key);
  }

  ~OverlayUserPrefStoreTest() override {}

  scoped_refptr<TestingPrefStore> underlay_;
  scoped_refptr<OverlayUserPrefStore> overlay_;
};

TEST_F(OverlayUserPrefStoreTest, Observer) {
  PrefStoreObserverMock obs;
  overlay_->AddObserver(&obs);

  // Check that underlay first value is reported.
  underlay_->SetValue(overlay_key, make_scoped_ptr(new FundamentalValue(42)),
                      WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  obs.VerifyAndResetChangedKey(overlay_key);

  // Check that underlay overwriting is reported.
  underlay_->SetValue(overlay_key, make_scoped_ptr(new FundamentalValue(43)),
                      WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  obs.VerifyAndResetChangedKey(overlay_key);

  // Check that overwriting change in overlay is reported.
  overlay_->SetValue(overlay_key, make_scoped_ptr(new FundamentalValue(44)),
                     WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  obs.VerifyAndResetChangedKey(overlay_key);

  // Check that hidden underlay change is not reported.
  underlay_->SetValue(overlay_key, make_scoped_ptr(new FundamentalValue(45)),
                      WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  EXPECT_TRUE(obs.changed_keys.empty());

  // Check that overlay remove is reported.
  overlay_->RemoveValue(overlay_key,
                        WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  obs.VerifyAndResetChangedKey(overlay_key);

  // Check that underlay remove is reported.
  underlay_->RemoveValue(overlay_key,
                         WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  obs.VerifyAndResetChangedKey(overlay_key);

  // Check respecting of silence.
  overlay_->SetValueSilently(overlay_key,
                             make_scoped_ptr(new FundamentalValue(46)),
                             WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  EXPECT_TRUE(obs.changed_keys.empty());

  overlay_->RemoveObserver(&obs);

  // Check successful unsubscription.
  underlay_->SetValue(overlay_key, make_scoped_ptr(new FundamentalValue(47)),
                      WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  overlay_->SetValue(overlay_key, make_scoped_ptr(new FundamentalValue(48)),
                     WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  EXPECT_TRUE(obs.changed_keys.empty());
}

TEST_F(OverlayUserPrefStoreTest, GetAndSet) {
  const Value* value = NULL;
  EXPECT_FALSE(overlay_->GetValue(overlay_key, &value));
  EXPECT_FALSE(underlay_->GetValue(overlay_key, &value));

  underlay_->SetValue(overlay_key, make_scoped_ptr(new FundamentalValue(42)),
                      WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);

  // Value shines through:
  EXPECT_TRUE(overlay_->GetValue(overlay_key, &value));
  EXPECT_TRUE(base::FundamentalValue(42).Equals(value));

  EXPECT_TRUE(underlay_->GetValue(overlay_key, &value));
  EXPECT_TRUE(base::FundamentalValue(42).Equals(value));

  overlay_->SetValue(overlay_key, make_scoped_ptr(new FundamentalValue(43)),
                     WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);

  EXPECT_TRUE(overlay_->GetValue(overlay_key, &value));
  EXPECT_TRUE(base::FundamentalValue(43).Equals(value));

  EXPECT_TRUE(underlay_->GetValue(overlay_key, &value));
  EXPECT_TRUE(base::FundamentalValue(42).Equals(value));

  overlay_->RemoveValue(overlay_key,
                        WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);

  // Value shines through:
  EXPECT_TRUE(overlay_->GetValue(overlay_key, &value));
  EXPECT_TRUE(base::FundamentalValue(42).Equals(value));

  EXPECT_TRUE(underlay_->GetValue(overlay_key, &value));
  EXPECT_TRUE(base::FundamentalValue(42).Equals(value));
}

// Check that GetMutableValue does not return the dictionary of the underlay.
TEST_F(OverlayUserPrefStoreTest, ModifyDictionaries) {
  underlay_->SetValue(overlay_key, make_scoped_ptr(new DictionaryValue),
                      WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);

  Value* modify = NULL;
  EXPECT_TRUE(overlay_->GetMutableValue(overlay_key, &modify));
  ASSERT_TRUE(modify);
  ASSERT_TRUE(modify->IsType(Value::TYPE_DICTIONARY));
  static_cast<DictionaryValue*>(modify)->SetInteger(overlay_key, 42);

  Value* original_in_underlay = NULL;
  EXPECT_TRUE(underlay_->GetMutableValue(overlay_key, &original_in_underlay));
  ASSERT_TRUE(original_in_underlay);
  ASSERT_TRUE(original_in_underlay->IsType(Value::TYPE_DICTIONARY));
  EXPECT_TRUE(static_cast<DictionaryValue*>(original_in_underlay)->empty());

  Value* modified = NULL;
  EXPECT_TRUE(overlay_->GetMutableValue(overlay_key, &modified));
  ASSERT_TRUE(modified);
  ASSERT_TRUE(modified->IsType(Value::TYPE_DICTIONARY));
  EXPECT_TRUE(Value::Equals(modify, static_cast<DictionaryValue*>(modified)));
}

// Here we consider a global preference that is not overlayed.
TEST_F(OverlayUserPrefStoreTest, GlobalPref) {
  PrefStoreObserverMock obs;
  overlay_->AddObserver(&obs);

  const Value* value = NULL;

  // Check that underlay first value is reported.
  underlay_->SetValue(regular_key, make_scoped_ptr(new FundamentalValue(42)),
                      WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  obs.VerifyAndResetChangedKey(regular_key);

  // Check that underlay overwriting is reported.
  underlay_->SetValue(regular_key, make_scoped_ptr(new FundamentalValue(43)),
                      WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  obs.VerifyAndResetChangedKey(regular_key);

  // Check that we get this value from the overlay
  EXPECT_TRUE(overlay_->GetValue(regular_key, &value));
  EXPECT_TRUE(base::FundamentalValue(43).Equals(value));

  // Check that overwriting change in overlay is reported.
  overlay_->SetValue(regular_key, make_scoped_ptr(new FundamentalValue(44)),
                     WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  obs.VerifyAndResetChangedKey(regular_key);

  // Check that we get this value from the overlay and the underlay.
  EXPECT_TRUE(overlay_->GetValue(regular_key, &value));
  EXPECT_TRUE(base::FundamentalValue(44).Equals(value));
  EXPECT_TRUE(underlay_->GetValue(regular_key, &value));
  EXPECT_TRUE(base::FundamentalValue(44).Equals(value));

  // Check that overlay remove is reported.
  overlay_->RemoveValue(regular_key,
                        WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  obs.VerifyAndResetChangedKey(regular_key);

  // Check that value was removed from overlay and underlay
  EXPECT_FALSE(overlay_->GetValue(regular_key, &value));
  EXPECT_FALSE(underlay_->GetValue(regular_key, &value));

  // Check respecting of silence.
  overlay_->SetValueSilently(regular_key,
                             make_scoped_ptr(new FundamentalValue(46)),
                             WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  EXPECT_TRUE(obs.changed_keys.empty());

  overlay_->RemoveObserver(&obs);

  // Check successful unsubscription.
  underlay_->SetValue(regular_key, make_scoped_ptr(new FundamentalValue(47)),
                      WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  overlay_->SetValue(regular_key, make_scoped_ptr(new FundamentalValue(48)),
                     WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  EXPECT_TRUE(obs.changed_keys.empty());
}

// Check that names mapping works correctly.
TEST_F(OverlayUserPrefStoreTest, NamesMapping) {
  PrefStoreObserverMock obs;
  overlay_->AddObserver(&obs);

  const Value* value = NULL;

  // Check that if there is no override in the overlay, changing underlay value
  // is reported as changing an overlay value.
  underlay_->SetValue(mapped_underlay_key,
                      make_scoped_ptr(new FundamentalValue(42)),
                      WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  obs.VerifyAndResetChangedKey(mapped_overlay_key);

  // Check that underlay overwriting is reported.
  underlay_->SetValue(mapped_underlay_key,
                      make_scoped_ptr(new FundamentalValue(43)),
                      WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  obs.VerifyAndResetChangedKey(mapped_overlay_key);

  // Check that we get this value from the overlay with both keys
  EXPECT_TRUE(overlay_->GetValue(mapped_overlay_key, &value));
  EXPECT_TRUE(base::FundamentalValue(43).Equals(value));
  // In this case, overlay reads directly from the underlay.
  EXPECT_TRUE(overlay_->GetValue(mapped_underlay_key, &value));
  EXPECT_TRUE(base::FundamentalValue(43).Equals(value));

  // Check that overwriting change in overlay is reported.
  overlay_->SetValue(mapped_overlay_key,
                     make_scoped_ptr(new FundamentalValue(44)),
                     WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  obs.VerifyAndResetChangedKey(mapped_overlay_key);

  // Check that we get an overriden value from overlay, while reading the
  // value from underlay still holds an old value.
  EXPECT_TRUE(overlay_->GetValue(mapped_overlay_key, &value));
  EXPECT_TRUE(base::FundamentalValue(44).Equals(value));
  EXPECT_TRUE(overlay_->GetValue(mapped_underlay_key, &value));
  EXPECT_TRUE(base::FundamentalValue(43).Equals(value));
  EXPECT_TRUE(underlay_->GetValue(mapped_underlay_key, &value));
  EXPECT_TRUE(base::FundamentalValue(43).Equals(value));

  // Check that hidden underlay change is not reported.
  underlay_->SetValue(mapped_underlay_key,
                      make_scoped_ptr(new FundamentalValue(45)),
                      WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  EXPECT_TRUE(obs.changed_keys.empty());

  // Check that overlay remove is reported.
  overlay_->RemoveValue(mapped_overlay_key,
                        WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  obs.VerifyAndResetChangedKey(mapped_overlay_key);

  // Check that underlay remove is reported.
  underlay_->RemoveValue(mapped_underlay_key,
                         WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  obs.VerifyAndResetChangedKey(mapped_overlay_key);

  // Check that value was removed.
  EXPECT_FALSE(overlay_->GetValue(mapped_overlay_key, &value));
  EXPECT_FALSE(overlay_->GetValue(mapped_underlay_key, &value));

  // Check respecting of silence.
  overlay_->SetValueSilently(mapped_overlay_key,
                             make_scoped_ptr(new FundamentalValue(46)),
                             WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  EXPECT_TRUE(obs.changed_keys.empty());

  overlay_->RemoveObserver(&obs);

  // Check successful unsubscription.
  underlay_->SetValue(mapped_underlay_key,
                      make_scoped_ptr(new FundamentalValue(47)),
                      WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  overlay_->SetValue(mapped_overlay_key,
                     make_scoped_ptr(new FundamentalValue(48)),
                     WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  EXPECT_TRUE(obs.changed_keys.empty());
}

}  // namespace base
