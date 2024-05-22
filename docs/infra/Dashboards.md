The index of Flutter dashboards is available at: https://flutter-dashboard.appspot.com/

## Using the Skia Performance dashboard

There are two, one for [benchmarks derived from running flutter/flutter tests](https://flutter-flutter-perf.skia.org/e/), and one [derived from flutter/engine tests](https://flutter-engine-perf.skia.org/e/).

### Viewing results for a specific benchmark

Each data set (results from a benchmark value) consists of date/value pairs associated with a set of parameters. These parameters include things like the branch that was being tested, the benchmark test name ("test"), and the specific value ("sub_result"). There are other parameters but they aren't important (see below).

1. Click Query.
2. A dialog shows, with a "Filter" text field focused. Type into that field the parts of the benchmark name you want to see that you remember.
3. Click "test" in the list box. This causes a second list box to appear.
4. Select the specific test from the list box that you care about.
5. Refocus the "Filter" text field, and type the name of the specific data point (the sub_result name) you care about.
6. Click "sub_result" in the list box.
7. Select the specific sub_result that you care about.
8. Click "Time Range", then "Date Range".
9. Click the calendar icon next to the "Begin" text field. (Don't just type in a new date, because https://bugs.chromium.org/p/skia/issues/detail?id=11279.)
10. Select the start date you care about.
11. Click "Plot".

You can navigate the X axis of the graph using WASD.


### Parameters

The parameters for a data set are as follows:

sub_result: the specific data stream provided by the test. Tests can provide multiple data points, in a JSON map; each key in that map becomes a sub_result in the Skia Perf system.

branch: the branch that was being tested.

config: always "default".

originId: always "devicelab" except for data that was migrated from the old database, which are labeled "legacy-flutter".

test: the name of the test that ran to collect the data.

unit: in theory, the units in which the data was collected (so each sub_result should only ever be associated with one unit). In practice this parameter is often incorrect.