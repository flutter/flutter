#!/usr/bin/env python

# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import datetime
import getpass
import json
import os
import smtplib
import sys
import time
import urllib
import urllib2

class Emailer:
  DEFAULT_EMAIL_PASSWORD_FILE = '.email_password'
  GMAIL_SMTP_SERVER = 'smtp.gmail.com:587'
  SUBJECT = 'Chrome GPU Bots Notification'

  def __init__(self, email_from, email_to, email_password_file):
    self.email_from = email_from
    self.email_to = email_to
    self.email_password = Emailer._getEmailPassword(email_password_file)

  @staticmethod
  def format_email_body(time_str, offline_str, failed_str, noteworthy_str):
    return '%s%s%s%s' % (time_str, offline_str, failed_str, noteworthy_str)

  def send_email(self, body):
    message = 'From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s' % (self.email_from,
            ','.join(self.email_to), Emailer.SUBJECT, body)

    try:
      server = smtplib.SMTP(Emailer.GMAIL_SMTP_SERVER)
      server.starttls()
      server.login(self.email_from, self.email_password)
      server.sendmail(self.email_from, self.email_to, message)
      server.quit()
    except Exception as e:
      print 'Error sending email: %s' % str(e)

  def testEmailLogin(self):
    server = smtplib.SMTP(Emailer.GMAIL_SMTP_SERVER)
    server.starttls()
    server.login(self.email_from, self.email_password)
    server.quit()

  @staticmethod
  def _getEmailPassword(email_password_file):
    password = ''

    password_file = (email_password_file if email_password_file is not None
            else Emailer.DEFAULT_EMAIL_PASSWORD_FILE)

    if os.path.isfile(password_file):
      with open(password_file, 'r') as f:
        password = f.read().strip()
    else:
      password = getpass.getpass(
              'Please enter email password for source email account: ')

    return password

class GpuBot:
  def __init__(self, waterfall_name, bot_name, bot_data):
    self.waterfall_name = waterfall_name
    self.bot_name = bot_name
    self.bot_data = bot_data
    self._end_time = None
    self._hours_since_last_run = None
    self.failure_string = None
    self.bot_url = None
    self.build_url = None

  def getEndTime(self):
    return self._end_time

  def setEndTime(self, end_time):
    self._end_time = end_time
    self._hours_since_last_run = \
            roughTimeDiffInHours(end_time, time.localtime())

  def getHoursSinceLastRun(self):
    return self._hours_since_last_run

  def toDict(self):
    dict = {'waterfall_name': self.waterfall_name, 'bot_name': self.bot_name}

    if self._end_time is not None:
      dict['end_time'] = serialTime(self._end_time)
      dict['hours_since_last_run'] = self._hours_since_last_run

    if self.failure_string is not None:
      dict['failure_string'] = self.failure_string

    if self.bot_url is not None:
      dict['bot_url'] = self.bot_url

    if self.build_url is not None:
      dict['build_url'] = self.build_url

    return dict

  @staticmethod
  def fromDict(dict):
    gpu_bot = GpuBot(dict['waterfall_name'], dict['bot_name'], None)

    if 'end_time' in dict:
      gpu_bot._end_time = unserializeTime(dict['end_time'])

    if 'hours_since_last_run' in dict:
      gpu_bot._hours_since_last_run = dict['hours_since_last_run']

    if 'failure_string' in dict:
      gpu_bot.failure_string = dict['failure_string']

    if 'bot_url' in dict:
      gpu_bot.bot_url = dict['bot_url']

    if 'build_url' in dict:
      gpu_bot.build_url = dict['build_url']

    return gpu_bot

def errorNoMostRecentBuild(waterfall_name, bot_name):
  print 'No most recent build available: %s::%s' % (waterfall_name, bot_name)

