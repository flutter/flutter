# -----------------------------------------------------------------------------
# ply: lex.py
#
# Copyright (C) 2001-2011,
# David M. Beazley (Dabeaz LLC)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.  
# * Redistributions in binary form must reproduce the above copyright notice, 
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.  
# * Neither the name of the David Beazley or Dabeaz LLC may be used to
#   endorse or promote products derived from this software without
#  specific prior written permission. 
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------

__version__    = "3.4"
__tabversion__ = "3.2"       # Version of table file used

import re, sys, types, copy, os

# This tuple contains known string types
try:
    # Python 2.6
    StringTypes = (types.StringType, types.UnicodeType)
except AttributeError:
    # Python 3.0
    StringTypes = (str, bytes)

# Extract the code attribute of a function. Different implementations
# are for Python 2/3 compatibility.

if sys.version_info[0] < 3:
    def func_code(f):
        return f.func_code
else:
    def func_code(f):
        return f.__code__

# This regular expression is used to match valid token names
_is_identifier = re.compile(r'^[a-zA-Z0-9_]+$')

# Exception thrown when invalid token encountered and no default error
# handler is defined.

class LexError(Exception):
    def __init__(self,message,s):
         self.args = (message,)
         self.text = s

# Token class.  This class is used to represent the tokens produced.
class LexToken(object):
    def __str__(self):
        return "LexToken(%s,%r,%d,%d)" % (self.type,self.value,self.lineno,self.lexpos)
    def __repr__(self):
        return str(self)

# This object is a stand-in for a logging object created by the 
# logging module.  

class PlyLogger(object):
    def __init__(self,f):
        self.f = f
    def critical(self,msg,*args,**kwargs):
        self.f.write((msg % args) + "\n")

    def warning(self,msg,*args,**kwargs):
        self.f.write("WARNING: "+ (msg % args) + "\n")

    def error(self,msg,*args,**kwargs):
        self.f.write("ERROR: " + (msg % args) + "\n")

    info = critical
    debug = critical

# Null logger is used when no output is generated. Does nothing.
class NullLogger(object):
    def __getattribute__(self,name):
        return self
    def __call__(self,*args,**kwargs):
        return self

# -----------------------------------------------------------------------------
#                        === Lexing Engine ===
#
# The following Lexer class implements the lexer runtime.   There are only
# a few public methods and attributes:
#
#    input()          -  Store a new string in the lexer
#    token()          -  Get the next token
#    clone()          -  Clone the lexer
#
#    lineno           -  Current line number
#    lexpos           -  Current position in the input string
# -----------------------------------------------------------------------------

