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

# Build the Amazon Machine Image (a raw disk plus image-info.json)
ami:
    nix build --no-link --print-out-paths .#ami

# Upload the AMI disk to EBS and register it as an AMI (needs AWS credentials and AWS_REGION)
ami-register name=("shortener-" + datetime("%Y%m%d-%H%M")):
    #!/usr/bin/env bash
    set -euo pipefail
    info="$(nix build --no-link --print-out-paths .#ami)/nix-support/image-info.json"
    file=$(jq -r .file "$info")
    boot_mode=$(jq -r .boot_mode "$info")
    size_gib=$(jq -r '(.logical_bytes | tonumber) / 1073741824 | ceil' "$info")
    case "$(jq -r .system "$info")" in
      x86_64-linux)  arch=x86_64 ;;
      aarch64-linux) arch=arm64 ;;
      *) echo "unsupported system" >&2; exit 1 ;;
    esac

    echo "uploading $file to an EBS snapshot..." >&2
    snapshot=$(coldsnap upload --wait --omit-zero-blocks --description "{{name}}" "$file")
    echo "snapshot: $snapshot" >&2

    aws ec2 register-image \
        --name "{{name}}" \
        --architecture "$arch" \
        --boot-mode "$boot_mode" \
        --virtualization-type hvm \
        --ena-support \
        --sriov-net-support simple \
        --imds-support v2.0 \
        --root-device-name /dev/xvda \
        --block-device-mappings "DeviceName=/dev/xvda,Ebs={SnapshotId=$snapshot,VolumeSize=$size_gib,VolumeType=gp3,DeleteOnTermination=true}" \
        --query ImageId --output text

# Present the README as a slideshow
present:
    presenterm -x README.md

# Remove local service data
clean:
    rm -rf .data
