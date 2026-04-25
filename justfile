repo_root    := justfile_directory() / ".."
abyssal_src  := repo_root / "multiplayer-fabric-abyssal"
godot_src    := repo_root / "multiplayer-fabric-godot"
zone_console := repo_root / "multiplayer-fabric-zone-console"
docker_src   := repo_root / "docker-multiplayer-fabric"
baker_dir    := repo_root / "multiplayer-fabric-baker" / "docker" / "build-project"
cache_dir    := env_var_or_default("HOME", "/root") / ".cache" / "zone-fabric-buildkit"

git_url_docker := "https://github.com/V-Sekai-fire/docker-multiplayer-fabric.git"
git_url_vsekai := "https://github.com/V-Sekai-fire/multiplayer-fabric-abyssal.git"

zone_tag  := "zone-fabric:local"
baker_tag := "multiplayer-fabric-baker:local"

# Build the zone-fabric Docker image from local Godot source
zone-fabric-image:
    docker buildx build \
      --build-context godot-src={{godot_src}} \
      --build-context zone-console-src={{zone_console}} \
      --file {{docker_src}}/Dockerfile.zone-fabric-build \
      --cache-from type=local,src={{cache_dir}} \
      --cache-to   type=local,dest={{cache_dir}},mode=max \
      --tag {{zone_tag}} \
      --load \
      {{docker_src}}

# Build the baker Docker image from local Godot source
baker-image:
    docker buildx build \
      --build-context godot-src={{godot_src}} \
      --file {{docker_src}}/Dockerfile.baker \
      --cache-from type=local,src={{cache_dir}} \
      --cache-to   type=local,dest={{cache_dir}},mode=max \
      --tag {{baker_tag}} \
      --load \
      {{baker_dir}}

godot_bin_default := repo_root / "multiplayer-fabric-godot" / "bin" / "godot.macos.editor.dev.arm64"

# Run Phase 1 GO headless observer test against local zone server (needs zone-up first)
go-test godot_bin=godot_bin_default:
    #!/usr/bin/env bash
    set -euo pipefail
    {{godot_bin}} --headless \
      --path {{abyssal_src}} \
      --script scripts/headless_log_observer.gd \
      -- --host=127.0.0.1 --port=7443 \
         --dump-json=/tmp/go_entities.json --frames=600
    count=$(python3 -c "import json; print(len(json.load(open('/tmp/go_entities.json'))))")
    echo "GO: $count entities"
    [ "$count" -gt 0 ]

# Build zone-fabric image then start the full stack
zone-up: zone-fabric-image
    ZONE_SERVER_IMAGE={{zone_tag}} docker compose up -d

# Stop the stack
zone-down:
    docker compose down
