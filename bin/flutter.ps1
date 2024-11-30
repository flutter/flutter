$flutter_tool_args=""
# $flutter_tool_args = "--enable-asserts $flutter_tool_args"

$flutter_root = "$PSScriptRoot/../"

$mingit_path = "$flutter_root/bin/mingit/cmd"

if(Test-Path $mingit_path)
{
	$Env:PATH+=";$mingit_path"
}

$shared_bin = "$flutter_root/bin/internal/shared.ps1"

& $shared_bin

$flutter_tools_dir = "$flutter_root/packages/flutter_tools"
$cache_dir = "$flutter_root/bin/cache"
$snapshot_path="$cache_dir/flutter_tools.snapshot"
$dart_sdk_path="$cache_dir/dart_sdk"
$dart = "$dart_sdk_path/bin/dart.exe"

$exit_with_errorlevel="$flutter_root/bin/internal/exit_with_errorlevel.ps1"

& $dart --packages="$flutter_tools_dir/.dart_tool/package_config.json" $flutter_tool_args $snapshot_path $args && &$exit_with_errorlevel
