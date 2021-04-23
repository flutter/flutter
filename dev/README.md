This directory contains tools and resources that the Flutter team uses
during the development of the framework. The tools in this directory
should not be necessary for developing Flutter applications, though of
course, they may be interesting if you are curious.

The tests in this directory are run in the `framework_tests_misc-*`
shards.

## Luci builder file
`try_builders.json` and `prod_builders.json` contain the supported luci
try/prod builders for flutter.
### `try_builders.json`
It follows format:
```json
{
    "builders":[
        {
            "name":"yyy",
            "repo":"flutter",
            "task_name":"zzz",
            "enabled":true,
            "run_if":["a/b/", "c/d/**"]
        }
    ]
}
```
* enabled(optional): `true` is the default value if unspecified
* run_if(optional): will always be triggered if unspecified
### `prod_builders.json`
It follows format:
```json
{
    "builders":[
        {
            "name":"yyy",
            "repo":"flutter",
            "task_name":"zzz",
            "flaky":false
        }
    ]
}
```
* name: (str), builder name
* repo: (str), name of the repository that this task runs against
* task_name: (str), task name that will appear in the flutter build dashboard
* flaky: (bool), if true, failure of this task will not close the tree

`try_builders.json` will be mainly used in
[`flutter/cocoon`](https://github.com/flutter/cocoon) to trigger/update pre-submit
flutter luci tasks, whereas `prod_builders.json` will be mainly used in `flutter/cocoon`
to refresh luci task statuses to [dashboard](https://flutter-dashboard.appspot.com).
