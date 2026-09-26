{
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  console.keyMap = "de";

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  system.stateVersion = "26.05";
}
