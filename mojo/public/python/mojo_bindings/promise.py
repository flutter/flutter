# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Promise used by the python bindings.

The API is following the ECMAScript 6 API for promises.
"""

import sys


class Promise(object):
  """The promise object."""

  STATE_PENDING = 0
  STATE_FULLFILLED = 1
  STATE_REJECTED = 2
  STATE_BOUND = 3

  def __init__(self, generator_function):
    """
    Constructor.

    Args:
      generator_function: A function taking 2 arguments: resolve and reject.
      When |resolve| is called, the promise is fullfilled with the given value.
      When |reject| is called, the promise is rejected with the given value.
      A promise can only be resolved or rejected once, all following calls will
      have no effect.
    """
    self._onCatched = []
    self._onFulfilled = []
    self._onRejected = []
    self._state = Promise.STATE_PENDING
    self._result = None
    try:
      generator_function(self._Resolve, self._Reject)
    except Exception as e:
      # Adding traceback similarly to python 3.0 (pep-3134)
      e.__traceback__ = sys.exc_info()[2]
      self._Reject(e)

  @staticmethod
  def Resolve(value):
    """
    If value is a promise, make a promise that have the same behavior as value,
    otherwise make a promise that fulfills to value.
    """
    if isinstance(value, Promise):
      return value
    return Promise(lambda x, y: x(value))

  @staticmethod
  def Reject(reason):
    "Make a promise that rejects to reason."""
    return Promise(lambda x, y: y(reason))

  @staticmethod
  def All(*iterable):
    """
    Make a promise that fulfills when every item in the array fulfills, and
    rejects if (and when) any item rejects. Each array item is passed to
    Promise.resolve, so the array can be a mixture of promise-like objects and
    other objects. The fulfillment value is an array (in order) of fulfillment
    values. The rejection value is the first rejection value.
    """
    def GeneratorFunction(resolve, reject):
      state = {
        'rejected': False,
        'nb_resolved': 0,
      }
      promises = [Promise.Resolve(x) for x in iterable]
      results = [None for x in promises]
      def OnFullfilled(i):
        def OnFullfilled(res):
          if state['rejected']:
            return
          results[i] = res
          state['nb_resolved'] = state['nb_resolved'] + 1
          if state['nb_resolved'] == len(results):
            resolve(results)
        return OnFullfilled
      def OnRejected(reason):
        if state['rejected']:
          return
        state['rejected'] = True
        reject(reason)

      for (i, promise) in enumerate(promises):
        promise.Then(OnFullfilled(i), OnRejected)
    return Promise(GeneratorFunction)

  @staticmethod
  def Race(*iterable):
    """
    Make a Promise that fulfills as soon as any item fulfills, or rejects as
    soon as any item rejects, whichever happens first.
    """
    def GeneratorFunction(resolve, reject):
      state = {
        'ended': False
      }
      def OnEvent(callback):
        def OnEvent(res):
          if state['ended']:
            return
          state['ended'] = True
          callback(res)
        return OnEvent
      for promise in [Promise.Resolve(x) for x in iterable]:
        promise.Then(OnEvent(resolve), OnEvent(reject))
    return Promise(GeneratorFunction)

  @property
  def state(self):
    if isinstance(self._result, Promise):
      return self._result.state
    return self._state

  def Then(self, onFullfilled=None, onRejected=None):
    """
    onFulfilled is called when/if this promise resolves. onRejected is called
    when/if this promise rejects. Both are optional, if either/both are omitted
    the next onFulfilled/onRejected in the chain is called. Both callbacks have
    a single parameter, the fulfillment value or rejection reason. |Then|
    returns a new promise equivalent to the value you return from
    onFulfilled/onRejected after being passed through Resolve. If an
    error is thrown in the callback, the returned promise rejects with that
    error.
    """
    if isinstance(self._result, Promise):
      return self._result.Then(onFullfilled, onRejected)
    def GeneratorFunction(resolve, reject):
      recover = reject
      if onRejected:
        recover = resolve
      if self._state == Promise.STATE_PENDING:
        self._onFulfilled.append(_Delegate(resolve, reject, onFullfilled))
        self._onRejected.append(_Delegate(recover, reject, onRejected))
      if self._state == self.STATE_FULLFILLED:
        _Delegate(resolve, reject, onFullfilled)(self._result)
      if self._state == self.STATE_REJECTED:
        _Delegate(recover, reject, onRejected)(self._result)
    return Promise(GeneratorFunction)

  def Catch(self, onCatched):
    """Equivalent to |Then(None, onCatched)|"""
    return self.Then(None, onCatched)

  def __getattr__(self, attribute):
    """
    Allows to get member of a promise. It will return a promise that will
    resolve to the member of the result.
    """
    return self.Then(lambda v: getattr(v, attribute))

  def __call__(self, *args, **kwargs):
    """
    Allows to call this promise. It will return a promise that will resolved to
    the result of calling the result of this promise with the given arguments.
    """
    return self.Then(lambda v: v(*args, **kwargs))


  def _Resolve(self, value):
    if self.state != Promise.STATE_PENDING:
      return
    self._result = value
    if isinstance(value, Promise):
      self._state = Promise.STATE_BOUND
      self._result.Then(_IterateAction(self._onFulfilled),
                        _IterateAction(self._onRejected))
      return
    self._state = Promise.STATE_FULLFILLED
    for f in self._onFulfilled:
      f(value)
    self._onFulfilled = None
    self._onRejected = None

  def _Reject(self, reason):
    if self.state != Promise.STATE_PENDING:
      return
    self._result = reason
    self._state = Promise.STATE_REJECTED
    for f in self._onRejected:
      f(reason)
    self._onFulfilled = None
    self._onRejected = None


def async(f):
  def _ResolvePromises(*args, **kwargs):
    keys = kwargs.keys()
    values = kwargs.values()
    all_args = list(args) + values
    return Promise.All(*all_args).Then(
        lambda r: f(*r[:len(args)], **dict(zip(keys, r[len(args):]))))
  return _ResolvePromises


def _IterateAction(iterable):
  def _Run(x):
    for f in iterable:
      f(x)
  return _Run


def _Delegate(resolve, reject, action):
  def _Run(x):
    try:
      if action:
        resolve(action(x))
      else:
        resolve(x)
    except Exception as e:
      # Adding traceback similarly to python 3.0 (pep-3134)
      e.__traceback__ = sys.exc_info()[2]
      reject(e)
  return _Run
