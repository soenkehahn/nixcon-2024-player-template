{
  description = "NixCon 2024 - NixOS on garnix: Production-grade hosting as a game";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.garnix-lib = {
    url = "github:garnix-io/garnix-lib";
    inputs = {
      nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, garnix-lib, flake-utils }:
    let
      system = "x86_64-linux";
    in
    (flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let pkgs = import nixpkgs { inherit system; };
      in rec {
        packages = {
          webserver = pkgs.hello;
          default = packages.webserver;
        };
        apps.default = {
          type = "app";
          program = pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "start-webserver";
              runtimeEnv = {
                PORT = "8080";
              };
              text = ''
                ${pkgs.lib.getExe packages.webserver}
              '';
            }
          );
        };
      }))
    //
    {
      nixosConfigurations.server = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          garnix-lib.nixosModules.garnix
          ./nixcon-garnix-player-module.nix
          ({ pkgs, ... }: {
            playerConfig = {
              # Your github user:
              githubLogin = "soenkehahn";
              # You only need to change this if you changed the forked repo name.
              githubRepo = "nixcon-2024-player-template";
              # The nix derivation that will be used as the server process. It
              # should open a webserver on port 8080.
              # The port is also provided to the process as the environment variable "PORT".
              webserver = self.packages.${system}.webserver;
              # If you want to log in to your deployed server, put your SSH key
              # here:
              sshKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzsYv/IpqFuE29NVBQrslVqvdeEdPVfQqSg1pVyTh40j2Z3UK8uK6fCSLGyQZNsqyO5B8785tqLL9MoVJMfqVPhSUiRZqXvjMFXuxCTqV5YndXc8qFNfjgPxVGWUrZQsGpFQKj8LAbSXjxdBKFZvuU9/vo9GlxBUhcKdDLax4r/OqGOBSIRb5Cgwt2i85Yi1uB5hivdTL28Csx19IlmlAxJyRRltxOetC2eD9jF3qRQQciz/CjXUSGNKcyI2PhnCpeoH9v7j2+UrTsyN0JVGfMJoOvYW97QE3vYvefK1VGWnU8BrS3ybW4c4snHDr5OzaBNfNkmw765bM89HRiTL+HBbkGx1f739UCdcZnYiUzZBKoJRw4J4XqlIyuApCRrRUOG8PBPcClh1kldMxeJxpmGmIIdvOh++kIffOkOfCnEZUVlmqwLxeeYMZTPJ13yL9bQis1vR2dqeNud25eyK1FbaMTt5GE08Zcg/j39YBLxz/0hK4uE3bQbOA+eCEgypU= shahn@lissabon";
            };
          })
        ];
      };
    };
}
