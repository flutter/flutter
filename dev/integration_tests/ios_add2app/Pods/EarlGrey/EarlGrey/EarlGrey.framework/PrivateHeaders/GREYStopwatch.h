//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A class that mimics a stopwatch for calculating code latency.
 *
 *  Usage example:
 *  @code
 *  GREYStopwatch *stopwatch = [[GREYStopwatch alloc] init];
 *  [stopwatch start];
 *  -------code block-------
 *  [stopwatch stop];
 *  NSLog(@"Time it took to execute codeblock %f", [stopwatch elapsedTime]);
 *  @endcode
 *
 */
@interface GREYStopwatch : NSObject

/**
 *  Set the start time of the stopwatch to the current time as obtained by @c mach_absolute_time().
 *  Calling this multiple times will result in the start time being reset every single time. This
 *  is the only way to set the start time of the stop watch.
 */
- (void)start;

/**
 *  Set the stop time of the stopwatch to the current time as obtained by @c mach_absolute_time().
 *  This also prevents subsequent calls to @c GREYStopwatch::lapAndReturnTime from being performed.
 *  This does not affect the stopwatch's saved start time or lap time. Calling stop without first
 *  calling @c GREYStopwatch::start will throw an exception.
 */
- (void)stop;

/**
 *  Returns the time obtained by subtracting the time the stopwatch was last stopped and last
 *  started. If the stopwatch is never started/stopped then it will throw an exception. This does
 *  not cumulatively add up the times the stopwatch was started/stopped. If the user wants the
 *  cumulative value of all start/stops, then the user will have to save the times and add them up.
 *
 *  @return an NSTimeInterval with the interval from the time the stopwatch was started.
 */
- (NSTimeInterval)elapsedTime;

/**
 *  Obtain the time interval from subtracting the current time as obtained by
 *  @c mach_absolute_time() from the reference time that @c GREYStopwatch::lapAndReturnTime was
 *  last called at. In case @c GREYStopwatch::lapAndReturnTime was never called, then this will
 *  return the interval from the start time. Similar to @c GREYStopwatch::elapsedTime, this will
 *  throw an exception if the stopwatch was never started.
 *
 *  @return an NSTimeInterval with the interval from the time the stopwatch was started.
 */
- (NSTimeInterval)lapAndReturnTime;


@end

NS_ASSUME_NONNULL_END
