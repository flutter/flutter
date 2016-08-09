# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Environment setup and teardown for remote devices."""

import distutils.version
import json
import logging
import os
import random
import sys

from pylib import constants
from pylib.base import environment
from pylib.remote.device import appurify_sanitized
from pylib.remote.device import remote_device_helper
from pylib.utils import timeout_retry
from pylib.utils import reraiser_thread

class RemoteDeviceEnvironment(environment.Environment):
  """An environment for running on remote devices."""

  _ENV_KEY = 'env'
  _DEVICE_KEY = 'device'
  _DEFAULT_RETRIES = 0

  def __init__(self, args, error_func):
    """Constructor.

    Args:
      args: Command line arguments.
      error_func: error to show when using bad command line arguments.
    """
    super(RemoteDeviceEnvironment, self).__init__()
    self._access_token = None
    self._device = None
    self._device_type = args.device_type
    self._verbose_count = args.verbose_count
    self._timeouts = {
        'queueing': 60 * 10,
        'installing': 60 * 10,
        'in-progress': 60 * 30,
        'unknown': 60 * 5
    }
    # Example config file:
    # {
    #   "remote_device": ["Galaxy S4", "Galaxy S3"],
    #   "remote_device_os": ["4.4.2", "4.4.4"],
    #   "remote_device_minimum_os": "4.4.2",
    #   "api_address": "www.example.com",
    #   "api_port": "80",
    #   "api_protocol": "http",
    #   "api_secret": "apisecret",
    #   "api_key": "apikey",
    #   "timeouts": {
    #     "queueing": 600,
    #     "installing": 600,
    #     "in-progress": 1800,
    #     "unknown": 300
    #   }
    # }
    if args.remote_device_file:
      with open(args.remote_device_file) as device_file:
        device_json = json.load(device_file)
    else:
      device_json = {}

    self._api_address = device_json.get('api_address', None)
    self._api_key = device_json.get('api_key', None)
    self._api_port = device_json.get('api_port', None)
    self._api_protocol = device_json.get('api_protocol', None)
    self._api_secret = device_json.get('api_secret', None)
    self._device_oem = device_json.get('device_oem', None)
    self._device_type = device_json.get('device_type', 'Android')
    self._network_config = device_json.get('network_config', None)
    self._remote_device = device_json.get('remote_device', None)
    self._remote_device_minimum_os = device_json.get(
        'remote_device_minimum_os', None)
    self._remote_device_os = device_json.get('remote_device_os', None)
    self._remote_device_timeout = device_json.get(
        'remote_device_timeout', None)
    self._results_path = device_json.get('results_path', None)
    self._runner_package = device_json.get('runner_package', None)
    self._runner_type = device_json.get('runner_type', None)
    self._timeouts.update(device_json.get('timeouts', {}))

    def command_line_override(
        file_value, cmd_line_value, desc, print_value=True):
      if cmd_line_value:
        if file_value and file_value != cmd_line_value:
          if print_value:
            logging.info('Overriding %s from %s to %s',
                         desc, file_value, cmd_line_value)
          else:
            logging.info('overriding %s', desc)
        return cmd_line_value
      return file_value

    self._api_address = command_line_override(
        self._api_address, args.api_address, 'api_address')
    self._api_port = command_line_override(
        self._api_port, args.api_port, 'api_port')
    self._api_protocol = command_line_override(
        self._api_protocol, args.api_protocol, 'api_protocol')
    self._device_oem = command_line_override(
        self._device_oem, args.device_oem, 'device_oem')
    self._device_type = command_line_override(
        self._device_type, args.device_type, 'device_type')
    self._network_config = command_line_override(
        self._network_config, args.network_config, 'network_config')
    self._remote_device = command_line_override(
        self._remote_device, args.remote_device, 'remote_device')
    self._remote_device_minimum_os = command_line_override(
        self._remote_device_minimum_os, args.remote_device_minimum_os,
        'remote_device_minimum_os')
    self._remote_device_os = command_line_override(
        self._remote_device_os, args.remote_device_os, 'remote_device_os')
    self._remote_device_timeout = command_line_override(
        self._remote_device_timeout, args.remote_device_timeout,
        'remote_device_timeout')
    self._results_path = command_line_override(
        self._results_path, args.results_path, 'results_path')
    self._runner_package = command_line_override(
        self._runner_package, args.runner_package, 'runner_package')
    self._runner_type = command_line_override(
        self._runner_type, args.runner_type, 'runner_type')

    if args.api_key_file:
      with open(args.api_key_file) as api_key_file:
        temp_key = api_key_file.read().strip()
        self._api_key = command_line_override(
            self._api_key, temp_key, 'api_key', print_value=False)
    self._api_key = command_line_override(
        self._api_key, args.api_key, 'api_key', print_value=False)

    if args.api_secret_file:
      with open(args.api_secret_file) as api_secret_file:
        temp_secret = api_secret_file.read().strip()
        self._api_secret = command_line_override(
            self._api_secret, temp_secret, 'api_secret', print_value=False)
    self._api_secret = command_line_override(
        self._api_secret, args.api_secret, 'api_secret', print_value=False)

    if not self._api_address:
      error_func('Must set api address with --api-address'
                 ' or in --remote-device-file.')
    if not self._api_key:
      error_func('Must set api key with --api-key, --api-key-file'
                 ' or in --remote-device-file')
    if not self._api_port:
      error_func('Must set api port with --api-port'
                 ' or in --remote-device-file')
    if not self._api_protocol:
      error_func('Must set api protocol with --api-protocol'
                 ' or in --remote-device-file. Example: http')
    if not self._api_secret:
      error_func('Must set api secret with --api-secret, --api-secret-file'
                 ' or in --remote-device-file')

    logging.info('Api address: %s', self._api_address)
    logging.info('Api port: %s', self._api_port)
    logging.info('Api protocol: %s', self._api_protocol)
    logging.info('Remote device: %s', self._remote_device)
    logging.info('Remote device minimum OS: %s',
                 self._remote_device_minimum_os)
    logging.info('Remote device OS: %s', self._remote_device_os)
    logging.info('Remote device OEM: %s', self._device_oem)
    logging.info('Remote device type: %s', self._device_type)
    logging.info('Remote device timout: %s', self._remote_device_timeout)
    logging.info('Results Path: %s', self._results_path)
    logging.info('Runner package: %s', self._runner_package)
    logging.info('Runner type: %s', self._runner_type)
    logging.info('Timeouts: %s', self._timeouts)

    if not args.trigger and not args.collect:
      self._trigger = True
      self._collect = True
    else:
      self._trigger = args.trigger
      self._collect = args.collect

  def SetUp(self):
    """Set up the test environment."""
    os.environ['APPURIFY_API_PROTO'] = self._api_protocol
    os.environ['APPURIFY_API_HOST'] = self._api_address
    os.environ['APPURIFY_API_PORT'] = self._api_port
    os.environ['APPURIFY_STATUS_BASE_URL'] = 'none'
    self._GetAccessToken()
    if self._trigger:
      self._SelectDevice()

  def TearDown(self):
    """Teardown the test environment."""
    self._RevokeAccessToken()

  def __enter__(self):
    """Set up the test run when used as a context manager."""
    try:
      self.SetUp()
      return self
    except:
      self.__exit__(*sys.exc_info())
      raise

  def __exit__(self, exc_type, exc_val, exc_tb):
    """Tears down the test run when used as a context manager."""
    self.TearDown()

  def DumpTo(self, persisted_data):
    env_data = {
      self._DEVICE_KEY: self._device,
    }
    persisted_data[self._ENV_KEY] = env_data

  def LoadFrom(self, persisted_data):
    env_data = persisted_data[self._ENV_KEY]
    self._device = env_data[self._DEVICE_KEY]

  def _GetAccessToken(self):
    """Generates access token for remote device service."""
    logging.info('Generating remote service access token')
    with appurify_sanitized.SanitizeLogging(self._verbose_count,
                                            logging.WARNING):
      access_token_results = appurify_sanitized.api.access_token_generate(
          self._api_key, self._api_secret)
    remote_device_helper.TestHttpResponse(access_token_results,
                                          'Unable to generate access token.')
    self._access_token = access_token_results.json()['response']['access_token']

  def _RevokeAccessToken(self):
    """Destroys access token for remote device service."""
    logging.info('Revoking remote service access token')
    with appurify_sanitized.SanitizeLogging(self._verbose_count,
                                            logging.WARNING):
      revoke_token_results = appurify_sanitized.api.access_token_revoke(
          self._access_token)
    remote_device_helper.TestHttpResponse(revoke_token_results,
                                          'Unable to revoke access token.')

  def _SelectDevice(self):
    if self._remote_device_timeout:
      try:
        timeout_retry.Run(self._FindDeviceWithTimeout,
                          self._remote_device_timeout, self._DEFAULT_RETRIES)
      except reraiser_thread.TimeoutError:
        self._NoDeviceFound()
    else:
      if not self._FindDevice():
        self._NoDeviceFound()

  def _FindDevice(self):
    """Find which device to use."""
    logging.info('Finding device to run tests on.')
    device_list = self._GetDeviceList()
    random.shuffle(device_list)
    for device in device_list:
      if device['os_name'] != self._device_type:
        continue
      if self._remote_device and device['name'] not in self._remote_device:
        continue
      if (self._remote_device_os
          and device['os_version'] not in self._remote_device_os):
        continue
      if self._device_oem and device['brand'] not in self._device_oem:
        continue
      if (self._remote_device_minimum_os
          and distutils.version.LooseVersion(device['os_version'])
          < distutils.version.LooseVersion(self._remote_device_minimum_os)):
        continue
      if device['has_available_device']:
        logging.info('Found device: %s %s',
                     device['name'], device['os_version'])
        self._device = device
        return True
    return False

  def _FindDeviceWithTimeout(self):
    """Find which device to use with timeout."""
    timeout_retry.WaitFor(self._FindDevice, wait_period=1)

  def _PrintAvailableDevices(self, device_list):
    def compare_devices(a,b):
      for key in ('os_version', 'name'):
        c = cmp(a[key], b[key])
        if c:
          return c
      return 0

    logging.critical('Available %s Devices:', self._device_type)
    logging.critical(
        '  %s %s %s %s %s',
        'OS'.ljust(10),
        'Device Name'.ljust(30),
        'Available'.ljust(10),
        'Busy'.ljust(10),
        'All'.ljust(10))
    devices = (d for d in device_list if d['os_name'] == self._device_type)
    for d in sorted(devices, compare_devices):
      logging.critical(
          '  %s %s %s %s %s',
          d['os_version'].ljust(10),
          d['name'].ljust(30),
          str(d['available_devices_count']).ljust(10),
          str(d['busy_devices_count']).ljust(10),
          str(d['all_devices_count']).ljust(10))

  def _GetDeviceList(self):
    with appurify_sanitized.SanitizeLogging(self._verbose_count,
                                            logging.WARNING):
      dev_list_res = appurify_sanitized.api.devices_list(self._access_token)
    remote_device_helper.TestHttpResponse(dev_list_res,
                                         'Unable to generate access token.')
    return dev_list_res.json()['response']

  def _NoDeviceFound(self):
    self._PrintAvailableDevices(self._GetDeviceList())
    raise remote_device_helper.RemoteDeviceError(
        'No device found.', is_infra_error=True)

  @property
  def collect(self):
    return self._collect

  @property
  def device_type_id(self):
    return self._device['device_type_id']

  @property
  def network_config(self):
    return self._network_config

  @property
  def only_output_failures(self):
    # TODO(jbudorick): Remove this once b/18981674 is fixed.
    return True

  @property
  def results_path(self):
    return self._results_path

  @property
  def runner_package(self):
    return self._runner_package

  @property
  def runner_type(self):
    return self._runner_type

  @property
  def timeouts(self):
    return self._timeouts

  @property
  def token(self):
    return self._access_token

  @property
  def trigger(self):
    return self._trigger

  @property
  def verbose_count(self):
    return self._verbose_count

  @property
  def device_type(self):
    return self._device_type
