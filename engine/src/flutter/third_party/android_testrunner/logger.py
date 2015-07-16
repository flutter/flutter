#!/usr/bin/python2.4
#
#
# Copyright 2007, The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Simple logging utility. Dumps log messages to stdout, and optionally, to a
log file.

Init(path) must be called to enable logging to a file
"""

import datetime

_LOG_FILE = None
_verbose = False
_log_time = True

def Init(log_file_path):
  """Set the path to the log file"""
  global _LOG_FILE
  _LOG_FILE = log_file_path
  print "Using log file: %s" % _LOG_FILE

def GetLogFilePath():
  """Returns the path and name of the Log file"""
  global _LOG_FILE
  return _LOG_FILE

def Log(new_str):
  """Appends new_str to the end of _LOG_FILE and prints it to stdout.

  Args:
    # new_str is a string.
    new_str: 'some message to log'
  """
  msg = _PrependTimeStamp(new_str)
  print msg
  _WriteLog(msg)

def _WriteLog(msg):
  global _LOG_FILE
  if _LOG_FILE is not None:
    file_handle = file(_LOG_FILE, 'a')
    file_handle.write('\n' + str(msg))
    file_handle.close()

def _PrependTimeStamp(log_string):
  """Returns the log_string prepended with current timestamp """
  global _log_time
  if _log_time:
    return "# %s: %s" % (datetime.datetime.now().strftime("%m/%d/%y %H:%M:%S"),
        log_string)
  else:
    # timestamp logging disabled
    return log_string  

def SilentLog(new_str):
  """Silently log new_str. Unless verbose mode is enabled, will log new_str
    only to the log file
  Args:
    # new_str is a string.
    new_str: 'some message to log'
  """
  global _verbose
  msg = _PrependTimeStamp(new_str)
  if _verbose:
    print msg
  _WriteLog(msg)

def SetVerbose(new_verbose=True):
  """ Enable or disable verbose logging"""
  global _verbose
  _verbose = new_verbose
  
def SetTimestampLogging(new_timestamp=True):
  """ Enable or disable outputting a timestamp with each log entry"""
  global _log_time
  _log_time = new_timestamp
    
def main():
  pass

if __name__ == '__main__':
  main()
