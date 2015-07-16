// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <map>
#include <set>

#include "base/bind.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder_mock.h"
#include "gpu/command_buffer/service/gpu_service_test.h"
#include "gpu/command_buffer/service/gpu_tracer.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_mock.h"
#include "ui/gl/gpu_timing.h"

namespace gpu {
namespace gles2 {
namespace {

using ::testing::_;
using ::testing::AtLeast;
using ::testing::AtMost;
using ::testing::Exactly;
using ::testing::Invoke;
using ::testing::NotNull;
using ::testing::Return;

int64 g_fakeCPUTime = 0;
int64 FakeCpuTime() {
  return g_fakeCPUTime;
}

class MockOutputter : public Outputter {
 public:
  MockOutputter() {}
  MOCK_METHOD4(TraceDevice,
               void(const std::string& category, const std::string& name,
                    int64 start_time, int64 end_time));

  MOCK_METHOD2(TraceServiceBegin,
               void(const std::string& category, const std::string& name));

  MOCK_METHOD2(TraceServiceEnd,
               void(const std::string& category, const std::string& name));

 protected:
  ~MockOutputter() {}
};

class GlFakeQueries {
 public:
  GlFakeQueries() {}

  void Reset() {
    current_time_ = 0;
    next_query_id_ = 23;
    alloced_queries_.clear();
    query_timestamp_.clear();
  }

  void SetCurrentGLTime(GLint64 current_time) { current_time_ = current_time; }
  void SetDisjoint() { disjointed_ = true; }

  void GenQueries(GLsizei n, GLuint* ids) {
    for (GLsizei i = 0; i < n; i++) {
      ids[i] = next_query_id_++;
      alloced_queries_.insert(ids[i]);
    }
  }

  void DeleteQueries(GLsizei n, const GLuint* ids) {
    for (GLsizei i = 0; i < n; i++) {
      alloced_queries_.erase(ids[i]);
      query_timestamp_.erase(ids[i]);
    }
  }

  void GetQueryObjectiv(GLuint id, GLenum pname, GLint* params) {
    switch (pname) {
      case GL_QUERY_RESULT_AVAILABLE: {
        std::map<GLuint, GLint64>::iterator it = query_timestamp_.find(id);
        if (it != query_timestamp_.end() && it->second <= current_time_)
          *params = 1;
        else
          *params = 0;
        break;
      }
      default:
        FAIL() << "Invalid variable passed to GetQueryObjectiv: " << pname;
    }
  }

  void QueryCounter(GLuint id, GLenum target) {
    switch (target) {
      case GL_TIMESTAMP:
        ASSERT_TRUE(alloced_queries_.find(id) != alloced_queries_.end());
        query_timestamp_[id] = current_time_;
        break;
      default:
        FAIL() << "Invalid variable passed to QueryCounter: " << target;
    }
  }

  void GetInteger64v(GLenum pname, GLint64 * data) {
    switch (pname) {
      case GL_TIMESTAMP:
        *data = current_time_;
        break;
      default:
        FAIL() << "Invalid variable passed to GetInteger64v: " << pname;
    }
  }

  void GetQueryObjectui64v(GLuint id, GLenum pname, GLuint64* params) {
    switch (pname) {
      case GL_QUERY_RESULT:
        ASSERT_TRUE(query_timestamp_.find(id) != query_timestamp_.end());
        *params = query_timestamp_.find(id)->second;
        break;
      default:
        FAIL() << "Invalid variable passed to GetQueryObjectui64v: " << pname;
    }
  }

  void GetIntegerv(GLenum pname, GLint* params) {
    switch (pname) {
      case GL_GPU_DISJOINT_EXT:
        *params = static_cast<GLint>(disjointed_);
        disjointed_ = false;
        break;
      default:
        FAIL() << "Invalid variable passed to GetIntegerv: " << pname;
    }
  }

  void Finish() {
  }

  GLenum GetError() {
    return GL_NO_ERROR;
  }

