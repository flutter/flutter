// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/prefs/pref_change_registrar.h"
#include "base/prefs/pref_observer.h"
#include "base/prefs/pref_registry_simple.h"
#include "base/prefs/testing_pref_service.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

using testing::Mock;
using testing::Eq;

namespace base {
namespace {

const char kHomePage[] = "homepage";
const char kHomePageIsNewTabPage[] = "homepage_is_newtabpage";
const char kApplicationLocale[] = "intl.app_locale";

// A mock provider that allows us to capture pref observer changes.
class MockPrefService : public TestingPrefServiceSimple {
 public:
  MockPrefService() {}
  virtual ~MockPrefService() {}

  MOCK_METHOD2(AddPrefObserver, void(const std::string&, PrefObserver*));
  MOCK_METHOD2(RemovePrefObserver, void(const std::string&, PrefObserver*));
};

}  // namespace

class PrefChangeRegistrarTest : public testing::Test {
 public:
  PrefChangeRegistrarTest() {}
  ~PrefChangeRegistrarTest() override {}

 protected:
  void SetUp() override;

  base::Closure observer() const {
    return base::Bind(&base::DoNothing);
  }

  MockPrefService* service() const { return service_.get(); }

 private:
  scoped_ptr<MockPrefService> service_;
};

void PrefChangeRegistrarTest::SetUp() {
  service_.reset(new MockPrefService());
}

TEST_F(PrefChangeRegistrarTest, AddAndRemove) {
  PrefChangeRegistrar registrar;
  registrar.Init(service());

  // Test adding.
  EXPECT_CALL(*service(),
              AddPrefObserver(Eq(std::string("test.pref.1")), &registrar));
  EXPECT_CALL(*service(),
              AddPrefObserver(Eq(std::string("test.pref.2")), &registrar));
  registrar.Add("test.pref.1", observer());
  registrar.Add("test.pref.2", observer());
  EXPECT_FALSE(registrar.IsEmpty());

  // Test removing.
  Mock::VerifyAndClearExpectations(service());
  EXPECT_CALL(*service(),
              RemovePrefObserver(Eq(std::string("test.pref.1")), &registrar));
  EXPECT_CALL(*service(),
              RemovePrefObserver(Eq(std::string("test.pref.2")), &registrar));
  registrar.Remove("test.pref.1");
  registrar.Remove("test.pref.2");
  EXPECT_TRUE(registrar.IsEmpty());

  // Explicitly check the expectations now to make sure that the Removes
  // worked (rather than the registrar destructor doing the work).
  Mock::VerifyAndClearExpectations(service());
}

TEST_F(PrefChangeRegistrarTest, AutoRemove) {
  PrefChangeRegistrar registrar;
  registrar.Init(service());

  // Setup of auto-remove.
  EXPECT_CALL(*service(),
              AddPrefObserver(Eq(std::string("test.pref.1")), &registrar));
  registrar.Add("test.pref.1", observer());
  Mock::VerifyAndClearExpectations(service());
  EXPECT_FALSE(registrar.IsEmpty());

  // Test auto-removing.
  EXPECT_CALL(*service(),
              RemovePrefObserver(Eq(std::string("test.pref.1")), &registrar));
}

TEST_F(PrefChangeRegistrarTest, RemoveAll) {
  PrefChangeRegistrar registrar;
  registrar.Init(service());

  EXPECT_CALL(*service(),
              AddPrefObserver(Eq(std::string("test.pref.1")), &registrar));
  EXPECT_CALL(*service(),
              AddPrefObserver(Eq(std::string("test.pref.2")), &registrar));
  registrar.Add("test.pref.1", observer());
  registrar.Add("test.pref.2", observer());
  Mock::VerifyAndClearExpectations(service());

  EXPECT_CALL(*service(),
              RemovePrefObserver(Eq(std::string("test.pref.1")), &registrar));
  EXPECT_CALL(*service(),
              RemovePrefObserver(Eq(std::string("test.pref.2")), &registrar));
  registrar.RemoveAll();
  EXPECT_TRUE(registrar.IsEmpty());

  // Explicitly check the expectations now to make sure that the RemoveAll
  // worked (rather than the registrar destructor doing the work).
  Mock::VerifyAndClearExpectations(service());
}

class ObserveSetOfPreferencesTest : public testing::Test {
 public:
  virtual void SetUp() {
    pref_service_.reset(new TestingPrefServiceSimple);
    PrefRegistrySimple* registry = pref_service_->registry();
    registry->RegisterStringPref(kHomePage, "http://google.com");
    registry->RegisterBooleanPref(kHomePageIsNewTabPage, false);
    registry->RegisterStringPref(kApplicationLocale, std::string());
  }

