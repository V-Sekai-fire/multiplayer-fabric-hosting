GODOT_SRC        ?= $(realpath ../multiplayer-fabric-godot)
ZONE_CONSOLE_SRC ?= $(realpath ../multiplayer-fabric-zone-console)
DOCKER_SRC       ?= $(realpath ../docker-multiplayer-fabric)
DOCKERFILE       := $(DOCKER_SRC)/Dockerfile.zone-fabric-build
CACHE_DIR        := /tmp/zone-fabric-buildkit-cache
TAG              := zone-fabric:local

export GIT_URL_DOCKER  := https://github.com/V-Sekai-fire/docker-multiplayer-fabric.git
export GIT_URL_VSEKAI  := https://github.com/V-Sekai/v-sekai-game.git

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
		$(DOCKER_SRC)

# Start the full stack using the locally built image.
zone-up: zone-fabric-image
	ZONE_SERVER_IMAGE=$(TAG) docker compose up -d

baker-image:
	bash build-baker.sh

zone-down:
	docker compose down
