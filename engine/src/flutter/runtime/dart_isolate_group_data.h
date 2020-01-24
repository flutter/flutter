// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_ISOLATE_GROUP_DATA_H_
#define FLUTTER_RUNTIME_DART_ISOLATE_GROUP_DATA_H_

#include <mutex>
#include <string>

#include "flutter/common/settings.h"
#include "flutter/fml/closure.h"
#include "flutter/fml/memory/ref_ptr.h"

namespace flutter {

class DartIsolate;
class DartSnapshot;

using ChildIsolatePreparer = std::function<bool(DartIsolate*)>;

// Object holding state associated with a Dart isolate group.  An instance of
// this class will be provided to Dart_CreateIsolateGroup as the
// isolate_group_data.
//
// This object must be thread safe because the Dart VM can invoke the isolate
// group cleanup callback on any thread.
class DartIsolateGroupData {
 public:
  DartIsolateGroupData(const Settings& settings,
                       fml::RefPtr<const DartSnapshot> isolate_snapshot,
                       std::string advisory_script_uri,
                       std::string advisory_script_entrypoint,
                       const ChildIsolatePreparer& child_isolate_preparer,
                       const fml::closure& isolate_create_callback,
                       const fml::closure& isolate_shutdown_callback);

  ~DartIsolateGroupData();

  const Settings& GetSettings() const;

  fml::RefPtr<const DartSnapshot> GetIsolateSnapshot() const;

  const std::string& GetAdvisoryScriptURI() const;

  const std::string& GetAdvisoryScriptEntrypoint() const;

  ChildIsolatePreparer GetChildIsolatePreparer() const;

  const fml::closure& GetIsolateCreateCallback() const;

  const fml::closure& GetIsolateShutdownCallback() const;

  void SetChildIsolatePreparer(const ChildIsolatePreparer& value);

 private:
  const Settings settings_;
  const fml::RefPtr<const DartSnapshot> isolate_snapshot_;
  const std::string advisory_script_uri_;
  const std::string advisory_script_entrypoint_;
  mutable std::mutex child_isolate_preparer_mutex_;
  ChildIsolatePreparer child_isolate_preparer_;
  const fml::closure isolate_create_callback_;
  const fml::closure isolate_shutdown_callback_;

  FML_DISALLOW_COPY_AND_ASSIGN(DartIsolateGroupData);
};

}  // namespace flutter

#endif  // FLUTTER_RUNTIME_DART_ISOLATE_GROUP_DATA_H_
