// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "src/lib/ui/base_view/embedded_view_utils.h"

#include <lib/ui/scenic/cpp/view_ref_pair.h>
#include <lib/ui/scenic/cpp/view_token_pair.h>
#include "flutter/fml/logging.h"

namespace scenic {

EmbeddedViewInfo LaunchComponentAndCreateView(
    const fuchsia::sys::LauncherPtr& launcher,
    const std::string& component_url,
    const std::vector<std::string>& component_args) {
  FML_DCHECK(launcher);

  EmbeddedViewInfo info;

  // Configure the information to launch the component with.
  fuchsia::sys::LaunchInfo launch_info;
  info.app_services =
      sys::ServiceDirectory::CreateWithRequest(&launch_info.directory_request);
  launch_info.url = component_url;
  launch_info.arguments = fidl::VectorPtr(
      std::vector<std::string>(component_args.begin(), component_args.end()));

  launcher->CreateComponent(std::move(launch_info),
                            info.controller.NewRequest());

  info.view_provider =
      info.app_services->Connect<fuchsia::ui::app::ViewProvider>();

  auto [view_token, view_holder_token] = scenic::ViewTokenPair::New();
  info.view_holder_token = std::move(view_holder_token);

  auto [view_ref_control, view_ref] = scenic::ViewRefPair::New();
  fidl::Clone(view_ref, &info.view_ref);

  info.view_provider->CreateViewWithViewRef(std::move(view_token.value),
                                            std::move(view_ref_control),
                                            std::move(view_ref));

  return info;
}

}  // namespace scenic
