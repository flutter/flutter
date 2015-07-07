// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/testing/test_runner.h"

#include <iostream>

#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "base/strings/string_util.h"
#include "sky/shell/platform_view.h"
#include "sky/shell/shell.h"
#include "sky/shell/shell_view.h"

namespace sky {
namespace shell {
namespace {

struct UrlData {
  std::string url;
  std::string expected_pixel_hash;
  bool enable_pixel_dumping = false;
};

void WaitForURL(UrlData& data) {
  // A test name is formated like file:///path/to/test'--pixel-test'pixelhash
  std::cin >> data.url;

  std::string pixel_switch;
  std::string::size_type separator_position = data.url.find('\'');
  if (separator_position != std::string::npos) {
    pixel_switch = data.url.substr(separator_position + 1);
    data.url.erase(separator_position);
  }

  std::string pixel_hash;
  separator_position = pixel_switch.find('\'');
  if (separator_position != std::string::npos) {
    pixel_hash = pixel_switch.substr(separator_position + 1);
    pixel_switch.erase(separator_position);
  }

  data.enable_pixel_dumping = pixel_switch == "--pixel-test";
  data.expected_pixel_hash = pixel_hash;
}

void PrintAndFlush(const std::string& value) {
  std::cout << value;
  std::cout.flush();
}

const char kFileUrlPrefix[] = "file://";
static TestRunner* g_test_runner = nullptr;

}  // namespace

TestRunner::TestRunner()
  : shell_view_(new ShellView(Shell::Shared())),
    weak_ptr_factory_(this) {
  CHECK(!g_test_runner) << "Only create one TestRunner.";

  shell_view_->view()->ConnectToEngine(GetProxy(&sky_engine_));
  ViewportMetricsPtr metrics = ViewportMetrics::New();
  metrics->physical_width = 800;
  metrics->physical_height = 600;
  sky_engine_->OnViewportMetricsChanged(metrics.Pass());
}

TestRunner::~TestRunner() {
}

TestRunner& TestRunner::Shared() {
  if (!g_test_runner)
    g_test_runner = new TestRunner();
  return *g_test_runner;
}

void TestRunner::Start(const std::string& single_test_url) {
  single_test_url_ = single_test_url;
  PrintAndFlush("#READY\n");
  ScheduleRun();
}

void TestRunner::OnTestComplete(const mojo::String& test_result,
                                const mojo::Array<uint8_t> pixels) {
  std::cout << "Content-Type: text/plain\n";
  std::cout << test_result << "\n";
  PrintAndFlush("#EOF\n"); // Text result complete
  PrintAndFlush("#EOF\n"); // Pixel result complete
  std::cerr << "#EOF\n";
  std::cerr.flush();
  bindings_.CloseAllBindings();

  if (single_test_url_.length())
    exit(0);
  ScheduleRun();
}

void TestRunner::DispatchInputEvent(mojo::EventPtr event) {
  // TODO(abarth): Not implemented.
}

void TestRunner::Create(mojo::ApplicationConnection* app,
                        mojo::InterfaceRequest<TestHarness> request) {
  bindings_.AddBinding(this, request.Pass());
}

void TestRunner::ScheduleRun() {
  base::MessageLoop::current()->PostTask(FROM_HERE,
      base::Bind(&TestRunner::Run, weak_ptr_factory_.GetWeakPtr()));
}

void TestRunner::Run() {
  UrlData data;
  if (single_test_url_.length()) {
    data.url = single_test_url_;
  } else {
    WaitForURL(data);
  }

  std::cout << "#BEGIN\n";
  std::cout.flush();

  if (StartsWithASCII(data.url, kFileUrlPrefix, true))
    ReplaceFirstSubstringAfterOffset(&data.url, 0, kFileUrlPrefix, "");
  sky_engine_->RunFromFile(data.url, package_root_);
}

}  // namespace shell
}  // namespace sky
