#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys

#
# IDL Node
#
# IDL Node defines the IDLAttribute and IDLNode objects which are constructed
# by the parser as it processes the various 'productions'.  The IDLAttribute
# objects are assigned to the IDLNode's property dictionary instead of being
# applied as children of The IDLNodes, so they do not exist in the final tree.
# The AST of IDLNodes is the output from the parsing state and will be used
# as the source data by the various generators.
#


#
# CopyToList
#
# Takes an input item, list, or None, and returns a new list of that set.
def CopyToList(item):
  # If the item is 'Empty' make it an empty list
  if not item:
    item = []

  # If the item is not a list
  if type(item) is not type([]):
    item = [item]

  # Make a copy we can modify
  return list(item)


# IDLSearch
#
# A temporary object used by the parsing process to hold an Extended Attribute
# which will be passed as a child to a standard IDLNode.
#
class IDLSearch(object):
  def __init__(self):
    self.depth = 0

  def Enter(self, node):
    pass

  def Exit(self, node):
    pass


# IDLAttribute
#
# A temporary object used by the parsing process to hold an Extended Attribute
# which will be passed as a child to a standard IDLNode.
#
class IDLAttribute(object):
  def __init__(self, name, value):
    self._cls = 'Property'
    self.name = name
    self.value = value

  def __str__(self):
    return '%s=%s' % (self.name, self.value)

  def GetClass(self):
    return self._cls

#
# IDLNode
#
# This class implements the AST tree, providing the associations between
# parents and children.  It also contains a namepsace and propertynode to
# allow for look-ups.  IDLNode is derived from IDLRelease, so it is
# version aware.
#
class IDLNode(object):
  def __init__(self, cls, filename, lineno, pos, children=None):
    self._cls = cls
    self._properties = {
      'ERRORS' : [],
      'WARNINGS': [],
      'FILENAME': filename,
      'LINENO' : lineno,
      'POSSITION' : pos,
    }

    self._children = []
    self._parent = None
    self.AddChildren(children)

#
#
#
  # Return a string representation of this node
  def __str__(self):
    name = self.GetProperty('NAME','')
    return '%s(%s)' % (self._cls, name)

  def GetLogLine(self, msg):
    filename, lineno = self.GetFileAndLine()
    return '%s(%d) : %s\n' % (filename, lineno, msg)

  # Log an error for this object
  def Error(self, msg):
    self.GetProperty('ERRORS').append(msg)
    sys.stderr.write(self.GetLogLine('error: ' + msg))

  # Log a warning for this object
  def Warning(self, msg):
    self.GetProperty('WARNINGS').append(msg)
    sys.stdout.write(self.GetLogLine('warning:' + msg))

  # Return file and line number for where node was defined
  def GetFileAndLine(self):
    return self.GetProperty('FILENAME'), self.GetProperty('LINENO')

  def GetClass(self):
    return self._cls

  def GetName(self):
    return self.GetProperty('NAME')

  def GetParent(self):
    return self._parent

  def Traverse(self, search, filter_nodes):
    if self._cls in filter_nodes:
      return ''

    search.Enter(self)
    search.depth += 1
    for child in self._children:
      child.Traverse(search, filter_nodes)
    search.depth -= 1
    search.Exit(self)


  def Tree(self, filter_nodes=None, accept_props=None):
    class DumpTreeSearch(IDLSearch):
      def __init__(self, props):
        IDLSearch.__init__(self)
        self.out = []
        self.props = props

      def Enter(self, node):
        tab = ''.rjust(self.depth * 2)
        self.out.append(tab + str(node))
        if self.props:
          proplist = []
          for key, value in node.GetProperties().iteritems():
            if key in self.props:
              proplist.append(tab + '    %s: %s' % (key, str(value)))
          if proplist:
            self.out.append(tab + '  PROPERTIES')
            self.out.extend(proplist)

    if filter_nodes == None:
      filter_nodes = ['Comment', 'Copyright']

    search = DumpTreeSearch(accept_props)
    self.Traverse(search, filter_nodes)
    return search.out

#
# Search related functions
#
  # Check if node is of a given type
  def IsA(self, *typelist):
    if self._cls in typelist:
      return True
    return False

  # Get a list of all children
  def GetChildren(self):
    return self._children

  def GetListOf(self, *keys):
    out = []
    for child in self.GetChildren():
      if child.GetClass() in keys:
        out.append(child)
    return out

  def GetOneOf(self, *keys):
    out = self.GetListOf(*keys)
    if out:
      return out[0]
    return None

  def AddChildren(self, children):
    children = CopyToList(children)
    for child in children:
      if not child:
        continue
      if type(child) == IDLAttribute:
        self.SetProperty(child.name, child.value)
        continue
      if type(child) == IDLNode:
        child._parent = self
        self._children.append(child)
        continue
      raise RuntimeError('Adding child of type %s.\n' % type(child).__name__)


#
# Property Functions
#
  def SetProperty(self, name, val):
    self._properties[name] = val

  def GetProperty(self, name, default=None):
    return self._properties.get(name, default)

  def GetProperties(self):
    return self._properties
