FROM --platform=linux/amd64 nixos/nix:latest

# Enable flakes and install jq
RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf \
    && nix-env -iA nixpkgs.jq

WORKDIR /work
COPY bootstrap.sh /work/bootstrap.sh
RUN chmod +x /work/bootstrap.sh

ENTRYPOINT ["/work/bootstrap.sh"]
