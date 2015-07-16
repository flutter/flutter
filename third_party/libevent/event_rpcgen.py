#!/usr/bin/env python
#
# Copyright (c) 2005 Niels Provos <provos@citi.umich.edu>
# All rights reserved.
#
# Generates marshaling code based on libevent.

import sys
import re

#
_NAME = "event_rpcgen.py"
_VERSION = "0.1"
_STRUCT_RE = '[a-z][a-z_0-9]*'

# Globals
line_count = 0

white = re.compile(r'^\s+')
cppcomment = re.compile(r'\/\/.*$')
headerdirect = []
cppdirect = []

# Holds everything that makes a struct
class Struct:
    def __init__(self, name):
        self._name = name
        self._entries = []
        self._tags = {}
        print >>sys.stderr, '  Created struct: %s' % name

    def AddEntry(self, entry):
        if self._tags.has_key(entry.Tag()):
            print >>sys.stderr, ( 'Entry "%s" duplicates tag number '
                                  '%d from "%s" around line %d' ) % (
                entry.Name(), entry.Tag(),
                self._tags[entry.Tag()], line_count)
            sys.exit(1)
        self._entries.append(entry)
        self._tags[entry.Tag()] = entry.Name()
        print >>sys.stderr, '    Added entry: %s' % entry.Name()

    def Name(self):
        return self._name

    def EntryTagName(self, entry):
        """Creates the name inside an enumeration for distinguishing data
        types."""
        name = "%s_%s" % (self._name, entry.Name())
        return name.upper()

    def PrintIdented(self, file, ident, code):
        """Takes an array, add indentation to each entry and prints it."""
        for entry in code:
            print >>file, '%s%s' % (ident, entry)

    def PrintTags(self, file):
        """Prints the tag definitions for a structure."""
        print >>file, '/* Tag definition for %s */' % self._name
        print >>file, 'enum %s_ {' % self._name.lower()
        for entry in self._entries:
            print >>file, '  %s=%d,' % (self.EntryTagName(entry),
                                        entry.Tag())
        print >>file, '  %s_MAX_TAGS' % (self._name.upper())
        print >>file, '};\n'

    def PrintForwardDeclaration(self, file):
        print >>file, 'struct %s;' % self._name

    def PrintDeclaration(self, file):
        print >>file, '/* Structure declaration for %s */' % self._name
        print >>file, 'struct %s_access_ {' % self._name
        for entry in self._entries:
            dcl = entry.AssignDeclaration('(*%s_assign)' % entry.Name())
            dcl.extend(
                entry.GetDeclaration('(*%s_get)' % entry.Name()))
            if entry.Array():
                dcl.extend(
                    entry.AddDeclaration('(*%s_add)' % entry.Name()))
            self.PrintIdented(file, '  ', dcl)
        print >>file, '};\n'

        print >>file, 'struct %s {' % self._name
        print >>file, '  struct %s_access_ *base;\n' % self._name
        for entry in self._entries:
            dcl = entry.Declaration()
            self.PrintIdented(file, '  ', dcl)
        print >>file, ''
        for entry in self._entries:
            print >>file, '  ev_uint8_t %s_set;' % entry.Name()
        print >>file, '};\n'

        print >>file, \