class Lexer:
    def __init__(self):
        self.lexre = None             # Master regular expression. This is a list of
                                      # tuples (re,findex) where re is a compiled
                                      # regular expression and findex is a list
                                      # mapping regex group numbers to rules
        self.lexretext = None         # Current regular expression strings
        self.lexstatere = {}          # Dictionary mapping lexer states to master regexs
        self.lexstateretext = {}      # Dictionary mapping lexer states to regex strings
        self.lexstaterenames = {}     # Dictionary mapping lexer states to symbol names
        self.lexstate = "INITIAL"     # Current lexer state
        self.lexstatestack = []       # Stack of lexer states
        self.lexstateinfo = None      # State information
        self.lexstateignore = {}      # Dictionary of ignored characters for each state
        self.lexstateerrorf = {}      # Dictionary of error functions for each state
        self.lexreflags = 0           # Optional re compile flags
        self.lexdata = None           # Actual input data (as a string)
        self.lexpos = 0               # Current position in input text
        self.lexlen = 0               # Length of the input text
        self.lexerrorf = None         # Error rule (if any)
        self.lextokens = None         # List of valid tokens
        self.lexignore = ""           # Ignored characters
        self.lexliterals = ""         # Literal characters that can be passed through
        self.lexmodule = None         # Module
        self.lineno = 1               # Current line number
        self.lexoptimize = 0          # Optimized mode

    def clone(self,object=None):
        c = copy.copy(self)

        # If the object parameter has been supplied, it means we are attaching the
        # lexer to a new object.  In this case, we have to rebind all methods in
        # the lexstatere and lexstateerrorf tables.

        if object:
            newtab = { }
            for key, ritem in self.lexstatere.items():
                newre = []
                for cre, findex in ritem:
                     newfindex = []
                     for f in findex:
                         if not f or not f[0]:
                             newfindex.append(f)
                             continue
                         newfindex.append((getattr(object,f[0].__name__),f[1]))
                newre.append((cre,newfindex))
                newtab[key] = newre
            c.lexstatere = newtab
            c.lexstateerrorf = { }
            for key, ef in self.lexstateerrorf.items():
                c.lexstateerrorf[key] = getattr(object,ef.__name__)
            c.lexmodule = object
        return c

    # ------------------------------------------------------------
    # writetab() - Write lexer information to a table file
    # ------------------------------------------------------------
    def writetab(self,tabfile,outputdir=""):
        if isinstance(tabfile,types.ModuleType):
            return
        basetabfilename = tabfile.split(".")[-1]
        filename = os.path.join(outputdir,basetabfilename)+".py"
        tf = open(filename,"w")
        tf.write("# %s.py. This file automatically created by PLY (version %s). Don't edit!\n" % (tabfile,__version__))
        tf.write("_tabversion   = %s\n" % repr(__version__))
        tf.write("_lextokens    = %s\n" % repr(self.lextokens))
        tf.write("_lexreflags   = %s\n" % repr(self.lexreflags))
        tf.write("_lexliterals  = %s\n" % repr(self.lexliterals))
        tf.write("_lexstateinfo = %s\n" % repr(self.lexstateinfo))

        tabre = { }
        # Collect all functions in the initial state
        initial = self.lexstatere["INITIAL"]
        initialfuncs = []
        for part in initial:
            for f in part[1]:
                if f and f[0]:
                    initialfuncs.append(f)

        for key, lre in self.lexstatere.items():
             titem = []
             for i in range(len(lre)):
                  titem.append((self.lexstateretext[key][i],_funcs_to_names(lre[i][1],self.lexstaterenames[key][i])))
             tabre[key] = titem

        tf.write("_lexstatere   = %s\n" % repr(tabre))
        tf.write("_lexstateignore = %s\n" % repr(self.lexstateignore))

        taberr = { }
        for key, ef in self.lexstateerrorf.items():
             if ef:
                  taberr[key] = ef.__name__
             else:
                  taberr[key] = None
        tf.write("_lexstateerrorf = %s\n" % repr(taberr))
        tf.close()

    # ------------------------------------------------------------
    # readtab() - Read lexer information from a tab file
    # ------------------------------------------------------------
    def readtab(self,tabfile,fdict):
        if isinstance(tabfile,types.ModuleType):
            lextab = tabfile
        else:
            if sys.version_info[0] < 3:
                exec("import %s as lextab" % tabfile)
            else:
                env = { }
                exec("import %s as lextab" % tabfile, env,env)
                lextab = env['lextab']

        if getattr(lextab,"_tabversion","0.0") != __version__:
            raise ImportError("Inconsistent PLY version")

        self.lextokens      = lextab._lextokens
        self.lexreflags     = lextab._lexreflags
        self.lexliterals    = lextab._lexliterals
        self.lexstateinfo   = lextab._lexstateinfo
        self.lexstateignore = lextab._lexstateignore
        self.lexstatere     = { }
        self.lexstateretext = { }
        for key,lre in lextab._lexstatere.items():
             titem = []
             txtitem = []
             for i in range(len(lre)):
                  titem.append((re.compile(lre[i][0],lextab._lexreflags | re.VERBOSE),_names_to_funcs(lre[i][1],fdict)))
                  txtitem.append(lre[i][0])
             self.lexstatere[key] = titem
             self.lexstateretext[key] = txtitem
        self.lexstateerrorf = { }
        for key,ef in lextab._lexstateerrorf.items():
             self.lexstateerrorf[key] = fdict[ef]
        self.begin('INITIAL')

    # ------------------------------------------------------------
    # input() - Push a new string into the lexer
    # ------------------------------------------------------------
    def input(self,s):
        # Pull off the first character to see if s looks like a string
        c = s[:1]
        if not isinstance(c,StringTypes):
            raise ValueError("Expected a string")
        self.lexdata = s
        self.lexpos = 0
        self.lexlen = len(s)

    # ------------------------------------------------------------
    # begin() - Changes the lexing state
    # ------------------------------------------------------------
    def begin(self,state):
        if not state in self.lexstatere:
            raise ValueError("Undefined state")
        self.lexre = self.lexstatere[state]
        self.lexretext = self.lexstateretext[state]
        self.lexignore = self.lexstateignore.get(state,"")
        self.lexerrorf = self.lexstateerrorf.get(state,None)
        self.lexstate = state

    # ------------------------------------------------------------
    # push_state() - Changes the lexing state and saves old on stack
    # ------------------------------------------------------------
    def push_state(self,state):
        self.lexstatestack.append(self.lexstate)
        self.begin(state)

    # ------------------------------------------------------------
    # pop_state() - Restores the previous state
    # ------------------------------------------------------------
    def pop_state(self):
        self.begin(self.lexstatestack.pop())

    # ------------------------------------------------------------
    # current_state() - Returns the current lexing state
    # ------------------------------------------------------------
    def current_state(self):
        return self.lexstate

    # ------------------------------------------------------------
    # skip() - Skip ahead n characters
    # ------------------------------------------------------------
    def skip(self,n):
        self.lexpos += n

    # ------------------------------------------------------------
    # opttoken() - Return the next token from the Lexer
    #
    # Note: This function has been carefully implemented to be as fast
    # as possible.  Don't make changes unless you really know what
    # you are doing
    # ------------------------------------------------------------
    def token(self):
        # Make local copies of frequently referenced attributes
        lexpos    = self.lexpos
        lexlen    = self.lexlen
        lexignore = self.lexignore
        lexdata   = self.lexdata

        while lexpos < lexlen:
            # This code provides some short-circuit code for whitespace, tabs, and other ignored characters
            if lexdata[lexpos] in lexignore:
                lexpos += 1
                continue

            # Look for a regular expression match
            for lexre,lexindexfunc in self.lexre:
                m = lexre.match(lexdata,lexpos)
                if not m: continue

                # Create a token for return
                tok = LexToken()
                tok.value = m.group()
                tok.lineno = self.lineno
                tok.lexpos = lexpos

                i = m.lastindex
                func,tok.type = lexindexfunc[i]

                if not func:
                   # If no token type was set, it's an ignored token
                   if tok.type:
                      self.lexpos = m.end()
                      return tok
                   else:
                      lexpos = m.end()
                      break

                lexpos = m.end()

                # If token is processed by a function, call it

                tok.lexer = self      # Set additional attributes useful in token rules
                self.lexmatch = m
                self.lexpos = lexpos

                newtok = func(tok)

                # Every function must return a token, if nothing, we just move to next token
                if not newtok:
                    lexpos    = self.lexpos         # This is here in case user has updated lexpos.
                    lexignore = self.lexignore      # This is here in case there was a state change
                    break

                # Verify type of the token.  If not in the token map, raise an error
                if not self.lexoptimize:
                    if not newtok.type in self.lextokens:
                        raise LexError("%s:%d: Rule '%s' returned an unknown token type '%s'" % (
                            func_code(func).co_filename, func_code(func).co_firstlineno,
                            func.__name__, newtok.type),lexdata[lexpos:])

                return newtok
            else:
                # No match, see if in literals
                if lexdata[lexpos] in self.lexliterals:
                    tok = LexToken()
                    tok.value = lexdata[lexpos]
                    tok.lineno = self.lineno
                    tok.type = tok.value
                    tok.lexpos = lexpos
                    self.lexpos = lexpos + 1
                    return tok

                # No match. Call t_error() if defined.
                if self.lexerrorf:
                    tok = LexToken()
                    tok.value = self.lexdata[lexpos:]
                    tok.lineno = self.lineno
                    tok.type = "error"
                    tok.lexer = self
                    tok.lexpos = lexpos
                    self.lexpos = lexpos
                    newtok = self.lexerrorf(tok)
                    if lexpos == self.lexpos:
                        # Error method didn't change text position at all. This is an error.
                        raise LexError("Scanning error. Illegal character '%s'" % (lexdata[lexpos]), lexdata[lexpos:])
                    lexpos = self.lexpos
                    if not newtok: continue
                    return newtok

                self.lexpos = lexpos
                raise LexError("Illegal character '%s' at index %d" % (lexdata[lexpos],lexpos), lexdata[lexpos:])

        self.lexpos = lexpos + 1
        if self.lexdata is None:
             raise RuntimeError("No input string given with input()")
        return None

    # Iterator interface
    def __iter__(self):
        return self

    def next(self):
        t = self.token()
        if t is None:
            raise StopIteration
        return t

    __next__ = next

