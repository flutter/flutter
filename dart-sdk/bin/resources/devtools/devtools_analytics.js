// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Used for GA collecting (communicating to https://www.googletagmanager.com/gtag/js script).
window.dataLayer = window.dataLayer || [];
function gtag() {
  dataLayer.push(arguments);
}

// InitializeGA with our dimensions. Both the name and order (dimension #) should match the those in gtags.dart.
// Note that you will also need add the custom dimension(1) or metric(2) in the Analytics 360 Admin console:
// [1]: https://analytics.google.com/analytics/web/#/a26406144w199489242p193859628/admin/custom-dimensions/
// [2]: https://analytics.google.com/analytics/web/#/a26406144w199489242p193859628/admin/custom-metrics/
// The index number assigned there should match the dimension or metric number assigned in this configuration.
function initializeGA() {
  gtag('js', new Date());
  gtag('event', 'config', {
    'send_to': DEVTOOLS_GOOGLE_TAG_ID,
    'custom_map': {
      // Custom dimensions:
      'dimension1': 'user_app',
      'dimension2': 'user_build',
      'dimension3': 'user_platform',
      'dimension4': 'devtools_platform',
      'dimension5': 'devtools_chrome',
      'dimension6': 'devtools_version',
      'dimension7': 'ide_launched',
      'dimension8': 'flutter_client_id',
      'dimension9': 'is_external_build',
      'dimension10': 'is_embedded',
      'dimension11': 'g3_username',
      'dimension12': 'ide_launched_feature',
      // Custom metrics:
      'metric1': 'ui_duration_micros',
      'metric2': 'raster_duration_micros',
      'metric3': 'shader_compilation_duration_micros',
      'metric4': 'cpu_sample_count',
      'metric5': 'cpu_stack_depth',
      'metric6': 'trace_event_count',
      'metric7': 'heap_diff_objects_before',
      'metric8': 'heap_diff_objects_after',
      'metric9': 'heap_objects_total',
      'metric10': 'root_set_count',
      'metric11': 'row_count',
      'metric12': 'inspector_tree_controller_id',
    },
    cookie_flags: 'SameSite=None;Secure',
  });
}

function hookupListenerForGA() {
  // Record when DevTools browser tab is selected (visible), not selected (hidden) or browser minimized.
  document.addEventListener('visibilitychange', function (e) {
    gtag('event', document.visibilityState, {
      event_category: 'application',
    });
  });
}
