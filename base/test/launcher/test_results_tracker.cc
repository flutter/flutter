// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/launcher/test_results_tracker.h"

#include "base/base64.h"
#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/format_macros.h"
#include "base/json/json_file_value_serializer.h"
#include "base/json/string_escape.h"
#include "base/logging.h"
#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"
#include "base/test/launcher/test_launcher.h"
#include "base/values.h"

namespace base {

namespace {

// The default output file for XML output.
const FilePath::CharType kDefaultOutputFile[] = FILE_PATH_LITERAL(
    "test_detail.xml");

// Utility function to print a list of test names. Uses iterator to be
// compatible with different containers, like vector and set.
template<typename InputIterator>
void PrintTests(InputIterator first,
                InputIterator last,
                const std::string& description) {
  size_t count = std::distance(first, last);
  if (count == 0)
    return;

  fprintf(stdout,
          "%" PRIuS " test%s %s:\n",
          count,
          count != 1 ? "s" : "",
          description.c_str());
  for (InputIterator i = first; i != last; ++i)
    fprintf(stdout, "    %s\n", (*i).c_str());
  fflush(stdout);
}

std::string TestNameWithoutDisabledPrefix(const std::string& test_name) {
  std::string test_name_no_disabled(test_name);
  ReplaceSubstringsAfterOffset(&test_name_no_disabled, 0, "DISABLED_", "");
  return test_name_no_disabled;
}

}  // namespace

TestResultsTracker::TestResultsTracker() : iteration_(-1), out_(NULL) {
}

TestResultsTracker::~TestResultsTracker() {
  DCHECK(thread_checker_.CalledOnValidThread());

  if (!out_)
    return;
  fprintf(out_, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
  fprintf(out_, "<testsuites name=\"AllTests\" tests=\"\" failures=\"\""
          " disabled=\"\" errors=\"\" time=\"\">\n");

  // Maps test case names to test results.
  typedef std::map<std::string, std::vector<TestResult> > TestCaseMap;
  TestCaseMap test_case_map;

  for (PerIterationData::ResultsMap::iterator i =
           per_iteration_data_[iteration_].results.begin();
       i != per_iteration_data_[iteration_].results.end();
       ++i) {
    // Use the last test result as the final one.
    TestResult result = i->second.test_results.back();
    test_case_map[result.GetTestCaseName()].push_back(result);
  }
  for (TestCaseMap::iterator i = test_case_map.begin();
       i != test_case_map.end();
       ++i) {
    fprintf(out_, "  <testsuite name=\"%s\" tests=\"%" PRIuS "\" failures=\"\""
            " disabled=\"\" errors=\"\" time=\"\">\n",
            i->first.c_str(), i->second.size());
    for (size_t j = 0; j < i->second.size(); ++j) {
      const TestResult& result = i->second[j];
      fprintf(out_, "    <testcase name=\"%s\" status=\"run\" time=\"%.3f\""
              " classname=\"%s\">\n",
              result.GetTestName().c_str(),
              result.elapsed_time.InSecondsF(),
              result.GetTestCaseName().c_str());
      if (result.status != TestResult::TEST_SUCCESS)
        fprintf(out_, "      <failure message=\"\" type=\"\"></failure>\n");
      fprintf(out_, "    </testcase>\n");
    }
    fprintf(out_, "  </testsuite>\n");
  }
  fprintf(out_, "</testsuites>\n");
  fclose(out_);
}

bool TestResultsTracker::Init(const CommandLine& command_line) {
  DCHECK(thread_checker_.CalledOnValidThread());

  // Prevent initializing twice.
  if (out_) {
    NOTREACHED();
    return false;
  }

  if (!command_line.HasSwitch(kGTestOutputFlag))
    return true;

  std::string flag = command_line.GetSwitchValueASCII(kGTestOutputFlag);
  size_t colon_pos = flag.find(':');
  FilePath path;
  if (colon_pos != std::string::npos) {
    FilePath flag_path =
        command_line.GetSwitchValuePath(kGTestOutputFlag);
    FilePath::StringType path_string = flag_path.value();
    path = FilePath(path_string.substr(colon_pos + 1));
    // If the given path ends with '/', consider it is a directory.
    // Note: This does NOT check that a directory (or file) actually exists
    // (the behavior is same as what gtest does).
    if (path.EndsWithSeparator()) {
      FilePath executable = command_line.GetProgram().BaseName();
      path = path.Append(executable.ReplaceExtension(
                             FilePath::StringType(FILE_PATH_LITERAL("xml"))));
    }
  }
  if (path.value().empty())
    path = FilePath(kDefaultOutputFile);
  FilePath dir_name = path.DirName();
  if (!DirectoryExists(dir_name)) {
    LOG(WARNING) << "The output directory does not exist. "
                 << "Creating the directory: " << dir_name.value();
    // Create the directory if necessary (because the gtest does the same).
    if (!base::CreateDirectory(dir_name)) {
      LOG(ERROR) << "Failed to created directory " << dir_name.value();
      return false;
    }
  }
  out_ = OpenFile(path, "w");
  if (!out_) {
    LOG(ERROR) << "Cannot open output file: "
               << path.value() << ".";
    return false;
  }

  return true;
}

void TestResultsTracker::OnTestIterationStarting() {
  DCHECK(thread_checker_.CalledOnValidThread());

  // Start with a fresh state for new iteration.
  iteration_++;
  per_iteration_data_.push_back(PerIterationData());
}

void TestResultsTracker::AddTest(const std::string& test_name) {
  // Record disabled test names without DISABLED_ prefix so that they are easy
  // to compare with regular test names, e.g. before or after disabling.
  all_tests_.insert(TestNameWithoutDisabledPrefix(test_name));
}

void TestResultsTracker::AddDisabledTest(const std::string& test_name) {
  // Record disabled test names without DISABLED_ prefix so that they are easy
  // to compare with regular test names, e.g. before or after disabling.
  disabled_tests_.insert(TestNameWithoutDisabledPrefix(test_name));
}

void TestResultsTracker::AddTestResult(const TestResult& result) {
  DCHECK(thread_checker_.CalledOnValidThread());

  per_iteration_data_[iteration_].results[
      result.full_name].test_results.push_back(result);
}

void TestResultsTracker::PrintSummaryOfCurrentIteration() const {
  TestStatusMap tests_by_status(GetTestStatusMapForCurrentIteration());

  PrintTests(tests_by_status[TestResult::TEST_FAILURE].begin(),
             tests_by_status[TestResult::TEST_FAILURE].end(),
             "failed");
  PrintTests(tests_by_status[TestResult::TEST_FAILURE_ON_EXIT].begin(),
             tests_by_status[TestResult::TEST_FAILURE_ON_EXIT].end(),
             "failed on exit");
  PrintTests(tests_by_status[TestResult::TEST_TIMEOUT].begin(),
             tests_by_status[TestResult::TEST_TIMEOUT].end(),
             "timed out");
  PrintTests(tests_by_status[TestResult::TEST_CRASH].begin(),
             tests_by_status[TestResult::TEST_CRASH].end(),
             "crashed");
  PrintTests(tests_by_status[TestResult::TEST_SKIPPED].begin(),
             tests_by_status[TestResult::TEST_SKIPPED].end(),
             "skipped");
  PrintTests(tests_by_status[TestResult::TEST_UNKNOWN].begin(),
             tests_by_status[TestResult::TEST_UNKNOWN].end(),
             "had unknown result");
}

void TestResultsTracker::PrintSummaryOfAllIterations() const {
  DCHECK(thread_checker_.CalledOnValidThread());

  TestStatusMap tests_by_status(GetTestStatusMapForAllIterations());

  fprintf(stdout, "Summary of all test iterations:\n");
  fflush(stdout);

  PrintTests(tests_by_status[TestResult::TEST_FAILURE].begin(),
             tests_by_status[TestResult::TEST_FAILURE].end(),
             "failed");
  PrintTests(tests_by_status[TestResult::TEST_FAILURE_ON_EXIT].begin(),
             tests_by_status[TestResult::TEST_FAILURE_ON_EXIT].end(),
             "failed on exit");
  PrintTests(tests_by_status[TestResult::TEST_TIMEOUT].begin(),
             tests_by_status[TestResult::TEST_TIMEOUT].end(),
             "timed out");
  PrintTests(tests_by_status[TestResult::TEST_CRASH].begin(),
             tests_by_status[TestResult::TEST_CRASH].end(),
             "crashed");
  PrintTests(tests_by_status[TestResult::TEST_SKIPPED].begin(),
             tests_by_status[TestResult::TEST_SKIPPED].end(),
             "skipped");
  PrintTests(tests_by_status[TestResult::TEST_UNKNOWN].begin(),
             tests_by_status[TestResult::TEST_UNKNOWN].end(),
             "had unknown result");

  fprintf(stdout, "End of the summary.\n");
  fflush(stdout);
}

void TestResultsTracker::AddGlobalTag(const std::string& tag) {
  global_tags_.insert(tag);
}

bool TestResultsTracker::SaveSummaryAsJSON(const FilePath& path) const {
  scoped_ptr<DictionaryValue> summary_root(new DictionaryValue);

  scoped_ptr<ListValue> global_tags(new ListValue);
  for (const auto& global_tag : global_tags_) {
    global_tags->AppendString(global_tag);
  }
  summary_root->Set("global_tags", global_tags.Pass());

  scoped_ptr<ListValue> all_tests(new ListValue);
  for (const auto& test : all_tests_) {
    all_tests->AppendString(test);
  }
  summary_root->Set("all_tests", all_tests.Pass());

  scoped_ptr<ListValue> disabled_tests(new ListValue);
  for (const auto& disabled_test : disabled_tests_) {
    disabled_tests->AppendString(disabled_test);
  }
  summary_root->Set("disabled_tests", disabled_tests.Pass());

  scoped_ptr<ListValue> per_iteration_data(new ListValue);

  for (int i = 0; i <= iteration_; i++) {
    scoped_ptr<DictionaryValue> current_iteration_data(new DictionaryValue);

    for (PerIterationData::ResultsMap::const_iterator j =
             per_iteration_data_[i].results.begin();
         j != per_iteration_data_[i].results.end();
         ++j) {
      scoped_ptr<ListValue> test_results(new ListValue);

      for (size_t k = 0; k < j->second.test_results.size(); k++) {
        const TestResult& test_result = j->second.test_results[k];

        scoped_ptr<DictionaryValue> test_result_value(new DictionaryValue);

        test_result_value->SetString("status", test_result.StatusAsString());
        test_result_value->SetInteger(
            "elapsed_time_ms",
            static_cast<int>(test_result.elapsed_time.InMilliseconds()));

        // There are no guarantees about character encoding of the output
        // snippet. Escape it and record whether it was losless.
        // It's useful to have the output snippet as string in the summary
        // for easy viewing.
        std::string escaped_output_snippet;
        bool losless_snippet = EscapeJSONString(
            test_result.output_snippet, false, &escaped_output_snippet);
        test_result_value->SetString("output_snippet",
                                     escaped_output_snippet);
        test_result_value->SetBoolean("losless_snippet", losless_snippet);

        // Also include the raw version (base64-encoded so that it can be safely
        // JSON-serialized - there are no guarantees about character encoding
        // of the snippet). This can be very useful piece of information when
        // debugging a test failure related to character encoding.
        std::string base64_output_snippet;
        Base64Encode(test_result.output_snippet, &base64_output_snippet);
        test_result_value->SetString("output_snippet_base64",
                                     base64_output_snippet);
        test_results->Append(test_result_value.Pass());
      }

      current_iteration_data->SetWithoutPathExpansion(j->first,
                                                      test_results.Pass());
    }
    per_iteration_data->Append(current_iteration_data.Pass());
    summary_root->Set("per_iteration_data", per_iteration_data.Pass());
  }

  JSONFileValueSerializer serializer(path);
  return serializer.Serialize(*summary_root);
}

TestResultsTracker::TestStatusMap
    TestResultsTracker::GetTestStatusMapForCurrentIteration() const {
  TestStatusMap tests_by_status;
  GetTestStatusForIteration(iteration_, &tests_by_status);
  return tests_by_status;
}

TestResultsTracker::TestStatusMap
    TestResultsTracker::GetTestStatusMapForAllIterations() const {
  TestStatusMap tests_by_status;
  for (int i = 0; i <= iteration_; i++)
    GetTestStatusForIteration(i, &tests_by_status);
  return tests_by_status;
}

void TestResultsTracker::GetTestStatusForIteration(
    int iteration, TestStatusMap* map) const {
  for (PerIterationData::ResultsMap::const_iterator j =
           per_iteration_data_[iteration].results.begin();
       j != per_iteration_data_[iteration].results.end();
       ++j) {
    // Use the last test result as the final one.
    const TestResult& result = j->second.test_results.back();
    (*map)[result.status].insert(result.full_name);
  }
}

TestResultsTracker::AggregateTestResult::AggregateTestResult() {
}

TestResultsTracker::AggregateTestResult::~AggregateTestResult() {
}

TestResultsTracker::PerIterationData::PerIterationData() {
}

TestResultsTracker::PerIterationData::~PerIterationData() {
}

}  // namespace base
