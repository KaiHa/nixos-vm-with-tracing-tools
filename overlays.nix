[( self: super: rec {
  ccacheWrapper = super.ccacheWrapper.override {
    extraConfig = ''
                    export CCACHE_NOCOMPRESS=1
                    export CCACHE_MAXSIZE=10G
                    export CCACHE_UMASK=007
                    export CCACHE_DIR=/var/cache/ccache
                  '';
  };
  linuxPackages_latest.kernel = super.linuxPackages_latest.kernel.override {
    extraConfig = ''
                    BUG_ON_DATA_CORRUPTION y
                    DEBUG_ATOMIC_SLEEP y
                    DEBUG_MUTEXES y
                    DEBUG_SPINLOCK y
                    DETECT_HUNG_TASK y
                    KGDB y
                    PANIC_ON_OOPS y
                    PANIC_TIMEOUT 0
                    PROVE_LOCKING y
                    PROVE_RCU y
                    SOFTLOCKUP_DETECTOR y
                  '';
    stdenv = super.ccacheStdenv;
    kernelPatches = super.linuxPackages_latest.kernel.kernelPatches ++ [
      # { name = "my-patch";
      #   patch = ./my.patch;
      # }
    ];
  };
})]