"""struct %(name)s *%(name)s_new(void);
void %(name)s_free(struct %(name)s *);
void %(name)s_clear(struct %(name)s *);
void %(name)s_marshal(struct evbuffer *, const struct %(name)s *);
int %(name)s_unmarshal(struct %(name)s *, struct evbuffer *);
int %(name)s_complete(struct %(name)s *);
void evtag_marshal_%(name)s(struct evbuffer *, ev_uint32_t, 
    const struct %(name)s *);
int evtag_unmarshal_%(name)s(struct evbuffer *, ev_uint32_t,
    struct %(name)s *);""" % { 'name' : self._name }


        # Write a setting function of every variable
        for entry in self._entries:
            self.PrintIdented(file, '', entry.AssignDeclaration(
                entry.AssignFuncName()))
            self.PrintIdented(file, '', entry.GetDeclaration(
                entry.GetFuncName()))
            if entry.Array():
                self.PrintIdented(file, '', entry.AddDeclaration(
                    entry.AddFuncName()))

        print >>file, '/* --- %s done --- */\n' % self._name

    def PrintCode(self, file):
        print >>file, ('/*\n'
                       ' * Implementation of %s\n'
                       ' */\n') % self._name

        print >>file, \
              'static struct %(name)s_access_ __%(name)s_base = {' % \
              { 'name' : self._name }
        for entry in self._entries:
            self.PrintIdented(file, '  ', entry.CodeBase())
        print >>file, '};\n'

        # Creation
        print >>file, (
            'struct %(name)s *\n'
            '%(name)s_new(void)\n'
            '{\n'
            '  struct %(name)s *tmp;\n'
            '  if ((tmp = malloc(sizeof(struct %(name)s))) == NULL) {\n'
            '    event_warn("%%s: malloc", __func__);\n'
            '    return (NULL);\n'
            '  }\n'
            '  tmp->base = &__%(name)s_base;\n') % { 'name' : self._name }

        for entry in self._entries:
            self.PrintIdented(file, '  ', entry.CodeNew('tmp'))
            print >>file, '  tmp->%s_set = 0;\n' % entry.Name()

        print >>file, (
            '  return (tmp);\n'
            '}\n')

        # Adding
        for entry in self._entries:
            if entry.Array():
                self.PrintIdented(file, '', entry.CodeAdd())
            print >>file, ''
            
        # Assigning
        for entry in self._entries:
            self.PrintIdented(file, '', entry.CodeAssign())
            print >>file, ''

        # Getting
        for entry in self._entries:
            self.PrintIdented(file, '', entry.CodeGet())
            print >>file, ''
            
        # Clearing
        print >>file, ( 'void\n'
                        '%(name)s_clear(struct %(name)s *tmp)\n'
                        '{'
                        ) % { 'name' : self._name }
        for entry in self._entries:
            self.PrintIdented(file, '  ', entry.CodeClear('tmp'))

        print >>file, '}\n'

        # Freeing
        print >>file, ( 'void\n'
                        '%(name)s_free(struct %(name)s *tmp)\n'
                        '{'
                        ) % { 'name' : self._name }
        
        for entry in self._entries:
            self.PrintIdented(file, '  ', entry.CodeFree('tmp'))

        print >>file, ('  free(tmp);\n'
                       '}\n')

        # Marshaling
        print >>file, ('void\n'
                       '%(name)s_marshal(struct evbuffer *evbuf, '
                       'const struct %(name)s *tmp)'
                       '{') % { 'name' : self._name }
        for entry in self._entries:
            indent = '  '
            # Optional entries do not have to be set
            if entry.Optional():
                indent += '  '
                print >>file, '  if (tmp->%s_set) {' % entry.Name()
            self.PrintIdented(
                file, indent,
                entry.CodeMarshal('evbuf', self.EntryTagName(entry), 'tmp'))
            if entry.Optional():
                print >>file, '  }'

        print >>file, '}\n'
                       
        # Unmarshaling
        print >>file, ('int\n'
                       '%(name)s_unmarshal(struct %(name)s *tmp, '
                       ' struct evbuffer *evbuf)\n'
                       '{\n'
                       '  ev_uint32_t tag;\n'
                       '  while (EVBUFFER_LENGTH(evbuf) > 0) {\n'
                       '    if (evtag_peek(evbuf, &tag) == -1)\n'
                       '      return (-1);\n'
                       '    switch (tag) {\n'
                       ) % { 'name' : self._name }
        for entry in self._entries:
            print >>file, '      case %s:\n' % self.EntryTagName(entry)
            if not entry.Array():
                print >>file, (
                    '        if (tmp->%s_set)\n'
                    '          return (-1);'
                    ) % (entry.Name())

            self.PrintIdented(
                file, '        ',
                entry.CodeUnmarshal('evbuf',
                                    self.EntryTagName(entry), 'tmp'))

            print >>file, ( '        tmp->%s_set = 1;\n' % entry.Name() +
                            '        break;\n' )
        print >>file, ( '      default:\n'
                        '        return -1;\n'
                        '    }\n'
                        '  }\n' )
        # Check if it was decoded completely
        print >>file, ( '  if (%(name)s_complete(tmp) == -1)\n'
                        '    return (-1);'
                        ) % { 'name' : self._name }

        # Successfully decoded
        print >>file, ( '  return (0);\n'
                        '}\n')

        # Checking if a structure has all the required data
        print >>file, (
            'int\n'
            '%(name)s_complete(struct %(name)s *msg)\n'
            '{' ) % { 'name' : self._name }
        for entry in self._entries:
            self.PrintIdented(
                file, '  ',
                entry.CodeComplete('msg'))
        print >>file, (
            '  return (0);\n'
            '}\n' )

        # Complete message unmarshaling
        print >>file, (
            'int\n'
            'evtag_unmarshal_%(name)s(struct evbuffer *evbuf, '
            'ev_uint32_t need_tag, struct %(name)s *msg)\n'
            '{\n'
            '  ev_uint32_t tag;\n'
            '  int res = -1;\n'
            '\n'
            '  struct evbuffer *tmp = evbuffer_new();\n'
            '\n'
            '  if (evtag_unmarshal(evbuf, &tag, tmp) == -1'
            ' || tag != need_tag)\n'
            '    goto error;\n'
            '\n'
            '  if (%(name)s_unmarshal(msg, tmp) == -1)\n'
            '    goto error;\n'
            '\n'
            '  res = 0;\n'
            '\n'
            ' error:\n'
            '  evbuffer_free(tmp);\n'
            '  return (res);\n'
            '}\n' ) % { 'name' : self._name }

        # Complete message marshaling
        print >>file, (
            'void\n'
            'evtag_marshal_%(name)s(struct evbuffer *evbuf, ev_uint32_t tag, '
            'const struct %(name)s *msg)\n'
            '{\n'
            '  struct evbuffer *_buf = evbuffer_new();\n'
            '  assert(_buf != NULL);\n'
            '  evbuffer_drain(_buf, -1);\n'
            '  %(name)s_marshal(_buf, msg);\n'
            '  evtag_marshal(evbuf, tag, EVBUFFER_DATA(_buf), '
            'EVBUFFER_LENGTH(_buf));\n'
            '  evbuffer_free(_buf);\n'
            '}\n' ) % { 'name' : self._name }

