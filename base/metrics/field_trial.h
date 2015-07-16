// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// FieldTrial is a class for handling details of statistical experiments
// performed by actual users in the field (i.e., in a shipped or beta product).
// All code is called exclusively on the UI thread currently.
//
// The simplest example is an experiment to see whether one of two options
// produces "better" results across our user population.  In that scenario, UMA
// data is uploaded to aggregate the test results, and this FieldTrial class
// manages the state of each such experiment (state == which option was
// pseudo-randomly selected).
//
// States are typically generated randomly, either based on a one time
// randomization (which will yield the same results, in terms of selecting
// the client for a field trial or not, for every run of the program on a
// given machine), or by a session randomization (generated each time the
// application starts up, but held constant during the duration of the
// process).

//------------------------------------------------------------------------------
// Example:  Suppose we have an experiment involving memory, such as determining
// the impact of some pruning algorithm.
// We assume that we already have a histogram of memory usage, such as:

//   UMA_HISTOGRAM_COUNTS("Memory.RendererTotal", count);

// Somewhere in main thread initialization code, we'd probably define an
// instance of a FieldTrial, with code such as:

// // FieldTrials are reference counted, and persist automagically until
// // process teardown, courtesy of their automatic registration in
// // FieldTrialList.
// // Note: This field trial will run in Chrome instances compiled through
// //       8 July, 2015, and after that all instances will be in "StandardMem".
// scoped_refptr<base::FieldTrial> trial(
//     base::FieldTrialList::FactoryGetFieldTrial(
//         "MemoryExperiment", 1000, "StandardMem", 2015, 7, 8,
//         base::FieldTrial::ONE_TIME_RANDOMIZED, NULL));
//
// const int high_mem_group =
//     trial->AppendGroup("HighMem", 20);  // 2% in HighMem group.
// const int low_mem_group =
//     trial->AppendGroup("LowMem", 20);   // 2% in LowMem group.
// // Take action depending of which group we randomly land in.
// if (trial->group() == high_mem_group)
//   SetPruningAlgorithm(kType1);  // Sample setting of browser state.
// else if (trial->group() == low_mem_group)
//   SetPruningAlgorithm(kType2);  // Sample alternate setting.

//------------------------------------------------------------------------------

#ifndef BASE_METRICS_FIELD_TRIAL_H_
#define BASE_METRICS_FIELD_TRIAL_H_

#include <map>
#include <set>
#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/gtest_prod_util.h"
#include "base/memory/ref_counted.h"
#include "base/observer_list_threadsafe.h"
#include "base/synchronization/lock.h"
#include "base/time/time.h"

namespace base {

class FieldTrialList;

class BASE_EXPORT FieldTrial : public RefCounted<FieldTrial> {
 public:
  typedef int Probability;  // Probability type for being selected in a trial.

  // Specifies the persistence of the field trial group choice.
  enum RandomizationType {
    // One time randomized trials will persist the group choice between
    // restarts, which is recommended for most trials, especially those that
    // change user visible behavior.
    ONE_TIME_RANDOMIZED,
    // Session randomized trials will roll the dice to select a group on every
    // process restart.
    SESSION_RANDOMIZED,
  };

  // EntropyProvider is an interface for providing entropy for one-time
  // randomized (persistent) field trials.
  class BASE_EXPORT EntropyProvider {
   public:
    virtual ~EntropyProvider();

    // Returns a double in the range of [0, 1) to be used for the dice roll for
    // the specified field trial. If |randomization_seed| is not 0, it will be
    // used in preference to |trial_name| for generating the entropy by entropy
    // providers that support it. A given instance should always return the same
    // value given the same input |trial_name| and |randomization_seed| values.
    virtual double GetEntropyForTrial(const std::string& trial_name,
                                      uint32 randomization_seed) const = 0;
  };

  // A pair representing a Field Trial and its selected group.
  struct ActiveGroup {
    std::string trial_name;
    std::string group_name;
  };

