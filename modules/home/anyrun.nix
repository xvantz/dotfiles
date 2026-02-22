{
  pkgs,
  inputs,
  ...
}: {
  programs.anyrun = {
    enable = true;
    package = inputs.anyrun.packages.${pkgs.stdenv.hostPlatform.system}.anyrun;
    config = {
      x = {fraction = 0.5;};
      y = {fraction = 0.3;};
      width = {fraction = 0.3;};
      hideIcons = false;
      ignoreExclusiveZones = false;
      layer = "overlay";
      hidePluginInfo = true;
      closeOnClick = false;
      showResultsImmediately = false;
      maxEntries = null;

      plugins = [
        "${inputs.anyrun.packages.${pkgs.stdenv.hostPlatform.system}.applications}/lib/libapplications.so"
        "${inputs.anyrun.packages.${pkgs.stdenv.hostPlatform.system}.rink}/lib/librink.so"
        "${inputs.anyrun.packages.${pkgs.stdenv.hostPlatform.system}.shell}/lib/libshell.so"
        "${inputs.anyrun.packages.${pkgs.stdenv.hostPlatform.system}.translate}/lib/libtranslate.so"
      ];
    };

    extraCss = ''
      window { background: transparent; }

      .main {
        background-color: #1a1b26;
        border: 1px solid #7aa2f7;
        border-radius: 15px;
        padding: 10px;
      }

      text {
        color: #c0caf5;
        padding: 10px;
        font-size: 20px;
      }

      .match {
        padding: 8px;
        border-radius: 10px;
      }

      .match:selected {
        background-color: #33467c;
      }

      .title {
        color: #c0caf5;
        font-size: 16px;
      }

      .description {
        color: #565f89;
        font-size: 13px;
      }
    '';
    extraConfigFiles."applications.ron".text = ''
      Config(
        desktop_actions: true,
        max_entries: 5,
      )
    '';
  };
}