 protected:
  bool disjointed_ = false;
  GLint64 current_time_ = 0;
  GLuint next_query_id_ = 0;
  std::set<GLuint> alloced_queries_;
  std::map<GLuint, GLint64> query_timestamp_;
};

class GPUTracerTester : public GPUTracer {
 public:
  explicit GPUTracerTester(gles2::GLES2Decoder* decoder)
      : GPUTracer(decoder), tracing_enabled_(0) {
    gpu_timing_client_->SetCpuTimeForTesting(base::Bind(&FakeCpuTime));

    // Force tracing to be dependent on our mock variable here.
    gpu_trace_srv_category = &tracing_enabled_;
    gpu_trace_dev_category = &tracing_enabled_;
  }

  ~GPUTracerTester() override {}

  void SetTracingEnabled(bool enabled) {
    tracing_enabled_ = enabled ? 1 : 0;
  }

  void SetOutputter(scoped_refptr<Outputter> outputter) {
    set_outputter_ = outputter;
  }

 protected:
  scoped_refptr<Outputter> CreateOutputter(const std::string& name) override {
    if (set_outputter_.get()) {
      return set_outputter_;
    }
    return new MockOutputter();
  }

  void PostTask() override {
    // Process synchronously.
    Process();
  }

  unsigned char tracing_enabled_;

  scoped_refptr<Outputter> set_outputter_;
};

class BaseGpuTest : public GpuServiceTest {
 public:
  explicit BaseGpuTest(gfx::GPUTiming::TimerType test_timer_type)
      : test_timer_type_(test_timer_type) {
  }

 protected:
  void SetUp() override {
    g_fakeCPUTime = 0;
    const char* gl_version = "3.2";
    const char* extensions = "";
    if (GetTimerType() == gfx::GPUTiming::kTimerTypeEXT) {
      gl_version = "opengl 2.1";
      extensions = "GL_EXT_timer_query";
    } else if (GetTimerType() == gfx::GPUTiming::kTimerTypeDisjoint) {
      gl_version = "opengl es 3.0";
      extensions = "GL_EXT_disjoint_timer_query";
    } else if (GetTimerType() == gfx::GPUTiming::kTimerTypeARB) {
      // TODO(sievers): The tracer should not depend on ARB_occlusion_query.
      // Try merge Query APIs (core, ARB, EXT) into a single binding each.
      extensions = "GL_ARB_timer_query GL_ARB_occlusion_query";
    }
    GpuServiceTest::SetUpWithGLVersion(gl_version, extensions);

    // Disjoint check should only be called by kTracerTypeDisjointTimer type.
    if (GetTimerType() == gfx::GPUTiming::kTimerTypeDisjoint) {
      EXPECT_CALL(*gl_, GetIntegerv(GL_GPU_DISJOINT_EXT, _)).Times(AtLeast(1))
          .WillRepeatedly(
              Invoke(&gl_fake_queries_, &GlFakeQueries::GetIntegerv));
    } else {
      EXPECT_CALL(*gl_, GetIntegerv(GL_GPU_DISJOINT_EXT, _)).Times(Exactly(0));
    }
    gpu_timing_client_ = GetGLContext()->CreateGPUTimingClient();
    gpu_timing_client_->SetCpuTimeForTesting(base::Bind(&FakeCpuTime));
    gl_fake_queries_.Reset();

    outputter_ref_ = new MockOutputter();
  }

  void TearDown() override {
    outputter_ref_ = NULL;
    gpu_timing_client_ = NULL;

    gl_fake_queries_.Reset();
    GpuServiceTest::TearDown();
  }

