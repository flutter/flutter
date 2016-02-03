// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library dart_ui_internals;

// TODO(abarth): Move these functions into dart:ui

int takeRootBundleHandle() native "takeRootBundleHandle";
int takeServiceRegistry() native "takeServiceRegistry";
int takeServicesProvidedByEmbedder() native "takeServicesProvidedByEmbedder";
int takeServicesProvidedToEmbedder() native "takeServicesProvidedToEmbedder";
int takeShellProxyHandle() native "takeShellProxyHandle";
int takeViewHostHandle() native "takeViewHostHandle";
