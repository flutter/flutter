// This crate's dependencies (android_logger, winit's android-game-activity
// feature, flutter-shell-winit) are declared `cfg(target_os = "android")` in
// Cargo.toml, so host builds (e.g. `cargo test --workspace` on Linux) never
// pull them in; gate the crate body the same way so those builds see an
// empty crate instead of unresolved-import errors.
#![cfg(target_os = "android")]

//! Android GameActivity entry point.
//!
//! Milestone 1 (see `flutter-rs-proggress.md`) proved the native
//! entry-point seam with a standalone winit/wgpu clear-color loop. This is
//! milestone 2: `android_main` now hands off to the same
//! `flutter-shell-winit::run_application` entry point Linux's `cpp/main.cc`
//! uses, dynamically linked against a GN-built `libflutter_rust_engine.so`
//! (see `build.rs`), so a real Dart isolate boots and Impeller renders a
//! real Flutter frame.
//!
//! Asset loading is still a placeholder: Android normally reads
//! `flutter_assets/` through `AAssetManager` and embeds `icudtl.dat` as a
//! linked symbol (see `cpp/rust_shell_icudtl_asm` in `BUILD.gn`), not plain
//! filesystem paths. This milestone instead expects `flutter_assets/` to
//! already exist under the app's files directory (adb-pushed ahead of
//! launch) and points `ShellConfig` at it directly, matching how Linux
//! already works. Real `AAssetManager`-backed loading is a later milestone.
//!
//! Milestone 3 adds release/AOT support: `cfg!(debug_assertions)` reflects
//! the cdylib's own Cargo profile (`build_rust.py` now passes `--release`
//! when GN's `FLUTTER_RUNTIME_MODE=release`, matching how
//! `runner-rs/src/main.rs.tmpl` picks its engine profile on Linux). In
//! release, `app.so` is expected next to `flutter_assets/` in the same
//! adb-pushed files directory.

use winit::platform::android::activity::AndroidApp;

#[unsafe(no_mangle)]
fn android_main(app: AndroidApp) {
    android_logger::init_once(
        android_logger::Config::default()
            .with_max_level(log::LevelFilter::Info)
            .with_tag("flutter_shell_android_runner"),
    );
    std::panic::set_hook(Box::new(|info| {
        log::error!("flutter-shell-android-runner panicked: {info}");
    }));

    // The app's private files directory, matching Context.getFilesDir() for
    // applicationId "dev.flutter.rustshell" (see android_shell_app's
    // AndroidManifest.xml). `adb push` a debug flutter_assets/ + icudtl.dat
    // here before launch; see flutter-rs-proggress.md milestone 2 for why
    // this is a placeholder rather than real APK asset loading.
    let files_dir = "/data/data/dev.flutter.rustshell/files";
    let aot_library_path = if cfg!(debug_assertions) {
        String::new()
    } else {
        format!("{files_dir}/app.so")
    };
    let config = flutter_shell_winit::ShellConfig {
        title: "Flutter Rust Shell (Android)".to_owned(),
        assets_path: format!("{files_dir}/flutter_assets"),
        icu_data_path: format!("{files_dir}/icudtl.dat"),
        aot_library_path,
        presentation_stats_path: None,
    };

    flutter_shell_winit::set_android_app(app);
    if let Err(error) = flutter_shell_winit::run_application(config, |_registrar| Ok(())) {
        log::error!("flutter-shell-android-runner: run_application failed: {error:?}");
    }
}