class Waterfall:
  BASE_URL = 'http://build.chromium.org/p/'
  BASE_BUILD_URL = BASE_URL + '%s/builders/%s'
  SPECIFIC_BUILD_URL = BASE_URL + '%s/builders/%s/builds/%s'
  BASE_JSON_BUILDERS_URL = BASE_URL + '%s/json/builders'
  BASE_JSON_BUILDS_URL = BASE_URL + '%s/json/builders/%s/builds'
  REGULAR_WATERFALLS = ['chromium.gpu', 'chromium.gpu.fyi']
  WEBKIT_GPU_BOTS = ['GPU Win Builder',
          'GPU Win Builder (dbg)',
          'GPU Win7 (NVIDIA)',
          'GPU Win7 (dbg) (NVIDIA)',
          'GPU Mac Builder',
          'GPU Mac Builder (dbg)',
          'GPU Mac10.7',
          'GPU Mac10.7 (dbg)',
          'GPU Linux Builder',
          'GPU Linux Builder (dbg)',
          'GPU Linux (NVIDIA)',
          'GPU Linux (dbg) (NVIDIA)']
  FILTERED_WATERFALLS = [('chromium.webkit', WEBKIT_GPU_BOTS)]

  @staticmethod
  def getJsonFromUrl(url):
    conn = urllib2.urlopen(url)
    result = conn.read()
    conn.close()
    return json.loads(result)

  @staticmethod
  def getBuildersJsonForWaterfall(waterfall):
    querystring = '?filter'
    return (Waterfall.getJsonFromUrl((Waterfall.BASE_JSON_BUILDERS_URL + '%s')
        % (waterfall, querystring)))

  @staticmethod
  def getLastNBuildsForBuilder(n, waterfall, builder):
    if n <= 0:
      return {}

    querystring = '?'

    for i in range(n):
      querystring += 'select=-%d&' % (i + 1)

    querystring += 'filter'

    return Waterfall.getJsonFromUrl((Waterfall.BASE_JSON_BUILDS_URL + '%s') %
            (waterfall, urllib.quote(builder), querystring))

  @staticmethod
  def getFilteredBuildersJsonForWaterfall(waterfall, filter):
    querystring = '?'

    for bot_name in filter:
      querystring += 'select=%s&' % urllib.quote(bot_name)

    querystring += 'filter'

    return Waterfall.getJsonFromUrl((Waterfall.BASE_JSON_BUILDERS_URL + '%s')
            % (waterfall, querystring))

  @staticmethod
  def getAllGpuBots():
    allbots = {k: Waterfall.getBuildersJsonForWaterfall(k)
            for k in Waterfall.REGULAR_WATERFALLS}

    filteredbots = {k[0]:
            Waterfall.getFilteredBuildersJsonForWaterfall(k[0], k[1])
            for k in Waterfall.FILTERED_WATERFALLS}

    allbots.update(filteredbots)

    return allbots

  @staticmethod
  def getOfflineBots(bots):
    offline_bots = []

    for waterfall_name in bots:
      waterfall = bots[waterfall_name]

      for bot_name in waterfall:
        bot = waterfall[bot_name]

        if bot['state'] != 'offline':
          continue

        gpu_bot = GpuBot(waterfall_name, bot_name, bot)
        gpu_bot.bot_url = Waterfall.BASE_BUILD_URL % (waterfall_name,
                urllib.quote(bot_name))

        most_recent_build = Waterfall.getMostRecentlyCompletedBuildForBot(
                gpu_bot)

        if (most_recent_build and 'times' in most_recent_build and
                most_recent_build['times']):
          gpu_bot.setEndTime(time.localtime(most_recent_build['times'][1]))
        else:
          errorNoMostRecentBuild(waterfall_name, bot_name)

        offline_bots.append(gpu_bot)

    return offline_bots

  @staticmethod
  def getMostRecentlyCompletedBuildForBot(bot):
    if bot.bot_data is not None and 'most_recent_build' in bot.bot_data:
      return bot.bot_data['most_recent_build']

    # Unfortunately, the JSON API doesn't provide a "most recent completed
    # build" call. We just have to get some number of the most recent (including
    # current, in-progress builds) and give up if that's not enough.
    NUM_BUILDS = 10
    builds = Waterfall.getLastNBuildsForBuilder(NUM_BUILDS, bot.waterfall_name,
            bot.bot_name)

    for i in range(NUM_BUILDS):
      current_build_name = '-%d' % (i + 1)
      current_build = builds[current_build_name]

      if 'results' in current_build and current_build['results'] is not None:
        if bot.bot_data is not None:
          bot.bot_data['most_recent_build'] = current_build

        return current_build

    return None

  @staticmethod
  def getFailedBots(bots):
    failed_bots = []

    for waterfall_name in bots:
      waterfall = bots[waterfall_name]

      for bot_name in waterfall:
        bot = waterfall[bot_name]
        gpu_bot = GpuBot(waterfall_name, bot_name, bot)
        gpu_bot.bot_url = Waterfall.BASE_BUILD_URL % (waterfall_name,
                urllib.quote(bot_name))

        most_recent_build = Waterfall.getMostRecentlyCompletedBuildForBot(
                gpu_bot)

        if (most_recent_build and 'text' in most_recent_build and
                'failed' in most_recent_build['text']):
          gpu_bot.failure_string = ' '.join(most_recent_build['text'])
          gpu_bot.build_url = Waterfall.SPECIFIC_BUILD_URL % (waterfall_name,
                  urllib.quote(bot_name), most_recent_build['number'])
          failed_bots.append(gpu_bot)
        elif not most_recent_build:
          errorNoMostRecentBuild(waterfall_name, bot_name)

    return failed_bots

