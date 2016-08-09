# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import atexit
import logging

from pylib import android_commands
from pylib.device import device_errors
from pylib.device import device_utils


class PerfControl(object):
  """Provides methods for setting the performance mode of a device."""
  _CPU_PATH = '/sys/devices/system/cpu'
  _KERNEL_MAX = '/sys/devices/system/cpu/kernel_max'

  def __init__(self, device):
    # TODO(jbudorick) Remove once telemetry gets switched over.
    if isinstance(device, android_commands.AndroidCommands):
      device = device_utils.DeviceUtils(device)
    self._device = device
    # this will raise an AdbCommandFailedError if no CPU files are found
    self._cpu_files = self._device.RunShellCommand(
        'ls -d cpu[0-9]*', cwd=self._CPU_PATH, check_return=True, as_root=True)
    assert self._cpu_files, 'Failed to detect CPUs.'
    self._cpu_file_list = ' '.join(self._cpu_files)
    logging.info('CPUs found: %s', self._cpu_file_list)
    self._have_mpdecision = self._device.FileExists('/system/bin/mpdecision')

  def SetHighPerfMode(self):
    """Sets the highest stable performance mode for the device."""
    try:
      self._device.EnableRoot()
    except device_errors.CommandFailedError:
      message = 'Need root for performance mode. Results may be NOISY!!'
      logging.warning(message)
      # Add an additional warning at exit, such that it's clear that any results
      # may be different/noisy (due to the lack of intended performance mode).
      atexit.register(logging.warning, message)
      return

    product_model = self._device.product_model
    # TODO(epenner): Enable on all devices (http://crbug.com/383566)
    if 'Nexus 4' == product_model:
      self._ForceAllCpusOnline(True)
      if not self._AllCpusAreOnline():
        logging.warning('Failed to force CPUs online. Results may be NOISY!')
      self._SetScalingGovernorInternal('performance')
    elif 'Nexus 5' == product_model:
      self._ForceAllCpusOnline(True)
      if not self._AllCpusAreOnline():
        logging.warning('Failed to force CPUs online. Results may be NOISY!')
      self._SetScalingGovernorInternal('performance')
      self._SetScalingMaxFreq(1190400)
      self._SetMaxGpuClock(200000000)
    else:
      self._SetScalingGovernorInternal('performance')

  def SetPerfProfilingMode(self):
    """Enables all cores for reliable perf profiling."""
    self._ForceAllCpusOnline(True)
    self._SetScalingGovernorInternal('performance')
    if not self._AllCpusAreOnline():
      if not self._device.HasRoot():
        raise RuntimeError('Need root to force CPUs online.')
      raise RuntimeError('Failed to force CPUs online.')

  def SetDefaultPerfMode(self):
    """Sets the performance mode for the device to its default mode."""
    if not self._device.HasRoot():
      return
    product_model = self._device.product_model
    if 'Nexus 5' == product_model:
      if self._AllCpusAreOnline():
        self._SetScalingMaxFreq(2265600)
        self._SetMaxGpuClock(450000000)

    governor_mode = {
        'GT-I9300': 'pegasusq',
        'Galaxy Nexus': 'interactive',
        'Nexus 4': 'ondemand',
        'Nexus 5': 'ondemand',
        'Nexus 7': 'interactive',
        'Nexus 10': 'interactive'
    }.get(product_model, 'ondemand')
    self._SetScalingGovernorInternal(governor_mode)
    self._ForceAllCpusOnline(False)

  def GetCpuInfo(self):
    online = (output.rstrip() == '1' and status == 0
              for (_, output, status) in self._ForEachCpu('cat "$CPU/online"'))
    governor = (output.rstrip() if status == 0 else None
                for (_, output, status)
                in self._ForEachCpu('cat "$CPU/cpufreq/scaling_governor"'))
    return zip(self._cpu_files, online, governor)

  def _ForEachCpu(self, cmd):
    script = '; '.join([
        'for CPU in %s' % self._cpu_file_list,
        'do %s' % cmd,
        'echo -n "%~%$?%~%"',
        'done'
    ])
    output = self._device.RunShellCommand(
        script, cwd=self._CPU_PATH, check_return=True, as_root=True)
    output = '\n'.join(output).split('%~%')
    return zip(self._cpu_files, output[0::2], (int(c) for c in output[1::2]))

  def _WriteEachCpuFile(self, path, value):
    results = self._ForEachCpu(
        'test -e "$CPU/{path}" && echo {value} > "$CPU/{path}"'.format(
            path=path, value=value))
    cpus = ' '.join(cpu for (cpu, _, status) in results if status == 0)
    if cpus:
      logging.info('Successfully set %s to %r on: %s', path, value, cpus)
    else:
      logging.warning('Failed to set %s to %r on any cpus')

  def _SetScalingGovernorInternal(self, value):
    self._WriteEachCpuFile('cpufreq/scaling_governor', value)

  def _SetScalingMaxFreq(self, value):
    self._WriteEachCpuFile('cpufreq/scaling_max_freq', '%d' % value)

  def _SetMaxGpuClock(self, value):
    self._device.WriteFile('/sys/class/kgsl/kgsl-3d0/max_gpuclk',
                           str(value),
                           as_root=True)

  def _AllCpusAreOnline(self):
    results = self._ForEachCpu('cat "$CPU/online"')
    # TODO(epenner): Investigate why file may be missing
    # (http://crbug.com/397118)
    return all(output.rstrip() == '1' and status == 0
               for (cpu, output, status) in results
               if cpu != 'cpu0')

  def _ForceAllCpusOnline(self, force_online):
    """Enable all CPUs on a device.

    Some vendors (or only Qualcomm?) hot-plug their CPUs, which can add noise
    to measurements:
    - In perf, samples are only taken for the CPUs that are online when the
      measurement is started.
    - The scaling governor can't be set for an offline CPU and frequency scaling
      on newly enabled CPUs adds noise to both perf and tracing measurements.

    It appears Qualcomm is the only vendor that hot-plugs CPUs, and on Qualcomm
    this is done by "mpdecision".

    """
    if self._have_mpdecision:
      script = 'stop mpdecision' if force_online else 'start mpdecision'
      self._device.RunShellCommand(script, check_return=True, as_root=True)

    if not self._have_mpdecision and not self._AllCpusAreOnline():
      logging.warning('Unexpected cpu hot plugging detected.')

    if force_online:
      self._ForEachCpu('echo 1 > "$CPU/online"')
