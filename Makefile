image_size := 8192M
intermediate_img := $(shell mktemp)
kernelEnv := 'with import <nixos> { overlays = import ./overlays.nix; }; linux_latest.overrideAttrs (o: {nativeBuildInputs=o.nativeBuildInputs ++ [ pkg-config ncurses ];})'
# nix_build_extra_options := --keep-failed --show-trace
nix_build_options := $(nix_build_extra_options) --attr vm --arg configuration ./configuration.nix

qemu_options := -no-reboot
ifndef graphic
  qemu_options += -nographic
endif

.PHONY: run.native
run.native: result.native/bin/run-nixvm-vm
	export QEMU_NET_OPTS=hostfwd=tcp::9922-:22; \
	export QEMU_OPTS="$(qemu_options)"; \
	$<

.PHONY: run.aarch64
run.aarch64: result.aarch64/bin/run-nixvm-vm
	# Replace the qemu-system-aarch64 for a aarch64 *host* by the qemu-system-aarch64 for the native host architecture
	awk '$$1 == "exec" && $$2 ~ /qemu-system-aarch64/ {$$2="qemu-system-aarch64"; print; next}; {print}' $< > ./run-nixvm.aarch64
	chmod 755 ./run-nixvm.aarch64
	export QEMU_NET_OPTS=hostfwd=tcp::9922-:22; \
	export QEMU_OPTS="-machine virt -cpu cortex-a57 $(qemu_options)"; \
	./run-nixvm.aarch64

result.native/bin/run-nixvm-vm: nixvm.qcow2
	nix-build '<nixpkgs/nixos>' $(nix_build_options) --out-link ./result.native

result.aarch64/bin/run-nixvm-vm: nixvm.qcow2
	nix-build '<nixpkgs/nixos>' $(nix_build_options) --out-link ./result.aarch64 --system aarch64-linux

# Creating a bigger image than the default image that would be created
# by run-nixvm-vm.
nixvm.qcow2:
	qemu-img create -f raw "$(intermediate_img)" $(image_size)
	mkfs.ext4 -L nixos "$(intermediate_img)"
	qemu-img convert -f raw -O qcow2 "$(intermediate_img)" $@
	rm "$(intermediate_img)"

.PHONY: prepare-kernel-workspace
prepare-kernel-workspace:
	nix-shell \
	  --expr $(kernelEnv) \
	  --command 'runPhase unpackPhase; runPhase patchPhase; runPhase configurePhase'

.PHONY: kernel-build-shell
kernel-build-shell:
	nix-shell \
	  --expr $(kernelEnv) \
	  --command 'cd linux-*/build; echo -e "\n# declare -f runPhase\n"; return'

.PHONY: ssh
ssh:
	ssh -p9922 -oStrictHostKeyChecking=off kai@localhost

.PHONY: clean
clean:
	-rm ./result.aarch64
	-rm ./result.native

.PHONY: clean-all
clean-all: clean
	-rm ./nixvm.qcow2
