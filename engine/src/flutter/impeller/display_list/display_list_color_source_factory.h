// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/display_list/display_list_color_source.h"
#include "impeller/aiks/color_source_factory.h"
#include "impeller/entity/contents/color_source_contents.h"

namespace impeller {

//------------------------------------------------------------------------------
/// DlColorSourceFactory
///

class DlColorSourceFactory : public ColorSourceFactory {
 public:
  // |ColorSourceFactory|
  ~DlColorSourceFactory() override;

 protected:
  explicit DlColorSourceFactory(
      const std::shared_ptr<flutter::DlColorSource>& dl_color_source);

  std::shared_ptr<flutter::DlColorSource> dl_color_source_;
};

//------------------------------------------------------------------------------
/// DlImageColorSourceFactory
///

class DlImageColorSourceFactory final : public DlColorSourceFactory {
 public:
  static std::shared_ptr<ColorSourceFactory> Make(
      const std::shared_ptr<flutter::DlColorSource>& dl_color_source);

  // |ColorSourceFactory|
  ~DlImageColorSourceFactory() override;

  // |ColorSourceFactory|
  std::shared_ptr<ColorSourceContents> MakeContents() override;

  // |ColorSourceFactory|
  ColorSourceFactory::ColorSourceType GetType() override;

 private:
  explicit DlImageColorSourceFactory(
      const std::shared_ptr<flutter::DlColorSource>& dl_color_source);
};

//------------------------------------------------------------------------------
/// DlLinearGradientColorSourceFactory
///

class DlLinearGradientColorSourceFactory final : public DlColorSourceFactory {
 public:
  static std::shared_ptr<ColorSourceFactory> Make(
      const std::shared_ptr<flutter::DlColorSource>& dl_color_source);

  // |ColorSourceFactory|
  ~DlLinearGradientColorSourceFactory() override;

  // |ColorSourceFactory|
  std::shared_ptr<ColorSourceContents> MakeContents() override;

  // |ColorSourceFactory|
  ColorSourceFactory::ColorSourceType GetType() override;

 private:
  explicit DlLinearGradientColorSourceFactory(
      const std::shared_ptr<flutter::DlColorSource>& dl_color_source);
};

//------------------------------------------------------------------------------
/// DlRadialGradientColorSourceFactory
///

class DlRadialGradientColorSourceFactory final : public DlColorSourceFactory {
 public:
  static std::shared_ptr<ColorSourceFactory> Make(
      const std::shared_ptr<flutter::DlColorSource>& dl_color_source);

  // |ColorSourceFactory|
  ~DlRadialGradientColorSourceFactory() override;

  // |ColorSourceFactory|
  std::shared_ptr<ColorSourceContents> MakeContents() override;

  // |ColorSourceFactory|
  ColorSourceFactory::ColorSourceType GetType() override;

 private:
  explicit DlRadialGradientColorSourceFactory(
      const std::shared_ptr<flutter::DlColorSource>& dl_color_source);
};

//------------------------------------------------------------------------------
/// DlSweepGradientColorSourceFactory
///

class DlSweepGradientColorSourceFactory final : public DlColorSourceFactory {
 public:
  static std::shared_ptr<ColorSourceFactory> Make(
      const std::shared_ptr<flutter::DlColorSource>& dl_color_source);

  // |ColorSourceFactory|
  ~DlSweepGradientColorSourceFactory() override;

  // |ColorSourceFactory|
  std::shared_ptr<ColorSourceContents> MakeContents() override;

  // |ColorSourceFactory|
  ColorSourceFactory::ColorSourceType GetType() override;

 private:
  explicit DlSweepGradientColorSourceFactory(
      const std::shared_ptr<flutter::DlColorSource>& dl_color_source);
};

//------------------------------------------------------------------------------
/// DlRuntimeEffectColorSourceFactory
///

class DlRuntimeEffectColorSourceFactory final : public DlColorSourceFactory {
 public:
  static std::shared_ptr<ColorSourceFactory> Make(
      const std::shared_ptr<flutter::DlColorSource>& dl_color_source);

  // |ColorSourceFactory|
  ~DlRuntimeEffectColorSourceFactory() override;

  // |ColorSourceFactory|
  std::shared_ptr<ColorSourceContents> MakeContents() override;

  // |ColorSourceFactory|
  ColorSourceFactory::ColorSourceType GetType() override;

 private:
  explicit DlRuntimeEffectColorSourceFactory(
      const std::shared_ptr<flutter::DlColorSource>& dl_color_source);
};

}  // namespace impeller
