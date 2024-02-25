# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
#
# VM too slow?  Increase the "virtualisation.msize" of your NixOS
# installation!

{ config, pkgs, ... }: with pkgs;
let
  myKernelPackages = pkgs.linuxPackagesFor linux_latest;
  mySshKeys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCKeT9XLuhzUU4k4gd8URDS3gQIZemTqXSvlVy5nYXJ4gMfJ0sYVMrI9KBBU2Ukkb0Cl8Rmfzblf1iE6IUMrat4Cb9RGIbzjiAzC2XaLUsDC5W87Qv5bgV0t83nWQFjWPWy38Ybjcp8+WuvJNaX9ECc8t+xwtUdVNZ5TszblEqE5wKfOAqJZNGO8uwX2ZY7hOLr9C9a/AM74ouHqR7iDaujMNdLuOA6XmHAnWI6aiA6Lu3NOpGO6UXIudUCIUQ+ymSCCfu99xaAs5aXw/XQLS2f8W8C4q45m/V+uozdqYOK2wrFQlhFa/7TZwi5s3XPeG0d7t5HnxymSIHO7HudP0E7 cardno:00050000351F"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCrph3lPTTICQR4SgX5X2XXTVcPqUmeS9urKJjCLS92rFycxJFgUNHq5Wwjctq1dwsNI7l7+td6kzaz5SsIfNLlFpEoiS3kfG/mRHlkJYOuiCpofI3AIDnHdNDRHhztf+n2i/s3758EyRu0Ct30QwMP+aVSOqA+NFpeKyJdSnL+PwVWPdi2HooUdNbBR2QtB/qQ39DmzB7BqtUWSOUB4EgoKnrfLfN03z1L4XOQCKtzrqar3oGYXvZ0K5nIOGktByd8TXecH1+DCE0tdTXvJoobj+fWvin3FmjjiitK05b7+pa7GadzmmnvgtrLLTY/CUSB/NNCs2k6j22woYNQcxeLHfifkMNFFBOXQKUHX5iw3RJAwbY92XKN6t8VyvHPv5qLXMo4NFhWjTRKgY5VWNn94sr1ZQ8RV/teUr3TnZTMyNo0a13BGtdKUGHppRSPEQQ3VZbureIvfGMcO7NQvloXdLjvFJyR9E+NX1MVZyLThsZkCgWLB/AIq+8Gl9myfe0= kai@nix230"
  ];

in {
  imports = [
    <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
  ];

  nixpkgs.overlays = import ./overlays.nix;
  
  nix.settings.extra-sandbox-paths = [
    "/var/cache/ccache"
  ];
  # nixpkgs.config.allowUnfree = true;

  virtualisation.vmVariant = {
    virtualisation.qemu.package = pkgs.qemu;
    virtualisation.cores = 4;
    virtualisation.memorySize = 4096;
    virtualisation.qemu.virtioKeyboard = false;
  };

  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
  ];

  boot.kernelPackages = myKernelPackages;
  boot.kernel.sysctl."kernel.perf_event_paranoid" = -1;
  boot.kernel.sysctl."kernel.kptr_restrict" = 0;
  boot.consoleLogLevel = 7;  # To have "early" livesigns of the aarch64 vm
  boot.tmp.cleanOnBoot = true;

  networking.hostName = "nixvm";
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.useNetworkd = true;

  time.timeZone = "Europe/Amsterdam";

  programs.bash.interactiveShellInit = ''
      PROMPT_COMMAND=__prompt_command
      __prompt_command ()
      {
          local rc=$?
          if [[ rc -ne 0 ]]; then
              echo -e "bash: \e[0;31mexit $rc\e[0m"
          fi
      }
    '';
  programs.bcc.enable = true;
  programs.ssh.startAgent = false;
  programs.systemtap.enable = true;
  programs.tmux = {
    enable = true;
    escapeTime = 0;
    terminal = "tmux-256color";
    extraConfig = ''
      run-shell ${pkgs.tmuxPlugins.urlview}/share/tmux-plugins/urlview/urlview.tmux
      run-shell ${pkgs.tmuxPlugins.open}/share/tmux-plugins/open/open.tmux
    '';
  };

  system.stateVersion = "23.11";

  users.users.kai.isNormalUser = true;
  users.users.kai.uid = 1000;
  users.users.kai.extraGroups = [
      "dialout"
      "networkmanager"
      "wheel"
    ];
  users.users.kai.openssh.authorizedKeys.keys = mySshKeys;
  users.users.root.openssh.authorizedKeys.keys = mySshKeys;

  security.sudo.extraConfig =''kai ALL = NOPASSWD : ALL'';

  services.getty.autologinUser = "kai";
  services.openssh.enable = true;
  services.openssh.settings.KbdInteractiveAuthentication = false;
  services.openssh.settings.PasswordAuthentication = false;

  environment.homeBinInPath = true;
  environment.etc."inputrc".text = lib.mkForce (
    builtins.readFile <nixpkgs/nixos/modules/programs/bash/inputrc> + ''

         ### My customization #############################
         set blink-matching-paren on
         set colored-completion-prefix on
         set completion-ignore-case on
         set completion-map-case on

         "\en": history-search-forward
         "\ep": history-search-backward

         "\ej": menu-complete
         "\ek": menu-complete-backward
         '');
  environment.systemPackages = [
    binutils
    dnsutils
    dstat
    emacs
    file
    fontconfig
    git
    gnumake
    myKernelPackages.bpftrace
    myKernelPackages.perf
    lshw
    pciutils
    psmisc
    pstree
    python3
    rsync
    stdenv
    sysstat
    vnstat
  ];
}
