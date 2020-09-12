// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_isolate_group_data.h"

#include "flutter/runtime/dart_snapshot.h"

namespace flutter {

DartIsolateGroupData::DartIsolateGroupData(
    const Settings& settings,
    fml::RefPtr<const DartSnapshot> isolate_snapshot,
    std::string advisory_script_uri,
    std::string advisory_script_entrypoint,
    const ChildIsolatePreparer& child_isolate_preparer,
    const fml::closure& isolate_create_callback,
    const fml::closure& isolate_shutdown_callback)
    : settings_(settings),
      isolate_snapshot_(isolate_snapshot),
      advisory_script_uri_(advisory_script_uri),
      advisory_script_entrypoint_(advisory_script_entrypoint),
      child_isolate_preparer_(child_isolate_preparer),
      isolate_create_callback_(isolate_create_callback),
      isolate_shutdown_callback_(isolate_shutdown_callback) {
  FML_DCHECK(isolate_snapshot_) << "Must contain a valid isolate snapshot.";
}

DartIsolateGroupData::~DartIsolateGroupData() = default;

const Settings& DartIsolateGroupData::GetSettings() const {
  return settings_;
}

fml::RefPtr<const DartSnapshot> DartIsolateGroupData::GetIsolateSnapshot()
    const {
  return isolate_snapshot_;
}

const std::string& DartIsolateGroupData::GetAdvisoryScriptURI() const {
  return advisory_script_uri_;
}

const std::string& DartIsolateGroupData::GetAdvisoryScriptEntrypoint() const {
  return advisory_script_entrypoint_;
}

ChildIsolatePreparer DartIsolateGroupData::GetChildIsolatePreparer() const {
  std::scoped_lock lock(child_isolate_preparer_mutex_);
  return child_isolate_preparer_;
}

const fml::closure& DartIsolateGroupData::GetIsolateCreateCallback() const {
  return isolate_create_callback_;
}

const fml::closure& DartIsolateGroupData::GetIsolateShutdownCallback() const {
  return isolate_shutdown_callback_;
}

void DartIsolateGroupData::SetChildIsolatePreparer(
    const ChildIsolatePreparer& value) {
  std::scoped_lock lock(child_isolate_preparer_mutex_);
  child_isolate_preparer_ = value;
}

}  // namespace flutter