  void ExpectTraceQueryMocks() {
    if (gpu_timing_client_->IsAvailable() &&
        gpu_timing_client_->IsTimerOffsetAvailable()) {
      // Delegate query APIs used by GPUTrace to a GlFakeQueries
      EXPECT_CALL(*gl_, GenQueries(2, NotNull())).Times(AtLeast(1))
          .WillRepeatedly(
              Invoke(&gl_fake_queries_, &GlFakeQueries::GenQueries));

      EXPECT_CALL(*gl_, GetQueryObjectiv(_, GL_QUERY_RESULT_AVAILABLE,
                                            NotNull()))
          .WillRepeatedly(
              Invoke(&gl_fake_queries_, &GlFakeQueries::GetQueryObjectiv));

      EXPECT_CALL(*gl_, GetInteger64v(GL_TIMESTAMP, _))
          .WillRepeatedly(
              Invoke(&gl_fake_queries_, &GlFakeQueries::GetInteger64v));

      EXPECT_CALL(*gl_, QueryCounter(_, GL_TIMESTAMP)).Times(AtLeast(2))
          .WillRepeatedly(
               Invoke(&gl_fake_queries_, &GlFakeQueries::QueryCounter));

      EXPECT_CALL(*gl_, GetQueryObjectui64v(_, GL_QUERY_RESULT, NotNull()))
          .WillRepeatedly(
               Invoke(&gl_fake_queries_,
                      &GlFakeQueries::GetQueryObjectui64v));

      EXPECT_CALL(*gl_, DeleteQueries(2, NotNull())).Times(AtLeast(1))
          .WillRepeatedly(
               Invoke(&gl_fake_queries_, &GlFakeQueries::DeleteQueries));
    }
  }

  void ExpectOutputterBeginMocks(MockOutputter* outputter,
                                 const std::string& category,
                                 const std::string& name) {
    EXPECT_CALL(*outputter,
                TraceServiceBegin(category, name));
  }

  void ExpectOutputterEndMocks(MockOutputter* outputter,
                               const std::string& category,
                               const std::string& name, int64 expect_start_time,
                               int64 expect_end_time,
                               bool trace_device) {
    EXPECT_CALL(*outputter,
                TraceServiceEnd(category, name));

    if (trace_device) {
      EXPECT_CALL(*outputter,
                  TraceDevice(category, name,
                              expect_start_time, expect_end_time))
          .Times(Exactly(1));
    } else {
      EXPECT_CALL(*outputter, TraceDevice(category, name,
                                          expect_start_time, expect_end_time))
          .Times(Exactly(0));
    }
  }

  void ExpectOutputterMocks(MockOutputter* outputter,
                            bool tracing_device,
                            const std::string& category,
                            const std::string& name, int64 expect_start_time,
                            int64 expect_end_time) {
    ExpectOutputterBeginMocks(outputter, category, name);
    bool valid_timer = tracing_device &&
                       gpu_timing_client_->IsAvailable() &&
                       gpu_timing_client_->IsTimerOffsetAvailable();
    ExpectOutputterEndMocks(outputter, category, name, expect_start_time,
                            expect_end_time, valid_timer);
  }

  void ExpectTracerOffsetQueryMocks() {
    if (GetTimerType() != gfx::GPUTiming::kTimerTypeARB) {
      EXPECT_CALL(*gl_, GetInteger64v(GL_TIMESTAMP, NotNull()))
          .Times(Exactly(0));
    } else {
      EXPECT_CALL(*gl_, GetInteger64v(GL_TIMESTAMP, NotNull()))
          .Times(AtMost(1))
          .WillRepeatedly(
              Invoke(&gl_fake_queries_, &GlFakeQueries::GetInteger64v));
    }
  }

  gfx::GPUTiming::TimerType GetTimerType() { return test_timer_type_; }

  gfx::GPUTiming::TimerType test_timer_type_;
  GlFakeQueries gl_fake_queries_;

  scoped_refptr<gfx::GPUTimingClient> gpu_timing_client_;
  scoped_refptr<MockOutputter> outputter_ref_;
};

// Test GPUTrace calls all the correct gl calls.
class BaseGpuTraceTest : public BaseGpuTest {
 public:
  explicit BaseGpuTraceTest(gfx::GPUTiming::TimerType test_timer_type)
      : BaseGpuTest(test_timer_type) {}

