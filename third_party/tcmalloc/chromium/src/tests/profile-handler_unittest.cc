// Copyright 2009 Google Inc. All Rights Reserved.
// Author: Nabeel Mian (nabeelmian@google.com)
//         Chris Demetriou (cgd@google.com)
//
// This file contains the unit tests for profile-handler.h interface.
//
// It is linked into three separate unit tests:
//     profile-handler_unittest tests basic functionality
//     profile-handler_disable_test tests that the profiler
//         is disabled with --install_signal_handlers=false
//     profile-handler_conflict_test tests that the profiler
//         is disabled when a SIGPROF handler is registered before InitGoogle.

#include "config.h"
#include "profile-handler.h"

#include <assert.h>
#include <pthread.h>
#include <sys/time.h>
#include <time.h>
#include "base/logging.h"
#include "base/simple_mutex.h"

// Some helpful macros for the test class
#define TEST_F(cls, fn)    void cls :: fn()

// Do we expect the profiler to be enabled?
DEFINE_bool(test_profiler_enabled, true,
            "expect profiler to be enabled during tests");

// Should we look at the kernel signal handler settings during the test?
// Not if we're in conflict_test, because we can't distinguish its nop
// handler from the real one.
DEFINE_bool(test_profiler_signal_handler, true,
            "check profiler signal handler during tests");

namespace {

// TODO(csilvers): error-checking on the pthreads routines
class Thread {
 public:
  Thread() : joinable_(false) { }
  void SetJoinable(bool value) { joinable_ = value; }
  void Start() {
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, joinable_ ? PTHREAD_CREATE_JOINABLE
                                                 : PTHREAD_CREATE_DETACHED);
    pthread_create(&thread_, &attr, &DoRun, this);
    pthread_attr_destroy(&attr);
  }
  void Join()  {
    assert(joinable_);
    pthread_join(thread_, NULL);
  }
  virtual void Run() = 0;
 private:
  static void* DoRun(void* cls) {
    ProfileHandlerRegisterThread();
    reinterpret_cast<Thread*>(cls)->Run();
    return NULL;
  }
  pthread_t thread_;
  bool joinable_;
};

// Sleep interval in nano secs. ITIMER_PROF goes off only afer the specified CPU
// time is consumed. Under heavy load this process may no get scheduled in a
// timely fashion. Therefore, give enough time (20x of ProfileHandle timer
// interval 10ms (100Hz)) for this process to accumulate enought CPU time to get
// a profile tick.
int kSleepInterval = 200000000;

// Sleep interval in nano secs. To ensure that if the timer has expired it is
// reset.
int kTimerResetInterval = 5000000;

// Whether each thread has separate timers.
static bool timer_separate_ = false;
static int timer_type_ = ITIMER_PROF;
static int signal_number_ = SIGPROF;

// Delays processing by the specified number of nano seconds. 'delay_ns'
// must be less than the number of nano seconds in a second (1000000000).
void Delay(int delay_ns) {
  static const int kNumNSecInSecond = 1000000000;
  EXPECT_LT(delay_ns, kNumNSecInSecond);
  struct timespec delay = { 0, delay_ns };
  nanosleep(&delay, 0);
}

// Checks whether the profile timer is enabled for the current thread.
bool IsTimerEnabled() {
  itimerval current_timer;
  EXPECT_EQ(0, getitimer(timer_type_, &current_timer));
  if ((current_timer.it_value.tv_sec == 0) &&
      (current_timer.it_value.tv_usec != 0)) {
    // May be the timer has expired. Sleep for a bit and check again.
    Delay(kTimerResetInterval);
    EXPECT_EQ(0, getitimer(timer_type_, &current_timer));
  }
  return (current_timer.it_value.tv_sec != 0 ||
          current_timer.it_value.tv_usec != 0);
}

class VirtualTimerGetterThread : public Thread {
 public:
  VirtualTimerGetterThread() {
    memset(&virtual_timer_, 0, sizeof virtual_timer_);
  }
  struct itimerval virtual_timer_;

 private:
  void Run() {
    CHECK_EQ(0, getitimer(ITIMER_VIRTUAL, &virtual_timer_));
  }
};