# -----------------------------------------------------------------------------
#                           ==== Lex Builder ===
#
# The functions and classes below are used to collect lexing information
# and build a Lexer object from it.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# get_caller_module_dict()
#
# This function returns a dictionary containing all of the symbols defined within
# a caller further down the call stack.  This is used to get the environment
# associated with the yacc() call if none was provided.
# -----------------------------------------------------------------------------

def get_caller_module_dict(levels):
    try:
        raise RuntimeError
    except RuntimeError:
        e,b,t = sys.exc_info()
        f = t.tb_frame
        while levels > 0:
            f = f.f_back                   
            levels -= 1
        ldict = f.f_globals.copy()
        if f.f_globals != f.f_locals:
            ldict.update(f.f_locals)

        return ldict

# -----------------------------------------------------------------------------
# _funcs_to_names()
#
# Given a list of regular expression functions, this converts it to a list
# suitable for output to a table file
# -----------------------------------------------------------------------------

def _funcs_to_names(funclist,namelist):
    result = []
    for f,name in zip(funclist,namelist):
         if f and f[0]:
             result.append((name, f[1]))
         else:
             result.append(f)
    return result

# -----------------------------------------------------------------------------
# _names_to_funcs()
#
# Given a list of regular expression function names, this converts it back to
# functions.
# -----------------------------------------------------------------------------

