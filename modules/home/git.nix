{...}: {
  programs.git = {
    enable = true;
    userName = "Ivan R.";
    userEmail = "xvantz@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
