run.native: ./result.native/bin/run-nixvm-vm
	QEMU_NET_OPTS=hostfwd=tcp::9922-:22; \
	QEMU_OPTS="-m 2G"; \
	export QEMU_NET_OPTS QEMU_OPTS; \
	$< &

result.native/bin/run-nixvm-vm:
	nix-build '<nixpkgs/nixos>' -A vm --arg configuration ./configuration.nix --out-link ./result.native

result.aarch64/bin/run-nixvm-vm:
	nix-build '<nixpkgs/nixos>' -A vm --arg configuration ./configuration.nix --out-link ./result.aarch64 --system aarch64-linux

ssh:
	ssh -p9922 -oStrictHostKeyChecking=off localhost

clean:
	-rm ./nixvm.qcow2
	-rm ./result.aarch64
	-rm ./result.native
