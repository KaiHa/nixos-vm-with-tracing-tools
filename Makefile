image_size := 4096M
intermediate_img := $(shell mktemp)
kernelEnv := 'with import <nixos> { overlays = import ./overlays.nix; }; linux_latest.overrideAttrs (o: {nativeBuildInputs=o.nativeBuildInputs ++ [ pkg-config ncurses ];})'

.PHONY: run.native
run.native: result.native/bin/run-nixvm-vm
	export QEMU_NET_OPTS=hostfwd=tcp::9922-:22; \
	export QEMU_OPTS="-m 2G -smp 4"; \
	$< &

.PHONY: run.aarch64
run.aarch64: result.aarch64/bin/run-nixvm-vm
	export QEMU_NET_OPTS=hostfwd=tcp::9922-:22; \
	export QEMU_OPTS="-m 2G"; \
	$< &

result.native/bin/run-nixvm-vm:
	nix-build '<nixpkgs/nixos>' --show-trace --attr vm --arg configuration ./configuration.nix --out-link ./result.native

result.aarch64/bin/run-nixvm-vm:
	nix-build '<nixpkgs/nixos>' --show-trace --attr vm --arg configuration ./configuration.nix --out-link ./result.aarch64 --system aarch64-linux

# Creating a bigger image than the default image that would be created
# by run-nixvm-vm.
nixvm.qcow2:
	qemu-img create -f raw "$(intermediate_img)" $(image_size)
	mkfs.ext4 -L nixos "$(intermediate_img)"
	qemu-img convert -f raw -O qcow2 "$(intermediate_img)" $@
	rm "$(intermediate_img)"

kernel-prepare-workspace:
	nix-shell \
	  --expr $(kernelEnv) \
	  --command 'unpackPhase; cd linux-*; patchPhase; nix-build --expr "import <nixos> { overlays = import ../overlays.nix; }" --attr linux_latest.configfile; cat ./result > ./.config; return'

kernel-build-shell:
	nix-shell \
	  --expr $(kernelEnv) \
	  --command 'cd linux-*; return'

.PHONY: ssh
ssh:
	ssh -p9922 -oStrictHostKeyChecking=off localhost

.PHONY: clean
clean:
	-rm ./result.aarch64
	-rm ./result.native

.PHONY: clean-all
clean-all: clean
	-rm ./nixvm.qcow2