def _names_to_funcs(namelist,fdict):
     result = []
     for n in namelist:
          if n and n[0]:
              result.append((fdict[n[0]],n[1]))
          else:
              result.append(n)
     return result

# -----------------------------------------------------------------------------
# _form_master_re()
#
# This function takes a list of all of the regex components and attempts to
# form the master regular expression.  Given limitations in the Python re
# module, it may be necessary to break the master regex into separate expressions.
# -----------------------------------------------------------------------------

def _form_master_re(relist,reflags,ldict,toknames):
    if not relist: return []
    regex = "|".join(relist)
    try:
        lexre = re.compile(regex,re.VERBOSE | reflags)

        # Build the index to function map for the matching engine
        lexindexfunc = [ None ] * (max(lexre.groupindex.values())+1)
        lexindexnames = lexindexfunc[:]

        for f,i in lexre.groupindex.items():
            handle = ldict.get(f,None)
            if type(handle) in (types.FunctionType, types.MethodType):
                lexindexfunc[i] = (handle,toknames[f])
                lexindexnames[i] = f
            elif handle is not None:
                lexindexnames[i] = f
                if f.find("ignore_") > 0:
                    lexindexfunc[i] = (None,None)
                else:
                    lexindexfunc[i] = (None, toknames[f])
        
        return [(lexre,lexindexfunc)],[regex],[lexindexnames]
    except Exception:
        m = int(len(relist)/2)
        if m == 0: m = 1
        llist, lre, lnames = _form_master_re(relist[:m],reflags,ldict,toknames)
        rlist, rre, rnames = _form_master_re(relist[m:],reflags,ldict,toknames)
        return llist+rlist, lre+rre, lnames+rnames

# -----------------------------------------------------------------------------
# def _statetoken(s,names)
#
# Given a declaration name s of the form "t_" and a dictionary whose keys are
# state names, this function returns a tuple (states,tokenname) where states
# is a tuple of state names and tokenname is the name of the token.  For example,
# calling this with s = "t_foo_bar_SPAM" might return (('foo','bar'),'SPAM')
# -----------------------------------------------------------------------------

def _statetoken(s,names):
    nonstate = 1
    parts = s.split("_")
    for i in range(1,len(parts)):
         if not parts[i] in names and parts[i] != 'ANY': break
    if i > 1:
       states = tuple(parts[1:i])
    else:
       states = ('INITIAL',)

    if 'ANY' in states:
       states = tuple(names)

    tokenname = "_".join(parts[i:])
    return (states,tokenname)