  PrefChangeRegistrar* CreatePrefChangeRegistrar() {
    PrefChangeRegistrar* pref_set = new PrefChangeRegistrar();
    base::Closure callback = base::Bind(&base::DoNothing);
    pref_set->Init(pref_service_.get());
    pref_set->Add(kHomePage, callback);
    pref_set->Add(kHomePageIsNewTabPage, callback);
    return pref_set;
  }

  MOCK_METHOD1(OnPreferenceChanged, void(const std::string&));

  scoped_ptr<TestingPrefServiceSimple> pref_service_;
};

TEST_F(ObserveSetOfPreferencesTest, IsObserved) {
  scoped_ptr<PrefChangeRegistrar> pref_set(CreatePrefChangeRegistrar());
  EXPECT_TRUE(pref_set->IsObserved(kHomePage));
  EXPECT_TRUE(pref_set->IsObserved(kHomePageIsNewTabPage));
  EXPECT_FALSE(pref_set->IsObserved(kApplicationLocale));
}

TEST_F(ObserveSetOfPreferencesTest, IsManaged) {
  scoped_ptr<PrefChangeRegistrar> pref_set(CreatePrefChangeRegistrar());
  EXPECT_FALSE(pref_set->IsManaged());
  pref_service_->SetManagedPref(kHomePage,
                                new StringValue("http://crbug.com"));
  EXPECT_TRUE(pref_set->IsManaged());
  pref_service_->SetManagedPref(kHomePageIsNewTabPage,
                                new FundamentalValue(true));
  EXPECT_TRUE(pref_set->IsManaged());
  pref_service_->RemoveManagedPref(kHomePage);
  EXPECT_TRUE(pref_set->IsManaged());
  pref_service_->RemoveManagedPref(kHomePageIsNewTabPage);
  EXPECT_FALSE(pref_set->IsManaged());
}

TEST_F(ObserveSetOfPreferencesTest, Observe) {
  using testing::_;
  using testing::Mock;

  PrefChangeRegistrar pref_set;
  PrefChangeRegistrar::NamedChangeCallback callback = base::Bind(
      &ObserveSetOfPreferencesTest::OnPreferenceChanged,
      base::Unretained(this));
  pref_set.Init(pref_service_.get());
  pref_set.Add(kHomePage, callback);
  pref_set.Add(kHomePageIsNewTabPage, callback);

  EXPECT_CALL(*this, OnPreferenceChanged(kHomePage));
  pref_service_->SetUserPref(kHomePage, new StringValue("http://crbug.com"));
  Mock::VerifyAndClearExpectations(this);

  EXPECT_CALL(*this, OnPreferenceChanged(kHomePageIsNewTabPage));
  pref_service_->SetUserPref(kHomePageIsNewTabPage,
                             new FundamentalValue(true));
  Mock::VerifyAndClearExpectations(this);

  EXPECT_CALL(*this, OnPreferenceChanged(_)).Times(0);
  pref_service_->SetUserPref(kApplicationLocale, new StringValue("en_US.utf8"));
  Mock::VerifyAndClearExpectations(this);
}

}  // namespace base