// This function checks whether the timers are shared between thread. This
// function spawns a thread, so use it carefully when testing thread-dependent
// behaviour.
static bool threads_have_separate_timers() {
  struct itimerval new_timer_val;

  // Enable the virtual timer in the current thread.
  memset(&new_timer_val, 0, sizeof new_timer_val);
  new_timer_val.it_value.tv_sec = 1000000;  // seconds
  CHECK_EQ(0, setitimer(ITIMER_VIRTUAL, &new_timer_val, NULL));

  // Spawn a thread, get the virtual timer's value there.
  VirtualTimerGetterThread thread;
  thread.SetJoinable(true);
  thread.Start();
  thread.Join();

  // Disable timer here.
  memset(&new_timer_val, 0, sizeof new_timer_val);
  CHECK_EQ(0, setitimer(ITIMER_VIRTUAL, &new_timer_val, NULL));

  bool target_timer_enabled = (thread.virtual_timer_.it_value.tv_sec != 0 ||
                               thread.virtual_timer_.it_value.tv_usec != 0);
  if (!target_timer_enabled) {
    LOG(INFO, "threads have separate timers");
    return true;
  } else {
    LOG(INFO, "threads have shared timers");
    return false;
  }
}

// Dummy worker thread to accumulate cpu time.
class BusyThread : public Thread {
 public:
  BusyThread() : stop_work_(false) {
  }

  // Setter/Getters
  bool stop_work() {
    MutexLock lock(&mu_);
    return stop_work_;
  }
  void set_stop_work(bool stop_work) {
    MutexLock lock(&mu_);
    stop_work_ = stop_work;
  }

 private:
  // Protects stop_work_ below.
  Mutex mu_;
  // Whether to stop work?
  bool stop_work_;

  // Do work until asked to stop.
  void Run() {
    while (!stop_work()) {
    }
    // If timers are separate, check that timer is enabled for this thread.
    EXPECT_TRUE(!timer_separate_ || IsTimerEnabled());
  }
};

class NullThread : public Thread {
 private:
  void Run() {
    // If timers are separate, check that timer is enabled for this thread.
    EXPECT_TRUE(!timer_separate_ || IsTimerEnabled());
  }
};

// Signal handler which tracks the profile timer ticks.
static void TickCounter(int sig, siginfo_t* sig_info, void *vuc,
                        void* tick_counter) {
  int* counter = static_cast<int*>(tick_counter);
  ++(*counter);
}

// This class tests the profile-handler.h interface.
class ProfileHandlerTest {
 protected:

  // Determines whether threads have separate timers.
  static void SetUpTestCase() {
    timer_type_ = (getenv("CPUPROFILE_REALTIME") ? ITIMER_REAL : ITIMER_PROF);
    signal_number_ = (getenv("CPUPROFILE_REALTIME") ? SIGALRM : SIGPROF);

    timer_separate_ = threads_have_separate_timers();
    Delay(kTimerResetInterval);
  }

  // Sets up the profile timers and SIGPROF/SIGALRM handler in a known state.
  // It does the following:
  // 1. Unregisters all the callbacks, stops the timer (if shared) and
  //    clears out timer_sharing state in the ProfileHandler. This clears
  //    out any state left behind by the previous test or during module
  //    initialization when the test program was started.
  // 2. Spawns two threads which will be registered with the ProfileHandler.
  //    At this time ProfileHandler knows if the timers are shared.
  // 3. Starts a busy worker thread to accumulate CPU usage.
  virtual void SetUp() {
    // Reset the state of ProfileHandler between each test. This unregisters
    // all callbacks, stops timer (if shared) and clears timer sharing state.
    ProfileHandlerReset();
    EXPECT_EQ(0, GetCallbackCount());
    VerifyDisabled();
    // ProfileHandler requires at least two threads to be registerd to determine
    // whether timers are shared.
    RegisterThread();
    RegisterThread();
    // Now that two threads are started, verify that the signal handler is
    // disabled and the timers are correctly enabled/disabled.
    VerifyDisabled();
    // Start worker to accumulate cpu usage.
    StartWorker();
  }

  virtual void TearDown() {
    ProfileHandlerReset();
    // Stops the worker thread.
    StopWorker();
  }

  // Starts a no-op thread that gets registered with the ProfileHandler. Waits
  // for the thread to stop.
  void RegisterThread() {
    NullThread t;
    t.SetJoinable(true);
    t.Start();
    t.Join();
  }

  // Starts a busy worker thread to accumulate cpu time. There should be only
  // one busy worker running. This is required for the case where there are
  // separate timers for each thread.
  void StartWorker() {
    busy_worker_ = new BusyThread();
    busy_worker_->SetJoinable(true);
    busy_worker_->Start();
    // Wait for worker to start up and register with the ProfileHandler.
    // TODO(nabeelmian) This may not work under very heavy load.
    Delay(kSleepInterval);
  }

