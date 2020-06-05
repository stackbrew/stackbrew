package eks

import (
	"blocklayer.dev/bl"
	"stackbrew.io/aws"
	"encoding/base64"
)

// KubeConfig config outputs a valid kube-auth-config for kubectl client
#KubeConfig: {
	// AWS Config
	config: aws.#Config

	// EKS cluster name
	cluster: string

	// kubeconfig is the generated kube configuration file
	kubeconfig: bl.Secret & {
		// FIXME: we should be able to output a bl.Secret directly
		value: base64.Encode(null, run.output["/outputs/kubeconfig"])
	}

	run: bl.BashScript & {
		runPolicy: "always"

		input: {
			"/inputs/access_key": config.accessKey
			"/inputs/secret_key": config.secretKey
			"/cache/aws":         bl.Cache
		}

		output: "/outputs/kubeconfig": string

		os: {
			package: {
				python: true
				curl:   true
			}

			extraCommand: [
				"apk add --no-cache py-pip && pip install awscli && apk del py-pip",
				"curl -L https://dl.k8s.io/v1.14.7/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl",
			]
		}

		environment: {
			AWS_CONFIG_FILE:    "/cache/aws/config"
			AWS_DEFAULT_REGION: config.region
			EKS_CLUSTER:        cluster
		}

		code: #"""
            export KUBECONFIG=/outputs/kubeconfig
            export AWS_ACCESS_KEY_ID="$(cat /inputs/access_key)"
            export AWS_SECRET_ACCESS_KEY="$(cat /inputs/secret_key)"

            # Generate a kube configiration
            aws eks update-kubeconfig --name "$EKS_CLUSTER"

            # Figure out the kubernetes username
            CONTEXT="$(kubectl config current-context)"
            USER="$(kubectl config view -o json | \
                jq -r ".contexts[] | select(.name==\"$CONTEXT\") | .context.user")"

            # Grab a kubernetes access token
            ACCESS_TOKEN="$(aws eks get-token --cluster-name "$EKS_CLUSTER" | \
                jq -r .status.token)"

            # Remove the user config and replace it with the token
            kubectl config unset "users.${USER}"
            kubectl config set-credentials "$USER" --token "$ACCESS_TOKEN"
        """#
	}
}
