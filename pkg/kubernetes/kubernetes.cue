package kubernetes

import (
	"b.l/bl"
)

// Apply a Kubernetes configuration
Apply :: {
	// Kubernetes config to deploy
	source: string | bl.Directory

	// Kubernetes Namespace to deploy to
	namespace: string

	// Version of kubectl client
	version: *"v1.14.7" | string

	// Kube config file
	kubeconfig: bl.Secret

	deploy: bl.BashScript & {
		runPolicy: "always"

		input: {
			"/kube/source": source
			"/kube/config": kubeconfig
		}

		os: {
			package: curl: true

			extraCommand: [
				"curl -L https://dl.k8s.io/\(version)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl",
			]
		}

		environment: KUBE_NAMESPACE: namespace

		code: """
            export KUBECONFIG=/kube/config

            kubectl create namespace "$KUBE_NAMESPACE" || true
            kubectl --namespace "$KUBE_NAMESPACE" apply -R -f /kube/source
        """
	}
}
