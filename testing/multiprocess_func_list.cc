// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "multiprocess_func_list.h"

#include <map>

// Helper functions to maintain mapping of "test name"->test func.
// The information is accessed via a global map.
namespace multi_process_function_list {

namespace {

struct ProcessFunctions {
  ProcessFunctions() : main(NULL), setup(NULL) {}
  ProcessFunctions(TestMainFunctionPtr main, SetupFunctionPtr setup)
      : main(main),
        setup(setup) {
  }
  TestMainFunctionPtr main;
  SetupFunctionPtr setup;
};

typedef std::map<std::string, ProcessFunctions> MultiProcessTestMap;

// Retrieve a reference to the global 'func name' -> func ptr map.
MultiProcessTestMap& GetMultiprocessFuncMap() {
  static MultiProcessTestMap test_name_to_func_ptr_map;
  return test_name_to_func_ptr_map;
}

}  // namespace

AppendMultiProcessTest::AppendMultiProcessTest(
    std::string test_name,
    TestMainFunctionPtr main_func_ptr,
    SetupFunctionPtr setup_func_ptr) {
  GetMultiprocessFuncMap()[test_name] =
      ProcessFunctions(main_func_ptr, setup_func_ptr);
}

int InvokeChildProcessTest(std::string test_name) {
  MultiProcessTestMap& func_lookup_table = GetMultiprocessFuncMap();
  MultiProcessTestMap::iterator it = func_lookup_table.find(test_name);
  if (it != func_lookup_table.end()) {
    const ProcessFunctions& process_functions = it->second;
    if (process_functions.setup)
      (*process_functions.setup)();
    if (process_functions.main)
      return (*process_functions.main)();
  }

  return -1;
}

}  // namespace multi_process_function_list