  void DoTraceTest(bool tracing_service, bool tracing_device) {
    // Expected results
    const std::string category_name("trace_category");
    const std::string trace_name("trace_test");
    const int64 offset_time = 3231;
    const GLint64 start_timestamp = 7 * base::Time::kNanosecondsPerMicrosecond;
    const GLint64 end_timestamp = 32 * base::Time::kNanosecondsPerMicrosecond;
    const int64 expect_start_time =
        (start_timestamp / base::Time::kNanosecondsPerMicrosecond) +
        offset_time;
    const int64 expect_end_time =
        (end_timestamp / base::Time::kNanosecondsPerMicrosecond) + offset_time;

    if (tracing_service)
      ExpectOutputterMocks(outputter_ref_.get(), tracing_device, category_name,
                           trace_name, expect_start_time, expect_end_time);

    if (tracing_device)
      ExpectTraceQueryMocks();

    scoped_refptr<GPUTrace> trace = new GPUTrace(
        outputter_ref_, gpu_timing_client_.get(),
        category_name, trace_name, tracing_service, tracing_device);

    gl_fake_queries_.SetCurrentGLTime(start_timestamp);
    g_fakeCPUTime = expect_start_time;
    trace->Start();

    // Shouldn't be available before End() call
    gl_fake_queries_.SetCurrentGLTime(end_timestamp);
    g_fakeCPUTime = expect_end_time;
    if (tracing_device)
      EXPECT_FALSE(trace->IsAvailable());

    trace->End();

    // Shouldn't be available until the queries complete
    gl_fake_queries_.SetCurrentGLTime(end_timestamp -
                                      base::Time::kNanosecondsPerMicrosecond);
    if (tracing_device)
      EXPECT_FALSE(trace->IsAvailable());

    // Now it should be available
    gl_fake_queries_.SetCurrentGLTime(end_timestamp);
    EXPECT_TRUE(trace->IsAvailable());

    // Proces should output expected Trace results to MockOutputter
    trace->Process();

    // Destroy trace after we are done.
    trace->Destroy(true);

    outputter_ref_ = NULL;
  }
};

class GpuARBTimerTraceTest : public BaseGpuTraceTest {
 public:
  GpuARBTimerTraceTest() : BaseGpuTraceTest(gfx::GPUTiming::kTimerTypeARB) {}
};

class GpuDisjointTimerTraceTest : public BaseGpuTraceTest {
 public:
  GpuDisjointTimerTraceTest()
      : BaseGpuTraceTest(gfx::GPUTiming::kTimerTypeDisjoint) {}
};

TEST_F(GpuARBTimerTraceTest, ARBTimerTraceTestOff) {
  DoTraceTest(false, false);
}

TEST_F(GpuARBTimerTraceTest, ARBTimerTraceTestServiceOnly) {
  DoTraceTest(true, false);
}

TEST_F(GpuARBTimerTraceTest, ARBTimerTraceTestDeviceOnly) {
  DoTraceTest(false, true);
}

TEST_F(GpuARBTimerTraceTest, ARBTimerTraceTestBothOn) {
  DoTraceTest(true, true);
}

TEST_F(GpuDisjointTimerTraceTest, DisjointTimerTraceTestOff) {
  DoTraceTest(false, false);
}

TEST_F(GpuDisjointTimerTraceTest, DisjointTimerTraceTestServiceOnly) {
  DoTraceTest(true, false);
}

TEST_F(GpuDisjointTimerTraceTest, DisjointTimerTraceTestDeviceOnly) {
  DoTraceTest(false, true);
}

TEST_F(GpuDisjointTimerTraceTest, DisjointTimerTraceTestBothOn) {
  DoTraceTest(true, true);
}

// Test GPUTracer calls all the correct gl calls.
class BaseGpuTracerTest : public BaseGpuTest {
 public:
  explicit BaseGpuTracerTest(gfx::GPUTiming::TimerType test_timer_type)
      : BaseGpuTest(test_timer_type) {}

