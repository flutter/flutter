// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/prefs/json_pref_store.h"

#include "base/bind.h"
#include "base/files/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "base/location.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/metrics/histogram_samples.h"
#include "base/metrics/statistics_recorder.h"
#include "base/path_service.h"
#include "base/prefs/pref_filter.h"
#include "base/run_loop.h"
#include "base/single_thread_task_runner.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"
#include "base/test/simple_test_clock.h"
#include "base/threading/sequenced_worker_pool.h"
#include "base/threading/thread.h"
#include "base/values.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace {

const char kHomePage[] = "homepage";

// Set the time on the given SimpleTestClock to the given time in minutes.
void SetCurrentTimeInMinutes(double minutes, base::SimpleTestClock* clock) {
  const int32_t kBaseTimeMins = 100;
  clock->SetNow(base::Time::FromDoubleT((kBaseTimeMins + minutes) * 60));
}

// A PrefFilter that will intercept all calls to FilterOnLoad() and hold on
// to the |prefs| until explicitly asked to release them.
class InterceptingPrefFilter : public PrefFilter {
 public:
  InterceptingPrefFilter();
  ~InterceptingPrefFilter() override;

  // PrefFilter implementation:
  void FilterOnLoad(
      const PostFilterOnLoadCallback& post_filter_on_load_callback,
      scoped_ptr<base::DictionaryValue> pref_store_contents) override;
  void FilterUpdate(const std::string& path) override {}
  void FilterSerializeData(
      base::DictionaryValue* pref_store_contents) override {}

  bool has_intercepted_prefs() const { return intercepted_prefs_ != NULL; }

  // Finalize an intercepted read, handing |intercepted_prefs_| back to its
  // JsonPrefStore.
  void ReleasePrefs();

 private:
  PostFilterOnLoadCallback post_filter_on_load_callback_;
  scoped_ptr<base::DictionaryValue> intercepted_prefs_;

  DISALLOW_COPY_AND_ASSIGN(InterceptingPrefFilter);
};

InterceptingPrefFilter::InterceptingPrefFilter() {}
InterceptingPrefFilter::~InterceptingPrefFilter() {}

void InterceptingPrefFilter::FilterOnLoad(
    const PostFilterOnLoadCallback& post_filter_on_load_callback,
    scoped_ptr<base::DictionaryValue> pref_store_contents) {
  post_filter_on_load_callback_ = post_filter_on_load_callback;
  intercepted_prefs_ = pref_store_contents.Pass();
}

void InterceptingPrefFilter::ReleasePrefs() {
  EXPECT_FALSE(post_filter_on_load_callback_.is_null());
  post_filter_on_load_callback_.Run(intercepted_prefs_.Pass(), false);
  post_filter_on_load_callback_.Reset();
}

class MockPrefStoreObserver : public PrefStore::Observer {
 public:
  MOCK_METHOD1(OnPrefValueChanged, void (const std::string&));
  MOCK_METHOD1(OnInitializationCompleted, void (bool));
};

class MockReadErrorDelegate : public PersistentPrefStore::ReadErrorDelegate {
 public:
  MOCK_METHOD1(OnError, void(PersistentPrefStore::PrefReadError));
};

}  // namespace

class JsonPrefStoreTest : public testing::Test {
 protected:
  void SetUp() override {
    ASSERT_TRUE(temp_dir_.CreateUniqueTempDir());

    ASSERT_TRUE(PathService::Get(base::DIR_TEST_DATA, &data_dir_));
    data_dir_ = data_dir_.AppendASCII("prefs");
    ASSERT_TRUE(PathExists(data_dir_));
  }

  void TearDown() override {
    // Make sure all pending tasks have been processed (e.g., deleting the
    // JsonPrefStore may post write tasks).
    RunLoop().RunUntilIdle();
  }

  // The path to temporary directory used to contain the test operations.
  base::ScopedTempDir temp_dir_;
  // The path to the directory where the test data is stored.
  base::FilePath data_dir_;
  // A message loop that we can use as the file thread message loop.
  MessageLoop message_loop_;

 private:
  // Ensure histograms are reset for each test.
  StatisticsRecorder statistics_recorder_;
};

// Test fallback behavior for a nonexistent file.
TEST_F(JsonPrefStoreTest, NonExistentFile) {
  base::FilePath bogus_input_file = temp_dir_.path().AppendASCII("read.txt");
  ASSERT_FALSE(PathExists(bogus_input_file));
  scoped_refptr<JsonPrefStore> pref_store = new JsonPrefStore(
      bogus_input_file, message_loop_.task_runner(), scoped_ptr<PrefFilter>());
  EXPECT_EQ(PersistentPrefStore::PREF_READ_ERROR_NO_FILE,
            pref_store->ReadPrefs());
  EXPECT_FALSE(pref_store->ReadOnly());
}

// Test fallback behavior for a nonexistent file and alternate file.
TEST_F(JsonPrefStoreTest, NonExistentFileAndAlternateFile) {
  base::FilePath bogus_input_file = temp_dir_.path().AppendASCII("read.txt");
  base::FilePath bogus_alternate_input_file =
      temp_dir_.path().AppendASCII("read_alternate.txt");
  ASSERT_FALSE(PathExists(bogus_input_file));
  ASSERT_FALSE(PathExists(bogus_alternate_input_file));
  scoped_refptr<JsonPrefStore> pref_store =
      new JsonPrefStore(bogus_input_file, bogus_alternate_input_file,
                        message_loop_.task_runner(), scoped_ptr<PrefFilter>());
  EXPECT_EQ(PersistentPrefStore::PREF_READ_ERROR_NO_FILE,
            pref_store->ReadPrefs());
  EXPECT_FALSE(pref_store->ReadOnly());
}