  // A triplet representing a FieldTrial, its selected group and whether it's
  // active.
  struct FieldTrialState {
    std::string trial_name;
    std::string group_name;
    bool activated;
  };

  typedef std::vector<ActiveGroup> ActiveGroups;

  // A return value to indicate that a given instance has not yet had a group
  // assignment (and hence is not yet participating in the trial).
  static const int kNotFinalized;

  // Disables this trial, meaning it always determines the default group
  // has been selected. May be called immediately after construction, or
  // at any time after initialization (should not be interleaved with
  // AppendGroup calls). Once disabled, there is no way to re-enable a
  // trial.
  // TODO(mad): http://code.google.com/p/chromium/issues/detail?id=121446
  // This doesn't properly reset to Default when a group was forced.
  void Disable();

  // Establish the name and probability of the next group in this trial.
  // Sometimes, based on construction randomization, this call may cause the
  // provided group to be *THE* group selected for use in this instance.
  // The return value is the group number of the new group.
  int AppendGroup(const std::string& name, Probability group_probability);

  // Return the name of the FieldTrial (excluding the group name).
  const std::string& trial_name() const { return trial_name_; }

  // Return the randomly selected group number that was assigned, and notify
  // any/all observers that this finalized group number has presumably been used
  // (queried), and will never change. Note that this will force an instance to
  // participate, and make it illegal to attempt to probabilistically add any
  // other groups to the trial.
  int group();

  // If the group's name is empty, a string version containing the group number
  // is used as the group name. This causes a winner to be chosen if none was.
  const std::string& group_name();

  // Set the field trial as forced, meaning that it was setup earlier than
  // the hard coded registration of the field trial to override it.
  // This allows the code that was hard coded to register the field trial to
  // still succeed even though the field trial has already been registered.
  // This must be called after appending all the groups, since we will make
  // the group choice here. Note that this is a NOOP for already forced trials.
  // And, as the rest of the FieldTrial code, this is not thread safe and must
  // be done from the UI thread.
  void SetForced();

  // Enable benchmarking sets field trials to a common setting.
  static void EnableBenchmarking();

  // Creates a FieldTrial object with the specified parameters, to be used for
  // simulation of group assignment without actually affecting global field
  // trial state in the running process. Group assignment will be done based on
  // |entropy_value|, which must have a range of [0, 1).
  //
  // Note: Using this function will not register the field trial globally in the
  // running process - for that, use FieldTrialList::FactoryGetFieldTrial().
  //
  // The ownership of the returned FieldTrial is transfered to the caller which
  // is responsible for deref'ing it (e.g. by using scoped_refptr<FieldTrial>).
  static FieldTrial* CreateSimulatedFieldTrial(
      const std::string& trial_name,
      Probability total_probability,
      const std::string& default_group_name,
      double entropy_value);

