#
#   Plex - Transition Maps
#
#   This version represents state sets direcly as dicts
#   for speed.
#

from sys import maxint as maxint

class TransitionMap(object):
  """
  A TransitionMap maps an input event to a set of states.
  An input event is one of: a range of character codes,
  the empty string (representing an epsilon move), or one
  of the special symbols BOL, EOL, EOF.

  For characters, this implementation compactly represents
  the map by means of a list:

    [code_0, states_0, code_1, states_1, code_2, states_2,
      ..., code_n-1, states_n-1, code_n]

  where |code_i| is a character code, and |states_i| is a
  set of states corresponding to characters with codes |c|
  in the range |code_i| <= |c| <= |code_i+1|.

  The following invariants hold:
    n >= 1
    code_0 == -maxint
    code_n == maxint
    code_i < code_i+1 for i in 0..n-1
    states_0 == states_n-1

  Mappings for the special events '', BOL, EOL, EOF are
  kept separately in a dictionary.
  """

  map = None     # The list of codes and states
  special = None # Mapping for special events

  def __init__(self, map = None, special = None):
    if not map:
      map = [-maxint, {}, maxint]
    if not special:
      special = {}
    self.map = map
    self.special = special
    #self.check() ###

  def add(self, event, new_state,
    TupleType = tuple):
    """
    Add transition to |new_state| on |event|.
    """
    if type(event) is TupleType:
      code0, code1 = event
      i = self.split(code0)
      j = self.split(code1)
      map = self.map
      while i < j:
        map[i + 1][new_state] = 1
        i = i + 2
    else:
      self.get_special(event)[new_state] = 1

  def add_set(self, event, new_set,
    TupleType = tuple):
    """
    Add transitions to the states in |new_set| on |event|.
    """
    if type(event) is TupleType:
      code0, code1 = event
      i = self.split(code0)
      j = self.split(code1)
      map = self.map
      while i < j:
        map[i + 1].update(new_set)
        i = i + 2
    else:
      self.get_special(event).update(new_set)

  def get_epsilon(self,
    none = None):
    """
    Return the mapping for epsilon, or None.
    """
    return self.special.get('', none)

  def iteritems(self,
    len = len):
    """
    Return the mapping as an iterable of ((code1, code2), state_set) and
    (special_event, state_set) pairs.
    """
    result = []
    map = self.map
    else_set = map[1]
    i = 0
    n = len(map) - 1
    code0 = map[0]
    while i < n:
      set = map[i + 1]
      code1 = map[i + 2]
      if set or else_set:
        result.append(((code0, code1), set))
      code0 = code1
      i = i + 2
    for event, set in self.special.iteritems():
      if set:
        result.append((event, set))
    return iter(result)
  items = iteritems

  # ------------------- Private methods --------------------

  def split(self, code,
    len = len, maxint = maxint):
    """
    Search the list for the position of the split point for |code|,
    inserting a new split point if necessary. Returns index |i| such
    that |code| == |map[i]|.
    """
    # We use a funky variation on binary search.
    map = self.map
    hi = len(map) - 1
    # Special case: code == map[-1]
    if code == maxint:
      return hi
    # General case
    lo = 0
    # loop invariant: map[lo] <= code < map[hi] and hi - lo >= 2
    while hi - lo >= 4:
      # Find midpoint truncated to even index
      mid = ((lo + hi) // 2) & ~1
      if code < map[mid]:
        hi = mid
      else:
        lo = mid
    # map[lo] <= code < map[hi] and hi - lo == 2
    if map[lo] == code:
      return lo
    else:
      map[hi:hi] = [code, map[hi - 1].copy()]
      #self.check() ###
      return hi

  def get_special(self, event):
    """
    Get state set for special event, adding a new entry if necessary.
    """
    special = self.special
    set = special.get(event, None)
    if not set:
      set = {}
      special[event] = set
    return set

  # --------------------- Conversion methods -----------------------

  def __str__(self):
    map_strs = []
    map = self.map
    n = len(map)
    i = 0
    while i < n:
      code = map[i]
      if code == -maxint:
        code_str = "-inf"
      elif code == maxint:
        code_str = "inf"
      else:
        code_str = str(code)
      map_strs.append(code_str)
      i = i + 1
      if i < n:
        map_strs.append(state_set_str(map[i]))
      i = i + 1
    special_strs = {}
    for event, set in self.special.iteritems():
      special_strs[event] = state_set_str(set)
    return "[%s]+%s" % (
      ','.join(map_strs),
      special_strs
    )

  # --------------------- Debugging methods -----------------------

  def check(self):
    """Check data structure integrity."""
    if not self.map[-3] < self.map[-1]:
      print(self)
      assert 0

  def dump(self, file):
    map = self.map
    i = 0
    n = len(map) - 1
    while i < n:
      self.dump_range(map[i], map[i + 2], map[i + 1], file)
      i = i + 2
    for event, set in self.special.iteritems():
      if set:
        if not event:
          event = 'empty'
        self.dump_trans(event, set, file)

  def dump_range(self, code0, code1, set, file):
    if set:
      if code0 == -maxint:
        if code1 == maxint:
          k = "any"
        else:
          k = "< %s" % self.dump_char(code1)
      elif code1 == maxint:
        k = "> %s" % self.dump_char(code0 - 1)
      elif code0 == code1 - 1:
        k = self.dump_char(code0)
      else:
        k = "%s..%s" % (self.dump_char(code0),
          self.dump_char(code1 - 1))
      self.dump_trans(k, set, file)

  def dump_char(self, code):
    if 0 <= code <= 255:
      return repr(chr(code))
    else:
      return "chr(%d)" % code

  def dump_trans(self, key, set, file):
    file.write("      %s --> %s\n" % (key, self.dump_set(set)))

  def dump_set(self, set):
    return state_set_str(set)

#
#   State set manipulation functions
#

#def merge_state_sets(set1, set2):
#        for state in set2.keys():
#            set1[state] = 1

def state_set_str(set):
  return "[%s]" % ','.join(["S%d" % state.number for state in set])



