# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import logging

from pylib import constants
from pylib import content_settings
from pylib.device import device_errors

_LOCK_SCREEN_SETTINGS_PATH = '/data/system/locksettings.db'
_ALTERNATE_LOCK_SCREEN_SETTINGS_PATH = (
    '/data/data/com.android.providers.settings/databases/settings.db')
PASSWORD_QUALITY_UNSPECIFIED = '0'


def ConfigureContentSettings(device, desired_settings):
  """Configures device content setings from a list.

  Many settings are documented at:
    http://developer.android.com/reference/android/provider/Settings.Global.html
    http://developer.android.com/reference/android/provider/Settings.Secure.html
    http://developer.android.com/reference/android/provider/Settings.System.html

  Many others are undocumented.

  Args:
    device: A DeviceUtils instance for the device to configure.
    desired_settings: A list of (table, [(key: value), ...]) for all
        settings to configure.
  """
  if device.build_type == 'userdebug':
    for table, key_value in desired_settings:
      settings = content_settings.ContentSettings(table, device)
      for key, value in key_value:
        settings[key] = value
      logging.info('\n%s %s', table, (80 - len(table)) * '-')
      for key, value in sorted(settings.iteritems()):
        logging.info('\t%s: %s', key, value)


def SetLockScreenSettings(device):
  """Sets lock screen settings on the device.

  On certain device/Android configurations we need to disable the lock screen in
  a different database. Additionally, the password type must be set to
  DevicePolicyManager.PASSWORD_QUALITY_UNSPECIFIED.
  Lock screen settings are stored in sqlite on the device in:
      /data/system/locksettings.db

  IMPORTANT: The first column is used as a primary key so that all rows with the
  same value for that column are removed from the table prior to inserting the
  new values.

  Args:
    device: A DeviceUtils instance for the device to configure.

  Raises:
    Exception if the setting was not properly set.
  """
  if device.build_type != 'userdebug':
    logging.warning('Unable to disable lockscreen on user builds.')
    return

  def get_lock_settings(table):
    return [(table, 'lockscreen.disabled', '1'),
            (table, 'lockscreen.password_type', PASSWORD_QUALITY_UNSPECIFIED),
            (table, 'lockscreen.password_type_alternate',
             PASSWORD_QUALITY_UNSPECIFIED)]

  if device.FileExists(_LOCK_SCREEN_SETTINGS_PATH):
    db = _LOCK_SCREEN_SETTINGS_PATH
    locksettings = get_lock_settings('locksettings')
    columns = ['name', 'user', 'value']
    generate_values = lambda k, v: [k, '0', v]
  elif device.FileExists(_ALTERNATE_LOCK_SCREEN_SETTINGS_PATH):
    db = _ALTERNATE_LOCK_SCREEN_SETTINGS_PATH
    locksettings = get_lock_settings('secure') + get_lock_settings('system')
    columns = ['name', 'value']
    generate_values = lambda k, v: [k, v]
  else:
    logging.warning('Unable to find database file to set lock screen settings.')
    return

  for table, key, value in locksettings:
    # Set the lockscreen setting for default user '0'
    values = generate_values(key, value)

    cmd = """begin transaction;
delete from '%(table)s' where %(primary_key)s='%(primary_value)s';
insert into '%(table)s' (%(columns)s) values (%(values)s);
commit transaction;""" % {
      'table': table,
      'primary_key': columns[0],
      'primary_value': values[0],
      'columns': ', '.join(columns),
      'values': ', '.join(["'%s'" % value for value in values])
    }
    output_msg = device.RunShellCommand('sqlite3 %s "%s"' % (db, cmd),
                                        as_root=True)
    if output_msg:
      logging.info(' '.join(output_msg))


ENABLE_LOCATION_SETTINGS = [
  # Note that setting these in this order is required in order for all of
  # them to take and stick through a reboot.
  ('com.google.settings/partner', [
    ('use_location_for_services', 1),
  ]),
  ('settings/secure', [
    # Ensure Geolocation is enabled and allowed for tests.
    ('location_providers_allowed', 'gps,network'),
  ]),
  ('com.google.settings/partner', [
    ('network_location_opt_in', 1),
  ])
]

DISABLE_LOCATION_SETTINGS = [
  ('com.google.settings/partner', [
    ('use_location_for_services', 0),
  ]),
  ('settings/secure', [
    # Ensure Geolocation is disabled.
    ('location_providers_allowed', ''),
  ]),
]

DETERMINISTIC_DEVICE_SETTINGS = [
  ('settings/global', [
    ('assisted_gps_enabled', 0),

    # Disable "auto time" and "auto time zone" to avoid network-provided time
    # to overwrite the device's datetime and timezone synchronized from host
    # when running tests later. See b/6569849.
    ('auto_time', 0),
    ('auto_time_zone', 0),

    ('development_settings_enabled', 1),

    # Flag for allowing ActivityManagerService to send ACTION_APP_ERROR intents
    # on application crashes and ANRs. If this is disabled, the crash/ANR dialog
    # will never display the "Report" button.
    # Type: int ( 0 = disallow, 1 = allow )
    ('send_action_app_error', 0),

    ('stay_on_while_plugged_in', 3),

    ('verifier_verify_adb_installs', 0),
  ]),
  ('settings/secure', [
    ('allowed_geolocation_origins',
        'http://www.google.co.uk http://www.google.com'),

    # Ensure that we never get random dialogs like "Unfortunately the process
    # android.process.acore has stopped", which steal the focus, and make our
    # automation fail (because the dialog steals the focus then mistakenly
    # receives the injected user input events).
    ('anr_show_background', 0),

    ('lockscreen.disabled', 1),

    ('screensaver_enabled', 0),
  ]),
  ('settings/system', [
    # Don't want devices to accidentally rotate the screen as that could
    # affect performance measurements.
    ('accelerometer_rotation', 0),

    ('lockscreen.disabled', 1),

    # Turn down brightness and disable auto-adjust so that devices run cooler.
    ('screen_brightness', 5),
    ('screen_brightness_mode', 0),

    ('user_rotation', 0),
  ]),
]

NETWORK_DISABLED_SETTINGS = [
  ('settings/global', [
    ('airplane_mode_on', 1),
    ('wifi_on', 0),
  ]),
]
