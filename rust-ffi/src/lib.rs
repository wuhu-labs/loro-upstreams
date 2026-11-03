//! loro-swift's FFI crate (its lib.rs, verbatim) and Wasmtime's C API artifact
//! crate (crates/c-api/artifact), in one staticlib with one Rust std.
loro_ffi::uniffi_reexport_scaffolding!();
pub use wasmtime_c_api::*;
