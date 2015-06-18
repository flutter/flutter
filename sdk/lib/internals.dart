// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky.internals;

String contentAsText() native "contentAsText";
String renderTreeAsText() native "renderTreeAsText";
void notifyTestComplete(String test_result) native "notifyTestComplete";

int takeShellProxyHandle() native "takeShellProxyHandle";
int takeServicesProvidedByEmbedder() native "takeServicesProvidedByEmbedder";
int takeServicesProvidedToEmbedder() native "takeServicesProvidedToEmbedder";
int takeServiceRegistry() native "takeServiceRegistry";
