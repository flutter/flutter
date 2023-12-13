// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_SCENE_ANIMATION_ANIMATION_H_
#define FLUTTER_IMPELLER_SCENE_ANIMATION_ANIMATION_H_

#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/macros.h"
#include "impeller/base/timing.h"
#include "impeller/geometry/quaternion.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/vector.h"
#include "impeller/scene/animation/property_resolver.h"
#include "impeller/scene/importer/scene_flatbuffers.h"

namespace impeller {
namespace scene {

class Node;

class Animation final {
 public:
  static std::shared_ptr<Animation> MakeFromFlatbuffer(
      const fb::Animation& animation,
      const std::vector<std::shared_ptr<Node>>& scene_nodes);

  enum class Property {
    kTranslation,
    kRotation,
    kScale,
  };

  struct BindKey {
    std::string node_name;
    Property property = Property::kTranslation;

    struct Hash {
      std::size_t operator()(const BindKey& o) const {
        return fml::HashCombine(o.node_name, o.property);
      }
    };

    struct Equal {
      bool operator()(const BindKey& lhs, const BindKey& rhs) const {
        return lhs.node_name == rhs.node_name && lhs.property == rhs.property;
      }
    };
  };

  struct Channel {
    BindKey bind_target;
    std::unique_ptr<PropertyResolver> resolver;
  };
  ~Animation();

  const std::string& GetName() const;

  const std::vector<Channel>& GetChannels() const;

  SecondsF GetEndTime() const;

 private:
  Animation();

  std::string name_;
  std::vector<Channel> channels_;
  SecondsF end_time_;

  Animation(const Animation&) = delete;

  Animation& operator=(const Animation&) = delete;
};

}  // namespace scene
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_SCENE_ANIMATION_ANIMATION_H_
