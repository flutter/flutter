#=======================================================================
#
#   Python Lexical Analyser
#
#   Converting NFA to DFA
#
#=======================================================================

import Machines
from Machines import LOWEST_PRIORITY
from Transitions import TransitionMap

def nfa_to_dfa(old_machine, debug = None):
  """
  Given a nondeterministic Machine, return a new equivalent
  Machine which is deterministic.
  """
  # We build a new machine whose states correspond to sets of states
  # in the old machine. Initially we add a new state corresponding to
  # the epsilon-closure of each initial old state. Then we give transitions
  # to each new state which are the union of all transitions out of any
  # of the corresponding old states. The new state reached on a given
  # character is the one corresponding to the set of states reachable
  # on that character from any of the old states. As new combinations of
  # old states are created, new states are added as needed until closure
  # is reached.
  new_machine = Machines.FastMachine()
  state_map = StateMap(new_machine)
  # Seed the process using the initial states of the old machine.
  # Make the corresponding new states into initial states of the new
  # machine with the same names.
  for (key, old_state) in old_machine.initial_states.iteritems():
    new_state = state_map.old_to_new(epsilon_closure(old_state))
    new_machine.make_initial_state(key, new_state)
  # Tricky bit here: we add things to the end of this list while we're
  # iterating over it. The iteration stops when closure is achieved.
  for new_state in new_machine.states:
    transitions = TransitionMap()
    for old_state in state_map.new_to_old(new_state):
      for event, old_target_states in old_state.transitions.iteritems():
        if event and old_target_states:
          transitions.add_set(event, set_epsilon_closure(old_target_states))
    for event, old_states in transitions.iteritems():
      new_machine.add_transitions(new_state, event, state_map.old_to_new(old_states))
  if debug:
    debug.write("\n===== State Mapping =====\n")
    state_map.dump(debug)
  return new_machine

def set_epsilon_closure(state_set):
  """
  Given a set of states, return the union of the epsilon
  closures of its member states.
  """
  result = {}
  for state1 in state_set:
    for state2 in epsilon_closure(state1):
      result[state2] = 1
  return result

def epsilon_closure(state):
  """
  Return the set of states reachable from the given state
  by epsilon moves.
  """
  # Cache the result
  result = state.epsilon_closure
  if result is None:
    result = {}
    state.epsilon_closure = result
    add_to_epsilon_closure(result, state)
  return result

def add_to_epsilon_closure(state_set, state):
  """
  Recursively add to |state_set| states reachable from the given state
  by epsilon moves.
  """
  if not state_set.get(state, 0):
    state_set[state] = 1
    state_set_2 = state.transitions.get_epsilon()
    if state_set_2:
      for state2 in state_set_2:
        add_to_epsilon_closure(state_set, state2)

class StateMap(object):
  """
  Helper class used by nfa_to_dfa() to map back and forth between
  sets of states from the old machine and states of the new machine.
  """
  new_machine     = None # Machine
  old_to_new_dict = None # {(old_state,...) : new_state}
  new_to_old_dict = None # {id(new_state) : old_state_set}

  def __init__(self, new_machine):
    self.new_machine = new_machine
    self.old_to_new_dict = {}
    self.new_to_old_dict= {}

  def old_to_new(self, old_state_set):
    """
    Return the state of the new machine corresponding to the
    set of old machine states represented by |state_set|. A new
    state will be created if necessary. If any of the old states
    are accepting states, the new state will be an accepting state
    with the highest priority action from the old states.
    """
    key = self.make_key(old_state_set)
    new_state = self.old_to_new_dict.get(key, None)
    if not new_state:
      action = self.highest_priority_action(old_state_set)
      new_state = self.new_machine.new_state(action)
      self.old_to_new_dict[key] = new_state
      self.new_to_old_dict[id(new_state)] = old_state_set
      #for old_state in old_state_set.keys():
        #new_state.merge_actions(old_state)
    return new_state

  def highest_priority_action(self, state_set):
    best_action = None
    best_priority = LOWEST_PRIORITY
    for state in state_set:
      priority = state.action_priority
      if priority > best_priority:
        best_action = state.action
        best_priority = priority
    return best_action

#    def old_to_new_set(self, old_state_set):
#        """
#        Return the new state corresponding to a set of old states as
#        a singleton set.
#        """
#        return {self.old_to_new(old_state_set):1}

  def new_to_old(self, new_state):
    """Given a new state, return a set of corresponding old states."""
    return self.new_to_old_dict[id(new_state)]

  def make_key(self, state_set):
    """
    Convert a set of states into a uniquified
    sorted tuple suitable for use as a dictionary key.
    """
    lst = list(state_set)
    lst.sort()
    return tuple(lst)

  def dump(self, file):
    from Transitions import state_set_str
    for new_state in self.new_machine.states:
      old_state_set = self.new_to_old_dict[id(new_state)]
      file.write("   State %s <-- %s\n" % (
        new_state['number'], state_set_str(old_state_set)))


