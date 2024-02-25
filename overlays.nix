[( self: super:
  let
    runtime_locking_correctness_validator = ''
        DEBUG_ATOMIC_SLEEP y
        DEBUG_MUTEXES y
        DEBUG_SPINLOCK y
        DETECT_HUNG_TASK y
        PROVE_LOCKING y
        PROVE_RCU y
        SOFTLOCKUP_DETECTOR y
      '';
    fail_io = ''
        FAULT_INJECTION y
        FAIL_IO_TIMEOUT y
        FAULT_INJECTION_DEBUG_FS y
      '';
  in rec {
    linux_latest = super.linux_latest.override {
      extraConfig =
        ''
          GDB_SCRIPTS y
          KGDB y
        ''
        # + runtime_locking_correctness_validator
        # + fail_io
      ;
      kernelPatches = super.linux_latest.kernelPatches ++ [
        # { name = "my-patch";
        #   patch = ./my.patch;
        # }
      ];
    };
  })]
