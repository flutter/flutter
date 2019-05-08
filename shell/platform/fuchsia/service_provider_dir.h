// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_SERVICE_PROVIDER_DIR_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_SERVICE_PROVIDER_DIR_H_

#include <map>
#include <string>
#include <unordered_set>
#include <utility>
#include <vector>

#include <fuchsia/io/cpp/fidl.h>
#include <fuchsia/sys/cpp/fidl.h>
#include <lib/vfs/cpp/pseudo_dir.h>
#include <lib/vfs/cpp/service.h>

#include "lib/fidl/cpp/binding_set.h"

namespace flutter_runner {

// A directory-like object which dynamically creates Service nodes
// for any file lookup. It also exposes service provider interface.
//
// It supports enumeration for only first level of services.
class ServiceProviderDir : public vfs::Directory {
 public:
  ServiceProviderDir();
  ~ServiceProviderDir() override;

  void set_fallback(fidl::InterfaceHandle<fuchsia::io::Directory> fallback_dir);

  void AddService(const std::string& service_name,
                  std::unique_ptr<vfs::Service> service);

  //
  // Overridden from |vfs::Node|:
  //

  zx_status_t Lookup(const std::string& name, vfs::Node** out_node) const final;

  zx_status_t GetAttr(fuchsia::io::NodeAttributes* out_attributes) const final;

  zx_status_t Readdir(uint64_t offset,
                      void* data,
                      uint64_t len,
                      uint64_t* out_offset,
                      uint64_t* out_actual) final;

 private:
  // |root_| has all services offered by this provider (including those
  // inherited from the parent, if any).
  std::unique_ptr<vfs::PseudoDir> root_;
  zx::channel fallback_dir_;
  // The collection of services that have been looked up on the fallback
  // directory. These services are just passthrough in the sense that they
  // forward connection requests to the fallback directory. Since there is no
  // good way in the present context to know whether these service entries
  // actually match an existing service, and since the present object must own
  // these entries, we keep them around until the present object gets deleted.
  // Needs to be marked mutable so that it can be altered by the Lookup method.
  mutable std::map<std::string, std::unique_ptr<vfs::Service>>
      fallback_services_;

  // Disallow copy and assignment.
  ServiceProviderDir(const ServiceProviderDir&) = delete;
  ServiceProviderDir& operator=(const ServiceProviderDir&) = delete;
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_SERVICE_PROVIDER_DIR_H_
