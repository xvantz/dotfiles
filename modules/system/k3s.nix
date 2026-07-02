{pkgs, ...}: {
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = "--disable servicelb --write-kubeconfig /home/xvantz/.kube/config --write-kubeconfig-mode 644";

    manifests."traefik-config" = {
      source = pkgs.writeText "traefik-config.yaml" ''
        apiVersion: helm.cattle.io/v1
        kind: HelmChartConfig
        metadata:
          name: traefik
          namespace: kube-system
        spec:
          valuesContent: |-
            service:
              type: NodePort
            ports:
              web:
                port: 80
                nodePort: 30080
              websecure:
                port: 443
                nodePort: 31443
      '';
    };

    manifests."argocd-ingress" = {
      source = pkgs.writeText "argocd-ingress.yaml" ''
        apiVersion: networking.k8s.io/v1
        kind: Ingress
        metadata:
          name: argocd
          namespace: argocd
        spec:
          ingressClassName: traefik
          rules:
            - host: argocd.827482.xyz
              http:
                paths:
                  - path: /
                    pathType: Prefix
                    backend:
                      service:
                        name: argo-cd-argocd-server
                        port:
                          number: 80
      '';
    };

    autoDeployCharts = {
      argo-cd = {
        repo = "https://argoproj.github.io/argo-helm";
        name = "argo-cd";
        version = "10.1.0";
        targetNamespace = "argocd";
        createNamespace = true;
        hash = "sha256-/n4esllwqKkXkpDmeaXfoKGAUkHlF2hrMhg5/9p19vw=";
        values = {
          configs.params = {
            "server.insecure" = "true";
            "server.dex.server.strict.tls" = "false";
          };
          server.ingress.enabled = false;
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [kubectl argocd];
}
