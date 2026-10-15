# Requirements

What building reloaded-terrain - Terrain3D patched and double precision, and its release - needs.

## Linux binaries: glibc 2.34

Every Linux binary of MaSzyna Reloaded that is released - a library (`.so`), an engine template, an
executable - is built against **glibc 2.34**, in libmaszyna's Linux SDK image
`ghcr.io/maszyna-reloaded/linux-sdk` (libmaszyna's `ci/docker/linux-sdk`: Godot's own buildroot
SDK, whose sysroot carries glibc 2.34; the image is tagged by the start of its Dockerfile's sha256).
glibc is only forward compatible: a binary linked against a newer host's glibc refuses to start on
any older distribution (Ubuntu 22.04/24.04, Debian 12, Mint). A binary built on the host is for that
machine only, never released. Every repository building or going to build binaries keeps this rule.

`make build` builds the Linux libraries in that image (`LINUX_SDK_IMAGE`, Docker): the tag of the
Makefile is libmaszyna's, bumped with it.

## Engine

Godot 4.7.2, double precision (`godot-double`): libmaszyna's `GODOT_VERSION`, built once by
libmaszyna's CI and published as its release `godot-4.7.2-double` (editor and export templates),
which the other repositories fetch (libmaszyna's `ci/fetch-godot.sh`). Single precision builds -
Godot's own, Terrain3D's own - do not load.

`make build` dumps the engine's API from it (`extension_api.json`, `GODOT`); Terrain3D is built
against libmaszyna's godot-cpp (`GODOT_CPP_COMMIT`).

## Windows binaries

Cross-compiled on Linux by MinGW-w64 with posix threads (`x86_64-w64-mingw32-g++-posix`, set by
`update-alternatives` as the CI does).

`make build-windows` runs scons on the host with it.

## Tools

- `git` with submodules (`vendor/terrain3d`).
- Docker (the Linux libraries), scons (the Windows library), `zip` (`make dist`).
