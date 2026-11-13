#[cxx::bridge(namespace = "flutter::rust")]
mod ffi {
    extern "Rust" {
        fn rust_greeting(version: i32) -> String;
    }
}

pub fn rust_greeting(version: i32) -> String {
    format!("Flutter Rust FFI initialized (JNI v{version:#x})")
}
