# Metrics Center

Metrics center is a minimal set of code and services to support multiple perf
metrics generators (e.g., Cocoon device lab, Cirrus bots, LUCI bots, Firebase
Test Lab) and destinations (e.g., old Cocoon perf dashboard, Skia perf
dashboard). The work and maintenance it requires is very close to that of just
supporting a single generator and destination (e.g., engine bots to Skia perf),
and the small amount of extra work is designed to make it easy to support more
generators and destinations in the future.
