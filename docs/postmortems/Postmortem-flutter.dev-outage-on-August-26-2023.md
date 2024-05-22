Status: final<br>
Owners: @Hixie

## Summary

Description: flutter.dev was offline for 80% of users for a period of several hours.<br>
Component: www.flutter.dev web site<br>
Date/time: 2023-08-26 21:14 PDT<br>
Duration: 15 hours 40 minutes<br>
User impact: Potential new users, anyone trying to visit flutter.dev

## Timeline (all times in PST/PDT)

At some point in 2023, a change in Google Groups caused the flutter.dev security@, conduct@, and press@ aliases to stop working. This issue was temporarily worked around by changing public documentation to give Hixie's personal e-mail address. The task of determining a more permanent solution was considered low priority.

### 2023-08-25

15:27 - Hixie and tvolkert submit a change to the DNS configuration to change the MX records in order to enable Google Workspace Google groups on the flutter.dev domain, enabling security@, conduct@, and press@ aliases to be reactivated, unaware that an error in the new configuration would add four A records and four AAAA records for flutter.dev providing incorrect IP addresses. (Internal ID 560528920.)<br>
21:14 - DNS configuration changes take effect. 80% of IPs served for flutter.dev fail to serve correctly. **&lt;START OF OUTAGE&gt;**<br>
21:20 - Monitoring system sends first e-mail, incorrectly reporting docs.flutter.dev is down.<br>
21:27 - Monitoring system sends second e-mail, reporting flutter.dev is down.<br>
21:42 - A user tweets concern: https://twitter.com/macoshita/status/1695295520351359040?s=20<br>
23:54 - The first dubious security vulnerability ("the javascript on your website is accessible") since the MX record update is received at security@flutter.dev.

### 2023-08-26

04:24 - @Abitofevrything on Discord pings @Hixie to inform them of the outage.<br>
04:27 - @Hixie sees and acknowledges the message.<br>
05:07 - jonasfj and Hixie submit a fix to the DNS configuration.<br>
10:07 - Another user tweets concern: https://twitter.com/its_me_mahmud/status/1695483187936555397?s=20 (in the brief resulting thread, another user confirms the outage, while the original poster expresses confusion that the site works on some machines but not others)<br>
12:55 - DNS configuration changes take effect. **&lt;END OF OUTAGE&gt;**

## Data
From monitoring data (highlighted line is the moving average of successful pings):
![](https://github.com/flutter/flutter/assets/551196/6fde84d6-922a-4536-8cd4-d5d5933078f5)

From analytics (the outage is visible at the bottom right):
![](https://github.com/flutter/flutter/assets/551196/cbbb6cde-9b65-45ec-9bd1-8adb169469e3)

## Impact

Four fifths of users were unable to learn about Flutter from flutter.dev during the outage. Traffic numbers recovered immediately when the DNS issue was fixed.

The outage seems to have slightly reduced traffic to docs.flutter.dev.

We don't have long-term impact data yet.

## Root causes

The DNS configuration change introduced an import of a configuration file for Google Workspace domains that itself imported two files: one to add MX records, and one to add IP addresses for web hosting. However, since flutter.dev is not hosted using Google Workspace, the additional IP addresses for web hosting returned error pages.

## Lessons learned

### What worked

The DNS server did exactly what it was told to do.

Our team has improved work-life balance significantly in the past year.

The MX record change worked as intended.

### Where we got lucky

Hixie checked his messages just prior to going to sleep, and once aware of the problem, was able to find a solution in a few minutes. Also, Hixie's questionable sleep habits meant he was awake at the time of the message.

The outage happened during one of our off-peak days.

### What didn't work

Monitoring detected the issue but one e-mailed one person, who was not working at the time. The issue went undetected by humans for seven hours and ten minutes.

It took about 25 minutes for Hixie to find someone to review the PR, because everyone was either sleeping or enjoying their weekend.

The DNS changes took hours to take effect.

## Follow-up

The monitoring system should notify more people. Ideally, it would ping Discord directly. Ideally it would not be limited to Googlers. (filed https://github.com/flutter/flutter/issues/133509)

The monitoring system for docs.flutter.dev is incorrectly configured to check docs.flutter.io, which redirects to flutter.dev. (fixed by adding a separate monitoring entry for docs.flutter.dev and api.flutter.dev)

It would be useful to have a channel for getting hold of team members in a hurry. (added an @emergency role on Discord which has notifications enabled)

The current setup requires a Google employee Flutter team member to approve DNS changes. We should expand this to Dart team members as well since that would increase the number of people in different time zones. (added Dart team members to the OWNERS file)

We could have a policy of not landing DNS changes on a Friday, since that would reduce the difficulty in getting hold of someone. On the other hand, the outage happening on a weekend greatly diminished the impact. These factors may cancel each other out.