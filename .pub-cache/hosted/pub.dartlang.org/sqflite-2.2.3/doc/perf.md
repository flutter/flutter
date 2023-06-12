# Some perf experiment

Nexus 5, Android 6. 2019/02/26

## Background thread priority (new default)

```
TEST Running Perf 1000 insert
1000 insert 0:00:01.461457
TEST Done Perf 1000 insert
```

```
TEST Running Perf 10000 item
sw 0:00:03.638205 insert 10000 items batch 
sw 0:00:00.483061 SELECT * From Test : 10000 items
sw 0:00:00.521089 SELECT * FROM Test WHERE name LIKE %item% 10000 items
sw 0:00:00.011873 SELECT * FROM Test WHERE name LIKE %dummy% 0 items
```

## Normal thread priority

```
TEST Done Perf 10000 item
TEST Running Perf android NORMAL_PRIORITY
1000 insert 0:00:01.171613
```

```
sw 0:00:03.583681 insert 10000 items batch 
sw 0:00:00.408970 SELECT * From Test : 10000 items
sw 0:00:00.426629 SELECT * FROM Test WHERE name LIKE %item% 10000 items
sw 0:00:00.012783 SELECT * FROM Test WHERE name LIKE %dummy% 0 items
TEST Done Perf android NORMAL_PRIORITY 
```