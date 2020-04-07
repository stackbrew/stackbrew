package eks

import (
	"b.l/bl"
	"stackbrew.io/aws"
)

// AuthConfig config outputs a valid kube-auth-config for kubectl client
AuthConfig :: {
	// AWS Config
	config: aws.Config

	// EKS cluster name
	eksClusterName: string

	out: run.output["/outputs/auth"]

	run: bl.BashScript & {
		input: {
			"/inputs/aws/access_key": config.accessKey
			"/inputs/aws/secret_key": config.secretKey
			"/inputs/cluster_name":   eksClusterName
			"/cache/aws":             bl.Cache
		}

		output: "/outputs/auth": string

		os: {
			package: {
				python:    true
				coreutils: true
			}

			extraCommand: [
				"apk add --no-cache py-pip && pip install awscli && apk del py-pip",
			]
		}

		environment: {
			AWS_DEFAULT_REGION: config.region
			AWS_CONFIG_FILE:    "/cache/aws/config"
		}

		code: """
            export AWS_ACCESS_KEY_ID="$(cat /inputs/aws/access_key)"
            export AWS_SECRET_ACCESS_KEY="$(cat /inputs/aws/secret_key)"

            aws eks update-kubeconfig --name "$(cat /inputs/cluster_name)"
            cp ~/.kube/config /outputs/auth
        """
	}
}

// Deployment of a kubernetes configuration on an AWS EKS cluster
Deployment :: {
	// AWS Config
	config: aws.Config

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
			"/kube/config.yaml":      kubeConfigYAML
			"/kube/auth":             kubeAuthConfig
			"/kube/namespace":        namespace
			"/inputs/aws/access_key": config.accessKey
			"/inputs/aws/secret_key": config.secretKey
		}

		os: {
			package: {
				curl:      true
				python:    true
				coreutils: true
			}

			extraCommand: [
				"apk add --no-cache py-pip && pip install awscli && apk del py-pip",
				"curl -L https://dl.k8s.io/\(version)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl",
			]
		}

		environment: {
			AWS_DEFAULT_REGION: config.region
			AWS_CONFIG_FILE:    "/cache/aws/config"
		}

		code: """
            export AWS_ACCESS_KEY_ID="$(cat /inputs/aws/access_key)"
            export AWS_SECRET_ACCESS_KEY="$(cat /inputs/aws/secret_key)"
            export KUBECONFIG=/kube/auth

            namespace="$(cat /kube/namespace)"
            kubectl create namespace "$namespace" || true
            kubectl --namespace "$namespace" apply -f /kube/config.yaml
        """
	}
}