// Test fallback behavior for an invalid file.
TEST_F(JsonPrefStoreTest, InvalidFile) {
  base::FilePath invalid_file_original = data_dir_.AppendASCII("invalid.json");
  base::FilePath invalid_file = temp_dir_.path().AppendASCII("invalid.json");
  ASSERT_TRUE(base::CopyFile(invalid_file_original, invalid_file));
  scoped_refptr<JsonPrefStore> pref_store = new JsonPrefStore(
      invalid_file, message_loop_.task_runner(), scoped_ptr<PrefFilter>());
  EXPECT_EQ(PersistentPrefStore::PREF_READ_ERROR_JSON_PARSE,
            pref_store->ReadPrefs());
  EXPECT_FALSE(pref_store->ReadOnly());

  // The file should have been moved aside.
  EXPECT_FALSE(PathExists(invalid_file));
  base::FilePath moved_aside = temp_dir_.path().AppendASCII("invalid.bad");
  EXPECT_TRUE(PathExists(moved_aside));
  EXPECT_TRUE(TextContentsEqual(invalid_file_original, moved_aside));
}

// This function is used to avoid code duplication while testing synchronous and
// asynchronous version of the JsonPrefStore loading.
void RunBasicJsonPrefStoreTest(JsonPrefStore* pref_store,
                               const base::FilePath& output_file,
                               const base::FilePath& golden_output_file) {
  const char kNewWindowsInTabs[] = "tabs.new_windows_in_tabs";
  const char kMaxTabs[] = "tabs.max_tabs";
  const char kLongIntPref[] = "long_int.pref";

  std::string cnn("http://www.cnn.com");

  const Value* actual;
  EXPECT_TRUE(pref_store->GetValue(kHomePage, &actual));
  std::string string_value;
  EXPECT_TRUE(actual->GetAsString(&string_value));
  EXPECT_EQ(cnn, string_value);

  const char kSomeDirectory[] = "some_directory";

  EXPECT_TRUE(pref_store->GetValue(kSomeDirectory, &actual));
  base::FilePath::StringType path;
  EXPECT_TRUE(actual->GetAsString(&path));
  EXPECT_EQ(base::FilePath::StringType(FILE_PATH_LITERAL("/usr/local/")), path);
  base::FilePath some_path(FILE_PATH_LITERAL("/usr/sbin/"));

  pref_store->SetValue(kSomeDirectory,
                       make_scoped_ptr(new StringValue(some_path.value())),
                       WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  EXPECT_TRUE(pref_store->GetValue(kSomeDirectory, &actual));
  EXPECT_TRUE(actual->GetAsString(&path));
  EXPECT_EQ(some_path.value(), path);

  // Test reading some other data types from sub-dictionaries.
  EXPECT_TRUE(pref_store->GetValue(kNewWindowsInTabs, &actual));
  bool boolean = false;
  EXPECT_TRUE(actual->GetAsBoolean(&boolean));
  EXPECT_TRUE(boolean);

  pref_store->SetValue(kNewWindowsInTabs,
                       make_scoped_ptr(new FundamentalValue(false)),
                       WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  EXPECT_TRUE(pref_store->GetValue(kNewWindowsInTabs, &actual));
  EXPECT_TRUE(actual->GetAsBoolean(&boolean));
  EXPECT_FALSE(boolean);

  EXPECT_TRUE(pref_store->GetValue(kMaxTabs, &actual));
  int integer = 0;
  EXPECT_TRUE(actual->GetAsInteger(&integer));
  EXPECT_EQ(20, integer);
  pref_store->SetValue(kMaxTabs, make_scoped_ptr(new FundamentalValue(10)),
                       WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  EXPECT_TRUE(pref_store->GetValue(kMaxTabs, &actual));
  EXPECT_TRUE(actual->GetAsInteger(&integer));
  EXPECT_EQ(10, integer);

  pref_store->SetValue(
      kLongIntPref,
      make_scoped_ptr(new StringValue(base::Int64ToString(214748364842LL))),
      WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  EXPECT_TRUE(pref_store->GetValue(kLongIntPref, &actual));
  EXPECT_TRUE(actual->GetAsString(&string_value));
  int64 value;
  base::StringToInt64(string_value, &value);
  EXPECT_EQ(214748364842LL, value);

  // Serialize and compare to expected output.
  ASSERT_TRUE(PathExists(golden_output_file));
  pref_store->CommitPendingWrite();
  RunLoop().RunUntilIdle();
  EXPECT_TRUE(TextContentsEqual(golden_output_file, output_file));
  ASSERT_TRUE(base::DeleteFile(output_file, false));
}

TEST_F(JsonPrefStoreTest, Basic) {
  ASSERT_TRUE(base::CopyFile(data_dir_.AppendASCII("read.json"),
                             temp_dir_.path().AppendASCII("write.json")));

  // Test that the persistent value can be loaded.
  base::FilePath input_file = temp_dir_.path().AppendASCII("write.json");
  ASSERT_TRUE(PathExists(input_file));
  scoped_refptr<JsonPrefStore> pref_store = new JsonPrefStore(
      input_file, message_loop_.task_runner(), scoped_ptr<PrefFilter>());
  ASSERT_EQ(PersistentPrefStore::PREF_READ_ERROR_NONE, pref_store->ReadPrefs());
  EXPECT_FALSE(pref_store->ReadOnly());
  EXPECT_TRUE(pref_store->IsInitializationComplete());

  // The JSON file looks like this:
  // {
  //   "homepage": "http://www.cnn.com",
  //   "some_directory": "/usr/local/",
  //   "tabs": {
  //     "new_windows_in_tabs": true,
  //     "max_tabs": 20
  //   }
  // }

  RunBasicJsonPrefStoreTest(
      pref_store.get(), input_file, data_dir_.AppendASCII("write.golden.json"));
}

TEST_F(JsonPrefStoreTest, BasicAsync) {
  ASSERT_TRUE(base::CopyFile(data_dir_.AppendASCII("read.json"),
                             temp_dir_.path().AppendASCII("write.json")));

  // Test that the persistent value can be loaded.
  base::FilePath input_file = temp_dir_.path().AppendASCII("write.json");
  ASSERT_TRUE(PathExists(input_file));
  scoped_refptr<JsonPrefStore> pref_store = new JsonPrefStore(
      input_file, message_loop_.task_runner(), scoped_ptr<PrefFilter>());

  {
    MockPrefStoreObserver mock_observer;
    pref_store->AddObserver(&mock_observer);

    MockReadErrorDelegate* mock_error_delegate = new MockReadErrorDelegate;
    pref_store->ReadPrefsAsync(mock_error_delegate);

    EXPECT_CALL(mock_observer, OnInitializationCompleted(true)).Times(1);
    EXPECT_CALL(*mock_error_delegate,
                OnError(PersistentPrefStore::PREF_READ_ERROR_NONE)).Times(0);
    RunLoop().RunUntilIdle();
    pref_store->RemoveObserver(&mock_observer);

    EXPECT_FALSE(pref_store->ReadOnly());
    EXPECT_TRUE(pref_store->IsInitializationComplete());
  }

  // The JSON file looks like this:
  // {
  //   "homepage": "http://www.cnn.com",
  //   "some_directory": "/usr/local/",
  //   "tabs": {
  //     "new_windows_in_tabs": true,
  //     "max_tabs": 20
  //   }
  // }

  RunBasicJsonPrefStoreTest(
      pref_store.get(), input_file, data_dir_.AppendASCII("write.golden.json"));
}

TEST_F(JsonPrefStoreTest, PreserveEmptyValues) {
  FilePath pref_file = temp_dir_.path().AppendASCII("empty_values.json");

  scoped_refptr<JsonPrefStore> pref_store = new JsonPrefStore(
      pref_file, message_loop_.task_runner(), scoped_ptr<PrefFilter>());

  // Set some keys with empty values.
  pref_store->SetValue("list", make_scoped_ptr(new base::ListValue),
                       WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  pref_store->SetValue("dict", make_scoped_ptr(new base::DictionaryValue),
                       WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);

  // Write to file.
  pref_store->CommitPendingWrite();
  RunLoop().RunUntilIdle();

  // Reload.
  pref_store = new JsonPrefStore(pref_file, message_loop_.task_runner(),
                                 scoped_ptr<PrefFilter>());
  ASSERT_EQ(PersistentPrefStore::PREF_READ_ERROR_NONE, pref_store->ReadPrefs());
  ASSERT_FALSE(pref_store->ReadOnly());

  // Check values.
  const Value* result = NULL;
  EXPECT_TRUE(pref_store->GetValue("list", &result));
  EXPECT_TRUE(ListValue().Equals(result));
  EXPECT_TRUE(pref_store->GetValue("dict", &result));
  EXPECT_TRUE(DictionaryValue().Equals(result));
}

// This test is just documenting some potentially non-obvious behavior. It
// shouldn't be taken as normative.
TEST_F(JsonPrefStoreTest, RemoveClearsEmptyParent) {
  FilePath pref_file = temp_dir_.path().AppendASCII("empty_values.json");

  scoped_refptr<JsonPrefStore> pref_store = new JsonPrefStore(
      pref_file, message_loop_.task_runner(), scoped_ptr<PrefFilter>());

  scoped_ptr<base::DictionaryValue> dict(new base::DictionaryValue);
  dict->SetString("key", "value");
  pref_store->SetValue("dict", dict.Pass(),
                       WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);

  pref_store->RemoveValue("dict.key",
                          WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);

  const base::Value* retrieved_dict = NULL;
  bool has_dict = pref_store->GetValue("dict", &retrieved_dict);
  EXPECT_FALSE(has_dict);
}

// Tests asynchronous reading of the file when there is no file.
TEST_F(JsonPrefStoreTest, AsyncNonExistingFile) {
  base::FilePath bogus_input_file = temp_dir_.path().AppendASCII("read.txt");
  ASSERT_FALSE(PathExists(bogus_input_file));
  scoped_refptr<JsonPrefStore> pref_store = new JsonPrefStore(
      bogus_input_file, message_loop_.task_runner(), scoped_ptr<PrefFilter>());
  MockPrefStoreObserver mock_observer;
  pref_store->AddObserver(&mock_observer);

  MockReadErrorDelegate *mock_error_delegate = new MockReadErrorDelegate;
  pref_store->ReadPrefsAsync(mock_error_delegate);

  EXPECT_CALL(mock_observer, OnInitializationCompleted(true)).Times(1);
  EXPECT_CALL(*mock_error_delegate,
              OnError(PersistentPrefStore::PREF_READ_ERROR_NO_FILE)).Times(1);
  RunLoop().RunUntilIdle();
  pref_store->RemoveObserver(&mock_observer);

  EXPECT_FALSE(pref_store->ReadOnly());
}

TEST_F(JsonPrefStoreTest, ReadWithInterceptor) {
  ASSERT_TRUE(base::CopyFile(data_dir_.AppendASCII("read.json"),
                             temp_dir_.path().AppendASCII("write.json")));

  // Test that the persistent value can be loaded.
  base::FilePath input_file = temp_dir_.path().AppendASCII("write.json");
  ASSERT_TRUE(PathExists(input_file));

  scoped_ptr<InterceptingPrefFilter> intercepting_pref_filter(
      new InterceptingPrefFilter());
  InterceptingPrefFilter* raw_intercepting_pref_filter_ =
      intercepting_pref_filter.get();
  scoped_refptr<JsonPrefStore> pref_store = new JsonPrefStore(
      input_file, message_loop_.task_runner(), intercepting_pref_filter.Pass());

  ASSERT_EQ(PersistentPrefStore::PREF_READ_ERROR_ASYNCHRONOUS_TASK_INCOMPLETE,
            pref_store->ReadPrefs());
  EXPECT_FALSE(pref_store->ReadOnly());

  // The store shouldn't be considered initialized until the interceptor
  // returns.
  EXPECT_TRUE(raw_intercepting_pref_filter_->has_intercepted_prefs());
  EXPECT_FALSE(pref_store->IsInitializationComplete());
  EXPECT_FALSE(pref_store->GetValue(kHomePage, NULL));

  raw_intercepting_pref_filter_->ReleasePrefs();

  EXPECT_FALSE(raw_intercepting_pref_filter_->has_intercepted_prefs());
  EXPECT_TRUE(pref_store->IsInitializationComplete());
  EXPECT_TRUE(pref_store->GetValue(kHomePage, NULL));

  // The JSON file looks like this:
  // {
  //   "homepage": "http://www.cnn.com",
  //   "some_directory": "/usr/local/",
  //   "tabs": {
  //     "new_windows_in_tabs": true,
  //     "max_tabs": 20
  //   }
  // }

  RunBasicJsonPrefStoreTest(
      pref_store.get(), input_file, data_dir_.AppendASCII("write.golden.json"));
}

TEST_F(JsonPrefStoreTest, ReadAsyncWithInterceptor) {
  ASSERT_TRUE(base::CopyFile(data_dir_.AppendASCII("read.json"),
                             temp_dir_.path().AppendASCII("write.json")));

  // Test that the persistent value can be loaded.
  base::FilePath input_file = temp_dir_.path().AppendASCII("write.json");
  ASSERT_TRUE(PathExists(input_file));

  scoped_ptr<InterceptingPrefFilter> intercepting_pref_filter(
      new InterceptingPrefFilter());
  InterceptingPrefFilter* raw_intercepting_pref_filter_ =
      intercepting_pref_filter.get();
  scoped_refptr<JsonPrefStore> pref_store = new JsonPrefStore(
      input_file, message_loop_.task_runner(), intercepting_pref_filter.Pass());

  MockPrefStoreObserver mock_observer;
  pref_store->AddObserver(&mock_observer);

  // Ownership of the |mock_error_delegate| is handed to the |pref_store| below.
  MockReadErrorDelegate* mock_error_delegate = new MockReadErrorDelegate;

  {
    pref_store->ReadPrefsAsync(mock_error_delegate);

    EXPECT_CALL(mock_observer, OnInitializationCompleted(true)).Times(0);
    // EXPECT_CALL(*mock_error_delegate,
    //             OnError(PersistentPrefStore::PREF_READ_ERROR_NONE)).Times(0);
    RunLoop().RunUntilIdle();

    EXPECT_FALSE(pref_store->ReadOnly());
    EXPECT_TRUE(raw_intercepting_pref_filter_->has_intercepted_prefs());
    EXPECT_FALSE(pref_store->IsInitializationComplete());
    EXPECT_FALSE(pref_store->GetValue(kHomePage, NULL));
  }

  {
    EXPECT_CALL(mock_observer, OnInitializationCompleted(true)).Times(1);
    // EXPECT_CALL(*mock_error_delegate,
    //             OnError(PersistentPrefStore::PREF_READ_ERROR_NONE)).Times(0);

    raw_intercepting_pref_filter_->ReleasePrefs();

    EXPECT_FALSE(pref_store->ReadOnly());
    EXPECT_FALSE(raw_intercepting_pref_filter_->has_intercepted_prefs());
    EXPECT_TRUE(pref_store->IsInitializationComplete());
    EXPECT_TRUE(pref_store->GetValue(kHomePage, NULL));
  }

  pref_store->RemoveObserver(&mock_observer);

  // The JSON file looks like this:
  // {
  //   "homepage": "http://www.cnn.com",
  //   "some_directory": "/usr/local/",
  //   "tabs": {
  //     "new_windows_in_tabs": true,
  //     "max_tabs": 20
  //   }
  // }

  RunBasicJsonPrefStoreTest(
      pref_store.get(), input_file, data_dir_.AppendASCII("write.golden.json"));
}

TEST_F(JsonPrefStoreTest, AlternateFile) {
  ASSERT_TRUE(
      base::CopyFile(data_dir_.AppendASCII("read.json"),
                     temp_dir_.path().AppendASCII("alternate.json")));

  // Test that the alternate file is moved to the main file and read as-is from
  // there.
  base::FilePath input_file = temp_dir_.path().AppendASCII("write.json");
  base::FilePath alternate_input_file =
      temp_dir_.path().AppendASCII("alternate.json");
  ASSERT_FALSE(PathExists(input_file));
  ASSERT_TRUE(PathExists(alternate_input_file));
  scoped_refptr<JsonPrefStore> pref_store =
      new JsonPrefStore(input_file, alternate_input_file,
                        message_loop_.task_runner(), scoped_ptr<PrefFilter>());

  ASSERT_FALSE(PathExists(input_file));
  ASSERT_TRUE(PathExists(alternate_input_file));
  ASSERT_EQ(PersistentPrefStore::PREF_READ_ERROR_NONE, pref_store->ReadPrefs());

  ASSERT_TRUE(PathExists(input_file));
  ASSERT_FALSE(PathExists(alternate_input_file));

  EXPECT_FALSE(pref_store->ReadOnly());
  EXPECT_TRUE(pref_store->IsInitializationComplete());

  // The JSON file looks like this:
  // {
  //   "homepage": "http://www.cnn.com",
  //   "some_directory": "/usr/local/",
  //   "tabs": {
  //     "new_windows_in_tabs": true,
  //     "max_tabs": 20
  //   }
  // }

  RunBasicJsonPrefStoreTest(
      pref_store.get(), input_file, data_dir_.AppendASCII("write.golden.json"));
}

TEST_F(JsonPrefStoreTest, AlternateFileIgnoredWhenMainFileExists) {
  ASSERT_TRUE(
      base::CopyFile(data_dir_.AppendASCII("read.json"),
                     temp_dir_.path().AppendASCII("write.json")));
  ASSERT_TRUE(
      base::CopyFile(data_dir_.AppendASCII("invalid.json"),
                     temp_dir_.path().AppendASCII("alternate.json")));

  // Test that the alternate file is ignored and that the read occurs from the
  // existing main file. There is no attempt at even deleting the alternate
  // file as this scenario should never happen in normal user-data-dirs.
  base::FilePath input_file = temp_dir_.path().AppendASCII("write.json");
  base::FilePath alternate_input_file =
      temp_dir_.path().AppendASCII("alternate.json");
  ASSERT_TRUE(PathExists(input_file));
  ASSERT_TRUE(PathExists(alternate_input_file));
  scoped_refptr<JsonPrefStore> pref_store =
      new JsonPrefStore(input_file, alternate_input_file,
                        message_loop_.task_runner(), scoped_ptr<PrefFilter>());

  ASSERT_TRUE(PathExists(input_file));
  ASSERT_TRUE(PathExists(alternate_input_file));
  ASSERT_EQ(PersistentPrefStore::PREF_READ_ERROR_NONE, pref_store->ReadPrefs());

  ASSERT_TRUE(PathExists(input_file));
  ASSERT_TRUE(PathExists(alternate_input_file));

  EXPECT_FALSE(pref_store->ReadOnly());
  EXPECT_TRUE(pref_store->IsInitializationComplete());

  // The JSON file looks like this:
  // {
  //   "homepage": "http://www.cnn.com",
  //   "some_directory": "/usr/local/",
  //   "tabs": {
  //     "new_windows_in_tabs": true,
  //     "max_tabs": 20
  //   }
  // }

  RunBasicJsonPrefStoreTest(
      pref_store.get(), input_file, data_dir_.AppendASCII("write.golden.json"));
}

TEST_F(JsonPrefStoreTest, AlternateFileDNE) {
  ASSERT_TRUE(
      base::CopyFile(data_dir_.AppendASCII("read.json"),
                     temp_dir_.path().AppendASCII("write.json")));

  // Test that the basic read works fine when an alternate file is specified but
  // does not exist.
  base::FilePath input_file = temp_dir_.path().AppendASCII("write.json");
  base::FilePath alternate_input_file =
      temp_dir_.path().AppendASCII("alternate.json");
  ASSERT_TRUE(PathExists(input_file));
  ASSERT_FALSE(PathExists(alternate_input_file));
  scoped_refptr<JsonPrefStore> pref_store =
      new JsonPrefStore(input_file, alternate_input_file,
                        message_loop_.task_runner(), scoped_ptr<PrefFilter>());

  ASSERT_TRUE(PathExists(input_file));
  ASSERT_FALSE(PathExists(alternate_input_file));
  ASSERT_EQ(PersistentPrefStore::PREF_READ_ERROR_NONE, pref_store->ReadPrefs());

  ASSERT_TRUE(PathExists(input_file));
  ASSERT_FALSE(PathExists(alternate_input_file));

  EXPECT_FALSE(pref_store->ReadOnly());
  EXPECT_TRUE(pref_store->IsInitializationComplete());

  // The JSON file looks like this:
  // {
  //   "homepage": "http://www.cnn.com",
  //   "some_directory": "/usr/local/",
  //   "tabs": {
  //     "new_windows_in_tabs": true,
  //     "max_tabs": 20
  //   }
  // }

  RunBasicJsonPrefStoreTest(
      pref_store.get(), input_file, data_dir_.AppendASCII("write.golden.json"));
}

TEST_F(JsonPrefStoreTest, BasicAsyncWithAlternateFile) {
  ASSERT_TRUE(
      base::CopyFile(data_dir_.AppendASCII("read.json"),
                     temp_dir_.path().AppendASCII("alternate.json")));

  // Test that the alternate file is moved to the main file and read as-is from
  // there even when the read is made asynchronously.
  base::FilePath input_file = temp_dir_.path().AppendASCII("write.json");
  base::FilePath alternate_input_file =
      temp_dir_.path().AppendASCII("alternate.json");
  ASSERT_FALSE(PathExists(input_file));
  ASSERT_TRUE(PathExists(alternate_input_file));
  scoped_refptr<JsonPrefStore> pref_store =
      new JsonPrefStore(input_file, alternate_input_file,
                        message_loop_.task_runner(), scoped_ptr<PrefFilter>());

  ASSERT_FALSE(PathExists(input_file));
  ASSERT_TRUE(PathExists(alternate_input_file));

  {
    MockPrefStoreObserver mock_observer;
    pref_store->AddObserver(&mock_observer);

    MockReadErrorDelegate* mock_error_delegate = new MockReadErrorDelegate;
    pref_store->ReadPrefsAsync(mock_error_delegate);

    EXPECT_CALL(mock_observer, OnInitializationCompleted(true)).Times(1);
    EXPECT_CALL(*mock_error_delegate,
                OnError(PersistentPrefStore::PREF_READ_ERROR_NONE)).Times(0);
    RunLoop().RunUntilIdle();
    pref_store->RemoveObserver(&mock_observer);

    EXPECT_FALSE(pref_store->ReadOnly());
    EXPECT_TRUE(pref_store->IsInitializationComplete());
  }

  ASSERT_TRUE(PathExists(input_file));
  ASSERT_FALSE(PathExists(alternate_input_file));

  // The JSON file looks like this:
  // {
  //   "homepage": "http://www.cnn.com",
  //   "some_directory": "/usr/local/",
  //   "tabs": {
  //     "new_windows_in_tabs": true,
  //     "max_tabs": 20
  //   }
  // }

  RunBasicJsonPrefStoreTest(
      pref_store.get(), input_file, data_dir_.AppendASCII("write.golden.json"));
}

TEST_F(JsonPrefStoreTest, WriteCountHistogramTestBasic) {
  SimpleTestClock* test_clock = new SimpleTestClock;
  SetCurrentTimeInMinutes(0, test_clock);
  JsonPrefStore::WriteCountHistogram histogram(
      base::TimeDelta::FromSeconds(10),
      base::FilePath(FILE_PATH_LITERAL("/tmp/Local State")),
      scoped_ptr<base::Clock>(test_clock));
  int32 report_interval =
      JsonPrefStore::WriteCountHistogram::kHistogramWriteReportIntervalMins;

  histogram.RecordWriteOccured();

  SetCurrentTimeInMinutes(1.5 * report_interval, test_clock);
  histogram.ReportOutstandingWrites();
  scoped_ptr<HistogramSamples> samples =
      histogram.GetHistogram()->SnapshotSamples();
  ASSERT_EQ(1, samples->GetCount(1));
  ASSERT_EQ(1, samples->TotalCount());

  ASSERT_EQ("Settings.JsonDataWriteCount.Local_State",
            histogram.GetHistogram()->histogram_name());
  ASSERT_TRUE(histogram.GetHistogram()->HasConstructionArguments(1, 30, 31));
}

TEST_F(JsonPrefStoreTest, WriteCountHistogramTestSinglePeriod) {
  SimpleTestClock* test_clock = new SimpleTestClock;
  SetCurrentTimeInMinutes(0, test_clock);
  JsonPrefStore::WriteCountHistogram histogram(
      base::TimeDelta::FromSeconds(10),
      base::FilePath(FILE_PATH_LITERAL("/tmp/Local State")),
      scoped_ptr<base::Clock>(test_clock));
  int32 report_interval =
      JsonPrefStore::WriteCountHistogram::kHistogramWriteReportIntervalMins;

  histogram.RecordWriteOccured();
  SetCurrentTimeInMinutes(0.5 * report_interval, test_clock);
  histogram.RecordWriteOccured();
  SetCurrentTimeInMinutes(0.7 * report_interval, test_clock);
  histogram.RecordWriteOccured();

  // Nothing should be recorded until the report period has elapsed.
  scoped_ptr<HistogramSamples> samples =
      histogram.GetHistogram()->SnapshotSamples();
  ASSERT_EQ(0, samples->TotalCount());

  SetCurrentTimeInMinutes(1.3 * report_interval, test_clock);
  histogram.RecordWriteOccured();

  // Now the report period has elapsed.
  samples = histogram.GetHistogram()->SnapshotSamples();
  ASSERT_EQ(1, samples->GetCount(3));
  ASSERT_EQ(1, samples->TotalCount());

  // The last write won't be recorded because the second count period hasn't
  // fully elapsed.
  SetCurrentTimeInMinutes(1.5 * report_interval, test_clock);
  histogram.ReportOutstandingWrites();

  samples = histogram.GetHistogram()->SnapshotSamples();
  ASSERT_EQ(1, samples->GetCount(3));
  ASSERT_EQ(1, samples->TotalCount());
}

TEST_F(JsonPrefStoreTest, WriteCountHistogramTestMultiplePeriods) {
  SimpleTestClock* test_clock = new SimpleTestClock;
  SetCurrentTimeInMinutes(0, test_clock);
  JsonPrefStore::WriteCountHistogram histogram(
      base::TimeDelta::FromSeconds(10),
      base::FilePath(FILE_PATH_LITERAL("/tmp/Local State")),
      scoped_ptr<base::Clock>(test_clock));
  int32 report_interval =
      JsonPrefStore::WriteCountHistogram::kHistogramWriteReportIntervalMins;

  histogram.RecordWriteOccured();
  SetCurrentTimeInMinutes(0.5 * report_interval, test_clock);
  histogram.RecordWriteOccured();
  SetCurrentTimeInMinutes(0.7 * report_interval, test_clock);
  histogram.RecordWriteOccured();
  SetCurrentTimeInMinutes(1.3 * report_interval, test_clock);
  histogram.RecordWriteOccured();
  SetCurrentTimeInMinutes(1.5 * report_interval, test_clock);
  histogram.RecordWriteOccured();
  SetCurrentTimeInMinutes(2.1 * report_interval, test_clock);
  histogram.RecordWriteOccured();
  SetCurrentTimeInMinutes(2.5 * report_interval, test_clock);
  histogram.RecordWriteOccured();
  SetCurrentTimeInMinutes(2.7 * report_interval, test_clock);
  histogram.RecordWriteOccured();
  SetCurrentTimeInMinutes(3.3 * report_interval, test_clock);
  histogram.RecordWriteOccured();

  // The last write won't be recorded because the second count period hasn't
  // fully elapsed
  SetCurrentTimeInMinutes(3.5 * report_interval, test_clock);
  histogram.ReportOutstandingWrites();
  scoped_ptr<HistogramSamples> samples =
      histogram.GetHistogram()->SnapshotSamples();
  ASSERT_EQ(2, samples->GetCount(3));
  ASSERT_EQ(1, samples->GetCount(2));
  ASSERT_EQ(3, samples->TotalCount());
}

TEST_F(JsonPrefStoreTest, WriteCountHistogramTestPeriodWithGaps) {
  SimpleTestClock* test_clock = new SimpleTestClock;
  SetCurrentTimeInMinutes(0, test_clock);
  JsonPrefStore::WriteCountHistogram histogram(
      base::TimeDelta::FromSeconds(10),
      base::FilePath(FILE_PATH_LITERAL("/tmp/Local State")),
      scoped_ptr<base::Clock>(test_clock));
  int32 report_interval =
      JsonPrefStore::WriteCountHistogram::kHistogramWriteReportIntervalMins;

  // 1 write in the first period.
  histogram.RecordWriteOccured();

  // No writes in the second and third periods.

  // 2 writes in the fourth period.
  SetCurrentTimeInMinutes(3.1 * report_interval, test_clock);
  histogram.RecordWriteOccured();
  SetCurrentTimeInMinutes(3.3 * report_interval, test_clock);
  histogram.RecordWriteOccured();

  // No writes in the fifth period.

  // 3 writes in the sixth period.
  SetCurrentTimeInMinutes(5.1 * report_interval, test_clock);
  histogram.RecordWriteOccured();
  SetCurrentTimeInMinutes(5.3 * report_interval, test_clock);
  histogram.RecordWriteOccured();
  SetCurrentTimeInMinutes(5.5 * report_interval, test_clock);
  histogram.RecordWriteOccured();

  SetCurrentTimeInMinutes(6.1 * report_interval, test_clock);
  histogram.ReportOutstandingWrites();
  scoped_ptr<HistogramSamples> samples =
      histogram.GetHistogram()->SnapshotSamples();
  ASSERT_EQ(3, samples->GetCount(0));
  ASSERT_EQ(1, samples->GetCount(1));
  ASSERT_EQ(1, samples->GetCount(2));
  ASSERT_EQ(1, samples->GetCount(3));
  ASSERT_EQ(6, samples->TotalCount());
}

class JsonPrefStoreLossyWriteTest : public JsonPrefStoreTest {
 protected:
  void SetUp() override {
    JsonPrefStoreTest::SetUp();
    test_file_ = temp_dir_.path().AppendASCII("test.json");
  }

  // Creates a JsonPrefStore with the given |file_writer|.
  scoped_refptr<JsonPrefStore> CreatePrefStore() {
    return new JsonPrefStore(test_file_, message_loop_.task_runner(),
                             scoped_ptr<PrefFilter>());
  }

  // Return the ImportantFileWriter for a given JsonPrefStore.
  ImportantFileWriter* GetImportantFileWriter(
      scoped_refptr<JsonPrefStore> pref_store) {
    return &(pref_store->writer_);
  }

  // Get the contents of kTestFile. Pumps the message loop before returning the
  // result.
  std::string GetTestFileContents() {
    RunLoop().RunUntilIdle();
    std::string file_contents;
    ReadFileToString(test_file_, &file_contents);
    return file_contents;
  }

 private:
  base::FilePath test_file_;
};

TEST_F(JsonPrefStoreLossyWriteTest, LossyWriteBasic) {
  scoped_refptr<JsonPrefStore> pref_store = CreatePrefStore();
  ImportantFileWriter* file_writer = GetImportantFileWriter(pref_store);

  // Set a normal pref and check that it gets scheduled to be written.
  ASSERT_FALSE(file_writer->HasPendingWrite());
  pref_store->SetValue("normal",
                       make_scoped_ptr(new base::StringValue("normal")),
                       WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  ASSERT_TRUE(file_writer->HasPendingWrite());
  file_writer->DoScheduledWrite();
  ASSERT_EQ("{\"normal\":\"normal\"}", GetTestFileContents());
  ASSERT_FALSE(file_writer->HasPendingWrite());

  // Set a lossy pref and check that it is not scheduled to be written.
  // SetValue/RemoveValue.
  pref_store->SetValue("lossy", make_scoped_ptr(new base::StringValue("lossy")),
                       WriteablePrefStore::LOSSY_PREF_WRITE_FLAG);
  ASSERT_FALSE(file_writer->HasPendingWrite());
  pref_store->RemoveValue("lossy", WriteablePrefStore::LOSSY_PREF_WRITE_FLAG);
  ASSERT_FALSE(file_writer->HasPendingWrite());

  // SetValueSilently/RemoveValueSilently.
  pref_store->SetValueSilently("lossy",
                               make_scoped_ptr(new base::StringValue("lossy")),
                               WriteablePrefStore::LOSSY_PREF_WRITE_FLAG);
  ASSERT_FALSE(file_writer->HasPendingWrite());
  pref_store->RemoveValueSilently("lossy",
                                  WriteablePrefStore::LOSSY_PREF_WRITE_FLAG);
  ASSERT_FALSE(file_writer->HasPendingWrite());

  // ReportValueChanged.
  pref_store->SetValue("lossy", make_scoped_ptr(new base::StringValue("lossy")),
                       WriteablePrefStore::LOSSY_PREF_WRITE_FLAG);
  ASSERT_FALSE(file_writer->HasPendingWrite());
  pref_store->ReportValueChanged("lossy",
                                 WriteablePrefStore::LOSSY_PREF_WRITE_FLAG);
  ASSERT_FALSE(file_writer->HasPendingWrite());

  // Call CommitPendingWrite and check that the lossy pref and the normal pref
  // are there with the last values set above.
  pref_store->CommitPendingWrite();
  ASSERT_FALSE(file_writer->HasPendingWrite());
  ASSERT_EQ("{\"lossy\":\"lossy\",\"normal\":\"normal\"}",
            GetTestFileContents());
}

TEST_F(JsonPrefStoreLossyWriteTest, LossyWriteMixedLossyFirst) {
  scoped_refptr<JsonPrefStore> pref_store = CreatePrefStore();
  ImportantFileWriter* file_writer = GetImportantFileWriter(pref_store);

  // Set a lossy pref and check that it is not scheduled to be written.
  ASSERT_FALSE(file_writer->HasPendingWrite());
  pref_store->SetValue("lossy", make_scoped_ptr(new base::StringValue("lossy")),
                       WriteablePrefStore::LOSSY_PREF_WRITE_FLAG);
  ASSERT_FALSE(file_writer->HasPendingWrite());

  // Set a normal pref and check that it is scheduled to be written.
  pref_store->SetValue("normal",
                       make_scoped_ptr(new base::StringValue("normal")),
                       WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  ASSERT_TRUE(file_writer->HasPendingWrite());

  // Call DoScheduledWrite and check both prefs get written.
  file_writer->DoScheduledWrite();
  ASSERT_EQ("{\"lossy\":\"lossy\",\"normal\":\"normal\"}",
            GetTestFileContents());
  ASSERT_FALSE(file_writer->HasPendingWrite());
}

TEST_F(JsonPrefStoreLossyWriteTest, LossyWriteMixedLossySecond) {
  scoped_refptr<JsonPrefStore> pref_store = CreatePrefStore();
  ImportantFileWriter* file_writer = GetImportantFileWriter(pref_store);

  // Set a normal pref and check that it is scheduled to be written.
  ASSERT_FALSE(file_writer->HasPendingWrite());
  pref_store->SetValue("normal",
                       make_scoped_ptr(new base::StringValue("normal")),
                       WriteablePrefStore::DEFAULT_PREF_WRITE_FLAGS);
  ASSERT_TRUE(file_writer->HasPendingWrite());

  // Set a lossy pref and check that the write is still scheduled.
  pref_store->SetValue("lossy", make_scoped_ptr(new base::StringValue("lossy")),
                       WriteablePrefStore::LOSSY_PREF_WRITE_FLAG);
  ASSERT_TRUE(file_writer->HasPendingWrite());

  // Call DoScheduledWrite and check both prefs get written.
  file_writer->DoScheduledWrite();
  ASSERT_EQ("{\"lossy\":\"lossy\",\"normal\":\"normal\"}",
            GetTestFileContents());
  ASSERT_FALSE(file_writer->HasPendingWrite());
}

TEST_F(JsonPrefStoreLossyWriteTest, ScheduleLossyWrite) {
  scoped_refptr<JsonPrefStore> pref_store = CreatePrefStore();
  ImportantFileWriter* file_writer = GetImportantFileWriter(pref_store);

  // Set a lossy pref and check that it is not scheduled to be written.
  pref_store->SetValue("lossy", make_scoped_ptr(new base::StringValue("lossy")),
                       WriteablePrefStore::LOSSY_PREF_WRITE_FLAG);
  ASSERT_FALSE(file_writer->HasPendingWrite());

  // Schedule pending lossy writes and check that it is scheduled.
  pref_store->SchedulePendingLossyWrites();
  ASSERT_TRUE(file_writer->HasPendingWrite());

  // Call CommitPendingWrite and check that the lossy pref is there with the
  // last value set above.
  pref_store->CommitPendingWrite();
  ASSERT_FALSE(file_writer->HasPendingWrite());
  ASSERT_EQ("{\"lossy\":\"lossy\"}", GetTestFileContents());
}

}  // namespace base
