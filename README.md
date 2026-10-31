# loro-upstreams

Prebuilt [Loro](https://github.com/loro-dev/loro) FFI libraries for platforms that [loro-swift](https://github.com/loro-dev/loro-swift)'s own release does not cover. Each release is one archive built from an exact upstream tag with the recipe in this repository; its `PROVENANCE.md` records the upstream tag, lockfile hash and toolchain.

- `linux/`: `libloro_swift.a` + `loroFFI.h` for `x86_64-unknown-linux-gnu`, to compile loro-swift's unmodified `Sources/Loro` on Linux. Releases `<loro-swift tag>-linux.<n>`.

Loro is MIT licensed (`LICENSE-loro`); every archive carries the license.