# -----------------------------------------------------------------------------
# LexerReflect()
#
# This class represents information needed to build a lexer as extracted from a
# user's input file.
# -----------------------------------------------------------------------------
class LexerReflect(object):
    def __init__(self,ldict,log=None,reflags=0):
        self.ldict      = ldict
        self.error_func = None
        self.tokens     = []
        self.reflags    = reflags
        self.stateinfo  = { 'INITIAL' : 'inclusive'}
        self.files      = {}
        self.error      = 0

        if log is None:
            self.log = PlyLogger(sys.stderr)
        else:
            self.log = log

    # Get all of the basic information
    def get_all(self):
        self.get_tokens()
        self.get_literals()
        self.get_states()
        self.get_rules()
        
    # Validate all of the information
    def validate_all(self):
        self.validate_tokens()
        self.validate_literals()
        self.validate_rules()
        return self.error

    # Get the tokens map
    def get_tokens(self):
        tokens = self.ldict.get("tokens",None)
        if not tokens:
            self.log.error("No token list is defined")
            self.error = 1
            return

        if not isinstance(tokens,(list, tuple)):
            self.log.error("tokens must be a list or tuple")
            self.error = 1
            return
        
        if not tokens:
            self.log.error("tokens is empty")
            self.error = 1
            return

        self.tokens = tokens

    # Validate the tokens
    def validate_tokens(self):
        terminals = {}
        for n in self.tokens:
            if not _is_identifier.match(n):
                self.log.error("Bad token name '%s'",n)
                self.error = 1
            if n in terminals:
                self.log.warning("Token '%s' multiply defined", n)
            terminals[n] = 1

    # Get the literals specifier
    def get_literals(self):
        self.literals = self.ldict.get("literals","")

    # Validate literals
    def validate_literals(self):
        try:
            for c in self.literals:
                if not isinstance(c,StringTypes) or len(c) > 1:
                    self.log.error("Invalid literal %s. Must be a single character", repr(c))
                    self.error = 1
                    continue

        except TypeError:
            self.log.error("Invalid literals specification. literals must be a sequence of characters")
            self.error = 1

    def get_states(self):
        self.states = self.ldict.get("states",None)
        # Build statemap
        if self.states:
             if not isinstance(self.states,(tuple,list)):
                  self.log.error("states must be defined as a tuple or list")
                  self.error = 1
             else:
                  for s in self.states:
                        if not isinstance(s,tuple) or len(s) != 2:
                               self.log.error("Invalid state specifier %s. Must be a tuple (statename,'exclusive|inclusive')",repr(s))
                               self.error = 1
                               continue
                        name, statetype = s
                        if not isinstance(name,StringTypes):
                               self.log.error("State name %s must be a string", repr(name))
                               self.error = 1
                               continue
                        if not (statetype == 'inclusive' or statetype == 'exclusive'):
                               self.log.error("State type for state %s must be 'inclusive' or 'exclusive'",name)
                               self.error = 1
                               continue
                        if name in self.stateinfo:
                               self.log.error("State '%s' already defined",name)
                               self.error = 1
                               continue
                        self.stateinfo[name] = statetype

    # Get all of the symbols with a t_ prefix and sort them into various
    # categories (functions, strings, error functions, and ignore characters)

    def get_rules(self):
        tsymbols = [f for f in self.ldict if f[:2] == 't_' ]

        # Now build up a list of functions and a list of strings

        self.toknames = { }        # Mapping of symbols to token names
        self.funcsym =  { }        # Symbols defined as functions
        self.strsym =   { }        # Symbols defined as strings
        self.ignore   = { }        # Ignore strings by state
        self.errorf   = { }        # Error functions by state

        for s in self.stateinfo:
             self.funcsym[s] = []
             self.strsym[s] = []

        if len(tsymbols) == 0:
            self.log.error("No rules of the form t_rulename are defined")
            self.error = 1
            return

        for f in tsymbols:
            t = self.ldict[f]
            states, tokname = _statetoken(f,self.stateinfo)
            self.toknames[f] = tokname

            if hasattr(t,"__call__"):
                if tokname == 'error':
                    for s in states:
                        self.errorf[s] = t
                elif tokname == 'ignore':
                    line = func_code(t).co_firstlineno
                    file = func_code(t).co_filename
                    self.log.error("%s:%d: Rule '%s' must be defined as a string",file,line,t.__name__)
                    self.error = 1
                else:
                    for s in states: 
                        self.funcsym[s].append((f,t))
            elif isinstance(t, StringTypes):
                if tokname == 'ignore':
                    for s in states:
                        self.ignore[s] = t
                    if "\\" in t:
                        self.log.warning("%s contains a literal backslash '\\'",f)

                elif tokname == 'error':
                    self.log.error("Rule '%s' must be defined as a function", f)
                    self.error = 1
                else:
                    for s in states: 
                        self.strsym[s].append((f,t))
            else:
                self.log.error("%s not defined as a function or string", f)
                self.error = 1

        # Sort the functions by line number
        for f in self.funcsym.values():
            if sys.version_info[0] < 3:
                f.sort(lambda x,y: cmp(func_code(x[1]).co_firstlineno,func_code(y[1]).co_firstlineno))
            else:
                # Python 3.0
                f.sort(key=lambda x: func_code(x[1]).co_firstlineno)

        # Sort the strings by regular expression length
        for s in self.strsym.values():
            if sys.version_info[0] < 3:
                s.sort(lambda x,y: (len(x[1]) < len(y[1])) - (len(x[1]) > len(y[1])))
            else:
                # Python 3.0
                s.sort(key=lambda x: len(x[1]),reverse=True)

    # Validate all of the t_rules collected 
    def validate_rules(self):
        for state in self.stateinfo:
            # Validate all rules defined by functions

            

            for fname, f in self.funcsym[state]:
                line = func_code(f).co_firstlineno
                file = func_code(f).co_filename
                self.files[file] = 1

                tokname = self.toknames[fname]
                if isinstance(f, types.MethodType):
                    reqargs = 2
                else:
                    reqargs = 1
                nargs = func_code(f).co_argcount
                if nargs > reqargs:
                    self.log.error("%s:%d: Rule '%s' has too many arguments",file,line,f.__name__)
                    self.error = 1
                    continue

                if nargs < reqargs:
                    self.log.error("%s:%d: Rule '%s' requires an argument", file,line,f.__name__)
                    self.error = 1
                    continue

                if not f.__doc__:
                    self.log.error("%s:%d: No regular expression defined for rule '%s'",file,line,f.__name__)
                    self.error = 1
                    continue

                try:
                    c = re.compile("(?P<%s>%s)" % (fname,f.__doc__), re.VERBOSE | self.reflags)
                    if c.match(""):
                        self.log.error("%s:%d: Regular expression for rule '%s' matches empty string", file,line,f.__name__)
                        self.error = 1
                except re.error:
                    _etype, e, _etrace = sys.exc_info()
                    self.log.error("%s:%d: Invalid regular expression for rule '%s'. %s", file,line,f.__name__,e)
                    if '#' in f.__doc__:
                        self.log.error("%s:%d. Make sure '#' in rule '%s' is escaped with '\\#'",file,line, f.__name__)
                    self.error = 1

            # Validate all rules defined by strings
            for name,r in self.strsym[state]:
                tokname = self.toknames[name]
                if tokname == 'error':
                    self.log.error("Rule '%s' must be defined as a function", name)
                    self.error = 1
                    continue

                if not tokname in self.tokens and tokname.find("ignore_") < 0:
                    self.log.error("Rule '%s' defined for an unspecified token %s",name,tokname)
                    self.error = 1
                    continue

                try:
                    c = re.compile("(?P<%s>%s)" % (name,r),re.VERBOSE | self.reflags)
                    if (c.match("")):
                         self.log.error("Regular expression for rule '%s' matches empty string",name)
                         self.error = 1
                except re.error:
                    _etype, e, _etrace = sys.exc_info()
                    self.log.error("Invalid regular expression for rule '%s'. %s",name,e)
                    if '#' in r:
                         self.log.error("Make sure '#' in rule '%s' is escaped with '\\#'",name)
                    self.error = 1

            if not self.funcsym[state] and not self.strsym[state]:
                self.log.error("No rules defined for state '%s'",state)
                self.error = 1

            # Validate the error function
            efunc = self.errorf.get(state,None)
            if efunc:
                f = efunc
                line = func_code(f).co_firstlineno
                file = func_code(f).co_filename
                self.files[file] = 1

                if isinstance(f, types.MethodType):
                    reqargs = 2
                else:
                    reqargs = 1
                nargs = func_code(f).co_argcount
                if nargs > reqargs:
                    self.log.error("%s:%d: Rule '%s' has too many arguments",file,line,f.__name__)
                    self.error = 1

                if nargs < reqargs:
                    self.log.error("%s:%d: Rule '%s' requires an argument", file,line,f.__name__)
                    self.error = 1

        for f in self.files:
            self.validate_file(f)


    # -----------------------------------------------------------------------------
    # validate_file()
    #
    # This checks to see if there are duplicated t_rulename() functions or strings
    # in the parser input file.  This is done using a simple regular expression
    # match on each line in the given file.  
    # -----------------------------------------------------------------------------

    def validate_file(self,filename):
        import os.path
        base,ext = os.path.splitext(filename)
        if ext != '.py': return         # No idea what the file is. Return OK

        try:
            f = open(filename)
            lines = f.readlines()
            f.close()
        except IOError:
            return                      # Couldn't find the file.  Don't worry about it

        fre = re.compile(r'\s*def\s+(t_[a-zA-Z_0-9]*)\(')
        sre = re.compile(r'\s*(t_[a-zA-Z_0-9]*)\s*=')

        counthash = { }
        linen = 1
        for l in lines:
            m = fre.match(l)
            if not m:
                m = sre.match(l)
            if m:
                name = m.group(1)
                prev = counthash.get(name)
                if not prev:
                    counthash[name] = linen
                else:
                    self.log.error("%s:%d: Rule %s redefined. Previously defined on line %d",filename,linen,name,prev)
                    self.error = 1
            linen += 1
            
