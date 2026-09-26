# List available recipes
default:
    @just --list

# Start postgres, redis, and the shortener via process-compose
dev:
    nix develop -c process-compose up

# Remove local service data
clean:
    rm -rf .data