class Entry:
    def __init__(self, type, name, tag):
        self._type = type
        self._name = name
        self._tag = int(tag)
        self._ctype = type
        self._optional = 0
        self._can_be_array = 0
        self._array = 0
        self._line_count = -1
        self._struct = None
        self._refname = None

    def GetTranslation(self):
        return { "parent_name" : self._struct.Name(),
                 "name" : self._name,
                 "ctype" : self._ctype,
                 "refname" : self._refname
                 }
    
    def SetStruct(self, struct):
        self._struct = struct

    def LineCount(self):
        assert self._line_count != -1
        return self._line_count

    def SetLineCount(self, number):
        self._line_count = number

    def Array(self):
        return self._array

    def Optional(self):
        return self._optional

    def Tag(self):
        return self._tag

    def Name(self):
        return self._name

    def Type(self):
        return self._type

    def MakeArray(self, yes=1):
        self._array = yes
        
    def MakeOptional(self):
        self._optional = 1

    def GetFuncName(self):
        return '%s_%s_get' % (self._struct.Name(), self._name)
    
    def GetDeclaration(self, funcname):
        code = [ 'int %s(struct %s *, %s *);' % (
            funcname, self._struct.Name(), self._ctype ) ]
        return code

    def CodeGet(self):
        code = (
            'int',
            '%(parent_name)s_%(name)s_get(struct %(parent_name)s *msg, '
            '%(ctype)s *value)',
            '{',
            '  if (msg->%(name)s_set != 1)',
            '    return (-1);',
            '  *value = msg->%(name)s_data;',
            '  return (0);',
            '}' )
        code = '\n'.join(code)
        code = code % self.GetTranslation()
        return code.split('\n')
        
    def AssignFuncName(self):
        return '%s_%s_assign' % (self._struct.Name(), self._name)
    
    def AddFuncName(self):
        return '%s_%s_add' % (self._struct.Name(), self._name)
    
    def AssignDeclaration(self, funcname):
        code = [ 'int %s(struct %s *, const %s);' % (
            funcname, self._struct.Name(), self._ctype ) ]
        return code

    def CodeAssign(self):
        code = [ 'int',
                 '%(parent_name)s_%(name)s_assign(struct %(parent_name)s *msg,'
                 ' const %(ctype)s value)',
                 '{',
                 '  msg->%(name)s_set = 1;',
                 '  msg->%(name)s_data = value;',
                 '  return (0);',
                 '}' ]
        code = '\n'.join(code)
        code = code % self.GetTranslation()
        return code.split('\n')

    def CodeClear(self, structname):
        code = [ '%s->%s_set = 0;' % (structname, self.Name()) ]

        return code
        
    def CodeComplete(self, structname):
        if self.Optional():
            return []
        
        code = [ 'if (!%s->%s_set)' % (structname, self.Name()),
                 '  return (-1);' ]

        return code

    def CodeFree(self, name):
        return []

    def CodeBase(self):
        code = [
            '%(parent_name)s_%(name)s_assign,',
            '%(parent_name)s_%(name)s_get,'
            ]
        if self.Array():
            code.append('%(parent_name)s_%(name)s_add,')

        code = '\n'.join(code)
        code = code % self.GetTranslation()
        return code.split('\n')

    def Verify(self):
        if self.Array() and not self._can_be_array:
            print >>sys.stderr, (
                'Entry "%s" cannot be created as an array '
                'around line %d' ) % (self._name, self.LineCount())
            sys.exit(1)
        if not self._struct:
            print >>sys.stderr, (
                'Entry "%s" does not know which struct it belongs to '
                'around line %d' ) % (self._name, self.LineCount())
            sys.exit(1)
        if self._optional and self._array:
            print >>sys.stderr,  ( 'Entry "%s" has illegal combination of '
                                   'optional and array around line %d' ) % (
                self._name, self.LineCount() )
            sys.exit(1)

class EntryBytes(Entry):
    def __init__(self, type, name, tag, length):
        # Init base class
        Entry.__init__(self, type, name, tag)

        self._length = length
        self._ctype = 'ev_uint8_t'

    def GetDeclaration(self, funcname):
        code = [ 'int %s(struct %s *, %s **);' % (
            funcname, self._struct.Name(), self._ctype ) ]
        return code
        
    def AssignDeclaration(self, funcname):
        code = [ 'int %s(struct %s *, const %s *);' % (
            funcname, self._struct.Name(), self._ctype ) ]
        return code
        
    def Declaration(self):
        dcl  = ['ev_uint8_t %s_data[%s];' % (self._name, self._length)]
        
        return dcl

    def CodeGet(self):
        name = self._name
        code = [ 'int',
                 '%s_%s_get(struct %s *msg, %s **value)' % (
            self._struct.Name(), name,
            self._struct.Name(), self._ctype),
                 '{',
                 '  if (msg->%s_set != 1)' % name,
                 '    return (-1);',
                 '  *value = msg->%s_data;' % name,
                 '  return (0);',
                 '}' ]
        return code
        
    def CodeAssign(self):
        name = self._name
        code = [ 'int',
                 '%s_%s_assign(struct %s *msg, const %s *value)' % (
            self._struct.Name(), name,
            self._struct.Name(), self._ctype),
                 '{',
                 '  msg->%s_set = 1;' % name,
                 '  memcpy(msg->%s_data, value, %s);' % (
            name, self._length),
                 '  return (0);',
                 '}' ]
        return code
        
    def CodeUnmarshal(self, buf, tag_name, var_name):
        code = [  'if (evtag_unmarshal_fixed(%s, %s, ' % (buf, tag_name) +
                  '%s->%s_data, ' % (var_name, self._name) +
                  'sizeof(%s->%s_data)) == -1) {' % (
            var_name, self._name),
                  '  event_warnx("%%s: failed to unmarshal %s", __func__);' % (
            self._name ),
                  '  return (-1);',
                  '}'
                  ]
        return code

    def CodeMarshal(self, buf, tag_name, var_name):
        code = ['evtag_marshal(%s, %s, %s->%s_data, sizeof(%s->%s_data));' % (
            buf, tag_name, var_name, self._name, var_name, self._name )]
        return code

    def CodeClear(self, structname):
        code = [ '%s->%s_set = 0;' % (structname, self.Name()),
                 'memset(%s->%s_data, 0, sizeof(%s->%s_data));' % (
            structname, self._name, structname, self._name)]

        return code
        
    def CodeNew(self, name):
        code  = ['memset(%s->%s_data, 0, sizeof(%s->%s_data));' % (
            name, self._name, name, self._name)]
        return code

    def Verify(self):
        if not self._length:
            print >>sys.stderr, 'Entry "%s" needs a length around line %d' % (
                self._name, self.LineCount() )
            sys.exit(1)

        Entry.Verify(self)

