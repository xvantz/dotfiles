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
        "ssh://forgejo@git.827482.xyz/" = {insteadOf = "https://git.827482.xyz/";};
      };
    };
  };
}
