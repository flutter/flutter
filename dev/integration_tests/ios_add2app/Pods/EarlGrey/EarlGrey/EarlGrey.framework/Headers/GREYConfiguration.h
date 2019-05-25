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

/**
 *  @file GREYConfiguration.h
 *  @brief A key-value store for configuring global behavior. Configuration values are read just
 *         before performing a related function. On-going functions may not be affected by the
 *         changes in the configuration until the values are re-read.
 */

#import <Foundation/Foundation.h>

#import <EarlGrey/GREYDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Configuration that enables or disables usage tracking for the framework.
 *
 *  Accepted values: @c BOOL (i.e. @c YES or @c NO)
 *  Default value: @c YES
 */
GREY_EXTERN NSString *const kGREYConfigKeyAnalyticsEnabled;

/**
 *  Configuration that enables or disables constraint checks before performing an action.
 *
 *  Accepted values: @c BOOL (i.e. @c YES or @c NO)
 *  Default value: @c YES
 */
GREY_EXTERN NSString *const kGREYConfigKeyActionConstraintsEnabled;

/**
 *  Configuration that holds timeout duration (in seconds) for actions and assertions. Actions or
 *  assertions that are not scheduled within this time will fail with a timeout. If the action or
 *  assertion starts within the timeout duration and if a search action is provided, then the search
 *  action will execute at least once regardless of the timeout duration.
 *
 *  Accepted values: @c double (negative values are invalid)
 *  Default value: 30.0
 */
GREY_EXTERN NSString *const kGREYConfigKeyInteractionTimeoutDuration;

/**
 *  Configuration that enables or disables EarlGrey's synchronization feature.
 *  When disabled, any command that used to wait for the app to idle before proceeding will no
 *  longer do so.
 *
 *  @remark For more fine-grained control over synchronization parameters, you can tweak other
 *          provided configuration options below.
 *
 *  Accepted values: @c BOOL (i.e. @c YES or @c NO)
 *  Default value: @c YES
 */
GREY_EXTERN NSString *const kGREYConfigKeySynchronizationEnabled;

/**
 *  Configuration for setting the max interval (in seconds) of non-repeating NSTimers that EarlGrey
 *  will automatically track.
 *
 *  Accepted values: @c double (negative values are invalid)
 *  Default value: 1.5
 */
GREY_EXTERN NSString *const kGREYConfigKeyNSTimerMaxTrackableInterval;

/**
 *  Configuration for setting the max delay (in seconds) for dispatch_after and dispatch_after_f
 *  calls that EarlGrey will automatically track. dispatch_after and dispatch_after_f calls
 *  exceeding the specified time won't be tracked by the framework.
 *
 *  Accepted values: @c double (negative values are invalid)
 *  Default value: 1.5
 */
GREY_EXTERN NSString *const kGREYConfigKeyDispatchAfterMaxTrackableDelay;

/**
 *  Configuration for setting the max duration (in seconds) for delayed executions on the
 *  main thread originating from any performSelector:afterDelay invocations that EarlGrey will
 *  automatically track.
 *
 *  Accepted values: @c double (negative values are invalid)
 *  Default value: 1.5
 */
GREY_EXTERN NSString *const kGREYConfigKeyDelayedPerformMaxTrackableDuration;

/**
 *  Configuration that determines whether or not CALayer animations are modified. If @c YES, then
 *  cyclic animations are set to run only once and the animation duration is limited to a maximum
 *  of @c kGREYConfigKeyCALayerMaxAnimationDuration.
 *
 *  @remark This should only be used if synchronization is disabled; otherwise cyclic animations
 *          will cause EarlGrey to timeout and fail tests.
 *
 *  Accepted values: @c BOOL (i.e. @c YES or @c NO)
 *  Default value: @c YES
 */
GREY_EXTERN NSString *const kGREYConfigKeyCALayerModifyAnimations;

/**
 *  Configuration for setting max allowable animation duration (in seconds) for any CALayer based
 *  animation. Animations exceeding the specified time will have their duration truncated to value
 *  specified by this config.
 *
 *  Accepted values: @c double (negative values are invalid)
 *  Default value: 10.0
 */
GREY_EXTERN NSString *const kGREYConfigKeyCALayerMaxAnimationDuration;

/**
 *  Configuration that holds regular expressions for URLs that are blacklisted from synchronization.
 *  EarlGrey will not wait for any network request with URLs matching the blacklisted regular
 *  expressions to complete. Most frequently blacklisted URLs include those used for sending
 *  analytics, pingbacks, and background network tasks that don't interfere with testing.
 *
 *  @remark By default, EarlGrey will not synchronize with any URLs with "data" scheme.
 *
 *  Accepted values: @c An @c NSArray of valid regular expressions as @c NSString.
 *                   The strings must be accepted by @c NSRegularExpression.
 *  Default value: an empty @c NSArray
 */
GREY_EXTERN NSString *const kGREYConfigKeyURLBlacklistRegex;

/**
 *  Configuration that enables/disables inclusion of status bar window in every operation performed
 *  by EarlGrey. By default, the status bar window is excluded from screenshots and UI hierarchy.
 *
 *  Accepted values: @c BOOL (i.e. @c YES or @c NO)
 *  Default value: NO
 */
GREY_EXTERN NSString *const kGREYConfigKeyIncludeStatusBarWindow;

/**
 *  Configuration for setting a directory location where any test artifacts such as screenshots,
 *  test logs, etc. are stored. The user should ensure that the location provided is writable by
 *  the test.
 *
 *  Accepted values: NSString containing a valid absolute filepath that is writable by the test.
 *  Default value: @c nil
 */
GREY_EXTERN NSString *const kGREYConfigKeyArtifactsDirLocation;