class EntryInt(Entry):
    def __init__(self, type, name, tag):
        # Init base class
        Entry.__init__(self, type, name, tag)

        self._ctype = 'ev_uint32_t'

    def CodeUnmarshal(self, buf, tag_name, var_name):
        code = ['if (evtag_unmarshal_int(%s, %s, &%s->%s_data) == -1) {' % (
            buf, tag_name, var_name, self._name),
                  '  event_warnx("%%s: failed to unmarshal %s", __func__);' % (
            self._name ),
                '  return (-1);',
                '}' ] 
        return code

    def CodeMarshal(self, buf, tag_name, var_name):
        code = ['evtag_marshal_int(%s, %s, %s->%s_data);' % (
            buf, tag_name, var_name, self._name)]
        return code

    def Declaration(self):
        dcl  = ['ev_uint32_t %s_data;' % self._name]

        return dcl

    def CodeNew(self, name):
        code = ['%s->%s_data = 0;' % (name, self._name)]
        return code

class EntryString(Entry):
    def __init__(self, type, name, tag):
        # Init base class
        Entry.__init__(self, type, name, tag)

        self._ctype = 'char *'

    def CodeAssign(self):
        name = self._name
        code = """int
%(parent_name)s_%(name)s_assign(struct %(parent_name)s *msg,
    const %(ctype)s value)
{
  if (msg->%(name)s_data != NULL)
    free(msg->%(name)s_data);
  if ((msg->%(name)s_data = strdup(value)) == NULL)
    return (-1);
  msg->%(name)s_set = 1;
  return (0);
}""" % self.GetTranslation()

        return code.split('\n')
        
    def CodeUnmarshal(self, buf, tag_name, var_name):
        code = ['if (evtag_unmarshal_string(%s, %s, &%s->%s_data) == -1) {' % (
            buf, tag_name, var_name, self._name),
                '  event_warnx("%%s: failed to unmarshal %s", __func__);' % (
            self._name ),
                '  return (-1);',
                '}'
                ]
        return code

    def CodeMarshal(self, buf, tag_name, var_name):
        code = ['evtag_marshal_string(%s, %s, %s->%s_data);' % (
            buf, tag_name, var_name, self._name)]
        return code

    def CodeClear(self, structname):
        code = [ 'if (%s->%s_set == 1) {' % (structname, self.Name()),
                 '  free (%s->%s_data);' % (structname, self.Name()),
                 '  %s->%s_data = NULL;' % (structname, self.Name()),
                 '  %s->%s_set = 0;' % (structname, self.Name()),
                 '}'
                 ]

        return code
        
    def CodeNew(self, name):
        code  = ['%s->%s_data = NULL;' % (name, self._name)]
        return code

    def CodeFree(self, name):
        code  = ['if (%s->%s_data != NULL)' % (name, self._name),
                 '    free (%s->%s_data); ' % (name, self._name)]

        return code

    def Declaration(self):
        dcl  = ['char *%s_data;' % self._name]

        return dcl

class EntryStruct(Entry):
    def __init__(self, type, name, tag, refname):
        # Init base class
        Entry.__init__(self, type, name, tag)

        self._can_be_array = 1
        self._refname = refname
        self._ctype = 'struct %s*' % refname

    def CodeGet(self):
        name = self._name
        code = [ 'int',
                 '%s_%s_get(struct %s *msg, %s *value)' % (
            self._struct.Name(), name,
            self._struct.Name(), self._ctype),
                 '{',
                 '  if (msg->%s_set != 1) {' % name,
                 '    msg->%s_data = %s_new();' % (name, self._refname),
                 '    if (msg->%s_data == NULL)' % name,
                 '      return (-1);',
                 '    msg->%s_set = 1;' % name,
                 '  }',
                 '  *value = msg->%s_data;' % name,
                 '  return (0);',
                 '}' ]
        return code
        
    def CodeAssign(self):
        name = self._name
        code = """int
%(parent_name)s_%(name)s_assign(struct %(parent_name)s *msg,
    const %(ctype)s value)
{
   struct evbuffer *tmp = NULL;
   if (msg->%(name)s_set) {
     %(refname)s_clear(msg->%(name)s_data);
     msg->%(name)s_set = 0;
   } else {
     msg->%(name)s_data = %(refname)s_new();
     if (msg->%(name)s_data == NULL) {
       event_warn("%%s: %(refname)s_new()", __func__);
       goto error;
     }
   }
   if ((tmp = evbuffer_new()) == NULL) {
     event_warn("%%s: evbuffer_new()", __func__);
     goto error;
   }
   %(refname)s_marshal(tmp, value);
   if (%(refname)s_unmarshal(msg->%(name)s_data, tmp) == -1) {
     event_warnx("%%s: %(refname)s_unmarshal", __func__);
     goto error;
   }
   msg->%(name)s_set = 1;
   evbuffer_free(tmp);
   return (0);
 error:
   if (tmp != NULL)
     evbuffer_free(tmp);
   if (msg->%(name)s_data != NULL) {
     %(refname)s_free(msg->%(name)s_data);
     msg->%(name)s_data = NULL;
   }
   return (-1);
}""" % self.GetTranslation()
        return code.split('\n')
        
    def CodeComplete(self, structname):
        if self.Optional():
            code = [ 'if (%s->%s_set && %s_complete(%s->%s_data) == -1)' % (
                structname, self.Name(),
                self._refname, structname, self.Name()),
                     '  return (-1);' ]
        else:
            code = [ 'if (%s_complete(%s->%s_data) == -1)' % (
                self._refname, structname, self.Name()),
                     '  return (-1);' ]

        return code
    
    def CodeUnmarshal(self, buf, tag_name, var_name):
        code = ['%s->%s_data = %s_new();' % (
            var_name, self._name, self._refname),
                'if (%s->%s_data == NULL)' % (var_name, self._name),
                '  return (-1);',
                'if (evtag_unmarshal_%s(%s, %s, %s->%s_data) == -1) {' % (
            self._refname, buf, tag_name, var_name, self._name),
                  '  event_warnx("%%s: failed to unmarshal %s", __func__);' % (
            self._name ),
                '  return (-1);',
                '}'
                ]
        return code

    def CodeMarshal(self, buf, tag_name, var_name):
        code = ['evtag_marshal_%s(%s, %s, %s->%s_data);' % (
            self._refname, buf, tag_name, var_name, self._name)]
        return code

    def CodeClear(self, structname):
        code = [ 'if (%s->%s_set == 1) {' % (structname, self.Name()),
                 '  %s_free(%s->%s_data);' % (
            self._refname, structname, self.Name()),
                 '  %s->%s_data = NULL;' % (structname, self.Name()),
                 '  %s->%s_set = 0;' % (structname, self.Name()),
                 '}'
                 ]

        return code
        
    def CodeNew(self, name):
        code  = ['%s->%s_data = NULL;' % (name, self._name)]
        return code

    def CodeFree(self, name):
        code  = ['if (%s->%s_data != NULL)' % (name, self._name),
                 '    %s_free(%s->%s_data); ' % (
            self._refname, name, self._name)]

        return code

    def Declaration(self):
        dcl  = ['%s %s_data;' % (self._ctype, self._name)]

        return dcl

