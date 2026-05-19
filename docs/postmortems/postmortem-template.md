# Flutter postmortem: {Incident Title}

Status: {draft|final}<br>
Owners: {who drove the incident resolution}

## Summary

Description: {brief description of symptoms and root cause}<br>
Component: {affected area}<br>
Date/time: {YYYY-MM-DD HH:MM}<br>
Duration: {time from initial breakage to final resolution}<br>
User impact: {who was affected by the incident}

## Timeline (all times in PST/PDT)

### 1900-01-01

14:44 - something happened<br>
14:45 - next thing happened **&lt;START OF OUTAGE&gt;**

### 1900-01-02

09:12 - another thing happened **&lt;END OF OUTAGE&gt;**

## Impact

{summarize the problems that the outage caused}

## Root causes

{without blame, describe the root cause of the outage}

## Lessons learned

### What worked

{list things where things worked as expected in a positive manner}

### Where we got lucky

{list things that mitigated this incident but not because of our foresight}

### What didn't work

{list things that failed, with github issues from the action items section}

## Action items

{each item here should have an owner}

### Prevention

{link to github issues for things that would have prevented this failure from happening in the first place, such as input validation, pinning dependencies, etc}

### Detection

{link to github issues for things that would have detected this failure before it became An Incident, such as better testing, monitoring, etc}

### Mitigation

{link to github issues for things that would have made this failure less serious, such as graceful degradation, better exception handling, etc}

### Process

{link to github issues for things that would have helped us resolve this failure faster, such as documented processes and protocols, etc}

### Fixes

{link to github issues or PRs/commits for the actual fixes that were necessary to resolve this incident}

## Appendix

{any other useful information, such as relevant chat logs}