  void DoBasicTracerTest() {
    ExpectTracerOffsetQueryMocks();

    MockGLES2Decoder decoder;
    EXPECT_CALL(decoder, GetGLContext()).WillOnce(Return(GetGLContext()));
    GPUTracerTester tracer(&decoder);
    tracer.SetTracingEnabled(true);

    tracer.SetOutputter(outputter_ref_);

    ASSERT_TRUE(tracer.BeginDecoding());
    ASSERT_TRUE(tracer.EndDecoding());

    outputter_ref_ = NULL;
  }

  void DoTracerMarkersTest() {
    ExpectTracerOffsetQueryMocks();

    EXPECT_CALL(*gl_, GetError()).Times(AtLeast(0))
          .WillRepeatedly(
               Invoke(&gl_fake_queries_, &GlFakeQueries::GetError));

    const std::string category_name("trace_category");
    const std::string trace_name("trace_test");
    const int64 offset_time = 3231;
    const GLint64 start_timestamp = 7 * base::Time::kNanosecondsPerMicrosecond;
    const GLint64 end_timestamp = 32 * base::Time::kNanosecondsPerMicrosecond;
    const int64 expect_start_time =
        (start_timestamp / base::Time::kNanosecondsPerMicrosecond) +
        offset_time;
    const int64 expect_end_time =
        (end_timestamp / base::Time::kNanosecondsPerMicrosecond) + offset_time;

    MockGLES2Decoder decoder;
    EXPECT_CALL(decoder, GetGLContext()).WillOnce(Return(GetGLContext()));
    GPUTracerTester tracer(&decoder);
    tracer.SetTracingEnabled(true);

    tracer.SetOutputter(outputter_ref_);

    gl_fake_queries_.SetCurrentGLTime(start_timestamp);
    g_fakeCPUTime = expect_start_time;

    ASSERT_TRUE(tracer.BeginDecoding());

    ExpectTraceQueryMocks();

    // This will test multiple marker sources which overlap one another.
    for (int i = 0; i < NUM_TRACER_SOURCES; ++i) {
      // Set times so each source has a different time.
      gl_fake_queries_.SetCurrentGLTime(
          start_timestamp +
          (i * base::Time::kNanosecondsPerMicrosecond));
      g_fakeCPUTime = expect_start_time + i;

      // Each trace name should be different to differentiate.
      const char num_char = static_cast<char>('0' + i);
      std::string source_category = category_name + num_char;
      std::string source_trace_name = trace_name + num_char;

      ExpectOutputterBeginMocks(outputter_ref_.get(),
                                source_category, source_trace_name);

      const GpuTracerSource source = static_cast<GpuTracerSource>(i);
      ASSERT_TRUE(tracer.Begin(source_category, source_trace_name, source));
    }

    for (int i = 0; i < NUM_TRACER_SOURCES; ++i) {
      // Set times so each source has a different time.
      gl_fake_queries_.SetCurrentGLTime(
          end_timestamp +
          (i * base::Time::kNanosecondsPerMicrosecond));
      g_fakeCPUTime = expect_end_time + i;

      // Each trace name should be different to differentiate.
      const char num_char = static_cast<char>('0' + i);
      std::string source_category = category_name + num_char;
      std::string source_trace_name = trace_name + num_char;

      bool valid_timer = gpu_timing_client_->IsAvailable() &&
                         gpu_timing_client_->IsTimerOffsetAvailable();
      ExpectOutputterEndMocks(outputter_ref_.get(), source_category,
                              source_trace_name, expect_start_time + i,
                              expect_end_time + i, valid_timer);

      const GpuTracerSource source = static_cast<GpuTracerSource>(i);

      // Check if the current category/name are correct for this source.
      ASSERT_EQ(source_category, tracer.CurrentCategory(source));
      ASSERT_EQ(source_trace_name, tracer.CurrentName(source));

      ASSERT_TRUE(tracer.End(source));
    }

    ASSERT_TRUE(tracer.EndDecoding());

    outputter_ref_ = NULL;
  }

