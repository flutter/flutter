Flutter reports data to two separate systems:

1. Anonymous usage statistics are reported to Google Analytics (for statistics
   such as the number of times the `flutter` tool was run within a given time
   period).
1. Crash reports for the `flutter` tool. These are not reports of when Flutter
   applications crash, but rather when the command-line `flutter` tool itself
   crashes. The code that manages this is in [crash_reporting.dart].

## Opting out

Users can opt out of all reporting in a single place by running
`flutter config --no-analytics`.
