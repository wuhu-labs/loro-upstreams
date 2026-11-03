# wuhu-rust-ffi 1.17.1-50.0.1-1

Loro's Swift FFI and Wasmtime's C API in one static library, so one binary links both with one Rust std (two Rust staticlibs each define `rust_eh_personality`, and GNU ld, gold, lld and ld64 all refuse the pair).

- Loro: crate `loro-ffi` 1.17.1 and `uniffi` 0.31.1, the dependencies of `loro-swift/` at `https://github.com/loro-dev/loro-swift` tag `1.17.1` (source sha `e222b3e1124e9e7e58e5e99658a3de75fcb0ec38` per its `release-artifact.json`). `src/lib.rs` repeats that crate's one-line lib.rs.
- Wasmtime: crate `wasmtime-c-api-impl` 50.0.1, re-exported as upstream's `crates/c-api/artifact` does, with the features upstream's C API release enables (`cmake/features.cmake` defaults: all but `disable-logging` and `all-arch`), so `include/wasmtime/conf.h` matches upstream's.
- `Cargo.lock` started as loro-swift 1.17.1's `loro-swift/Cargo.lock`; adding Wasmtime raised only the shared crates whose locked version fell below Wasmtime's requirement: anstyle, anyhow, arbitrary, bitflags, bumpalo, bytes, cobs, derive_arbitrary, libc, linux-raw-sys, log, postcard, proc-macro2, quote, regex, regex-automata, regex-syntax, rustix, semver, serde_spanned, toml_parser, toml_writer and unicode-ident. Built with `--locked`.
- Profile: upstream's release one (`ci/build-release-artifacts.sh`: fat LTO, debuginfo stripped, build scripts at opt-level 0) except panic, which stays `unwind`: uniffi turns a Loro panic into a Swift error by catching it.
- `lib/libwuhu_rust_ffi.a`: the staticlib, debug info stripped.
- `include/`: Wasmtime's installed header tree, generated `wasmtime/conf.h` included, plus `loroFFI.h` from `uniffi-bindgen generate --library` on this library.
- `LICENSE-loro` (MIT), `LICENSE-wasmtime` (Apache-2.0 WITH LLVM-exception).
- `recipe/`: `build.sh` and the crate it builds. `build.sh` fails unless `loroFFI.h` is byte-identical to the xcframework's, `include/` to upstream Wasmtime's for the same platform, and every C API symbol of both upstream libraries is defined here.