  // Stops the worker thread.
  void StopWorker() {
    busy_worker_->set_stop_work(true);
    busy_worker_->Join();
    delete busy_worker_;
  }

  // Checks whether SIGPROF/SIGALRM signal handler is enabled.
  bool IsSignalEnabled() {
    struct sigaction sa;
    CHECK_EQ(sigaction(signal_number_, NULL, &sa), 0);
    return ((sa.sa_handler == SIG_IGN) || (sa.sa_handler == SIG_DFL)) ?
        false : true;
  }

  // Gets the number of callbacks registered with the ProfileHandler.
  uint32 GetCallbackCount() {
    ProfileHandlerState state;
    ProfileHandlerGetState(&state);
    return state.callback_count;
  }

  // Gets the current ProfileHandler interrupt count.
  uint64 GetInterruptCount() {
    ProfileHandlerState state;
    ProfileHandlerGetState(&state);
    return state.interrupts;
  }

  // Verifies that a callback is correctly registered and receiving
  // profile ticks.
  void VerifyRegistration(const int& tick_counter) {
    // Check the callback count.
    EXPECT_GT(GetCallbackCount(), 0);
    // Check that the profile timer is enabled.
    EXPECT_EQ(FLAGS_test_profiler_enabled, IsTimerEnabled());
    // Check that the signal handler is enabled.
    if (FLAGS_test_profiler_signal_handler) {
      EXPECT_EQ(FLAGS_test_profiler_enabled, IsSignalEnabled());
    }
    uint64 interrupts_before = GetInterruptCount();
    // Sleep for a bit and check that tick counter is making progress.
    int old_tick_count = tick_counter;
    Delay(kSleepInterval);
    int new_tick_count = tick_counter;
    uint64 interrupts_after = GetInterruptCount();
    if (FLAGS_test_profiler_enabled) {
      EXPECT_GT(new_tick_count, old_tick_count);
      EXPECT_GT(interrupts_after, interrupts_before);
    } else {
      EXPECT_EQ(new_tick_count, old_tick_count);
      EXPECT_EQ(interrupts_after, interrupts_before);
    }
  }

  // Verifies that a callback is not receiving profile ticks.
  void VerifyUnregistration(const int& tick_counter) {
    // Sleep for a bit and check that tick counter is not making progress.
    int old_tick_count = tick_counter;
    Delay(kSleepInterval);
    int new_tick_count = tick_counter;
    EXPECT_EQ(old_tick_count, new_tick_count);
    // If no callbacks, signal handler and shared timer should be disabled.
    if (GetCallbackCount() == 0) {
      if (FLAGS_test_profiler_signal_handler) {
        EXPECT_FALSE(IsSignalEnabled());
      }
      if (timer_separate_) {
        EXPECT_TRUE(IsTimerEnabled());
      } else {
        EXPECT_FALSE(IsTimerEnabled());
      }
    }
  }

  // Verifies that the SIGPROF/SIGALRM interrupt handler is disabled and the
  // timer, if shared, is disabled. Expects the worker to be running.
  void VerifyDisabled() {
    // Check that the signal handler is disabled.
    if (FLAGS_test_profiler_signal_handler) {
      EXPECT_FALSE(IsSignalEnabled());
    }
    // Check that the callback count is 0.
    EXPECT_EQ(0, GetCallbackCount());
    // Check that the timer is disabled if shared, enabled otherwise.
    if (timer_separate_) {
      EXPECT_TRUE(IsTimerEnabled());
    } else {
      EXPECT_FALSE(IsTimerEnabled());
    }
    // Verify that the ProfileHandler is not accumulating profile ticks.
    uint64 interrupts_before = GetInterruptCount();
    Delay(kSleepInterval);
    uint64 interrupts_after = GetInterruptCount();
    EXPECT_EQ(interrupts_before, interrupts_after);
  }

  // Registers a callback and waits for kTimerResetInterval for timers to get
  // reset.
  ProfileHandlerToken* RegisterCallback(void* callback_arg) {
    ProfileHandlerToken* token = ProfileHandlerRegisterCallback(
        TickCounter, callback_arg);
    Delay(kTimerResetInterval);
    return token;
  }

  // Unregisters a callback and waits for kTimerResetInterval for timers to get
  // reset.
  void UnregisterCallback(ProfileHandlerToken* token) {
    ProfileHandlerUnregisterCallback(token);
    Delay(kTimerResetInterval);
  }

  // Busy worker thread to accumulate cpu usage.
  BusyThread* busy_worker_;