class EntryVarBytes(Entry):
    def __init__(self, type, name, tag):
        # Init base class
        Entry.__init__(self, type, name, tag)

        self._ctype = 'ev_uint8_t *'

    def GetDeclaration(self, funcname):
        code = [ 'int %s(struct %s *, %s *, ev_uint32_t *);' % (
            funcname, self._struct.Name(), self._ctype ) ]
        return code
        
    def AssignDeclaration(self, funcname):
        code = [ 'int %s(struct %s *, const %s, ev_uint32_t);' % (
            funcname, self._struct.Name(), self._ctype ) ]
        return code
        
    def CodeAssign(self):
        name = self._name
        code = [ 'int',
                 '%s_%s_assign(struct %s *msg, '
                 'const %s value, ev_uint32_t len)' % (
            self._struct.Name(), name,
            self._struct.Name(), self._ctype),
                 '{',
                 '  if (msg->%s_data != NULL)' % name,
                 '    free (msg->%s_data);' % name,
                 '  msg->%s_data = malloc(len);' % name,
                 '  if (msg->%s_data == NULL)' % name,
                 '    return (-1);',
                 '  msg->%s_set = 1;' % name,
                 '  msg->%s_length = len;' % name,
                 '  memcpy(msg->%s_data, value, len);' % name,
                 '  return (0);',
                 '}' ]
        return code
        
    def CodeGet(self):
        name = self._name
        code = [ 'int',
                 '%s_%s_get(struct %s *msg, %s *value, ev_uint32_t *plen)' % (
            self._struct.Name(), name,
            self._struct.Name(), self._ctype),
                 '{',
                 '  if (msg->%s_set != 1)' % name,
                 '    return (-1);',
                 '  *value = msg->%s_data;' % name,
                 '  *plen = msg->%s_length;' % name,
                 '  return (0);',
                 '}' ]
        return code

    def CodeUnmarshal(self, buf, tag_name, var_name):
        code = ['if (evtag_payload_length(%s, &%s->%s_length) == -1)' % (
            buf, var_name, self._name),
                '  return (-1);',
                # We do not want DoS opportunities
                'if (%s->%s_length > EVBUFFER_LENGTH(%s))' % (
            var_name, self._name, buf),
                '  return (-1);',
                'if ((%s->%s_data = malloc(%s->%s_length)) == NULL)' % (
            var_name, self._name, var_name, self._name),
                '  return (-1);',
                'if (evtag_unmarshal_fixed(%s, %s, %s->%s_data, '
                '%s->%s_length) == -1) {' % (
            buf, tag_name, var_name, self._name, var_name, self._name),
                '  event_warnx("%%s: failed to unmarshal %s", __func__);' % (
            self._name ),
                '  return (-1);',
                '}'
                ]
        return code

    def CodeMarshal(self, buf, tag_name, var_name):
        code = ['evtag_marshal(%s, %s, %s->%s_data, %s->%s_length);' % (
            buf, tag_name, var_name, self._name, var_name, self._name)]
        return code

    def CodeClear(self, structname):
        code = [ 'if (%s->%s_set == 1) {' % (structname, self.Name()),
                 '  free (%s->%s_data);' % (structname, self.Name()),
                 '  %s->%s_data = NULL;' % (structname, self.Name()),
                 '  %s->%s_length = 0;' % (structname, self.Name()),
                 '  %s->%s_set = 0;' % (structname, self.Name()),
                 '}'
                 ]

        return code
        
    def CodeNew(self, name):
        code  = ['%s->%s_data = NULL;' % (name, self._name),
                 '%s->%s_length = 0;' % (name, self._name) ]
        return code

    def CodeFree(self, name):
        code  = ['if (%s->%s_data != NULL)' % (name, self._name),
                 '    free (%s->%s_data); ' % (name, self._name)]

        return code

    def Declaration(self):
        dcl  = ['ev_uint8_t *%s_data;' % self._name,
                'ev_uint32_t %s_length;' % self._name]

        return dcl