def formatTime(t):
  return time.strftime("%a, %d %b %Y %H:%M:%S", t)

def roughTimeDiffInHours(t1, t2):
  datetimes = []

  for t in [t1, t2]:
    datetimes.append(datetime.datetime(t.tm_year, t.tm_mon, t.tm_mday,
        t.tm_hour, t.tm_min, t.tm_sec))

  datetime_diff = datetimes[0] - datetimes[1]

  hours = float(datetime_diff.total_seconds()) / 3600.0

  return abs(hours)

def getBotStr(bot):
  s = '  %s::%s\n' % (bot.waterfall_name, bot.bot_name)

  if bot.failure_string is not None:
    s += '  failure: %s\n' % bot.failure_string

  if bot.getEndTime() is not None:
    s += ('  last build end time: %s (roughly %f hours ago)\n' %
    (formatTime(bot.getEndTime()), bot.getHoursSinceLastRun()))

  if bot.bot_url is not None:
    s += '  bot url: %s\n' % bot.bot_url

  if bot.build_url is not None:
    s += '  build url: %s\n' % bot.build_url

  s += '\n'
  return s

def getBotsStr(bots):
  s = ''

  for bot in bots:
    s += getBotStr(bot)

  s += '\n'
  return s

def getOfflineBotsStr(offline_bots):
  return 'Offline bots:\n%s' % getBotsStr(offline_bots)

def getFailedBotsStr(failed_bots):
  return 'Failed bots:\n%s' % getBotsStr(failed_bots)

def getBotDicts(bots):
  dicts = []

  for bot in bots:
    dicts.append(bot.toDict())

  return dicts

def unserializeTime(t):
  return time.struct_time((t['year'], t['mon'], t['day'], t['hour'], t['min'],
      t['sec'], 0, 0, 0))

def serialTime(t):
  return {'year': t.tm_year, 'mon': t.tm_mon, 'day': t.tm_mday,
          'hour': t.tm_hour, 'min': t.tm_min, 'sec': t.tm_sec}

def getSummary(offline_bots, failed_bots):
  offline_bot_dict = getBotDicts(offline_bots)
  failed_bot_dict = getBotDicts(failed_bots)
  return {'offline': offline_bot_dict, 'failed': failed_bot_dict}

def findBot(name, lst):
  for bot in lst:
    if bot.bot_name == name:
      return bot

  return None

def getNoteworthyEvents(offline_bots, failed_bots, previous_results):
  CRITICAL_NUM_HOURS = 1.0

  previous_offline = (previous_results['offline'] if 'offline'
          in previous_results else [])

  previous_failures = (previous_results['failed'] if 'failed'
          in previous_results else [])

  noteworthy_offline = []
  for bot in offline_bots:
    if bot.getHoursSinceLastRun() >= CRITICAL_NUM_HOURS:
      previous_bot = findBot(bot.bot_name, previous_offline)

      if (previous_bot is None or
              previous_bot.getHoursSinceLastRun() < CRITICAL_NUM_HOURS):
        noteworthy_offline.append(bot)

  noteworthy_new_failures = []
  for bot in failed_bots:
    previous_bot = findBot(bot.bot_name, previous_failures)

    if previous_bot is None:
      noteworthy_new_failures.append(bot)

  noteworthy_new_offline_recoveries = []
  for bot in previous_offline:
    if bot.getHoursSinceLastRun() < CRITICAL_NUM_HOURS:
      continue

    current_bot = findBot(bot.bot_name, offline_bots)
    if current_bot is None:
      noteworthy_new_offline_recoveries.append(bot)

  noteworthy_new_failure_recoveries = []
  for bot in previous_failures:
    current_bot = findBot(bot.bot_name, failed_bots)

    if current_bot is None:
      noteworthy_new_failure_recoveries.append(bot)

  return {'offline': noteworthy_offline, 'failed': noteworthy_new_failures,
          'recovered_failures': noteworthy_new_failure_recoveries,
          'recovered_offline': noteworthy_new_offline_recoveries}

