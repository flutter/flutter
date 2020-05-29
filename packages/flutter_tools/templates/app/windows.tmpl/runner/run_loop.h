#ifndef RUN_LOOP_H_
#define RUN_LOOP_H_

#include <flutter/flutter_view_controller.h>

#include <chrono>
#include <set>

// A runloop that will service events for Flutter instances as well
// as native messages.
class RunLoop {
 public:
  RunLoop();
  ~RunLoop();

  // Prevent copying
  RunLoop(RunLoop const&) = delete;
  RunLoop& operator=(RunLoop const&) = delete;

  // Runs the run loop until the application quits.
  void Run();

  // Registers the given Flutter instance for event servicing.
  void RegisterFlutterInstance(
      flutter::FlutterViewController* flutter_instance);

  // Unregisters the given Flutter instance from event servicing.
  void UnregisterFlutterInstance(
      flutter::FlutterViewController* flutter_instance);

 private:
  using TimePoint = std::chrono::steady_clock::time_point;

  // Processes all currently pending messages for registered Flutter instances.
  TimePoint ProcessFlutterMessages();

  std::set<flutter::FlutterViewController*> flutter_instances_;
};

#endif  // RUN_LOOP_H_