  void DoDisjointTest() {
    // Cause a disjoint in a middle of a trace and expect no output calls.
    ExpectTracerOffsetQueryMocks();

    EXPECT_CALL(*gl_, GetError()).Times(AtLeast(0))
          .WillRepeatedly(
               Invoke(&gl_fake_queries_, &GlFakeQueries::GetError));

    const std::string category_name("trace_category");
    const std::string trace_name("trace_test");
    const GpuTracerSource source = static_cast<GpuTracerSource>(0);
    const int64 offset_time = 3231;
    const GLint64 start_timestamp = 7 * base::Time::kNanosecondsPerMicrosecond;
    const GLint64 end_timestamp = 32 * base::Time::kNanosecondsPerMicrosecond;
    const int64 expect_start_time =
        (start_timestamp / base::Time::kNanosecondsPerMicrosecond) +
        offset_time;
    const int64 expect_end_time =
        (end_timestamp / base::Time::kNanosecondsPerMicrosecond) + offset_time;

    MockGLES2Decoder decoder;
    EXPECT_CALL(decoder, GetGLContext()).WillOnce(Return(GetGLContext()));
    GPUTracerTester tracer(&decoder);
    tracer.SetTracingEnabled(true);

    tracer.SetOutputter(outputter_ref_);

    gl_fake_queries_.SetCurrentGLTime(start_timestamp);
    g_fakeCPUTime = expect_start_time;

    ASSERT_TRUE(tracer.BeginDecoding());

    ExpectTraceQueryMocks();

    ExpectOutputterBeginMocks(outputter_ref_.get(),
                              category_name, trace_name);
    ASSERT_TRUE(tracer.Begin(category_name, trace_name, source));

    gl_fake_queries_.SetCurrentGLTime(end_timestamp);
    g_fakeCPUTime = expect_end_time;

    // Create GPUTimingClient to make sure disjoint value is correct. This
    // should not interfere with the tracer's disjoint value.
    scoped_refptr<gfx::GPUTimingClient>  disjoint_client =
        GetGLContext()->CreateGPUTimingClient();

    // We assert here based on the disjoint_client because if disjoints are not
    // working properly there is no point testing the tracer output.
    ASSERT_FALSE(disjoint_client->CheckAndResetTimerErrors());
    gl_fake_queries_.SetDisjoint();
    ASSERT_TRUE(disjoint_client->CheckAndResetTimerErrors());

    ExpectOutputterEndMocks(outputter_ref_.get(), category_name, trace_name,
                            expect_start_time, expect_end_time, false);

    ASSERT_TRUE(tracer.End(source));
    ASSERT_TRUE(tracer.EndDecoding());

    outputter_ref_ = NULL;
  }
};

class InvalidTimerTracerTest : public BaseGpuTracerTest {
 public:
  InvalidTimerTracerTest()
      : BaseGpuTracerTest(gfx::GPUTiming::kTimerTypeInvalid) {}
};

class GpuEXTTimerTracerTest : public BaseGpuTracerTest {
 public:
  GpuEXTTimerTracerTest() : BaseGpuTracerTest(gfx::GPUTiming::kTimerTypeEXT) {}
};

class GpuARBTimerTracerTest : public BaseGpuTracerTest {
 public:
  GpuARBTimerTracerTest()
      : BaseGpuTracerTest(gfx::GPUTiming::kTimerTypeARB) {}
};

class GpuDisjointTimerTracerTest : public BaseGpuTracerTest {
 public:
  GpuDisjointTimerTracerTest()
      : BaseGpuTracerTest(gfx::GPUTiming::kTimerTypeDisjoint) {}
};

TEST_F(InvalidTimerTracerTest, InvalidTimerBasicTracerTest) {
  DoBasicTracerTest();
}

TEST_F(GpuEXTTimerTracerTest, EXTTimerBasicTracerTest) {
  DoBasicTracerTest();
}

TEST_F(GpuARBTimerTracerTest, ARBTimerBasicTracerTest) {
  DoBasicTracerTest();
}

TEST_F(GpuDisjointTimerTracerTest, DisjointTimerBasicTracerTest) {
  DoBasicTracerTest();
}

TEST_F(InvalidTimerTracerTest, InvalidTimerTracerMarkersTest) {
  DoTracerMarkersTest();
}

TEST_F(GpuEXTTimerTracerTest, EXTTimerTracerMarkersTest) {
  DoTracerMarkersTest();
}

TEST_F(GpuARBTimerTracerTest, ARBTimerBasicTracerMarkersTest) {
  DoTracerMarkersTest();
}

TEST_F(GpuDisjointTimerTracerTest, DisjointTimerBasicTracerMarkersTest) {
  DoTracerMarkersTest();
}

TEST_F(GpuDisjointTimerTracerTest, DisjointTimerDisjointTraceTest) {
  DoDisjointTest();
}

class GPUTracerTest : public GpuServiceTest {
 protected:
  void SetUp() override {
    g_fakeCPUTime = 0;
    GpuServiceTest::SetUpWithGLVersion("3.2", "");
    decoder_.reset(new MockGLES2Decoder());
    EXPECT_CALL(*decoder_, GetGLContext())
        .Times(AtMost(1))
        .WillRepeatedly(Return(GetGLContext()));
    tracer_tester_.reset(new GPUTracerTester(decoder_.get()));
  }

