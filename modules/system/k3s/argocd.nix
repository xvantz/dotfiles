{pkgs, ...}: {
  services.k3s = {
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
}
