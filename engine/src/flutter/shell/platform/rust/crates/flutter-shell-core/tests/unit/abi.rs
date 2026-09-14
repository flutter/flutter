use super::*;

#[test]
fn exports_the_expected_abi_versions() {
    assert_eq!(
        FlutterRustShellGetAbi(),
        FlutterRustShellAbi {
            shell_abi_version: SHELL_ABI_VERSION,
            plugin_sdk_api_version: PLUGIN_SDK_API_VERSION,
        }
    );
}
