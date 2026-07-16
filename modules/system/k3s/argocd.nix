{pkgs, ...}: let
  repoURL = "https://git.827482.xyz/xvantz/infra-gitops";
in {
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

    manifests."argocd-project" = {
      source = pkgs.writeText "argocd-project.yaml" ''
        apiVersion: argoproj.io/v1alpha1
        kind: AppProject
        metadata:
          name: cluster
          namespace: argocd
        spec:
          description: Cluster-wide project for all applications
          sourceRepos:
            - '${repoURL}'
            - 'https://victoriametrics.github.io/helm-charts/'
            - 'https://grafana.github.io/helm-charts/'
          destinations:
            - namespace: 'argocd'
              server: 'https://kubernetes.default.svc'
            - namespace: 'animark-dev'
              server: 'https://kubernetes.default.svc'
            - namespace: 'animark-prod'
              server: 'https://kubernetes.default.svc'
            - namespace: 'monitoring'
              server: 'https://kubernetes.default.svc'
          clusterResourceWhitelist:
            - group: ""
              kind: 'Namespace'
            - group: "rbac.authorization.k8s.io"
              kind: 'ClusterRole'
            - group: "rbac.authorization.k8s.io"
              kind: 'ClusterRoleBinding'
            - group: "admissionregistration.k8s.io"
              kind: 'ValidatingWebhookConfiguration'
            - group: "admissionregistration.k8s.io"
              kind: 'MutatingWebhookConfiguration'
            - group: "apiextensions.k8s.io"
              kind: 'CustomResourceDefinition'
      '';
    };

    manifests."argocd-apps" = {
      source = pkgs.writeText "argocd-apps.yaml" ''
        apiVersion: argoproj.io/v1alpha1
        kind: Application
        metadata:
          name: argocd-apps
          namespace: argocd
        spec:
          project: cluster
          source:
            repoURL: ${repoURL}
            targetRevision: main
            path: argocd/applications
            directory:
              recurse: true
          destination:
            namespace: argocd
            server: 'https://kubernetes.default.svc'
          syncPolicy:
            automated:
              prune: true
              selfHeal: true
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
          configs.cm = {
            "resource.customizations.health.networking.k8s.io_Ingress" = ''
              hs = {}
              hs.status = "Healthy"
              return hs
            '';
          };
          server.ingress.enabled = false;
        };
      };
    };
  };
}