  void TearDown() override {
    tracer_tester_ = nullptr;
    decoder_ = nullptr;
    GpuServiceTest::TearDown();
  }
  scoped_ptr<MockGLES2Decoder> decoder_;
  scoped_ptr<GPUTracerTester> tracer_tester_;
};

TEST_F(GPUTracerTest, IsTracingTest) {
  EXPECT_FALSE(tracer_tester_->IsTracing());
  tracer_tester_->SetTracingEnabled(true);
  EXPECT_TRUE(tracer_tester_->IsTracing());
}
// Test basic functionality of the GPUTracerTester.
TEST_F(GPUTracerTest, DecodeTest) {
  ASSERT_TRUE(tracer_tester_->BeginDecoding());
  EXPECT_FALSE(tracer_tester_->BeginDecoding());
  ASSERT_TRUE(tracer_tester_->EndDecoding());
  EXPECT_FALSE(tracer_tester_->EndDecoding());
}

TEST_F(GPUTracerTest, TraceDuringDecodeTest) {
  const std::string category_name("trace_category");
  const std::string trace_name("trace_test");

  EXPECT_FALSE(
      tracer_tester_->Begin(category_name, trace_name, kTraceGroupMarker));

  ASSERT_TRUE(tracer_tester_->BeginDecoding());
  EXPECT_TRUE(
      tracer_tester_->Begin(category_name, trace_name, kTraceGroupMarker));
  ASSERT_TRUE(tracer_tester_->EndDecoding());
}

TEST_F(GpuDisjointTimerTracerTest, MultipleClientsDisjointTest) {
  scoped_refptr<gfx::GPUTimingClient> client1 =
      GetGLContext()->CreateGPUTimingClient();
  scoped_refptr<gfx::GPUTimingClient>  client2 =
      GetGLContext()->CreateGPUTimingClient();

  // Test both clients are initialized as no errors.
  ASSERT_FALSE(client1->CheckAndResetTimerErrors());
  ASSERT_FALSE(client2->CheckAndResetTimerErrors());

  // Issue a disjoint.
  gl_fake_queries_.SetDisjoint();

  ASSERT_TRUE(client1->CheckAndResetTimerErrors());
  ASSERT_TRUE(client2->CheckAndResetTimerErrors());

  // Test both are now reset.
  ASSERT_FALSE(client1->CheckAndResetTimerErrors());
  ASSERT_FALSE(client2->CheckAndResetTimerErrors());

  // Issue a disjoint.
  gl_fake_queries_.SetDisjoint();

  // Test new client disjoint value is cleared.
  scoped_refptr<gfx::GPUTimingClient>  client3 =
      GetGLContext()->CreateGPUTimingClient();
  ASSERT_TRUE(client1->CheckAndResetTimerErrors());
  ASSERT_TRUE(client2->CheckAndResetTimerErrors());
  ASSERT_FALSE(client3->CheckAndResetTimerErrors());
}

}  // namespace
}  // namespace gles2
}  // namespace gpu