class EntryArray(Entry):
    def __init__(self, entry):
        # Init base class
        Entry.__init__(self, entry._type, entry._name, entry._tag)

        self._entry = entry
        self._refname = entry._refname
        self._ctype = 'struct %s *' % self._refname

    def GetDeclaration(self, funcname):
        """Allows direct access to elements of the array."""
        translate = self.GetTranslation()
        translate["funcname"] = funcname
        code = [
            'int %(funcname)s(struct %(parent_name)s *, int, %(ctype)s *);' %
            translate ]
        return code
        
    def AssignDeclaration(self, funcname):
        code = [ 'int %s(struct %s *, int, const %s);' % (
            funcname, self._struct.Name(), self._ctype ) ]
        return code
        
    def AddDeclaration(self, funcname):
        code = [ '%s %s(struct %s *);' % (
            self._ctype, funcname, self._struct.Name() ) ]
        return code
        
    def CodeGet(self):
        code = """int
%(parent_name)s_%(name)s_get(struct %(parent_name)s *msg, int offset,
    %(ctype)s *value)
{
  if (!msg->%(name)s_set || offset < 0 || offset >= msg->%(name)s_length)
    return (-1);
  *value = msg->%(name)s_data[offset];
  return (0);
}""" % self.GetTranslation()

        return code.split('\n')
        
    def CodeAssign(self):
        code = """int
%(parent_name)s_%(name)s_assign(struct %(parent_name)s *msg, int off,
    const %(ctype)s value)
{
  struct evbuffer *tmp = NULL;
  if (!msg->%(name)s_set || off < 0 || off >= msg->%(name)s_length)
    return (-1);
  %(refname)s_clear(msg->%(name)s_data[off]);
  if ((tmp = evbuffer_new()) == NULL) {
    event_warn("%%s: evbuffer_new()", __func__);
    goto error;
  }
  %(refname)s_marshal(tmp, value);
  if (%(refname)s_unmarshal(msg->%(name)s_data[off], tmp) == -1) {
    event_warnx("%%s: %(refname)s_unmarshal", __func__);
    goto error;
  }
  evbuffer_free(tmp);
  return (0);
error:
  if (tmp != NULL)
    evbuffer_free(tmp);
  %(refname)s_clear(msg->%(name)s_data[off]);
  return (-1);
}""" % self.GetTranslation()

        return code.split('\n')
        
    def CodeAdd(self):
        code = \
"""%(ctype)s
%(parent_name)s_%(name)s_add(struct %(parent_name)s *msg)
{
  if (++msg->%(name)s_length >= msg->%(name)s_num_allocated) {
    int tobe_allocated = msg->%(name)s_num_allocated;
    %(ctype)s* new_data = NULL;
    tobe_allocated = !tobe_allocated ? 1 : tobe_allocated << 1;
    new_data = (%(ctype)s*) realloc(msg->%(name)s_data,
        tobe_allocated * sizeof(%(ctype)s));
    if (new_data == NULL)
      goto error;
    msg->%(name)s_data = new_data;
    msg->%(name)s_num_allocated = tobe_allocated;
  }
  msg->%(name)s_data[msg->%(name)s_length - 1] = %(refname)s_new();
  if (msg->%(name)s_data[msg->%(name)s_length - 1] == NULL)
    goto error;
  msg->%(name)s_set = 1;
  return (msg->%(name)s_data[msg->%(name)s_length - 1]);
error:
  --msg->%(name)s_length;
  return (NULL);
}
        """ % self.GetTranslation()

        return code.split('\n')

    def CodeComplete(self, structname):
        code = []
        translate = self.GetTranslation()

        if self.Optional():
            code.append( 'if (%(structname)s->%(name)s_set)'  % translate)

        translate["structname"] = structname
        tmp = """{
  int i;
  for (i = 0; i < %(structname)s->%(name)s_length; ++i) {
    if (%(refname)s_complete(%(structname)s->%(name)s_data[i]) == -1)
      return (-1);
  }
}""" % translate
        code.extend(tmp.split('\n'))

        return code
    
    def CodeUnmarshal(self, buf, tag_name, var_name):
        translate = self.GetTranslation()
        translate["var_name"] = var_name
        translate["buf"] = buf
        translate["tag_name"] = tag_name
        code = """if (%(parent_name)s_%(name)s_add(%(var_name)s) == NULL)
  return (-1);
if (evtag_unmarshal_%(refname)s(%(buf)s, %(tag_name)s,
  %(var_name)s->%(name)s_data[%(var_name)s->%(name)s_length - 1]) == -1) {
  --%(var_name)s->%(name)s_length;
  event_warnx("%%s: failed to unmarshal %(name)s", __func__);
  return (-1);
}""" % translate

        return code.split('\n')

    def CodeMarshal(self, buf, tag_name, var_name):
        code = ['{',
                '  int i;',
                '  for (i = 0; i < %s->%s_length; ++i) {' % (
            var_name, self._name),
                '    evtag_marshal_%s(%s, %s, %s->%s_data[i]);' % (
            self._refname, buf, tag_name, var_name, self._name),
                '  }',
                '}'
                ]
        return code

    def CodeClear(self, structname):
        code = [ 'if (%s->%s_set == 1) {' % (structname, self.Name()),
                 '  int i;',
                 '  for (i = 0; i < %s->%s_length; ++i) {' % (
            structname, self.Name()),
                 '    %s_free(%s->%s_data[i]);' % (
            self._refname, structname, self.Name()),
                 '  }',
                 '  free(%s->%s_data);' % (structname, self.Name()),
                 '  %s->%s_data = NULL;' % (structname, self.Name()),
                 '  %s->%s_set = 0;' % (structname, self.Name()),
                 '  %s->%s_length = 0;' % (structname, self.Name()),
                 '  %s->%s_num_allocated = 0;' % (structname, self.Name()),
                 '}'
                 ]

        return code
        
    def CodeNew(self, name):
        code  = ['%s->%s_data = NULL;' % (name, self._name),
                 '%s->%s_length = 0;' % (name, self._name),
                 '%s->%s_num_allocated = 0;' % (name, self._name)]
        return code

    def CodeFree(self, name):
        code  = ['if (%s->%s_data != NULL) {' % (name, self._name),
                 '  int i;',
                 '  for (i = 0; i < %s->%s_length; ++i) {' % (
            name, self._name),
                 '    %s_free(%s->%s_data[i]); ' % (
            self._refname, name, self._name),
                 '    %s->%s_data[i] = NULL;' % (name, self._name),
                 '  }',
                 '  free(%s->%s_data);' % (name, self._name),
                 '  %s->%s_data = NULL;' % (name, self._name),
                 '  %s->%s_length = 0;' % (name, self._name),
                 '  %s->%s_num_allocated = 0;' % (name, self._name),
                 '}'
                 ]

        return code

    def Declaration(self):
        dcl  = ['struct %s **%s_data;' % (self._refname, self._name),
                'int %s_length;' % self._name,
                'int %s_num_allocated;' % self._name ]

        return dcl

