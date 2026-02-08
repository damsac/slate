{
  description = "Slate iOS development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        isDarwin = pkgs.stdenv.isDarwin;

        preCommitHook = pkgs.writeShellScript "pre-commit" ''
          # Validate entitlements if project.yml is being committed
          if git diff --cached --name-only | grep -qE '(project\.yml|project\.local\.yml)'; then
            echo "project.yml changed — validating entitlements..."
            test -f project.local.yml || touch project.local.yml
            ${pkgs.xcodegen}/bin/xcodegen generate --quiet
            APP_GROUP="group.com.damsac.slate.shared"
            for f in Slate/Slate.entitlements SlateWidget/SlateWidget.entitlements; do
              if ! grep -q "$APP_GROUP" "$f" 2>/dev/null; then
                echo "ERROR: $f missing App Group '$APP_GROUP'" >&2
                echo "Check project.yml entitlements.properties for both targets." >&2
                exit 1
              fi
            done
            echo "Entitlements validated."
          fi

          # Lint staged Swift files
          STAGED_SWIFT=$(git diff --cached --name-only --diff-filter=ACM | grep '\.swift$' || true)
          if [ -n "$STAGED_SWIFT" ]; then
            echo "Linting staged Swift files..."
            echo "$STAGED_SWIFT" | xargs ${pkgs.swiftlint}/bin/swiftlint lint --quiet --strict 2>&1
            RESULT=$?
            if [ $RESULT -ne 0 ]; then
              echo "SwiftLint found errors. Fix them or commit with --no-verify to skip." >&2
              exit 1
            fi
          fi
        '';

        postMergeHook = pkgs.writeShellScript "post-merge" ''
          # Regenerate xcodeproj if project.yml or flake changed
          CHANGED=$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD)

          if echo "$CHANGED" | grep -qE '(project\.yml|project\.local\.yml\.template)'; then
            echo "project.yml changed — regenerating Xcode project..."
            make generate
          fi

          if echo "$CHANGED" | grep -qE '(flake\.nix|flake\.lock)'; then
            echo "Flake inputs changed — run 'direnv reload' or re-enter the shell to update tools."
          fi
        '';

      in
      {
        devShells.default = pkgs.mkShell {
          name = "slate-dev";
          packages = pkgs.lib.optionals isDarwin (with pkgs; [
            swiftlint
            xcodegen
            xcbeautify
            gnumake
          ]);
          shellHook = pkgs.lib.optionalString isDarwin ''
            # Install git hooks from Nix store
            if [ -d .git ]; then
              mkdir -p .git/hooks
              ln -sf ${preCommitHook} .git/hooks/pre-commit
              ln -sf ${postMergeHook} .git/hooks/post-merge
            fi

            # Check Xcode version
            if command -v xcodebuild &> /dev/null; then
              XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -n1 | awk '{print $2}' | cut -d. -f1)
              if [ -n "$XCODE_VERSION" ]; then
                if [ "$XCODE_VERSION" -ge 26 ]; then
                  echo "⚠️  WARNING: Xcode $XCODE_VERSION detected"
                  echo "   Known issue: CLI builds may fail with linker errors"
                  echo "   Workaround: Use Xcode GUI (Cmd+R) or see Issue #6"
                fi
              fi
            else
              echo "⚠️  WARNING: xcodebuild not found — Xcode may not be installed"
            fi

            # Check disk space
            DISK_SPACE=$(df -k . | tail -1 | awk '{print $4}')
            DISK_SPACE_GB=$((DISK_SPACE / 1024 / 1024))
            if [ "$DISK_SPACE_GB" -lt 10 ]; then
              echo "⚠️  WARNING: Low disk space detected (${DISK_SPACE_GB}GB free)"
              echo "   Xcode DerivedData can consume significant space"
              echo "   To free space: rm -rf ~/Library/Developer/Xcode/DerivedData"
            fi

            echo "Slate dev shell — run 'make help' for available targets"
          '';
        };

      });
}