 private:
  // The tests to run
  void RegisterUnregisterCallback();
  void MultipleCallbacks();
  void Reset();
  void RegisterCallbackBeforeThread();

 public:
#define RUN(test)  do {                         \
    printf("Running %s\n", #test);              \
    ProfileHandlerTest pht;                     \
    pht.SetUp();                                \
    pht.test();                                 \
    pht.TearDown();                             \
} while (0)

  static int RUN_ALL_TESTS() {
    SetUpTestCase();
    RUN(RegisterUnregisterCallback);
    RUN(MultipleCallbacks);
    RUN(Reset);
    RUN(RegisterCallbackBeforeThread);
    printf("Done\n");
    return 0;
  }
};

// Verifies ProfileHandlerRegisterCallback and
// ProfileHandlerUnregisterCallback.
TEST_F(ProfileHandlerTest, RegisterUnregisterCallback) {
  int tick_count = 0;
  ProfileHandlerToken* token = RegisterCallback(&tick_count);
  VerifyRegistration(tick_count);
  UnregisterCallback(token);
  VerifyUnregistration(tick_count);
}

// Verifies that multiple callbacks can be registered.
TEST_F(ProfileHandlerTest, MultipleCallbacks) {
  // Register first callback.
  int first_tick_count;
  ProfileHandlerToken* token1 = RegisterCallback(&first_tick_count);
  // Check that callback was registered correctly.
  VerifyRegistration(first_tick_count);
  EXPECT_EQ(1, GetCallbackCount());

  // Register second callback.
  int second_tick_count;
  ProfileHandlerToken* token2 = RegisterCallback(&second_tick_count);
  // Check that callback was registered correctly.
  VerifyRegistration(second_tick_count);
  EXPECT_EQ(2, GetCallbackCount());

  // Unregister first callback.
  UnregisterCallback(token1);
  VerifyUnregistration(first_tick_count);
  EXPECT_EQ(1, GetCallbackCount());
  // Verify that second callback is still registered.
  VerifyRegistration(second_tick_count);

  // Unregister second callback.
  UnregisterCallback(token2);
  VerifyUnregistration(second_tick_count);
  EXPECT_EQ(0, GetCallbackCount());

  // Verify that the signal handler and timers are correctly disabled.
  VerifyDisabled();
}

// Verifies ProfileHandlerReset
TEST_F(ProfileHandlerTest, Reset) {
  // Verify that the profile timer interrupt is disabled.
  VerifyDisabled();
  int first_tick_count;
  RegisterCallback(&first_tick_count);
  VerifyRegistration(first_tick_count);
  EXPECT_EQ(1, GetCallbackCount());

  // Register second callback.
  int second_tick_count;
  RegisterCallback(&second_tick_count);
  VerifyRegistration(second_tick_count);
  EXPECT_EQ(2, GetCallbackCount());

  // Reset the profile handler and verify that callback were correctly
  // unregistered and timer/signal are disabled.
  ProfileHandlerReset();
  VerifyUnregistration(first_tick_count);
  VerifyUnregistration(second_tick_count);
  VerifyDisabled();
}

// Verifies that ProfileHandler correctly handles a case where a callback was
// registered before the second thread started.
TEST_F(ProfileHandlerTest, RegisterCallbackBeforeThread) {
  // Stop the worker.
  StopWorker();
  // Unregister all existing callbacks, stop the timer (if shared), disable
  // the signal handler and reset the timer sharing state in the Profile
  // Handler.
  ProfileHandlerReset();
  EXPECT_EQ(0, GetCallbackCount());
  VerifyDisabled();

  // Start the worker. At this time ProfileHandler doesn't know if timers are
  // shared as only one thread has registered so far.
  StartWorker();
  // Register a callback and check that profile ticks are being delivered.
  int tick_count;
  RegisterCallback(&tick_count);
  EXPECT_EQ(1, GetCallbackCount());
  VerifyRegistration(tick_count);

  // Register a second thread and verify that timer and signal handler are
  // correctly enabled.
  RegisterThread();
  EXPECT_EQ(1, GetCallbackCount());
  EXPECT_EQ(FLAGS_test_profiler_enabled, IsTimerEnabled());
  if (FLAGS_test_profiler_signal_handler) {
    EXPECT_EQ(FLAGS_test_profiler_enabled, IsSignalEnabled());
  }
}

}  // namespace

int main(int argc, char** argv) {
  return ProfileHandlerTest::RUN_ALL_TESTS();
}