 private:
  // Allow tests to access our innards for testing purposes.
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, Registration);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, AbsoluteProbabilities);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, RemainingProbability);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, FiftyFiftyProbability);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, MiddleProbabilities);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, OneWinner);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, DisableProbability);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, ActiveGroups);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, AllGroups);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, ActiveGroupsNotFinalized);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, Save);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, SaveAll);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, DuplicateRestore);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, SetForcedTurnFeatureOff);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, SetForcedTurnFeatureOn);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, SetForcedChangeDefault_Default);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, SetForcedChangeDefault_NonDefault);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, FloatBoundariesGiveEqualGroupSizes);
  FRIEND_TEST_ALL_PREFIXES(FieldTrialTest, DoesNotSurpassTotalProbability);

  friend class base::FieldTrialList;

  friend class RefCounted<FieldTrial>;

  // This is the group number of the 'default' group when a choice wasn't forced
  // by a call to FieldTrialList::CreateFieldTrial. It is kept private so that
  // consumers don't use it by mistake in cases where the group was forced.
  static const int kDefaultGroupNumber;

  // Creates a field trial with the specified parameters. Group assignment will
  // be done based on |entropy_value|, which must have a range of [0, 1).
  FieldTrial(const std::string& trial_name,
             Probability total_probability,
             const std::string& default_group_name,
             double entropy_value);
  virtual ~FieldTrial();

  // Return the default group name of the FieldTrial.
  std::string default_group_name() const { return default_group_name_; }

  // Marks this trial as having been registered with the FieldTrialList. Must be
  // called no more than once and before any |group()| calls have occurred.
  void SetTrialRegistered();

  // Sets the chosen group name and number.
  void SetGroupChoice(const std::string& group_name, int number);

  // Ensures that a group is chosen, if it hasn't yet been. The field trial
  // might yet be disabled, so this call will *not* notify observers of the
  // status.
  void FinalizeGroupChoice();

  // Returns the trial name and selected group name for this field trial via
  // the output parameter |active_group|, but only if the group has already
  // been chosen and has been externally observed via |group()| and the trial
  // has not been disabled. In that case, true is returned and |active_group|
  // is filled in; otherwise, the result is false and |active_group| is left
  // untouched.
  bool GetActiveGroup(ActiveGroup* active_group) const;

  // Returns the trial name and selected group name for this field trial via
  // the output parameter |field_trial_state|, but only if the trial has not
  // been disabled. In that case, true is returned and |field_trial_state| is
  // filled in; otherwise, the result is false and |field_trial_state| is left
  // untouched.
  bool GetState(FieldTrialState* field_trial_state) const;

  // Returns the group_name. A winner need not have been chosen.
  std::string group_name_internal() const { return group_name_; }

  // The name of the field trial, as can be found via the FieldTrialList.
  const std::string trial_name_;

  // The maximum sum of all probabilities supplied, which corresponds to 100%.
  // This is the scaling factor used to adjust supplied probabilities.
  const Probability divisor_;

  // The name of the default group.
  const std::string default_group_name_;

  // The randomly selected probability that is used to select a group (or have
  // the instance not participate).  It is the product of divisor_ and a random
  // number between [0, 1).
  Probability random_;

  // Sum of the probabilities of all appended groups.
  Probability accumulated_group_probability_;

  // The number that will be returned by the next AppendGroup() call.
  int next_group_number_;

  // The pseudo-randomly assigned group number.
  // This is kNotFinalized if no group has been assigned.
  int group_;

  // A textual name for the randomly selected group. Valid after |group()|
  // has been called.
  std::string group_name_;

  // When enable_field_trial_ is false, field trial reverts to the 'default'
  // group.
  bool enable_field_trial_;

  // When forced_ is true, we return the chosen group from AppendGroup when
  // appropriate.
  bool forced_;

  // Specifies whether the group choice has been reported to observers.
  bool group_reported_;

  // Whether this trial is registered with the global FieldTrialList and thus
  // should notify it when its group is queried.
  bool trial_registered_;

  // When benchmarking is enabled, field trials all revert to the 'default'
  // group.
  static bool enable_benchmarking_;

  DISALLOW_COPY_AND_ASSIGN(FieldTrial);
};

//------------------------------------------------------------------------------
// Class with a list of all active field trials.  A trial is active if it has
// been registered, which includes evaluating its state based on its probaility.
// Only one instance of this class exists.
class BASE_EXPORT FieldTrialList {
 public:
  // Specifies whether field trials should be activated (marked as "used"), when
  // created using |CreateTrialsFromString()|. Has no effect on trials that are
  // prefixed with |kActivationMarker|, which will always be activated."
  enum FieldTrialActivationMode {
    DONT_ACTIVATE_TRIALS,
    ACTIVATE_TRIALS,
  };

  // Define a separator character to use when creating a persistent form of an
  // instance.  This is intended for use as a command line argument, passed to a
  // second process to mimic our state (i.e., provide the same group name).
  static const char kPersistentStringSeparator;  // Currently a slash.

  // Define a marker character to be used as a prefix to a trial name on the
  // command line which forces its activation.
  static const char kActivationMarker;  // Currently an asterisk.

  // Year that is guaranteed to not be expired when instantiating a field trial
  // via |FactoryGetFieldTrial()|.  Set to two years from the build date.
  static int kNoExpirationYear;

