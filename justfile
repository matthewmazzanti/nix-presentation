# Container runtime: docker if present, otherwise podman
container := `command -v docker >/dev/null 2>&1 && echo docker || echo podman`

# podman prefixes loaded images with "localhost/"; docker does not
image := if container == "podman" { "localhost/shortener:latest" } else { "shortener:latest" }

# List available recipes
default:
    @just --list

# Start postgres, redis, and the shortener via process-compose
dev:
    nix develop -c process-compose -f process-compose.yaml up

# Build the container image with nix and load it into the container runtime
image:
    {{container}} load < "$(nix build --no-link --print-out-paths .#image)"

# Run the container against the postgres/redis started by `just dev`
run-image: image
    {{container}} run --rm -p 8000:8000 \
        -e DATABASE_URL -e REDIS_URL -e PGUSER="$USER" \
        -v "$DATA_DIR:$DATA_DIR" \
        {{image}}

compose := "SHORTENER_IMAGE=" + image + " " + container + " compose"

# Build the image and bring up the full stack (shortener, postgres, redis) via compose
up: image
    {{compose}} up

# Tear down the compose stack and its volumes
down:
    {{compose}} down -v

# Run any other compose subcommand, e.g. `just compose logs -f shortener`
compose *args:
    {{compose}} {{args}}

# Build and boot a NixOS VM running postgres, redis, and the shortener
vm:
    mkdir -p .data
    NIX_DISK_IMAGE=.data/shortener.qcow2 nix run .#vm

# Present the README as a slideshow
present:
    presenterm -x README.md

# Remove local service data
clean:
    rm -rf .data
