{...}: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Ivan R.";
        email = "xvantz@gmail.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
