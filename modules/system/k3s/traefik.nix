{pkgs, ...}: {
  services.k3s.manifests."traefik-config" = {
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
}
