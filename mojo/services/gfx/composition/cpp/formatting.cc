// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/gfx/composition/cpp/formatting.h"

#include <ostream>

namespace mojo {
namespace gfx {
namespace composition {

class Delimiter {
 public:
  Delimiter(std::ostream& os) : os_(os) {}

  std::ostream& Append() {
    if (need_comma_)
      os_ << ", ";
    else
      need_comma_ = true;
    return os_;
  }

 private:
  std::ostream& os_;
  bool need_comma_ = false;
};

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::SceneToken& value) {
  return os << "<S" << value.value << ">";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::SceneUpdate& value) {
  os << "{";
  Delimiter d(os);
  if (value.clear_resources) {
    d.Append() << "clear_resources=true";
  }
  if (value.clear_nodes) {
    d.Append() << "clear_nodes=true";
  }
  if (value.resources) {
    d.Append() << "resources=" << value.resources;
  }
  if (value.nodes) {
    d.Append() << "nodes=" << value.nodes;
  }
  os << "}";
  return os;
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::SceneMetadata& value) {
  return os << "{version=" << value.version
            << ", presentation_time=" << value.presentation_time << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::Resource& value) {
  os << "{";
  if (value.is_scene()) {
    os << "scene=" << value.get_scene();
  } else if (value.is_mailbox_texture()) {
    os << "mailbox_texture=" << value.get_mailbox_texture();
  } else {
    os << "???";
  }
  return os << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::SceneResource& value) {
  return os << "{scene_token=" << value.scene_token << "}";
}

std::ostream& operator<<(
    std::ostream& os,
    const mojo::gfx::composition::MailboxTextureResource& value) {
  return os << "{sync_point=" << value.sync_point << ", size=" << value.size
            << ", origin=" << &value.origin << "}";
}

std::ostream& operator<<(
    std::ostream& os,
    const mojo::gfx::composition::MailboxTextureResource::Origin* value) {
  switch (*value) {
    case mojo::gfx::composition::MailboxTextureResource::Origin::TOP_LEFT:
      return os << "TOP_LEFT";
    case mojo::gfx::composition::MailboxTextureResource::Origin::BOTTOM_LEFT:
      return os << "BOTTOM_LEFT";
    default:
      return os << "???";
  }
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::Node& value) {
  os << "{";
  Delimiter d(os);
  if (value.content_transform)
    d.Append() << "content_transform=" << value.content_transform;
  if (value.content_clip)
    d.Append() << "content_clip=" << value.content_clip;
  if (value.hit_test_behavior)
    d.Append() << "hit_test_behavior=" << value.hit_test_behavior;
  if (value.op)
    d.Append() << "op=" << value.op;
  d.Append() << "combinator=" << &value.combinator;
  if (value.child_node_ids)
    d.Append() << "child_node_ids=" << value.child_node_ids;
  return os << "}";
}

std::ostream& operator<<(
    std::ostream& os,
    const mojo::gfx::composition::Node::Combinator* value) {
  switch (*value) {
    case mojo::gfx::composition::Node::Combinator::MERGE:
      return os << "MERGE";
    case mojo::gfx::composition::Node::Combinator::PRUNE:
      return os << "PRUNE";
    case mojo::gfx::composition::Node::Combinator::FALLBACK:
      return os << "FALLBACK";
    default:
      return os << "???";
  }
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::NodeOp& value) {
  os << "{";
  if (value.is_rect()) {
    os << "rect=" << value.get_rect();
  } else if (value.is_image()) {
    os << "image=" << value.get_image();
  } else if (value.is_scene()) {
    os << "scene=" << value.get_scene();
  } else if (value.is_layer()) {
    os << "layer=" << value.get_layer();
  } else {
    os << "???";
  }
  return os << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::RectNodeOp& value) {
  return os << "{content_rect=" << value.content_rect
            << ", color=" << value.color << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::ImageNodeOp& value) {
  return os << "{content_rect=" << value.content_rect
            << ", image_rect=" << value.image_rect
            << ", image_resource_id=" << value.image_resource_id
            << ", blend=" << value.blend << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::SceneNodeOp& value) {
  return os << "{scene_resource_id=" << value.scene_resource_id
            << ", scene_version=" << value.scene_version << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::LayerNodeOp& value) {
  return os << "{layer_rect=" << value.layer_rect << ", blend=" << value.blend
            << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::Color& value) {
  return os << "{red=" << static_cast<int>(value.red)
            << ", green=" << static_cast<int>(value.green)
            << ", blue=" << static_cast<int>(value.blue)
            << ", alpha=" << static_cast<int>(value.alpha) << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::Blend& value) {
  return os << "{alpha=" << static_cast<int>(value.alpha) << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::FrameInfo& value) {
  return os << "{frame_time=" << value.frame_time
            << ", frame_interval=" << value.frame_interval
            << ", frame_deadline=" << value.frame_deadline << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::HitTestBehavior& value) {
  return os << "{visibility=" << &value.visibility << ", prune" << value.prune
            << ", hit_rect=" << value.hit_rect << "}";
}

std::ostream& operator<<(
    std::ostream& os,
    const mojo::gfx::composition::HitTestBehavior::Visibility* value) {
  switch (*value) {
    case mojo::gfx::composition::HitTestBehavior::Visibility::OPAQUE:
      return os << "OPAQUE";
    case mojo::gfx::composition::HitTestBehavior::Visibility::TRANSLUCENT:
      return os << "TRANSLUCENT";
    case mojo::gfx::composition::HitTestBehavior::Visibility::INVISIBLE:
      return os << "INVISIBLE";
    default:
      return os << "???";
  }
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::HitTestResult& value) {
  return os << "{root=" << value.root << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::Hit& value) {
  os << "{";
  if (value.is_scene()) {
    os << "scene=" << value.get_scene();
  } else if (value.is_node()) {
    os << "node=" << value.get_node();
  } else {
    os << "???";
  }
  return os << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::SceneHit& value) {
  return os << "{scene_token=" << value.scene_token
            << ", scene_version=" << value.scene_version
            << ", hits=" << value.hits << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::gfx::composition::NodeHit& value) {
  return os << "{node_id=" << value.node_id << ", transform=" << value.transform
            << "}";
}

}  // namespace composition
}  // namespace gfx
}  // namespace mojo
