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
      url = {
        "git@github.com:" = {insteadOf = "https://github.com/";};
      };
    };
  };
}
