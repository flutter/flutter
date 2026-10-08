// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Host API prerequisites, not a guarantee of engine configuration or behavior.
/// Keep these symbol groups aligned with fl_gtk4_runtime_api.cc capability gates.
const gtk4Capabilities = <Gtk4Capability>[
  Gtk4Capability('Native accessibility tree APIs', 10, <String>[
    'gtk_accessible_set_accessible_parent',
    'gtk_accessible_get_first_accessible_child',
  ]),
  Gtk4Capability('Accessible text APIs', 14, <String>[
    'gtk_accessible_text_get_type',
    'gtk_accessible_text_update_caret_position',
    'gtk_accessible_text_update_selection_bound',
    'gtk_accessible_text_update_contents',
  ]),
  Gtk4Capability('Accessibility announcement API', 14, <String>['gtk_accessible_announce']),
  Gtk4Capability('DMA-BUF texture APIs', 14, <String>[
    'gdk_display_get_dmabuf_formats',
    'gdk_dmabuf_formats_ref',
    'gdk_dmabuf_formats_unref',
    'gdk_dmabuf_formats_get_n_formats',
    'gdk_dmabuf_formats_get_format',
    'gdk_dmabuf_formats_contains',
    'gdk_dmabuf_texture_builder_new',
    'gdk_dmabuf_texture_builder_set_display',
    'gdk_dmabuf_texture_builder_set_width',
    'gdk_dmabuf_texture_builder_set_height',
    'gdk_dmabuf_texture_builder_set_fourcc',
    'gdk_dmabuf_texture_builder_set_modifier',
    'gdk_dmabuf_texture_builder_set_premultiplied',
    'gdk_dmabuf_texture_builder_set_n_planes',
    'gdk_dmabuf_texture_builder_set_fd',
    'gdk_dmabuf_texture_builder_set_stride',
    'gdk_dmabuf_texture_builder_set_offset',
    'gdk_dmabuf_texture_builder_build',
  ]),
];

class Gtk4Capability {
  const Gtk4Capability(this.name, this.minorVersion, this.symbols);

  final String name;
  final int minorVersion;
  final List<String> symbols;
}
