package gke

import (
	"b.l/bl"
	"stackbrew.io/googlecloud"
)

// AuthConfig config outputs a valid kube-auth-config for kubectl client
AuthConfig :: {
	// GCP Config
	config: googlecloud.Config

	// GKE cluster name
	gkeClusterName: string

	out: run.output["/outputs/auth"]

	run: bl.BashScript & {
		input: {
			"/inputs/service_key": config.serviceKey
			"/cache/googlecloud":  bl.Cache
		}

		output: "/outputs/auth": string

		os: {
			package: {
				python:    true
				coreutils: true
				curl:      true
			}

			extraCommand: [
				"curl https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-288.0.0-linux-x86_64.tar.gz | tar -C /var -zx",
			]
		}

		environment: {
			CLOUDSDK_CONFIG: "/cache/gcloud/gcloud-config"
			GKE_REGION:      config.region
			GKE_PROJECT:     config.project
			GKE_CLUSTER:     gkeClusterName
		}

		code: """
        export PATH="/var/google-cloud-sdk/bin:${PATH}"

        gcloud -q auth activate-service-account --key-file=/inputs/service_key
        gcloud -q config set project "$GKE_PROJECT"
        gcloud -q config set compute/zone "$GKE_REGION"

        gcloud -q container clusters get-credentials "$GKE_CLUSTER"

        cp ~/.kube/config /outputs/auth
        """
	}
}

// Deployment of a kubernetes configuration on an GKE cluster
Deployment :: {
	// GCP Config
	config: googlecloud.Config

	// Kubernetes config to deploy
	kubeConfigYAML: string

	// Kubernetes Namespace to deploy to
	namespace: string

	// Version of kubectl client
	version: *"v1.14.7" | string

	// Kube auth config file
	kubeAuthConfig: string

	deploy: bl.BashScript & {
		runPolicy: "always"

		input: {
			"/kube/config.yaml":   kubeConfigYAML
			"/kube/auth":          kubeAuthConfig
			"/inputs/service_key": config.serviceKey
			"/cache/googlecloud":  bl.Cache
		}

		os: {
			package: {
				curl:      true
				python:    true
				coreutils: true
			}

			extraCommand: [
				"curl https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-288.0.0-linux-x86_64.tar.gz | tar -C /var -zx",
				"curl -L https://dl.k8s.io/\(version)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl",
			]
		}

		environment: {
			CLOUDSDK_CONFIG: "/cache/gcloud/gcloud-config"
			GKE_REGION:      config.region
			GKE_PROJECT:     config.project
			KUBE_NAMESPACE:  namespace
		}

		code: """
            export PATH="/var/google-cloud-sdk/bin:${PATH}"

            gcloud -q auth activate-service-account --key-file=/inputs/service_key
            gcloud -q config set project "$GKE_PROJECT"
            gcloud -q config set compute/zone "$GKE_REGION"

            export KUBECONFIG=/kube/auth

            kubectl create namespace "$KUBE_NAMESPACE" || true
            kubectl --namespace "$KUBE_NAMESPACE" apply -f /kube/config.yaml
        """
	}
}
