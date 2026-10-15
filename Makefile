# reloaded-terrain: Terrain3D (vendor/terrain3d, TokisanGames' v1.0.2-stable) patched for the worlds
# of MaSzyna Reloaded and built double precision - its release builds are single precision and do
# not load in the double precision engine - with the worlds' terrain streamer (addons/reloaded_terrain,
# WorldTerrainStreamer). Released as reloaded-terrain.zip (make dist, .github/workflows/release.yml),
# addons/terrain_3d and addons/reloaded_terrain, which the game, the scenery importer, the world
# assets and the worlds unzip into their own addons/ - nobody else builds Terrain3D.
#
# terrain3d-godot-cpp-10.patch adapts Terrain3D to the godot-cpp of the 4.7 API (GODOT_CPP_COMMIT);
# terrain3d-region-window.patch lets the region map's 32x32 window move (Terrain3DData.
# set_region_map_origin()) and makes the shaders - the addon's own extras too - work relative to it,
# so a world's regions can be streamed anywhere around the camera and stay precise hundreds of km
# from the origin. Each patch is applied only while it still applies, i.e. once.

TERRAIN3D:=vendor/terrain3d
TERRAIN3D_PATCHES:=terrain3d-godot-cpp-10.patch terrain3d-region-window.patch
# Terrain3D 1.0.2's own godot-cpp is too old for the 4.7 API: it is moved to libmaszyna's (its
# godot-cpp submodule's commit), bumped with it
GODOT_CPP_COMMIT:=507ed9d840c01a3c5b2a39af8bb4000bfac30bf5
# The engine whose API it is built against (libmaszyna's GODOT_VERSION): its double precision editor
# (GODOT; the CI takes it from libmaszyna's release godot-<version>-double) dumps the API
GODOT_VERSION:=4.7.2
GODOT?=godot-double
API:=$(CURDIR)/extension_api.json
# glibc is only forward compatible (libmaszyna's Makefile): the Linux libraries are built in
# libmaszyna's Linux SDK image - Godot's buildroot SDK, glibc 2.34 - so they start wherever the game
# does. Its tag is libmaszyna's (the start of its ci/docker/linux-sdk/Dockerfile's sha256), bumped
# with it
LINUX_SDK_IMAGE:=ghcr.io/maszyna-reloaded/linux-sdk:a3d8d7314879
LINUX_SDK_RUN=docker run --rm --user $(shell id -u):$(shell id -g) -v $(CURDIR):$(CURDIR) -w $(CURDIR) $(LINUX_SDK_IMAGE)
DIST_DIR:=dist
DIST:=$(DIST_DIR)/reloaded-terrain.zip

.PHONY: godot-version patches build build-windows dist

godot-version:
	@echo $(GODOT_VERSION)

$(API):
	$(GODOT) --headless --dump-extension-api

patches:
	cd $(TERRAIN3D) && for p in $(TERRAIN3D_PATCHES); do \
		git apply --check $(CURDIR)/patches/$$p 2>/dev/null && git apply $(CURDIR)/patches/$$p || true; \
	done

# the libraries of Linux (the editor's template_debug, the game's template_release), in LINUX_SDK_IMAGE
build: patches $(API)
	cd $(TERRAIN3D)/godot-cpp && git fetch -q origin $(GODOT_CPP_COMMIT) && git checkout -q $(GODOT_CPP_COMMIT)
	$(LINUX_SDK_RUN) sh -c 'cd $(TERRAIN3D) && for t in template_debug template_release; do \
		scons platform=linux target=$$t precision=double custom_api_file=$(API) -j$$(nproc) || exit 1; \
	done'

# the game's library of Windows, cross-compiled by MinGW (posix threads)
build-windows: patches $(API)
	cd $(TERRAIN3D)/godot-cpp && git fetch -q origin $(GODOT_CPP_COMMIT) && git checkout -q $(GODOT_CPP_COMMIT)
	cd $(TERRAIN3D) && scons platform=windows use_mingw=yes target=template_release precision=double \
		custom_api_file=$(API) -j$$(nproc)

# the patched addon with the libraries built and the streamer, as the projects unzip it
dist: patches
	mkdir -p $(DIST_DIR)/addons
	cp -rT $(TERRAIN3D)/project/addons/terrain_3d $(DIST_DIR)/addons/terrain_3d
	cp -rT addons/reloaded_terrain $(DIST_DIR)/addons/reloaded_terrain
	rm -f $(DIST)
	cd $(DIST_DIR) && zip -qr $(notdir $(DIST)) addons
