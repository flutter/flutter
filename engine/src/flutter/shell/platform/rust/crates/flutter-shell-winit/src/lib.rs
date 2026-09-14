//! Winit-owned native host for the optional Flutter Rust shell.
//!
//! The implementation is kept in focused modules under `src/`; this file is
//! the public crate boundary used by the C++ bridge and generated runners.

mod shell;

pub use shell::{
    FlutterRustShellRun, RunError, ScheduledTask, ShellConfig, TaskQueue, run, run_application,
};

#[cfg(target_os = "android")]
pub use shell::set_android_app;
