---
title: The Case for Nix
sub_title: ""
author: Nikita Wootten & Matthew Mazzanti
options:
  end_slide_shorthand: true
  h1_slide_titles: true
---

# What is Nix?
<!-- column_layout: [1, 1] -->
<!-- column: 0 -->
![](assets/holy-trinity.jpg)
[Image Source: Andreas Fuchs](https://boinkor.net/2024/04/what-nix-will-have-been/)

<!-- column: 1 -->
Nix is:
- A package manager
- A language
- An operating system
- Poorly named

---

# A better question to ask
<!-- column_layout: [1, 2, 1] -->
<!-- column: 1 -->
<!-- pause -->
What can nix do?

---

# Project: link simple link shortener
<!-- speaker_note: ensure `just dev` is running for the below curl commands to resolve -->
Simple web service with a connected database

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

---

# Lets build a shell script!
<!-- pause -->
But shell scripts suck:
<!-- pause -->
- What runtime environment are you on?
- What version of `sed`, `curl` and dependencies do you have?
- Do it wrong and your script is broken on a PDP 11 and a nerd on the internet yells at you

---

# Creating a shell script with nix

```nix
{ writeShellApplication, curl, jq }:
writeShellApplication {
  name = "shortctl";
  runtimeInputs = [ curl jq ];
  text = builtins.readFile ./shortctl.sh;
}
```
---

# Creating a shell script with nix

Evaluating this expression produces a "derivation" (package):

```bash +exec
nix build .#shortctl
nix eval .#shortctl --raw
```

---

# Installing the script

---

# Lets build a developer environment!
<!-- pause -->
But dev environments suck:
<!-- pause -->
- Dev machines are mostly cruft
- Huge runbook of commands to get set up
- Then it breaks and takes forever to fix

---

# Dev environments

- Run ephemeral commands with `nix run` and `nix shell`
- Prepare and sync a full dev environment for your team
- Direnv gets a shoutout here

```nix
{ mkShell, go, gopls, postgresql, redis, process-compose, jq, just }:
mkShell {
  packages = [ go gopls postgresql redis process-compose jq just ];
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

---

# Dev environments

```bash +exec
nix build .#devShells.x86_64-linux.default
nix eval .#devShells.x86_64-linux.default --raw
```

---

# Lets deploy the app!
<!-- pause -->
But Deploying apps sucks:
<!-- pause -->
- Differences between prod & your laptop
- Dockers solution: Ship the laptop
- That can break too, if your deps change
- Isn't "reproducible"

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