def getNoteworthyStr(noteworthy_events):
  s = ''

  if noteworthy_events['offline']:
    s += 'IMPORTANT bots newly offline for over an hour:\n'

    for bot in noteworthy_events['offline']:
      s += getBotStr(bot)

    s += '\n'

  if noteworthy_events['failed']:
    s += 'IMPORTANT new failing bots:\n'

    for bot in noteworthy_events['failed']:
      s += getBotStr(bot)

    s += '\n'

  if noteworthy_events['recovered_offline']:
    s += 'IMPORTANT newly recovered previously offline bots:\n'

    for bot in noteworthy_events['recovered_offline']:
      s += getBotStr(bot)

    s += '\n'

  if noteworthy_events['recovered_failures']:
    s += 'IMPORTANT newly recovered failing bots:\n'

    for bot in noteworthy_events['recovered_failures']:
      s += getBotStr(bot)

    s += '\n'

  return s

def dictsToBots(bots):
  offline_bots = []
  for bot in bots['offline']:
    offline_bots.append(GpuBot.fromDict(bot))

  failed_bots = []
  for bot in bots['failed']:
    failed_bots.append(GpuBot.fromDict(bot))

  return {'offline': offline_bots, 'failed': failed_bots}

class GpuBotPoller:
  DEFAULT_PREVIOUS_RESULTS_FILE = '.check_gpu_bots_previous_results'

  def __init__(self, emailer, send_email_for_recovered_offline_bots,
          send_email_for_recovered_failing_bots, send_email_on_error,
          previous_results_file):
    self.emailer = emailer

    self.send_email_for_recovered_offline_bots = \
            send_email_for_recovered_offline_bots

    self.send_email_for_recovered_failing_bots = \
            send_email_for_recovered_failing_bots

    self.send_email_on_error = send_email_on_error
    self.previous_results_file = previous_results_file

  def shouldEmail(self, noteworthy_events):
    if noteworthy_events['offline'] or noteworthy_events['failed']:
      return True

    if (self.send_email_for_recovered_offline_bots and
            noteworthy_events['recovered_offline']):
      return True

    if (self.send_email_for_recovered_failing_bots and
          noteworthy_events['recovered_failures']):
      return True

    return False

  def writeResults(self, summary):
    results_file = (self.previous_results_file
            if self.previous_results_file is not None
            else GpuBotPoller.DEFAULT_PREVIOUS_RESULTS_FILE)

    with open(results_file, 'w') as f:
      f.write(json.dumps(summary))

  def getPreviousResults(self):
    previous_results_file = (self.previous_results_file
            if self.previous_results_file is not None
            else GpuBotPoller.DEFAULT_PREVIOUS_RESULTS_FILE)

    previous_results = {}
    if os.path.isfile(previous_results_file):
      with open(previous_results_file, 'r') as f:
        previous_results = dictsToBots(json.loads(f.read()))

    return previous_results

  def checkBots(self):
    time_str = 'Current time: %s\n\n' % (formatTime(time.localtime()))
    print time_str

    try:
      bots = Waterfall.getAllGpuBots()

      offline_bots = Waterfall.getOfflineBots(bots)
      offline_str = getOfflineBotsStr(offline_bots)
      print offline_str

      failed_bots = Waterfall.getFailedBots(bots)
      failed_str = getFailedBotsStr(failed_bots)
      print failed_str

      previous_results = self.getPreviousResults()
      noteworthy_events = getNoteworthyEvents(offline_bots, failed_bots,
              previous_results)

      noteworthy_str = getNoteworthyStr(noteworthy_events)
      print noteworthy_str

      summary = getSummary(offline_bots, failed_bots)
      self.writeResults(summary)

      if (self.emailer is not None and self.shouldEmail(noteworthy_events)):
        self.emailer.send_email(Emailer.format_email_body(time_str, offline_str,
            failed_str, noteworthy_str))
    except Exception as e:
      error_str = 'Error: %s' % str(e)
      print error_str

      if self.send_email_on_error:
        self.emailer.send_email(error_str)

