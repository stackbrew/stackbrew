package gke

import (
	"blocklayer.dev/bl"
	"stackbrew.io/googlecloud"
	"encoding/base64"
)

// KubeConfig config outputs a valid kube-auth-config for kubectl client
#KubeConfig: {
	// GCP Config
	config: googlecloud.#Config

	// GKE cluster name
	cluster: string

	// kubeconfig is the generated kube configuration file
	kubeconfig: bl.Secret & {
		// FIXME: we should be able to output a bl.Secret directly
		value: base64.Encode(null, run.output["/outputs/kubeconfig"])
	}

	run: bl.BashScript & {
		runPolicy: "always"

		input: {
			"/inputs/service_key": config.serviceKey
			"/cache/googlecloud":  bl.Cache
		}

		output: "/outputs/kubeconfig": string

		os: {
			package: {
				python: true
				curl:   true
			}

			extraCommand: [
				"curl -S https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-288.0.0-linux-x86_64.tar.gz | tar -C /usr/local -zx",
				"curl -S -L https://dl.k8s.io/v1.14.7/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl",
			]
		}

		environment: {
			CLOUDSDK_CONFIG: "/cache/gcloud/gcloud-config"
			GCP_REGION:      config.region
			GCP_PROJECT:     config.project
			GKE_CLUSTER:     cluster
		}

		code: #"""
            export PATH="/usr/local/google-cloud-sdk/bin:${PATH}"
            export KUBECONFIG=/outputs/kubeconfig

            # Setup the gcloud environment
            gcloud -q auth activate-service-account --key-file=/inputs/service_key
            gcloud -q config set project "$GCP_PROJECT"
            gcloud -q config set compute/zone "$GCP_REGION"

            # Generate a kube configiration
            gcloud -q container clusters get-credentials "$GKE_CLUSTER"

            # Figure out the kubernetes username
            CONTEXT="$(kubectl config current-context)"
            USER="$(kubectl config view -o json | \
                jq -r ".contexts[] | select(.name==\"$CONTEXT\") | .context.user")"

            # Grab a kubernetes access token
            ACCESS_TOKEN="$(gcloud -q config config-helper --format json --min-expiry 1h | \
                jq -r .credential.access_token)"

            # Remove the user config and replace it with the token
            kubectl config unset "users.${USER}"
            kubectl config set-credentials "$USER" --token "$ACCESS_TOKEN"
            """#
	}
}
