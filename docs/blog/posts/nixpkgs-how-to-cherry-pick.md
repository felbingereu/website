---
date:
  created: 2025-02-15
authors:
- nicof2000
categories:
- NixOS
---

# NixOS: Cherry-Picken von Commits

Wenn man an nixpkgs arbeitet oder einen Pull Request testet, möchte man oft nicht einfach
auf den Master-Branch wechseln, nur um die Änderungen aus diesem PR zu testen. Stattdessen
ist es oft sinnvoller, die notwendigen Commits direkt in die eigene Version von nixpkgs zu
übernehmen. So kann man spezifische Änderungen testen, ohne die gesamte Umgebung auf den
neuesten Stand zu bringen. Besonders praktisch ist das, wenn man mit einer stabilen Version
von nixpkgs arbeitet, etwa einem Release-Branch, und nur gezielt bestimmte Commits aus einem
PR übernehmen möchte.

<!-- more -->

Um die Version von nixpkgs, die in deinem System verwendet wird, herauszufinden, führst du den
Befehl `jq -r .nodes.nixpkgs.locked.rev flake.lock` aus. Dieser gibt dir die genaue Revision
zurück, die in deiner flake.lock definiert ist. Danach klonst du nixpkgs und checkst die
entsprechende Revision aus: `git checkout <rev>.`.

Für die Verwendung deiner lokalen Version von nixpkgs hast du zwei Optionen. Eine Möglichkeit ist,
bei jedem Aufruf des nix-Befehls die Option `--override-input nixpkgs path:/path/to/nixpkgs` zu
verwenden. Alternativ kannst du die flake.nix bearbeiten, die Input-URL auf `git+file:/path/to/nixpkgs/`
setzen und anschließend `nix flake update nixpkgs` ausführen. Wird deploy-sh verwendet, ist letztere
Methode erforderlich, da derzeit keine Möglichkeit der Weitergabe von Optionen an Nix besteht.

Wenn du nun dein System baust, sollte nichts gebaut werden müssen, da die verwendete Version von
nixpkgs gleich geblieben ist.

Falls die Commits nicht in einem anderen Branch liegen, sondern du z. B. einen PR testen möchtest,
musst du zunächst den Branch des PR-Autors fetchen:
```shell
git remote add <autor> <repo_url>
git fetch <autor>
```

Nun kannst du die benötigten Commits in dein lokales nixpkgs übernehmen:
```shell
git cherry-pick <commit-hash>
```