def NormalizeLine(line):
    global white
    global cppcomment
    
    line = cppcomment.sub('', line)
    line = line.strip()
    line = white.sub(' ', line)

    return line

def ProcessOneEntry(newstruct, entry):
    optional = 0
    array = 0
    entry_type = ''
    name = ''
    tag = ''
    tag_set = None
    separator = ''
    fixed_length = ''

    tokens = entry.split(' ')
    while tokens:
        token = tokens[0]
        tokens = tokens[1:]

        if not entry_type:
            if not optional and token == 'optional':
                optional = 1
                continue

            if not array and token == 'array':
                array = 1
                continue

        if not entry_type:
            entry_type = token
            continue

        if not name:
            res = re.match(r'^([^\[\]]+)(\[.*\])?$', token)
            if not res:
                print >>sys.stderr, 'Cannot parse name: \"%s\" around %d' % (
                    entry, line_count)
                sys.exit(1)
            name = res.group(1)
            fixed_length = res.group(2)
            if fixed_length:
                fixed_length = fixed_length[1:-1]
            continue

        if not separator:
            separator = token
            if separator != '=':
                print >>sys.stderr, 'Expected "=" after name \"%s\" got %s' % (
                    name, token)
                sys.exit(1)
            continue

        if not tag_set:
            tag_set = 1
            if not re.match(r'^(0x)?[0-9]+$', token):
                print >>sys.stderr, 'Expected tag number: \"%s\"' % entry
                sys.exit(1)
            tag = int(token, 0)
            continue

        print >>sys.stderr, 'Cannot parse \"%s\"' % entry
        sys.exit(1)

    if not tag_set:
        print >>sys.stderr, 'Need tag number: \"%s\"' % entry
        sys.exit(1)

    # Create the right entry
    if entry_type == 'bytes':
        if fixed_length:
            newentry = EntryBytes(entry_type, name, tag, fixed_length)
        else:
            newentry = EntryVarBytes(entry_type, name, tag)
    elif entry_type == 'int' and not fixed_length:
        newentry = EntryInt(entry_type, name, tag)
    elif entry_type == 'string' and not fixed_length:
        newentry = EntryString(entry_type, name, tag)
    else:
        res = re.match(r'^struct\[(%s)\]$' % _STRUCT_RE,
                       entry_type, re.IGNORECASE)
        if res:
            # References another struct defined in our file
            newentry = EntryStruct(entry_type, name, tag, res.group(1))
        else:
            print >>sys.stderr, 'Bad type: "%s" in "%s"' % (entry_type, entry)
            sys.exit(1)

    structs = []
        
    if optional:
        newentry.MakeOptional()
    if array:
        newentry.MakeArray()

    newentry.SetStruct(newstruct)
    newentry.SetLineCount(line_count)
    newentry.Verify()

    if array:
        # We need to encapsulate this entry into a struct
        newname = newentry.Name()+ '_array'

        # Now borgify the new entry.
        newentry = EntryArray(newentry)
        newentry.SetStruct(newstruct)
        newentry.SetLineCount(line_count)
        newentry.MakeArray()

    newstruct.AddEntry(newentry)

    return structs

def ProcessStruct(data):
    tokens = data.split(' ')

    # First three tokens are: 'struct' 'name' '{'
    newstruct = Struct(tokens[1])

    inside = ' '.join(tokens[3:-1])

    tokens = inside.split(';')

    structs = []

    for entry in tokens:
        entry = NormalizeLine(entry)
        if not entry:
            continue

        # It's possible that new structs get defined in here
        structs.extend(ProcessOneEntry(newstruct, entry))

    structs.append(newstruct)
    return structs

def GetNextStruct(file):
    global line_count
    global cppdirect

    got_struct = 0

    processed_lines = []

    have_c_comment = 0
    data = ''
    while 1:
        line = file.readline()
        if not line:
            break
        
        line_count += 1
        line = line[:-1]

        if not have_c_comment and re.search(r'/\*', line):
            if re.search(r'/\*.*\*/', line):
                line = re.sub(r'/\*.*\*/', '', line)
            else:
                line = re.sub(r'/\*.*$', '', line)
                have_c_comment = 1

        if have_c_comment:
            if not re.search(r'\*/', line):
                continue
            have_c_comment = 0
            line = re.sub(r'^.*\*/', '', line)

        line = NormalizeLine(line)

        if not line:
            continue

        if not got_struct:
            if re.match(r'#include ["<].*[>"]', line):
                cppdirect.append(line)
                continue
            
            if re.match(r'^#(if( |def)|endif)', line):
                cppdirect.append(line)
                continue

            if re.match(r'^#define', line):
                headerdirect.append(line)
                continue

            if not re.match(r'^struct %s {$' % _STRUCT_RE,
                            line, re.IGNORECASE):
                print >>sys.stderr, 'Missing struct on line %d: %s' % (
                    line_count, line)
                sys.exit(1)
            else:
                got_struct = 1
                data += line
            continue

        # We are inside the struct
        tokens = line.split('}')
        if len(tokens) == 1:
            data += ' ' + line
            continue

        if len(tokens[1]):
            print >>sys.stderr, 'Trailing garbage after struct on line %d' % (
                line_count )
            sys.exit(1)

        # We found the end of the struct
        data += ' %s}' % tokens[0]
        break

    # Remove any comments, that might be in there
    data = re.sub(r'/\*.*\*/', '', data)
    
    return data
        

