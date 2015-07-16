#=======================================================================
#
#   Python Lexical Analyser
#
#
#   Scanning an input stream
#
#=======================================================================

import cython
cython.declare(BOL=object, EOL=object, EOF=object, NOT_FOUND=object)

import Errors
from Regexps import BOL, EOL, EOF

NOT_FOUND = object()

class Scanner(object):
  """
  A Scanner is used to read tokens from a stream of characters
  using the token set specified by a Plex.Lexicon.

  Constructor:

    Scanner(lexicon, stream, name = '')

      See the docstring of the __init__ method for details.

  Methods:

    See the docstrings of the individual methods for more
    information.

    read() --> (value, text)
      Reads the next lexical token from the stream.

    position() --> (name, line, col)
      Returns the position of the last token read using the
      read() method.

    begin(state_name)
      Causes scanner to change state.

    produce(value [, text])
      Causes return of a token value to the caller of the
      Scanner.

  """

#  lexicon = None        # Lexicon
#  stream = None         # file-like object
#  name = ''
#  buffer = ''
#  buf_start_pos = 0     # position in input of start of buffer
#  next_pos = 0          # position in input of next char to read
#  cur_pos = 0           # position in input of current char
#  cur_line = 1          # line number of current char
#  cur_line_start = 0    # position in input of start of current line
#  start_pos = 0         # position in input of start of token
#  start_line = 0        # line number of start of token
#  start_col = 0         # position in line of start of token
#  text = None           # text of last token read
#  initial_state = None  # Node
#  state_name = ''       # Name of initial state
#  queue = None          # list of tokens to be returned
#  trace = 0

  def __init__(self, lexicon, stream, name = '', initial_pos = None):
    """
    Scanner(lexicon, stream, name = '')

      |lexicon| is a Plex.Lexicon instance specifying the lexical tokens
      to be recognised.

      |stream| can be a file object or anything which implements a
      compatible read() method.

      |name| is optional, and may be the name of the file being
      scanned or any other identifying string.
    """
    self.trace = 0

    self.buffer = u''
    self.buf_start_pos = 0
    self.next_pos = 0
    self.cur_pos = 0
    self.cur_line = 1
    self.start_pos = 0
    self.start_line = 0
    self.start_col = 0
    self.text = None
    self.state_name = None

    self.lexicon = lexicon
    self.stream = stream
    self.name = name
    self.queue = []
    self.initial_state = None
    self.begin('')
    self.next_pos = 0
    self.cur_pos = 0
    self.cur_line_start = 0
    self.cur_char = BOL
    self.input_state = 1
    if initial_pos is not None:
        self.cur_line, self.cur_line_start = initial_pos[1], -initial_pos[2]

  def read(self):
    """
    Read the next lexical token from the stream and return a
    tuple (value, text), where |value| is the value associated with
    the token as specified by the Lexicon, and |text| is the actual
    string read from the stream. Returns (None, '') on end of file.
    """
    queue = self.queue
    while not queue:
      self.text, action = self.scan_a_token()
      if action is None:
        self.produce(None)
        self.eof()
      else:
        value = action.perform(self, self.text)
        if value is not None:
          self.produce(value)
    result = queue[0]
    del queue[0]
    return result

  def scan_a_token(self):
    """
    Read the next input sequence recognised by the machine
    and return (text, action). Returns ('', None) on end of
    file.
    """
    self.start_pos = self.cur_pos
    self.start_line = self.cur_line
    self.start_col = self.cur_pos - self.cur_line_start
    action = self.run_machine_inlined()
    if action is not None:
      if self.trace:
        print("Scanner: read: Performing %s %d:%d" % (
          action, self.start_pos, self.cur_pos))
      text = self.buffer[self.start_pos - self.buf_start_pos :
                         self.cur_pos   - self.buf_start_pos]
      return (text, action)
    else:
      if self.cur_pos == self.start_pos:
        if self.cur_char is EOL:
          self.next_char()
        if self.cur_char is None or self.cur_char is EOF:
          return (u'', None)
      raise Errors.UnrecognizedInput(self, self.state_name)

  def run_machine_inlined(self):
    """
    Inlined version of run_machine for speed.
    """
    state = self.initial_state
    cur_pos = self.cur_pos
    cur_line = self.cur_line
    cur_line_start = self.cur_line_start
    cur_char = self.cur_char
    input_state = self.input_state
    next_pos = self.next_pos
    buffer = self.buffer
    buf_start_pos = self.buf_start_pos
    buf_len = len(buffer)
    b_action, b_cur_pos, b_cur_line, b_cur_line_start, b_cur_char, b_input_state, b_next_pos = \
              None, 0, 0, 0, u'', 0, 0
    trace = self.trace
    while 1:
      if trace: #TRACE#
        print("State %d, %d/%d:%s -->" % ( #TRACE#
          state['number'], input_state, cur_pos, repr(cur_char)))  #TRACE#
      # Begin inlined self.save_for_backup()
      #action = state.action #@slow
      action = state['action'] #@fast
      if action is not None:
        b_action, b_cur_pos, b_cur_line, b_cur_line_start, b_cur_char, b_input_state, b_next_pos = \
                  action, cur_pos, cur_line, cur_line_start, cur_char, input_state, next_pos
      # End inlined self.save_for_backup()
      c = cur_char
      #new_state = state.new_state(c) #@slow
      new_state = state.get(c, NOT_FOUND) #@fast
      if new_state is NOT_FOUND: #@fast
        new_state = c and state.get('else') #@fast
      if new_state:
        if trace: #TRACE#
          print("State %d" % new_state['number'])  #TRACE#
        state = new_state
        # Begin inlined: self.next_char()
        if input_state == 1:
          cur_pos = next_pos
          # Begin inlined: c = self.read_char()
          buf_index = next_pos - buf_start_pos
          if buf_index < buf_len:
            c = buffer[buf_index]
            next_pos = next_pos + 1
          else:
            discard = self.start_pos - buf_start_pos
            data = self.stream.read(0x1000)
            buffer = self.buffer[discard:] + data
            self.buffer = buffer
            buf_start_pos = buf_start_pos + discard
            self.buf_start_pos = buf_start_pos
            buf_len = len(buffer)
            buf_index = buf_index - discard
            if data:
              c = buffer[buf_index]
              next_pos = next_pos + 1
            else:
              c = u''
          # End inlined: c = self.read_char()
          if c == u'\n':
            cur_char = EOL
            input_state = 2
          elif not c:
            cur_char = EOL
            input_state = 4
          else:
            cur_char = c
        elif input_state == 2:
          cur_char = u'\n'
          input_state = 3
        elif input_state == 3:
          cur_line = cur_line + 1
          cur_line_start = cur_pos = next_pos
          cur_char = BOL
          input_state = 1
        elif input_state == 4:
          cur_char = EOF
          input_state = 5
        else: # input_state = 5
          cur_char = u''
        # End inlined self.next_char()
      else: # not new_state
        if trace: #TRACE#
          print("blocked")  #TRACE#
        # Begin inlined: action = self.back_up()
        if b_action is not None:
          (action, cur_pos, cur_line, cur_line_start,
           cur_char, input_state, next_pos) = \
                   (b_action, b_cur_pos, b_cur_line, b_cur_line_start,
                    b_cur_char, b_input_state, b_next_pos)
        else:
          action = None
        break # while 1
        # End inlined: action = self.back_up()
    self.cur_pos = cur_pos
    self.cur_line = cur_line
    self.cur_line_start = cur_line_start
    self.cur_char = cur_char
    self.input_state = input_state
    self.next_pos     = next_pos
    if trace: #TRACE#
      if action is not None: #TRACE#
        print("Doing %s" % action) #TRACE#
    return action

  def next_char(self):
    input_state = self.input_state
    if self.trace:
      print("Scanner: next: %s [%d] %d" % (" "*20, input_state, self.cur_pos))
    if input_state == 1:
      self.cur_pos = self.next_pos
      c = self.read_char()
      if c == u'\n':
        self.cur_char = EOL
        self.input_state = 2
      elif not c:
        self.cur_char = EOL
        self.input_state = 4
      else:
        self.cur_char = c
    elif input_state == 2:
      self.cur_char = u'\n'
      self.input_state = 3
    elif input_state == 3:
      self.cur_line = self.cur_line + 1
      self.cur_line_start = self.cur_pos = self.next_pos
      self.cur_char = BOL
      self.input_state = 1
    elif input_state == 4:
      self.cur_char = EOF
      self.input_state = 5
    else: # input_state = 5
      self.cur_char = u''
    if self.trace:
      print("--> [%d] %d %s" % (input_state, self.cur_pos, repr(self.cur_char)))

  def position(self):
    """
    Return a tuple (name, line, col) representing the location of
    the last token read using the read() method. |name| is the
    name that was provided to the Scanner constructor; |line|
    is the line number in the stream (1-based); |col| is the
    position within the line of the first character of the token
    (0-based).
    """
    return (self.name, self.start_line, self.start_col)

  def get_position(self):
    """Python accessible wrapper around position(), only for error reporting.
    """
    return self.position()

  def begin(self, state_name):
    """Set the current state of the scanner to the named state."""
    self.initial_state = (
      self.lexicon.get_initial_state(state_name))
    self.state_name = state_name

  def produce(self, value, text = None):
    """
    Called from an action procedure, causes |value| to be returned
    as the token value from read(). If |text| is supplied, it is
    returned in place of the scanned text.

    produce() can be called more than once during a single call to an action
    procedure, in which case the tokens are queued up and returned one
    at a time by subsequent calls to read(), until the queue is empty,
    whereupon scanning resumes.
    """
    if text is None:
      text = self.text
    self.queue.append((value, text))

  def eof(self):
    """
    Override this method if you want something to be done at
    end of file.
    """
