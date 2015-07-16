#=======================================================================
#
#   Python Lexical Analyser
#
#   Lexical Analyser Specification
#
#=======================================================================

import types

import Actions
import DFA
import Errors
import Machines
import Regexps

# debug_flags for Lexicon constructor
DUMP_NFA = 1
DUMP_DFA = 2

class State(object):
  """
  This class is used as part of a Plex.Lexicon specification to
  introduce a user-defined state.

  Constructor:

     State(name, token_specifications)
  """

  name = None
  tokens = None

  def __init__(self, name, tokens):
    self.name = name
    self.tokens = tokens

class Lexicon(object):
  """
  Lexicon(specification) builds a lexical analyser from the given
  |specification|. The specification consists of a list of
  specification items. Each specification item may be either:

     1) A token definition, which is a tuple:

           (pattern, action)

        The |pattern| is a regular axpression built using the
        constructors defined in the Plex module.

        The |action| is the action to be performed when this pattern
        is recognised (see below).

     2) A state definition:

           State(name, tokens)

        where |name| is a character string naming the state,
        and |tokens| is a list of token definitions as
        above. The meaning and usage of states is described
        below.

  Actions
  -------

  The |action| in a token specication may be one of three things:

     1) A function, which is called as follows:

           function(scanner, text)

        where |scanner| is the relevant Scanner instance, and |text|
        is the matched text. If the function returns anything
        other than None, that value is returned as the value of the
        token. If it returns None, scanning continues as if the IGNORE
        action were specified (see below).

      2) One of the following special actions:

         IGNORE means that the recognised characters will be treated as
                white space and ignored. Scanning will continue until
                the next non-ignored token is recognised before returning.

         TEXT   causes the scanned text itself to be returned as the
                value of the token.

      3) Any other value, which is returned as the value of the token.

  States
  ------

  At any given time, the scanner is in one of a number of states.
  Associated with each state is a set of possible tokens. When scanning,
  only tokens associated with the current state are recognised.

  There is a default state, whose name is the empty string. Token
  definitions which are not inside any State definition belong to
  the default state.

  The initial state of the scanner is the default state. The state can
  be changed in one of two ways:

     1) Using Begin(state_name) as the action of a token.

     2) Calling the begin(state_name) method of the Scanner.

  To change back to the default state, use '' as the state name.
  """

  machine = None # Machine
  tables = None # StateTableMachine

  def __init__(self, specifications, debug = None, debug_flags = 7, timings = None):
    if type(specifications) != types.ListType:
      raise Errors.InvalidScanner("Scanner definition is not a list")
    if timings:
      from Timing import time
      total_time = 0.0
      time1 = time()
    nfa = Machines.Machine()
    default_initial_state = nfa.new_initial_state('')
    token_number = 1
    for spec in specifications:
      if isinstance(spec, State):
        user_initial_state = nfa.new_initial_state(spec.name)
        for token in spec.tokens:
          self.add_token_to_machine(
            nfa, user_initial_state, token, token_number)
          token_number = token_number + 1
      elif type(spec) == types.TupleType:
        self.add_token_to_machine(
          nfa, default_initial_state, spec, token_number)
        token_number = token_number + 1
      else:
        raise Errors.InvalidToken(
          token_number,
          "Expected a token definition (tuple) or State instance")
    if timings:
      time2 = time()
      total_time = total_time + (time2 - time1)
      time3 = time()
    if debug and (debug_flags & 1):
      debug.write("\n============= NFA ===========\n")
      nfa.dump(debug)
    dfa = DFA.nfa_to_dfa(nfa, debug = (debug_flags & 3) == 3 and debug)
    if timings:
      time4 = time()
      total_time = total_time + (time4 - time3)
    if debug and (debug_flags & 2):
      debug.write("\n============= DFA ===========\n")
      dfa.dump(debug)
    if timings:
      timings.write("Constructing NFA : %5.2f\n" % (time2 - time1))
      timings.write("Converting to DFA: %5.2f\n" % (time4 - time3))
      timings.write("TOTAL            : %5.2f\n" % total_time)
    self.machine = dfa

  def add_token_to_machine(self, machine, initial_state, token_spec, token_number):
    try:
      (re, action_spec) = self.parse_token_definition(token_spec)
      # Disabled this -- matching empty strings can be useful
      #if re.nullable:
      #  raise Errors.InvalidToken(
      #    token_number, "Pattern can match 0 input symbols")
      if isinstance(action_spec, Actions.Action):
        action = action_spec
      else:
        try:
          action_spec.__call__
        except AttributeError:
          action = Actions.Return(action_spec)
        else:
          action = Actions.Call(action_spec)
      final_state = machine.new_state()
      re.build_machine(machine, initial_state, final_state,
                       match_bol = 1, nocase = 0)
      final_state.set_action(action, priority = -token_number)
    except Errors.PlexError, e:
      raise e.__class__("Token number %d: %s" % (token_number, e))

  def parse_token_definition(self, token_spec):
    if type(token_spec) != types.TupleType:
      raise Errors.InvalidToken("Token definition is not a tuple")
    if len(token_spec) != 2:
      raise Errors.InvalidToken("Wrong number of items in token definition")
    pattern, action = token_spec
    if not isinstance(pattern, Regexps.RE):
      raise Errors.InvalidToken("Pattern is not an RE instance")
    return (pattern, action)

  def get_initial_state(self, name):
    return self.machine.get_initial_state(name)