def Parse(file):
    """
    Parses the input file and returns C code and corresponding header file.
    """

    entities = []

    while 1:
        # Just gets the whole struct nicely formatted
        data = GetNextStruct(file)

        if not data:
            break

        entities.extend(ProcessStruct(data))

    return entities

def GuardName(name):
    name = '_'.join(name.split('.'))
    name = '_'.join(name.split('/'))
    guard = '_'+name.upper()+'_'

    return guard

def HeaderPreamble(name):
    guard = GuardName(name)
    pre = (
        '/*\n'
        ' * Automatically generated from %s\n'
        ' */\n\n'
        '#ifndef %s\n'
        '#define %s\n\n' ) % (
        name, guard, guard)

    # insert stdint.h - let's hope everyone has it
    pre += (
        '#include <event-config.h>\n'
        '#ifdef _EVENT_HAVE_STDINT_H\n'
        '#include <stdint.h>\n'
        '#endif\n' )

    for statement in headerdirect:
        pre += '%s\n' % statement
    if headerdirect:
        pre += '\n'

    pre += (
        '#define EVTAG_HAS(msg, member) ((msg)->member##_set == 1)\n'
        '#ifdef __GNUC__\n'
        '#define EVTAG_ASSIGN(msg, member, args...) '
        '(*(msg)->base->member##_assign)(msg, ## args)\n'
        '#define EVTAG_GET(msg, member, args...) '
        '(*(msg)->base->member##_get)(msg, ## args)\n'
        '#else\n'
        '#define EVTAG_ASSIGN(msg, member, ...) '
        '(*(msg)->base->member##_assign)(msg, ## __VA_ARGS__)\n'
        '#define EVTAG_GET(msg, member, ...) '
        '(*(msg)->base->member##_get)(msg, ## __VA_ARGS__)\n'
        '#endif\n'
        '#define EVTAG_ADD(msg, member) (*(msg)->base->member##_add)(msg)\n'
        '#define EVTAG_LEN(msg, member) ((msg)->member##_length)\n'
        )

    return pre
     

def HeaderPostamble(name):
    guard = GuardName(name)
    return '#endif  /* %s */' % guard

def BodyPreamble(name):
    global _NAME
    global _VERSION
    
    header_file = '.'.join(name.split('.')[:-1]) + '.gen.h'

    pre = ( '/*\n'
            ' * Automatically generated from %s\n'
            ' * by %s/%s.  DO NOT EDIT THIS FILE.\n'
            ' */\n\n' ) % (name, _NAME, _VERSION)
    pre += ( '#include <sys/types.h>\n'
             '#ifdef _EVENT_HAVE_SYS_TIME_H\n'
             '#include <sys/time.h>\n'
             '#endif\n'
             '#include <stdlib.h>\n'
             '#include <string.h>\n'
             '#include <assert.h>\n'
             '#define EVENT_NO_STRUCT\n'
             '#include <event.h>\n\n'
             '#ifdef _EVENT___func__\n'
             '#define __func__ _EVENT___func__\n'
             '#endif\n' )

    for statement in cppdirect:
        pre += '%s\n' % statement
    
    pre += '\n#include "%s"\n\n' % header_file

    pre += 'void event_err(int eval, const char *fmt, ...);\n'
    pre += 'void event_warn(const char *fmt, ...);\n'
    pre += 'void event_errx(int eval, const char *fmt, ...);\n'
    pre += 'void event_warnx(const char *fmt, ...);\n\n'

    return pre

def main(argv):
    if len(argv) < 2 or not argv[1]:
        print >>sys.stderr, 'Need RPC description file as first argument.'
        sys.exit(1)

    filename = argv[1]

    ext = filename.split('.')[-1]
    if ext != 'rpc':
        print >>sys.stderr, 'Unrecognized file extension: %s' % ext
        sys.exit(1)

    print >>sys.stderr, 'Reading \"%s\"' % filename

    fp = open(filename, 'r')
    entities = Parse(fp)
    fp.close()

    header_file = '.'.join(filename.split('.')[:-1]) + '.gen.h'
    impl_file = '.'.join(filename.split('.')[:-1]) + '.gen.c'

    print >>sys.stderr, '... creating "%s"' % header_file
    header_fp = open(header_file, 'w')
    print >>header_fp, HeaderPreamble(filename)

    # Create forward declarations: allows other structs to reference
    # each other
    for entry in entities:
        entry.PrintForwardDeclaration(header_fp)
    print >>header_fp, ''

    for entry in entities:
        entry.PrintTags(header_fp)
        entry.PrintDeclaration(header_fp)
    print >>header_fp, HeaderPostamble(filename)
    header_fp.close()

    print >>sys.stderr, '... creating "%s"' % impl_file
    impl_fp = open(impl_file, 'w')
    print >>impl_fp, BodyPreamble(filename)
    for entry in entities:
        entry.PrintCode(impl_fp)
    impl_fp.close()

if __name__ == '__main__':
    main(sys.argv)