def parseArgs(sys_args):
  parser = argparse.ArgumentParser(prog=sys_args[0],
          description='Query the Chromium GPU Bots Waterfall, output ' +
          'potential problems, and optionally repeat automatically and/or ' +
          'email notifications of results.')

  parser.add_argument('--repeat-delay', type=int, dest='repeat_delay',
          required=False,
          help='How often to automatically re-run the script, in minutes.')

  parser.add_argument('--email-from', type=str, dest='email_from',
          required=False,
          help='Email address to send from. Requires also specifying ' +
          '\'--email-to\'.')

  parser.add_argument('--email-to', type=str, dest='email_to', required=False,
          nargs='+',
          help='Email address(es) to send to. Requires also specifying ' +
          '\'--email-from\'')

  parser.add_argument('--send-email-for-recovered-offline-bots',
          dest='send_email_for_recovered_offline_bots', action='store_true',
          default=False,
          help='Send an email out when a bot which has been offline for more ' +
          'than 1 hour goes back online.')

  parser.add_argument('--send-email-for-recovered-failing-bots',
          dest='send_email_for_recovered_failing_bots',
          action='store_true', default=False,
          help='Send an email when a failing bot recovers.')

  parser.add_argument('--send-email-on-error',
          dest='send_email_on_error',
          action='store_true', default=False,
          help='Send an email when the script has an error. For example, if ' +
          'the server is unreachable.')

  parser.add_argument('--email-password-file',
          dest='email_password_file',
          required=False,
          help=(('File containing the plaintext password of the source email ' +
          'account. By default, \'%s\' will be tried. If it does not exist, ' +
          'you will be prompted. If you opt to store your password on disk ' +
          'in plaintext, use of a dummy account is strongly recommended.')
          % Emailer.DEFAULT_EMAIL_PASSWORD_FILE))

  parser.add_argument('--previous-results-file',
          dest='previous_results_file',
          required=False,
          help=(('File to store the results of the previous invocation of ' +
              'this script. By default, \'%s\' will be used.')
              % GpuBotPoller.DEFAULT_PREVIOUS_RESULTS_FILE))

  args = parser.parse_args(sys_args[1:])

  if args.email_from is not None and args.email_to is None:
    parser.error('--email-from requires --email-to.')
  elif args.email_to is not None and args.email_from is None:
    parser.error('--email-to requires --email-from.')
  elif args.email_from is None and args.send_email_for_recovered_offline_bots:
    parser.error('--send-email-for-recovered-offline-bots requires ' +
            '--email-to and --email-from.')
  elif (args.email_from is None and args.send_email_for_recovered_failing_bots):
    parser.error('--send-email-for-recovered-failing-bots ' +
            'requires --email-to and --email-from.')
  elif (args.email_from is None and args.send_email_on_error):
    parser.error('--send-email-on-error ' +
            'requires --email-to and --email-from.')
  elif (args.email_password_file and
          not os.path.isfile(args.email_password_file)):
    parser.error('File does not exist: %s' % args.email_password_file)

  return args

def main(sys_args):
  args = parseArgs(sys_args)

  emailer = None
  if args.email_from is not None and args.email_to is not None:
    emailer = Emailer(args.email_from, args.email_to, args.email_password_file)

    try:
      emailer.testEmailLogin()
    except Exception as e:
      print 'Error logging into email account: %s' % str(e)
      return 1

  poller = GpuBotPoller(emailer,
          args.send_email_for_recovered_offline_bots,
          args.send_email_for_recovered_failing_bots,
          args.send_email_on_error,
          args.previous_results_file)

  while True:
    poller.checkBots()

    if args.repeat_delay is None:
      break

    print 'Will run again in %d minutes...\n' % args.repeat_delay
    time.sleep(args.repeat_delay * 60)

  return 0

if __name__ == '__main__':
  sys.exit(main(sys.argv))
