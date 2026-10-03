---
title: The Case for Nix
sub_title: ""
author: Nikita Wootten & Matthew Mazzanti
options:
  end_slide_shorthand: true
  h1_slide_titles: true
---

# What is Nix anyways?
<!-- column_layout: [2, 1] -->

<!-- column: 0 -->
![](assets/holy-trinity.jpg)

[Source: Reddit](https://www.reddit.com/r/linuxmemes/comments/17n0nzb/the_holy_trinity/)

<!-- column: 1 -->
Nix is:
* A language
* A package manager
* An operating system
* A bit of a mess

---

# Overview

* Quick tour of the hits of nix
* Repo available if you want to go deeper: https://github.com/nikitawootten/the-case-for-nix/

---

# Nix Shell

```sh
# Run btop ephemerally
nix run nixpkgs#btop
# Create a shell with btop available
nix shell nixpkgs#btop
```

- Allows you to try out any nix package locally with just a command
- Doesn't install permanently
- "Try before you buy"

---

# Nix Develop

```sh
nix develop
```

- Create a shell with a configured developer environment
- Allows standardized set of packages/tools
- Uses a lockfile like package-lock.json or uv.lock so versions stay stable

---

# Packaging a simple app

- Source: ./shortener/main.go
- Packaging: ./nix/package.nix

---

# Running in a NixOS System (Bare Metal)

---

# Containerizing the package

- Source: ./nix/docker.nix

---

# Running in a NixOS VM

- Source: ./nix/vm.nix

---

# Running as an AMI

- Source: ./nix/ami.nix

---

# Appendix A: What's the deal with Flakes?