/**
 *  Provides an interface for runtime configuration of EarlGrey's behavior.
 */
@interface GREYConfiguration : NSObject

/**
 *  @return The singleton GREYConfiguration instance.
 */
+ (instancetype)sharedInstance;

/**
 *  If a user-configured value is associated with the given @c configKey, it is returned,
 *  otherwise the default value is returned. If a default value is not found, or an
 *  NSInvalidArgumentException is raised.
 *
 *  @param configKey The key whose value is being queried. Must be a valid @c NSString.
 *
 *  @throws NSInvalidArgumentException If no value could be found associated with @c configKey.
 *
 *  @return The value for the configuration stored associate with @c configKey.
 */
- (id)valueForConfigKey:(NSString *)configKey;

/**
 *  If a user-configured value is associated with the given @c configKey, it is returned, otherwise
 *  the default value is returned. If a default value is not found, NSInvalidArgumentException is
 *  raised.
 *
 *  @param configKey The key whose value is being queried. Must be a valid @c NSString.
 *
 *  @throws NSInvalidArgumentException If no value could be found for the given @c configKey.
 *
 *  @return The @c BOOL value for the configuration associated with @c configKey.
 */
- (BOOL)boolValueForConfigKey:(NSString *)configKey;

/**
 *  If a user-configured value is associated with the given @c configKey, it is returned, otherwise
 *  the default value is returned. If a default value is not found, NSInvalidArgumentException is
 *  raised.
 *
 *  @param configKey The key whose value is being queried. Must be a valid @c NSString.
 *
 *  @throws NSInvalidArgumentException If no value could be found for the given @c configKey.
 *
 *  @return The integer value for the configuration associated with @c configKey.
 */
- (NSInteger)integerValueForConfigKey:(NSString *)configKey;

/**
 *  If a user-configured value is associated with the given @c configKey, it is returned, otherwise
 *  the default value is returned. If a default value is not found, NSInvalidArgumentException is
 *  raised.
 *
 *  @param configKey The key whose value is being queried. Must be a valid @c NSString.
 *
 *  @throws NSInvalidArgumentException If no value could be found for the given @c configKey.
 *
 *  @return The @c double value for the configuration associated with @c configKey.
 */
- (double)doubleValueForConfigKey:(NSString *)configKey;

/**
 *  If a user-configured value is associated with the given @c configKey, it is returned, otherwise
 *  the default value is returned. If a default value is not found, NSInvalidArgumentException is
 *  raised.
 *
 *  @param configKey The key whose value is being queried. Must be a valid @c NSString.
 *
 *  @throws NSInvalidArgumentException If no value could be found for the given @c configKey.
 *
 *  @return The string value for the configuration associated with @c configKey.
 */
- (NSString *)stringValueForConfigKey:(NSString *)configKey;

/**
 *  If a user-configured value is associated with the given @c configKey, it is returned, otherwise
 *  the default value is returned. If a default value is not found, NSInvalidArgumentException is
 *  raised.
 *
 *  @param configKey The key whose value is being queried. Must be a valid @c NSString.
 *
 *  @throws NSInvalidArgumentException If no value could be found for the given @c configKey.
 *
 *  @return The array value for the configuration associated with @c configKey.
 */
- (NSArray *)arrayValueForConfigKey:(NSString *)configKey;

/**
 *  Resets all configurations to default values, removing all the configured values.
 *
 *  @remark Any default values added by calling GREYConfiguration:setDefaultValue:forConfigKey:
 *  are not reset.
 */
- (void)reset;

/**
 *  Given a value and a key that identifies a configuration, set the value of the configuration.
 *  Overwrites any previous value for the configuration.
 *
 *  @remark To restore original values, call GREYConfiguration::reset.
 *
 *  @param value     The configuration value to be set. Scalars should be wrapped in @c NSValue.
 *  @param configKey Key identifying an existing or new configuration. Must be a valid @c NSString.
 */
- (void)setValue:(id)value forConfigKey:(NSString *)configKey;

/**
 *  Associates configuration identified by @c configKey with the provided @c value.
 *
 *  @remark Default values persist even after resetting the configuration
 *          (using GREYConfiguration::reset)
 *
 *  @param value     The configuration value to be set. Scalars should be wrapped in @c NSValue.
 *  @param configKey Key identifying an existing or new configuration. Must be a valid @c NSString.
 */
- (void)setDefaultValue:(id)value forConfigKey:(NSString *)configKey;

@end

/**
 *  @return the value of type @c id associated with the given @c __configName.
 */
#define GREY_CONFIG(__configName) \
  [[GREYConfiguration sharedInstance] valueForConfigKey:(__configName)]

/**
 *  @return @c BOOL value associated with the given @c __configName.
 */
#define GREY_CONFIG_BOOL(__configName) \
  [[GREYConfiguration sharedInstance] boolValueForConfigKey:(__configName)]

/**
 *  @return @c NSInteger value associated with the given @c __configName.
 */
#define GREY_CONFIG_INTEGER(__configName) \
  [[GREYConfiguration sharedInstance] integerValueForConfigKey:(__configName)]

/**
 *  @return @c double value associated with the given @c __configName.
 */
#define GREY_CONFIG_DOUBLE(__configName) \
  [[GREYConfiguration sharedInstance] doubleValueForConfigKey:(__configName)]

/**
 *  @return @c NSString value associated with the given @c __configName.
 */
#define GREY_CONFIG_STRING(__configName) \
  [[GREYConfiguration sharedInstance] stringValueForConfigKey:(__configName)]

/**
 *  @return @c NSArray value associated with the given @c __configName.
 */
#define GREY_CONFIG_ARRAY(__configName) \
  [[GREYConfiguration sharedInstance] arrayValueForConfigKey:(__configName)]

NS_ASSUME_NONNULL_END
