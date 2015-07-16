#!/usr/bin/python2.4
#
# Copyright 2008 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file is used for testing.  The original is at:
#   http://code.google.com/p/pymox/

class StubOutForTesting:
  """Sample Usage:
     You want os.path.exists() to always return true during testing.

     stubs = StubOutForTesting()
     stubs.Set(os.path, 'exists', lambda x: 1)
       ...
     stubs.UnsetAll()

     The above changes os.path.exists into a lambda that returns 1.  Once
     the ... part of the code finishes, the UnsetAll() looks up the old value
     of os.path.exists and restores it.

  """
  def __init__(self):
    self.cache = []
    self.stubs = []

  def __del__(self):
    self.SmartUnsetAll()
    self.UnsetAll()

  def SmartSet(self, obj, attr_name, new_attr):
    """Replace obj.attr_name with new_attr. This method is smart and works
       at the module, class, and instance level while preserving proper
       inheritance. It will not stub out C types however unless that has been
       explicitly allowed by the type.

       This method supports the case where attr_name is a staticmethod or a
       classmethod of obj.

       Notes:
      - If obj is an instance, then it is its class that will actually be
        stubbed. Note that the method Set() does not do that: if obj is
        an instance, it (and not its class) will be stubbed.
      - The stubbing is using the builtin getattr and setattr. So, the __get__
        and __set__ will be called when stubbing (TODO: A better idea would
        probably be to manipulate obj.__dict__ instead of getattr() and
        setattr()).

       Raises AttributeError if the attribute cannot be found.
    """
    if (inspect.ismodule(obj) or
        (not inspect.isclass(obj) and obj.__dict__.has_key(attr_name))):
      orig_obj = obj
      orig_attr = getattr(obj, attr_name)

    else:
      if not inspect.isclass(obj):
        mro = list(inspect.getmro(obj.__class__))
      else:
        mro = list(inspect.getmro(obj))

      mro.reverse()

      orig_attr = None

      for cls in mro:
        try:
          orig_obj = cls
          orig_attr = getattr(obj, attr_name)
        except AttributeError:
          continue

    if orig_attr is None:
      raise AttributeError("Attribute not found.")

    # Calling getattr() on a staticmethod transforms it to a 'normal' function.
    # We need to ensure that we put it back as a staticmethod.
    old_attribute = obj.__dict__.get(attr_name)
    if old_attribute is not None and isinstance(old_attribute, staticmethod):
      orig_attr = staticmethod(orig_attr)

    self.stubs.append((orig_obj, attr_name, orig_attr))
    setattr(orig_obj, attr_name, new_attr)

  def SmartUnsetAll(self):
    """Reverses all the SmartSet() calls, restoring things to their original
    definition.  Its okay to call SmartUnsetAll() repeatedly, as later calls
    have no effect if no SmartSet() calls have been made.

    """
    self.stubs.reverse()

    for args in self.stubs:
      setattr(*args)

    self.stubs = []

  def Set(self, parent, child_name, new_child):
    """Replace child_name's old definition with new_child, in the context
    of the given parent.  The parent could be a module when the child is a
    function at module scope.  Or the parent could be a class when a class'
    method is being replaced.  The named child is set to new_child, while
    the prior definition is saved away for later, when UnsetAll() is called.

    This method supports the case where child_name is a staticmethod or a
    classmethod of parent.
    """
    old_child = getattr(parent, child_name)

    old_attribute = parent.__dict__.get(child_name)
    if old_attribute is not None and isinstance(old_attribute, staticmethod):
      old_child = staticmethod(old_child)

    self.cache.append((parent, old_child, child_name))
    setattr(parent, child_name, new_child)

  def UnsetAll(self):
    """Reverses all the Set() calls, restoring things to their original
    definition.  Its okay to call UnsetAll() repeatedly, as later calls have
    no effect if no Set() calls have been made.

    """
    # Undo calls to Set() in reverse order, in case Set() was called on the
    # same arguments repeatedly (want the original call to be last one undone)
    self.cache.reverse()

    for (parent, old_child, child_name) in self.cache:
      setattr(parent, child_name, old_child)
    self.cache = []
