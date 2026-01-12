{
  services = {
    flatpak = {
      enable = true;
      # remotes = [{
      #   name = "flathub-beta"; location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      # }];
      packages = [
      #  "com.github.wwmm.easyeffects"
      ];
      update.auto = {
        enable = true;
        onCalendar = "weekly"; 
      };
    };
  };
}