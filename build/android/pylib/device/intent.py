# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Manages intents and associated information.

This is generally intended to be used with functions that calls Android's
Am command.
"""

class Intent(object):

  def __init__(self, action='android.intent.action.VIEW', activity=None,
               category=None, component=None, data=None, extras=None,
               flags=None, package=None):
    """Creates an Intent.

    Args:
      action: A string containing the action.
      activity: A string that, with |package|, can be used to specify the
                component.
      category: A string or list containing any categories.
      component: A string that specifies the component to send the intent to.
      data: A string containing a data URI.
      extras: A dict containing extra parameters to be passed along with the
              intent.
      flags: A string containing flags to pass.
      package: A string that, with activity, can be used to specify the
               component.
    """
    self._action = action
    self._activity = activity
    if isinstance(category, list) or category is None:
      self._category = category
    else:
      self._category = [category]
    self._component = component
    self._data = data
    self._extras = extras
    self._flags = flags
    self._package = package

    if self._component and '/' in component:
      self._package, self._activity = component.split('/', 1)
    elif self._package and self._activity:
      self._component = '%s/%s' % (package, activity)

  @property
  def action(self):
    return self._action

  @property
  def activity(self):
    return self._activity

  @property
  def category(self):
    return self._category

  @property
  def component(self):
    return self._component

  @property
  def data(self):
    return self._data

  @property
  def extras(self):
    return self._extras

  @property
  def flags(self):
    return self._flags

  @property
  def package(self):
    return self._package

  @property
  def am_args(self):
    """Returns the intent as a list of arguments for the activity manager.

    For details refer to the specification at:
    - http://developer.android.com/tools/help/adb.html#IntentSpec
    """
    args = []
    if self.action:
      args.extend(['-a', self.action])
    if self.data:
      args.extend(['-d', self.data])
    if self.category:
      args.extend(arg for cat in self.category for arg in ('-c', cat))
    if self.component:
      args.extend(['-n', self.component])
    if self.flags:
      args.extend(['-f', self.flags])
    if self.extras:
      for key, value in self.extras.iteritems():
        if value is None:
          args.extend(['--esn', key])
        elif isinstance(value, str):
          args.extend(['--es', key, value])
        elif isinstance(value, bool):
          args.extend(['--ez', key, str(value)])
        elif isinstance(value, int):
          args.extend(['--ei', key, str(value)])
        elif isinstance(value, float):
          args.extend(['--ef', key, str(value)])
        else:
          raise NotImplementedError(
              'Intent does not know how to pass %s extras' % type(value))
    return args
