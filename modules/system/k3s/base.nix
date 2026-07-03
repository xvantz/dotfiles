{pkgs, ...}: {
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = "--disable servicelb --write-kubeconfig /home/xvantz/.kube/config --write-kubeconfig-mode 644";
  };

  environment.systemPackages = with pkgs; [kubectl argocd];
}
