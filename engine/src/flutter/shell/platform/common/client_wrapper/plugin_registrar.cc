// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/flutter/plugin_registrar.h"

#include <iostream>
#include <map>

#include "binary_messenger_impl.h"
#include "include/flutter/engine_method_result.h"
#include "include/flutter/method_channel.h"
#include "texture_registrar_impl.h"

namespace flutter {

namespace {

class PluginRegistrarMapImpl : public PluginRegistrarMap {
  using WrapperMap =
      std::map<FlutterDesktopPluginRegistrarRef,
               std::pair<PluginRegistrar*, OnPluginRegistrarDestructed>>;

 public:
  ~PluginRegistrarMapImpl() { ClearAndDestruct(); }

  void* AllocateMemory(size_t size) override { return malloc(size); }

  void ReleaseMemory(void* address) override { free(address); }

  PluginRegistrar* EmplaceIfNeeded(
      FlutterDesktopPluginRegistrarRef registrar_ref,
      OnPluginRegistrarConstructed on_constructed,
      OnPluginRegistrarDestructed on_destructed) override {
    auto it = map_.find(registrar_ref);
    if (it == map_.end()) {
      auto* registrar_wrapper = on_constructed(registrar_ref);
      map_.emplace(registrar_ref,
                   std::make_pair(registrar_wrapper, on_destructed));
      return registrar_wrapper;
    } else {
      PluginRegistrar* registrar_wrapper = it->second.first;
      return registrar_wrapper;
    }
  }

  void Erase(FlutterDesktopPluginRegistrarRef registrar_ref) override {
    auto it = map_.find(registrar_ref);
    if (it == map_.end()) {
      return;
    }

    PluginRegistrar* registrar_wrapper = it->second.first;
    OnPluginRegistrarDestructed on_destructed = it->second.second;

    if (registrar_wrapper && on_destructed) {
      on_destructed(registrar_wrapper);
    }

    map_.erase(it);
  }

  void Clear() override { ClearAndDestruct(); }

 private:
  void ClearAndDestruct() {
    for (auto& pair : map_) {
      PluginRegistrar* registrar_wrapper = pair.second.first;
      OnPluginRegistrarDestructed on_destructed = pair.second.second;

      if (registrar_wrapper && on_destructed) {
        on_destructed(registrar_wrapper);
      }
    }

    map_.clear();
  }

 private:
  WrapperMap map_;
};

}  // namespace

// ===== PluginRegistrar =====

PluginRegistrar::PluginRegistrar(FlutterDesktopPluginRegistrarRef registrar)
    : registrar_(registrar) {
  auto core_messenger = FlutterDesktopPluginRegistrarGetMessenger(registrar_);
  messenger_ = std::make_unique<BinaryMessengerImpl>(core_messenger);

  auto texture_registrar =
      FlutterDesktopRegistrarGetTextureRegistrar(registrar_);
  texture_registrar_ =
      std::make_unique<TextureRegistrarImpl>(texture_registrar);
}

PluginRegistrar::~PluginRegistrar() {
  // This must always be the first call.
  ClearPlugins();

  // Explicitly cleared to facilitate testing of destruction order.
  messenger_.reset();
}

void PluginRegistrar::AddPlugin(std::unique_ptr<Plugin> plugin) {
  plugins_.insert(std::move(plugin));
}

void PluginRegistrar::ClearPlugins() {
  plugins_.clear();
}

// ===== PluginRegistrarManager =====

// static
PluginRegistrarManager* PluginRegistrarManager::GetInstance() {
  static PluginRegistrarManager* instance = new PluginRegistrarManager();
  return instance;
}

PluginRegistrarManager::PluginRegistrarManager()
    : registrars_(new PluginRegistrarMapImpl()) {}

PluginRegistrarManager::~PluginRegistrarManager() {
  delete registrars_;
}

}  // namespace flutter