# -----------------------------------------------------------------------------
# lex(module)
#
# Build all of the regular expression rules from definitions in the supplied module
# -----------------------------------------------------------------------------
def lex(module=None,object=None,debug=0,optimize=0,lextab="lextab",reflags=0,nowarn=0,outputdir="", debuglog=None, errorlog=None):
    global lexer
    ldict = None
    stateinfo  = { 'INITIAL' : 'inclusive'}
    lexobj = Lexer()
    lexobj.lexoptimize = optimize
    global token,input

    if errorlog is None:
        errorlog = PlyLogger(sys.stderr)

    if debug:
        if debuglog is None:
            debuglog = PlyLogger(sys.stderr)

    # Get the module dictionary used for the lexer
    if object: module = object

    if module:
        _items = [(k,getattr(module,k)) for k in dir(module)]
        ldict = dict(_items)
    else:
        ldict = get_caller_module_dict(2)

    # Collect parser information from the dictionary
    linfo = LexerReflect(ldict,log=errorlog,reflags=reflags)
    linfo.get_all()
    if not optimize:
        if linfo.validate_all():
            raise SyntaxError("Can't build lexer")

    if optimize and lextab:
        try:
            lexobj.readtab(lextab,ldict)
            token = lexobj.token
            input = lexobj.input
            lexer = lexobj
            return lexobj

        except ImportError:
            pass

    # Dump some basic debugging information
    if debug:
        debuglog.info("lex: tokens   = %r", linfo.tokens)
        debuglog.info("lex: literals = %r", linfo.literals)
        debuglog.info("lex: states   = %r", linfo.stateinfo)

    # Build a dictionary of valid token names
    lexobj.lextokens = { }
    for n in linfo.tokens:
        lexobj.lextokens[n] = 1

    # Get literals specification
    if isinstance(linfo.literals,(list,tuple)):
        lexobj.lexliterals = type(linfo.literals[0])().join(linfo.literals)
    else:
        lexobj.lexliterals = linfo.literals

    # Get the stateinfo dictionary
    stateinfo = linfo.stateinfo

    regexs = { }
    # Build the master regular expressions
    for state in stateinfo:
        regex_list = []

        # Add rules defined by functions first
        for fname, f in linfo.funcsym[state]:
            line = func_code(f).co_firstlineno
            file = func_code(f).co_filename
            regex_list.append("(?P<%s>%s)" % (fname,f.__doc__))
            if debug:
                debuglog.info("lex: Adding rule %s -> '%s' (state '%s')",fname,f.__doc__, state)

        # Now add all of the simple rules
        for name,r in linfo.strsym[state]:
            regex_list.append("(?P<%s>%s)" % (name,r))
            if debug:
                debuglog.info("lex: Adding rule %s -> '%s' (state '%s')",name,r, state)

        regexs[state] = regex_list

    # Build the master regular expressions

    if debug:
        debuglog.info("lex: ==== MASTER REGEXS FOLLOW ====")

    for state in regexs:
        lexre, re_text, re_names = _form_master_re(regexs[state],reflags,ldict,linfo.toknames)
        lexobj.lexstatere[state] = lexre
        lexobj.lexstateretext[state] = re_text
        lexobj.lexstaterenames[state] = re_names
        if debug:
            for i in range(len(re_text)):
                debuglog.info("lex: state '%s' : regex[%d] = '%s'",state, i, re_text[i])

    # For inclusive states, we need to add the regular expressions from the INITIAL state
    for state,stype in stateinfo.items():
        if state != "INITIAL" and stype == 'inclusive':
             lexobj.lexstatere[state].extend(lexobj.lexstatere['INITIAL'])
             lexobj.lexstateretext[state].extend(lexobj.lexstateretext['INITIAL'])
             lexobj.lexstaterenames[state].extend(lexobj.lexstaterenames['INITIAL'])

    lexobj.lexstateinfo = stateinfo
    lexobj.lexre = lexobj.lexstatere["INITIAL"]
    lexobj.lexretext = lexobj.lexstateretext["INITIAL"]
    lexobj.lexreflags = reflags

    # Set up ignore variables
    lexobj.lexstateignore = linfo.ignore
    lexobj.lexignore = lexobj.lexstateignore.get("INITIAL","")

    # Set up error functions
    lexobj.lexstateerrorf = linfo.errorf
    lexobj.lexerrorf = linfo.errorf.get("INITIAL",None)
    if not lexobj.lexerrorf:
        errorlog.warning("No t_error rule is defined")

    # Check state information for ignore and error rules
    for s,stype in stateinfo.items():
        if stype == 'exclusive':
              if not s in linfo.errorf:
                   errorlog.warning("No error rule is defined for exclusive state '%s'", s)
              if not s in linfo.ignore and lexobj.lexignore:
                   errorlog.warning("No ignore rule is defined for exclusive state '%s'", s)
        elif stype == 'inclusive':
              if not s in linfo.errorf:
                   linfo.errorf[s] = linfo.errorf.get("INITIAL",None)
              if not s in linfo.ignore:
                   linfo.ignore[s] = linfo.ignore.get("INITIAL","")

    # Create global versions of the token() and input() functions
    token = lexobj.token
    input = lexobj.input
    lexer = lexobj

    # If in optimize mode, we write the lextab
    if lextab and optimize:
        lexobj.writetab(lextab,outputdir)

    return lexobj

# -----------------------------------------------------------------------------
# runmain()
#
# This runs the lexer as a main program
# -----------------------------------------------------------------------------

def runmain(lexer=None,data=None):
    if not data:
        try:
            filename = sys.argv[1]
            f = open(filename)
            data = f.read()
            f.close()
        except IndexError:
            sys.stdout.write("Reading from standard input (type EOF to end):\n")
            data = sys.stdin.read()

    if lexer:
        _input = lexer.input
    else:
        _input = input
    _input(data)
    if lexer:
        _token = lexer.token
    else:
        _token = token

    while 1:
        tok = _token()
        if not tok: break
        sys.stdout.write("(%s,%r,%d,%d)\n" % (tok.type, tok.value, tok.lineno,tok.lexpos))

# -----------------------------------------------------------------------------
# @TOKEN(regex)
#
# This decorator function can be used to set the regex expression on a function
# when its docstring might need to be set in an alternative way
# -----------------------------------------------------------------------------

def TOKEN(r):
    def set_doc(f):
        if hasattr(r,"__call__"):
            f.__doc__ = r.__doc__
        else:
            f.__doc__ = r
        return f
    return set_doc

# Alternative spelling of the TOKEN decorator
Token = TOKEN

