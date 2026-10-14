---
title: The Case for Nix
sub_title: ""
author: Nikita Wootten & Matthew Mazzanti
options:
  end_slide_shorthand: true
  h1_slide_titles: true
---

# Overview

- Quick tour of the hits of nix
- Repo available if you want to go deeper: https://github.com/nikitawootten/the-case-for-nix/

---

# Introducing our subject: a link simple link shortener

<!-- speaker_note: ensure `just dev` is running for the below curl commands to resolve -->

Simple web service with a connected database

- API surface:

```bash +exec
/// set -euo pipefail
# Create short link
code=$(curl -fsS http://127.0.0.1:8000/links \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://nixos.org"}' | jq -er .code)
echo "Short link: http://127.0.0.1:8000/$code"
# Follow short link
curl -fsS -D - -o /dev/null "http://127.0.0.1:8000/$code" | grep Location
# Get short link hit count
curl -fsS "http://127.0.0.1:8000/$code/stats"
```

- Writes to a Postgres database, uses Redis for a cache
- Shell wrapper

---

# Super simple application, what's the catch?

There are so many opportunities for things to go wrong.

- Onboarding new devs
- Building and deploying the application

---

# Shell scripts suck

- What runtime environment are you on?
- What version of `sed`, `curl` and other runtime dependencies do you have?

<!-- speaker_note: GNU vs BSD `sed` a good example here -->

- Do it wrong and your script is broken on a PDP 11 and a nerd on the internet yells at you

---

# Developer environments suck

- Every developer environment is mostly cruft; subtle differences add up
- Always a huge runbook of commands nobody understands to get the environment set up
- Then it breaks when someone adds something weird and you debug for 4 hours before formatting their disk

---

# Packaging and deployment sucks

- Docker's approach: Just ship the dev laptop
- Isn't "reproducible", ie can run more later at a later time
- Same build at different points in time produces different outputs

---

# Introducing Nix

<!-- column_layout: [2, 1] -->

<!-- column: 0 -->
![](assets/holy-trinity.jpg)

[Image Source: Andreas Fuchs](https://boinkor.net/2024/04/what-nix-will-have-been/)

<!-- column: 1 -->
Nix is:
- A package manager
- A language
- An operating system
- A bit of a mess

---

# Packaging the shell script

<!-- speaker_note: Nix is a functional language vaguely resembling JSON with functions, derivations are a core language feature -->

```nix
{ writeShellApplication, curl, jq }:
writeShellApplication {
  name = "shortctl";
  runtimeInputs = [ curl jq ];
  text = builtins.readFile ./shortctl.sh;
}
```

Evaluating this expression produces a "derivation" (package):

```bash +exec
nix build .#shortctl
nix eval .#shortctl --raw
```

<!-- speaker_note: show the structure mirroring the root FS with the script in a bin folder -->

---

# Dev environments

- Run ephemeral commands with nix run/shell. Doesn't clog up your system over time
- Prepare a full dev environment for your team ahead of time, stays in sync through git & updates
- Combine with tools like Direnv

```nix
{ mkShell, go, gopls, postgresql, redis, process-compose, jq, just, presenterm }:
mkShell {
  packages = [ go gopls postgresql redis process-compose jq just presenterm ];
  shellHook = ''
    export DATA_DIR=$PWD/.data
    export PGDATA=$DATA_DIR/postgres
    export PGHOST=$DATA_DIR
    export REDIS_SOCKET=$DATA_DIR/redis.sock
    export DATABASE_URL="postgresql:///postgres?host=$PGHOST"
    export REDIS_URL="unix://$REDIS_SOCKET"
  '';
}
```

```bash +exec
nix build .#devShells.x86_64-linux.default
nix eval .#devShells.x86_64-linux.default --raw
```

---

# Packaging the backend

- Similar to the shell script
- Uses "nixpkgs" builder for go
- Compiles the software

```bash +exec
nix build .#shortener
nix eval .#shortener --raw
```

---

# Deploying the backend (Docker)

- Nix provides an OCI builder
- The output image is very minimal, only `shortener`'s runtime dependencies are included (no shell, no package manager)

```nix
# Here `shortener` is the previously built package
{ dockerTools, lib, shortener }:
dockerTools.buildLayeredImage {
  name = "shortener";
  tag = "latest";
  contents = [ shortener ];
  config = {
    Cmd = [ (lib.getExe shortener) ];
    Env = [ "HOST=0.0.0.0" ];
    ExposedPorts = { "8000/tcp" = { }; };
  };
}
```

```bash +exec
nix build .#image
nix eval .#image --raw
```

<!-- speaker_note: mention how slim the image is, 4.7 MB is smaller than Alpine's 5.2 MB -->

---

# Deploying the backend (VM)



---

# Deploying the backend (NixOS module)


---

# Conclusion

---

# Appendices

---

# Appendix: Nix the package manager

```sh
# Run btop ephemerally
nix run nixpkgs#btop

# Create a shell with btop available
nix shell nixpkgs#btop

# Run a 3rd party package
nix run github:nikitawootten/infra#editor
```

- Allows you to try out any nix package locally with just a command
- Doesn't install permanently
- "Try before you buy"
- Available on many Linux distributions & on MacOS

---

# Appendix: Nix the language


<!-- column_layout: [1, 1] -->

<!-- column: 0 -->
- JSON-like functional language
- "Derivations" (packages) are a core language feature
- Packages built in a sandbox, written to "the Nix store"

<!-- column: 1 -->

```nix +line_numbers
{ pkgs ? import <nixpkgs> {} }:
let
  audience = "Python Frederick";
in
pkgs.writeShellApplication {
  name = "example-package";
  text = ''
    ${pkgs.cowsay} "Hello, ${audience}"
  '';
}
```

*Example derivation producing a shell script*

---

# Appendix: Nix the operating system

<!-- column_layout: [1, 1] -->

<!-- column: 0 -->
- A linux distribution
- Uses the Nix language to declare the system state
- The users, packages, config files, running services, etc. all configured through one interface
- Nix "modules" allow for re-usable configuration

<!-- column: 1 -->

```nix +line_numbers
{ config, pkgs, ... }:
{
  networking.hostName = "my-server";

  users.users.nikita = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  services.openssh = {
    enable = true;
    settings = {
      # written to /etc/ssh/sshd_config
      PermitRootLogin = "no";
    };
  };
}
```

*Example NixOS configuration defining a machine's hostname, user, and running OpenSSH server*

