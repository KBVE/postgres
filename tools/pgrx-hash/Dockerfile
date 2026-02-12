FROM --platform=linux/amd64 nixos/nix:latest

# Disable sandbox (required for QEMU-emulated builds on ARM hosts)
# and enable flakes
RUN echo "sandbox = false" >> /etc/nix/nix.conf \
 && echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf \
 && echo "filter-syscalls = false" >> /etc/nix/nix.conf

WORKDIR /work
COPY bootstrap.sh /work/bootstrap.sh
RUN chmod +x /work/bootstrap.sh

ENTRYPOINT ["/work/bootstrap.sh"]
