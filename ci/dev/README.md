This directory contains resources that the Flutter team uses during 
the development of engine.

## Luci builder file
`engine_try_builders.json` and `engine_prod_builders.json` contains the 
supported luci try/prod builders for engine. It follows format:
```json
{
    "builders":[
        {
            "name":"xxx",
            "repo":"engine"
        },
        {
            "name":"yyy",
            "repo":"engine"
        }
    ]
}
```
This file will be mainly used in [`flutter/cocoon`](https://github.com/flutter/cocoon)
to trigger/update engine luci tasks.

If any new changes, please validate json contents by running
```
dart validate_json.dart engine_try_builders.json
dart validate_json.dart engine_prod_builders.json
```
