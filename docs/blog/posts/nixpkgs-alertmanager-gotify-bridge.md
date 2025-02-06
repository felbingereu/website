---
date:
  created: 2025-01-30
  updated: 2025-02-06
authors: 
- nicof2000
---

# NixOS: Erstellen eines neuen Pakets

Dieser Artikel entstand, weil ein Bekannter mich bat, ihm zu zeigen, wie man eine Software
für Nix paketiert und in [github.com/nixos/nixpkgs](https://github.com/nixos/nixpkgs) integriert.
Konkret ging es um das Paket `alertmanager-gotify-bridge`, das eine Brücke zwischen dem Prometheus
Alertmanager und Gotify bildet. Ziel war es, nicht nur das Paket zu erstellen, sondern auch den
gesamten Prozess zu verstehen, um es später selbstständig in das offizielle nixpkgs-Repository
einzubringen. Um diesen Ablauf für andere nachvollziehbar zu machen, entschied ich mich, ihn
umfassend zu dokumentieren.

<!-- more -->

1. Vorarbeiten
    - [Contributing Guide](https://nix.dev/contributing/index.html) lesen

    - GitHub Account anlegen

    - Fork von <github.com/nixos/nixpkgs> erstellen

    - Fork klonen und offizielles Repository als "upstream" hinzufügen (für späteres rebasen):
      ```shell
      git remote add upstream git@github.com:nixos/nixpkgs.git
      ```

2. Neuen Feature-Branch in Fork erstellen:
    Da die NixOS-Maintainer den master-Branch aufgrund von GitHub-Schutzmechanismen nicht bearbeiten können -
    insbesondere, weil GitHub Action Workflows dort direkt ausgeführt würden - ist es sinnvoll, einen neuen
    Feature-Branch zu erstellen.
    
    Dies hilft auch dabei, mögliche Merge-Konflikte zu lösen, besonders wenn man noch nicht viel Erfahrung im
    Umgang mit Git hat.
    
    ```shell
    git checkout -b alertmanager-gotify-bridge
    ```

3. Sofern dies die erste Contribution zu `nixpkgs` ist, sollte anschließend ein Eintrag in der Datei
    `maintainers/maintainers-list.nix` angelegt werden.
    ```nix
    <handle> = {
      # Required
      name = "Your name";

      # Optional, but at least one of email, matrix or githubId must be given
      email = "address@example.org";
      matrix = "@user:example.org";
      github = "<github-name>";
      githubId = your-github-id; # see profile -> profile picture -> url

      keys = [{
        fingerprint = "AAAA BBBB CCCC DDDD EEEE  FFFF 0000 1111 2222 3333";
      }];
    };
    ```
    Anschließend werden die Änderungen hinzugefügt:
    ```shell
    git add maintainers/maintainers-list.nix
    git commit -m "maintainers: add <handle>"
    ```

4. Software analysieren: Programmiersprache und Lizenz bestimmen:  
    Nix bietet eine Vielzahl von Modulen zur Unterstützung unterschiedlicher Programmiersprachen. Daher ist
    der erste Schritt, die Programmiersprache der Software zu identifizieren. Sobald die Sprache bestimmt ist,
    kann man sich im [Language Framework](https://nixos.org/manual/nixpkgs/stable/#chap-language-support) der
    NixOS-Dokumentation weiter informieren, um das passende Build-Modul auszuwählen und zu verstehen, wie man
    es korrekt in das Paket integriert.

    Die Lizenz wird im weiteren Verlauf für die Metainformationen des Pakets benötigt.

    Im Fall der `alertmanager-gotify-bridge` handelt es sich um eine Go-Anwendung, die unter der Apache-2.0 Lizenz
    steht. Zum Paketieren von Go-Anwendungen bietet Nix das Modul [`buildGoModule`](https://nixos.org/manual/nixpkgs/stable/#sec-language-go).
    Die Lizenz kann mit `lib.licenses.asl20` definiert werden (siehe [lib/licenses.nix](https://github.com/NixOS/nixpkgs/blob/master/lib/licenses.nix)).

5. Unter Verwendung des Beispielaufrufes von `buildGoModule` und der Informationen aus dem GitHub Repositories
    der Anwendung kann die Derrivation definiert werden:
    ```nix
    {
     lib,
     buildGoModule,
     fetchFromGitHub,
    }:
    buildGoModule rec {
      pname = "alertmanager-gotify-bridge";  # name of the package
      version = "2.3.1";  # version of last release (on github)

      src = fetchFromGitHub {
        owner = "DRuggeri";  # github owner
        repo = "alertmanager_gotify_bridge";  # github repository name
        tag = "v${version}";  # releases use semver schema for versioning
        hash = lib.fakeHash;  # we don't know the hash yet, so let's use a fake one
      };

      vendorHash = lib.fakeHash;

      meta = {
        description = "Bridge between Prometheus AlertManager and a Gotify server";
        homepage = "https://github.com/DRuggeri/alertmanager_gotify_bridge";
        changelog = "https://github.com/DRuggeri/alertmanager_gotify_bridge/releases/tag/v${version}";
        license = lib.licenses.asl20;
        maintainers = with lib.maintainers; [ <handle> ];
      };
    }
    ```
    Nachdem diese unter dem Pfad `pkgs/by-name/al/alertmanager-gotify-bridge/package.nix` gespeichert wurde,
    kann das Programm mithilfe des Befehls `nix build -f . alertmanager-gotify-bridge` gebaut werden.

    Beim ersten Ausführen wurde der Build jedoch abgebrochen, da Nix einen Fehler im Zusammenhang mit dem
    `src.hash`-Attribut erkennt:
    ```shell
    error: hash mismatch in fixed-output derivation '/nix/store/9v7c1qjzibbq3r4v579h684zgkbg0nkz-source.drv':
      specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
         got:    sha256-yXPOrpkhQUNPg5YNBxsgGijT1utRcUZ1k38T7wmkbgg=
    error: 1 dependencies of derivation '/nix/store/zafjqknp6vq3lrh1lf4y9h1npim3vzz6-alertmanager-gotify-bridge-2.3.1.drv' failed to build
    ```

    Auch nachdem der korrekte Hash in `src.hash` eingetragen und der Build erneut gestartet wurde, bricht Nix den
    Build-Prozess ab, da der `vendorHash` ebenfalls falsch ist:
    ```shell
    error: hash mismatch in fixed-output derivation '/nix/store/gx9qq67fn953xyzfgznz4ygh9p1rirbc-alertmanager-gotify-bridge-2.3.1-go-modules.drv':
      specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
         got:    sha256-YDSKSSMTdjROyBaiOO2tZtu9QPKSUqwAd8VWf3ZOvDI=
    error: 1 dependencies of derivation '/nix/store/pgrywjs655jqkn2p11hg8hg7nh835m1f-alertmanager-gotify-bridge-2.3.1.drv' failed to build

    ```

    Nachdem auch dieser korrigiert ist schlug der Build mit folgender Fehlermeldung fehl:
    ```shell
    error: builder for '/nix/store/q8751wvq5fnrlr8d0h1dlpdihn2jclcv-alertmanager-gotify-bridge-2.3.1.drv' failed with exit code 1;
       last 25 log lines:
       > vendor/golang.org/x/exp/constraints/constraints.go:49:2: embedding interface element Integer | Float | ~string requires go1.18 or later (-lang was set to go1.16; check go.mod)
       > # go.opentelemetry.io/otel/internal/attribute
       > vendor/go.opentelemetry.io/otel/internal/attribute/attribute.go:26:17: type parameter requires go1.18 or later (-lang was set to go1.16; check go.mod)
       > vendor/go.opentelemetry.io/otel/internal/attribute/attribute.go:26:19: embedding interface element bool | int64 | float64 | string requires go1.18 or later (-lang was set to go1.16; check go.mod)
       > vendor/go.opentelemetry.io/otel/internal/attribute/attribute.go:26:59: predeclared any requires go1.18 or later (-lang was set to go1.16; check go.mod)
       > vendor/go.opentelemetry.io/otel/internal/attribute/attribute.go:34:14: type parameter requires go1.18 or later (-lang was set to go1.16; check go.mod)
       > vendor/go.opentelemetry.io/otel/internal/attribute/attribute.go:34:16: embedding interface element bool | int64 | float64 | string requires go1.18 or later (-lang was set to go1.16; check go.mod)
       > vendor/go.opentelemetry.io/otel/internal/attribute/attribute.go:34:51: predeclared any requires go1.18 or later (-lang was set to go1.16; check go.mod)
       <... SNIP ...>
       For full logs, run 'nix log /nix/store/q8751wvq5fnrlr8d0h1dlpdihn2jclcv-alertmanager-gotify-bridge-2.3.1.drv'.
    ```

    Um diesen Fehler zu beheben, musste die in der `go.mod` definierten Go-Version aktualisiert werden. Dazu wurde
    <github.com/DRuggeri/alertmanager_gotify_bridge> zunächst geforked und geklont. Nachdem die Version in der `go.mod` auf 1.18 gesetzt
    wurde, kann der Befehl `go mod tidy` ausgeführt werden, um die indirekten Abhängigkeiten in `go.mod`, und die dazugehörigen Hashes
    in der `go.sum`, hinzuzufügen.

    Danach wurde mithilfe von `git diff` ein Patch für die beiden Dateien angelegt, der in der Derrivation hinzugefügt werden kann:
    ```nix
    patches = [ ./go.sum.patch ./go.mod.patch ];
    ```
    
    Nachdem das Programm erneut gebaut wurde und der `vendorHash` aktualisiert wurde, ist der Build erfolgreich.
    ```nix
    {
      lib,
      buildGoModule,
      fetchFromGitHub,
    }:
    buildGoModule rec {
      pname = "alertmanager-gotify-bridge";
      version = "2.3.1";

      src = fetchFromGitHub {
        owner = "DRuggeri";
        repo = "alertmanager_gotify_bridge";
        tag = "v${version}";
        hash = "sha256-yXPOrpkhQUNPg5YNBxsgGijT1utRcUZ1k38T7wmkbgg=";
      };
      patches = [ ./go.sum.patch ./go.mod.patch ];

      vendorHash = "sha256-APFoNLCrSiAoeuVIzlnmtUthyqFDcG0cjoJf/jGbrTg=";

      meta = {
        description = "A bridge between Prometheus AlertManager and a Gotify server";
        homepage = "https://github.com/DRuggeri/alertmanager_gotify_bridge";
        changelog = "https://github.com/DRuggeri/alertmanager_gotify_bridge/releases/tag/v${version}";
        license = lib.licenses.asl20;
        maintainers = with lib.maintainers; [ <handle> ];
      };
    }
    ```

6. Testen und erstellen des Pull Requests
    Die resultierende `alertmanager_gotify_brudge` Binary ist im Verzeichnis `result` zu finden.

    Nun kann die `package.nix` sowie die beiden Patches `go.{mod,sum}` zur Staging Umgebung hinzugefügt, commited und gepushed werden.
    ```shell
    git add pkgs/by-name/al/alertmanager-gotify-bridge/
    git commit -m "alertmanager-gotify-bridge: init at 2.3.1"
    git push -u origin alertmanager-gotify-bridge
    ```

    Zuletzt wird der Pull Request erstellt (siehe Nachricht von `git push`) und geprüft, ob die Pakete alle kompilieren:
    ```shell
    nix-shell -p nixpkgs-review --run "nixpkgs-review rev HEAD --print-result"
    ```