  // Observer is notified when a FieldTrial's group is selected.
  class BASE_EXPORT Observer {
   public:
    // Notify observers when FieldTrials's group is selected.
    virtual void OnFieldTrialGroupFinalized(const std::string& trial_name,
                                            const std::string& group_name) = 0;

   protected:
    virtual ~Observer();
  };

  // This singleton holds the global list of registered FieldTrials.
  //
  // To support one-time randomized field trials, specify a non-NULL
  // |entropy_provider| which should be a source of uniformly distributed
  // entropy values. Takes ownership of |entropy_provider|. If one time
  // randomization is not desired, pass in NULL for |entropy_provider|.
  explicit FieldTrialList(const FieldTrial::EntropyProvider* entropy_provider);

  // Destructor Release()'s references to all registered FieldTrial instances.
  ~FieldTrialList();

  // Get a FieldTrial instance from the factory.
  //
  // |name| is used to register the instance with the FieldTrialList class,
  // and can be used to find the trial (only one trial can be present for each
  // name). |default_group_name| is the name of the default group which will
  // be chosen if none of the subsequent appended groups get to be chosen.
  // |default_group_number| can receive the group number of the default group as
  // AppendGroup returns the number of the subsequence groups. |trial_name| and
  // |default_group_name| may not be empty but |default_group_number| can be
  // NULL if the value is not needed.
  //
  // Group probabilities that are later supplied must sum to less than or equal
  // to the |total_probability|. Arguments |year|, |month| and |day_of_month|
  // specify the expiration time. If the build time is after the expiration time
  // then the field trial reverts to the 'default' group.
  //
  // Use this static method to get a startup-randomized FieldTrial or a
  // previously created forced FieldTrial.
  static FieldTrial* FactoryGetFieldTrial(
      const std::string& trial_name,
      FieldTrial::Probability total_probability,
      const std::string& default_group_name,
      const int year,
      const int month,
      const int day_of_month,
      FieldTrial::RandomizationType randomization_type,
      int* default_group_number);

  // Same as FactoryGetFieldTrial(), but allows specifying a custom seed to be
  // used on one-time randomized field trials (instead of a hash of the trial
  // name, which is used otherwise or if |randomization_seed| has value 0). The
  // |randomization_seed| value (other than 0) should never be the same for two
  // trials, else this would result in correlated group assignments.
  // Note: Using a custom randomization seed is only supported by the
  // PermutedEntropyProvider (which is used when UMA is not enabled).
  static FieldTrial* FactoryGetFieldTrialWithRandomizationSeed(
      const std::string& trial_name,
      FieldTrial::Probability total_probability,
      const std::string& default_group_name,
      const int year,
      const int month,
      const int day_of_month,
      FieldTrial::RandomizationType randomization_type,
      uint32 randomization_seed,
      int* default_group_number);

  // The Find() method can be used to test to see if a named Trial was already
  // registered, or to retrieve a pointer to it from the global map.
  static FieldTrial* Find(const std::string& name);

  // Returns the group number chosen for the named trial, or
  // FieldTrial::kNotFinalized if the trial does not exist.
  static int FindValue(const std::string& name);

  // Returns the group name chosen for the named trial, or the
  // empty string if the trial does not exist.
  static std::string FindFullName(const std::string& name);

  // Returns true if the named trial has been registered.
  static bool TrialExists(const std::string& name);

  // Creates a persistent representation of active FieldTrial instances for
  // resurrection in another process. This allows randomization to be done in
  // one process, and secondary processes can be synchronized on the result.
  // The resulting string contains the name and group name pairs of all
  // registered FieldTrials for which the group has been chosen and externally
  // observed (via |group()|) and which have not been disabled, with "/" used
  // to separate all names and to terminate the string. This string is parsed
  // by |CreateTrialsFromString()|.
  static void StatesToString(std::string* output);

