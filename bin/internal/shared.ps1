$flutter_root = "$PSScriptRoot/../../"
$flutter_tools_dir="$flutter_root/packages/flutter_tools"
$cache_dir="$flutter_root/bin/cache"
$snapshot_path="$cache_dir/flutter_tools.snapshot"
$snapshot_path_old="$cache_dir/flutter_tools.snapshot.old"
$stamp_path="$cache_dir/flutter_tools.stamp"
$script_path="$flutter_tools_dir/bin/flutter_tools.dart"
$dart_sdk_path="$cache_dir/dart-sdk"
$engine_stamp="$cache_dir/engine-dart-sdk.stamp"
$engine_version_path="$flutter_root/bin/internal/engine.version"
$dart="$dart_sdk_path/bin/dart.exe"

if(!(Test-Path $cache_dir))
{
    New-Item -ItemType Directory -Path $cache_dir
}

function do_snapshot
{
    if(Test-Path "$flutter_root/version")
    {
        Remove-Item "$flutter_root/version"
    }
    $json="$flutter_root/bin/cache/flutter.version.json"
    if(Test-Path $json)
    {
        Remove-Item $json
    }
    "" > "$cache_dir/.dartignore"

    "Building flutter tool..."

    Push-Location $flutter_tools_dir

    function on_bot
    {
        $pub_environment += ":flutter_bot"
    }
    if($CI -eq "true")
    {
        on_bot
    }
    if($Bot -eq "true")
    {
        on_bot
    }
    if($Continuous_Integration -eq "true")
    {
        on_bot
    }
    if($Chrome_headless -eq "1")
    {
        on_bot
    }


    $pub_summary_only = 1
    $pub_environment+=":flutter_install"
    if($pub_cache -eq "")
    {
        if(Test-Path $pub_cache_path)
        {
            $pub_cache=$pub_cache_path
        }
    }

    $total_tries=10

    & $dart pub upgrade --supress-analytics

    $snapshot_path_suffix=1
    function move_old_snapshot
    {
        if(Test-Path "$snapshot_path_old$snapshot_path_suffix")
        {
            $snapshot_path_suffix +=1
            move_old_snapshot
        } else
        {
            if(Test-Path "$snapshot_path")
            {
                Move-Item $snapshot_path "$snapshot_path_old$snapshot_path_suffix"
            }
        }
    }
    move_old_snapshot

    $dart_args = "--snapshot=$snapshot_path --snapshot-kind=""app-jit"" --packages=""$flutter_tools_dir/.dart_tool/package_config.json"" --no-enable-mirrors $script_path"
    if($flutter_tool_args =="" )
    {
        & $dart --verbosity=error $dart_args
    } else
    {
        & $dart $flutter_tool_args $dart_args
    }

    $compile_key > $stamp_path

    Remove-Item "$snapshot_path.old*"
}

function do_sdk_update_and_snapshot
{
    & "$PSScriptRoot/update_dart_sdk.ps1"
    do_snapshot
}

function subroutine
{
    $bootstrap_path="$flutter_root/bin/internal/bootstrap.ps1"
    if(Test-Path $bootstrap_path)
    {
        & $bootstrap_path
    }
    Push-Location $flutter_root
    $revision=(git rev-parse HEAD)
    Pop-Location

    $compilekey="$revision\:$flutter_tool_args"

    if(!(Test-Path $engine_stamp))
    {
        do_sdk_update_and_snapshot
    }

    $dart_required_version=Get-Content $engine_version_path
    $dart_installed_version= Get-Content $engine_stamp
    if($dart_required_version -ne $dart_installed_version)
    {
        do_sdk_update_and_snapshot
    }
    if(!(Test-Path $snapshot_path))
    {
        do_snapshot
    }
    if(!(Test-Path $stamp_path))
    {
        do_snapshot
    }
    $stamp_value=Get-Content $stamp_path

    if($stamp_value -ne $compilekey)
    {
        do_snapshot
    }

    $pubspec_yaml_path="$flutter_tools_dir/pubspec.yaml"
    $pubspec_lock_path="$flutter_tools_dir/pubspec.lock"

    if((Get-Item $pubspec_yaml_path).LastWriteTime -gt (Get-Item $pubspec_lock_path).LastWriteTime )
    {
        do_snapshot
    }
}

