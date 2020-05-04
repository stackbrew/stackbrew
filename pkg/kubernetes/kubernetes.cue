package kubernetes

import (
    "stackbrew.io/bash"
    "stackbrew.io/fs"
    "stackbrew.io/secret"
)

// Exposes `kubectl kustomize`
Kustomize :: {
	// Kubernetes config to take as input
	source: string | fs.Directory

	// Optionnal kustomization.yaml
	kustomization: *"" | string

	// Version of kubectl client
	version: *"v1.14.7" | string

	// Output of kustomize
	out: kustomize.output["/kube/out"]

	kustomize: bash.BashScript & {
		input: {
			"/kube/source": source
			"/kube/kustomization.yaml": kustomization
		}

		output: "/kube/out": string

		os: {
			package: curl: true

			extraCommand: [
				"curl -L https://dl.k8s.io/\(version)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl",
			]
		}

		code: """
            cp -a /kube/source /tmp
            if [ -s /kube/kustomization.yaml ]; then
                cp /kube/kustomization.yaml /tmp/source
            fi
            kubectl kustomize /tmp/source > /kube/out
        """
	}
}

// Apply a Kubernetes configuration
Apply :: {
	// Kubernetes config to deploy
	source: string | fs.Directory

	// Kubernetes Namespace to deploy to
	namespace: string

	// Version of kubectl client
	version: *"v1.14.7" | string

	// Kube config file
	kubeconfig: secret.Secret

	deploy: bash.BashScript & {
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
