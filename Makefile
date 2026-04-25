GODOT_SRC       ?= $(realpath ../multiplayer-fabric-godot)
ZONE_CONSOLE_SRC ?= $(realpath ../multiplayer-fabric-zone-console)
DOCKERFILE      := $(GODOT_SRC)/.github/docker/Dockerfile.zone-fabric-build
DOCKERIGNORE    := $(GODOT_SRC)/.github/docker/.dockerignore-godot-src
CACHE_DIR       := /tmp/zone-fabric-buildkit-cache
TAG             := zone-fabric:local

.PHONY: zone-fabric-image baker-image zone-up zone-down

# Build the zone-fabric Docker image from local Godot source.
# Scons cache is preserved across builds via BuildKit cache mount.
zone-fabric-image:
	docker buildx build \
		--build-context godot-src=$(GODOT_SRC) \
		--build-context zone-console-src=$(ZONE_CONSOLE_SRC) \
		--file $(DOCKERFILE) \
		--cache-from type=local,src=$(CACHE_DIR) \
		--cache-to   type=local,dest=$(CACHE_DIR),mode=max \
		--tag $(TAG) \
		--load \
		.

# Start the full stack using the locally built image.
zone-up: zone-fabric-image
	ZONE_SERVER_IMAGE=$(TAG) docker compose up -d

baker-image:
	bash build-baker.sh

zone-down:
	docker compose down
