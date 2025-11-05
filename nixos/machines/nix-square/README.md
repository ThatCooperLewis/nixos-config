# Nix on Square MacBooks

## Installation for replacement MBP

1. Download and install [Determinate Nix](https://docs.determinate.systems/)
2. Git clone this repo
3. Change hostname in flake. If you don't do this correctly, it'll cause the error:

       'git+file:///Users/cooperl/nixos-config?dir=nixos' does not provide attribute 'packages.aarch64-darwin.darwinConfigurations.17d1d9ba598842f4940f332987fe3c5c.system'

4. Run nix update code

        sudo nix run nix-darwin -- switch --flake ~/nixos-config/nixos

5. It'll complain that several files already exist. For each one, rename it.

        sudo mv /etc/zshenv /etc/zshenv.beforeNix

6. Install the FiraCode font in /assets, set it in the your Terminal's `Profiles` settings (it should auto-apply to VSCode/Cursor)