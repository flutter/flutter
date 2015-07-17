// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/prefs/testing_pref_store.h"

#include "base/memory/scoped_ptr.h"
#include "base/values.h"

TestingPrefStore::TestingPrefStore()
    : read_only_(true),
      read_success_(true),
      read_error_(PersistentPrefStore::PREF_READ_ERROR_NONE),
      block_async_read_(false),
      pending_async_read_(false),
      init_complete_(false),
      committed_(true) {}

bool TestingPrefStore::GetValue(const std::string& key,
                                const base::Value** value) const {
  return prefs_.GetValue(key, value);
}

bool TestingPrefStore::GetMutableValue(const std::string& key,
                                       base::Value** value) {
  return prefs_.GetValue(key, value);
}

void TestingPrefStore::AddObserver(PrefStore::Observer* observer) {
  observers_.AddObserver(observer);
}

void TestingPrefStore::RemoveObserver(PrefStore::Observer* observer) {
  observers_.RemoveObserver(observer);
}

bool TestingPrefStore::HasObservers() const {
  return observers_.might_have_observers();
}

bool TestingPrefStore::IsInitializationComplete() const {
  return init_complete_;
}

void TestingPrefStore::SetValue(const std::string& key,
                                scoped_ptr<base::Value> value,
                                uint32 flags) {
  if (prefs_.SetValue(key, value.Pass())) {
    committed_ = false;
    NotifyPrefValueChanged(key);
  }
}

void TestingPrefStore::SetValueSilently(const std::string& key,
                                        scoped_ptr<base::Value> value,
                                        uint32 flags) {
  if (prefs_.SetValue(key, value.Pass()))
    committed_ = false;
}

void TestingPrefStore::RemoveValue(const std::string& key, uint32 flags) {
  if (prefs_.RemoveValue(key)) {
    committed_ = false;
    NotifyPrefValueChanged(key);
  }
}

bool TestingPrefStore::ReadOnly() const {
  return read_only_;
}

PersistentPrefStore::PrefReadError TestingPrefStore::GetReadError() const {
  return read_error_;
}

PersistentPrefStore::PrefReadError TestingPrefStore::ReadPrefs() {
  NotifyInitializationCompleted();
  return read_error_;
}

void TestingPrefStore::ReadPrefsAsync(ReadErrorDelegate* error_delegate) {
  DCHECK(!pending_async_read_);
  error_delegate_.reset(error_delegate);
  if (block_async_read_)
    pending_async_read_ = true;
  else
    NotifyInitializationCompleted();
}

void TestingPrefStore::CommitPendingWrite() { committed_ = true; }

void TestingPrefStore::SchedulePendingLossyWrites() {}

void TestingPrefStore::SetInitializationCompleted() {
  NotifyInitializationCompleted();
}

void TestingPrefStore::NotifyPrefValueChanged(const std::string& key) {
  FOR_EACH_OBSERVER(Observer, observers_, OnPrefValueChanged(key));
}

void TestingPrefStore::NotifyInitializationCompleted() {
  DCHECK(!init_complete_);
  init_complete_ = true;
  if (read_success_ && read_error_ != PREF_READ_ERROR_NONE && error_delegate_)
    error_delegate_->OnError(read_error_);
  FOR_EACH_OBSERVER(
      Observer, observers_, OnInitializationCompleted(read_success_));
}

void TestingPrefStore::ReportValueChanged(const std::string& key,
                                          uint32 flags) {
  FOR_EACH_OBSERVER(Observer, observers_, OnPrefValueChanged(key));
}

void TestingPrefStore::SetString(const std::string& key,
                                 const std::string& value) {
  SetValue(key, make_scoped_ptr(new base::StringValue(value)),
           DEFAULT_PREF_WRITE_FLAGS);
}

void TestingPrefStore::SetInteger(const std::string& key, int value) {
  SetValue(key, make_scoped_ptr(new base::FundamentalValue(value)),
           DEFAULT_PREF_WRITE_FLAGS);
}

void TestingPrefStore::SetBoolean(const std::string& key, bool value) {
  SetValue(key, make_scoped_ptr(new base::FundamentalValue(value)),
           DEFAULT_PREF_WRITE_FLAGS);
}

bool TestingPrefStore::GetString(const std::string& key,
                                 std::string* value) const {
  const base::Value* stored_value;
  if (!prefs_.GetValue(key, &stored_value) || !stored_value)
    return false;

  return stored_value->GetAsString(value);
}

bool TestingPrefStore::GetInteger(const std::string& key, int* value) const {
  const base::Value* stored_value;
  if (!prefs_.GetValue(key, &stored_value) || !stored_value)
    return false;

  return stored_value->GetAsInteger(value);
}

bool TestingPrefStore::GetBoolean(const std::string& key, bool* value) const {
  const base::Value* stored_value;
  if (!prefs_.GetValue(key, &stored_value) || !stored_value)
    return false;

  return stored_value->GetAsBoolean(value);
}

void TestingPrefStore::SetBlockAsyncRead(bool block_async_read) {
  DCHECK(!init_complete_);
  block_async_read_ = block_async_read;
  if (pending_async_read_ && !block_async_read_)
    NotifyInitializationCompleted();
}

void TestingPrefStore::set_read_only(bool read_only) {
  read_only_ = read_only;
}

void TestingPrefStore::set_read_success(bool read_success) {
  DCHECK(!init_complete_);
  read_success_ = read_success;
}

void TestingPrefStore::set_read_error(
    PersistentPrefStore::PrefReadError read_error) {
  DCHECK(!init_complete_);
  read_error_ = read_error;
}

TestingPrefStore::~TestingPrefStore() {}