  // Creates a persistent representation of all FieldTrial instances for
  // resurrection in another process. This allows randomization to be done in
  // one process, and secondary processes can be synchronized on the result.
  // The resulting string contains the name and group name pairs of all
  // registered FieldTrials which have not been disabled, with "/" used
  // to separate all names and to terminate the string. All activated trials
  // have their name prefixed with "*". This string is parsed by
  // |CreateTrialsFromString()|.
  static void AllStatesToString(std::string* output);

  // Fills in the supplied vector |active_groups| (which must be empty when
  // called) with a snapshot of all registered FieldTrials for which the group
  // has been chosen and externally observed (via |group()|) and which have
  // not been disabled.
  static void GetActiveFieldTrialGroups(
      FieldTrial::ActiveGroups* active_groups);

  // Use a state string (re: StatesToString()) to augment the current list of
  // field trials to include the supplied trials, and using a 100% probability
  // for each trial, force them to have the same group string. This is commonly
  // used in a non-browser process, to carry randomly selected state in a
  // browser process into this non-browser process, but could also be invoked
  // through a command line argument to the browser process. The created field
  // trials are all marked as "used" for the purposes of active trial reporting
  // if |mode| is ACTIVATE_TRIALS, otherwise each trial will be marked as "used"
  // if it is prefixed with |kActivationMarker|. Trial names in
  // |ignored_trial_names| are ignored when parsing |prior_trials|.
  static bool CreateTrialsFromString(
      const std::string& prior_trials,
      FieldTrialActivationMode mode,
      const std::set<std::string>& ignored_trial_names);

  // Create a FieldTrial with the given |name| and using 100% probability for
  // the FieldTrial, force FieldTrial to have the same group string as
  // |group_name|. This is commonly used in a non-browser process, to carry
  // randomly selected state in a browser process into this non-browser process.
  // It returns NULL if there is a FieldTrial that is already registered with
  // the same |name| but has different finalized group string (|group_name|).
  static FieldTrial* CreateFieldTrial(const std::string& name,
                                      const std::string& group_name);

  // Add an observer to be notified when a field trial is irrevocably committed
  // to being part of some specific field_group (and hence the group_name is
  // also finalized for that field_trial).
  static void AddObserver(Observer* observer);

  // Remove an observer.
  static void RemoveObserver(Observer* observer);

  // Notify all observers that a group has been finalized for |field_trial|.
  static void NotifyFieldTrialGroupSelection(FieldTrial* field_trial);

  // Return the number of active field trials.
  static size_t GetFieldTrialCount();

 private:
  // A map from FieldTrial names to the actual instances.
  typedef std::map<std::string, FieldTrial*> RegistrationMap;

  // If one-time randomization is enabled, returns a weak pointer to the
  // corresponding EntropyProvider. Otherwise, returns NULL.
  static const FieldTrial::EntropyProvider*
      GetEntropyProviderForOneTimeRandomization();

  // Helper function should be called only while holding lock_.
  FieldTrial* PreLockedFind(const std::string& name);

  // Register() stores a pointer to the given trial in a global map.
  // This method also AddRef's the indicated trial.
  // This should always be called after creating a new FieldTrial instance.
  static void Register(FieldTrial* trial);

  static FieldTrialList* global_;  // The singleton of this class.

  // This will tell us if there is an attempt to register a field
  // trial or check if one-time randomization is enabled without
  // creating the FieldTrialList. This is not an error, unless a
  // FieldTrialList is created after that.
  static bool used_without_global_;

  // Lock for access to registered_.
  base::Lock lock_;
  RegistrationMap registered_;

  // Entropy provider to be used for one-time randomized field trials. If NULL,
  // one-time randomization is not supported.
  scoped_ptr<const FieldTrial::EntropyProvider> entropy_provider_;

  // List of observers to be notified when a group is selected for a FieldTrial.
  scoped_refptr<ObserverListThreadSafe<Observer> > observer_list_;

  DISALLOW_COPY_AND_ASSIGN(FieldTrialList);
};

}  // namespace base

#endif  // BASE_METRICS_FIELD_TRIAL_H_
