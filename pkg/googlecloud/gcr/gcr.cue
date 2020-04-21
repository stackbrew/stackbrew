package gcr

import (
	"b.l/bl"
	"stackbrew.io/googlecloud"
	"encoding/base64"
)

// Credentials retriever for GCR
Credentials :: {

	// GCP Config
	config: googlecloud.Config

	// Target is the GCR image
	target: string

	// Registry Credentials
	credentials: bl.RegistryCredentials & {
		username: run.output["/outputs/username"]
		secret:   bl.Secret & {
			// FIXME: we should be able to output a bl.Secret directly
			value: base64.Encode(null, run.output["/outputs/secret"])
		}
	}

	// Authentication for GCR Registries
	// This list is hardcoded from:
	// https://github.com/GoogleCloudPlatform/docker-credential-gcr/blob/be7633a109f04f19953c4d830ec5788709c16df4/config/const.go#L50
	auth: bl.RegistryAuth
	auth: "gcr.io": credentials
	auth: "asia.gcr.io": credentials
	auth: "eu.gcr.io": credentials
	auth: "marketplace.gcr.io": credentials
	auth: "staging-k8s.gcr.io": credentials
	auth: "us.gcr.io": credentials

	helperUrl:
		"https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v2.0.1/docker-credential-gcr_linux_amd64-2.0.1.tar.gz"

	run: bl.BashScript & {
		runPolicy: "always"

		input: {
			"/inputs/gcp/service_key": config.serviceKey
			"/inputs/target":          target
		}

		output: {
			"/outputs/username": string

			// FIXME: this should be bl.Secret
			"/outputs/secret": string
		}

		os: {
			package: curl: true

			extraCommand: [
				#"""
                curl -L "\#(helperUrl)" | tar -C /usr/local/bin -zx && \
                    chmod +x "/usr/local/bin/docker-credential-gcr"
                """#,
			]
		}

		code: #"""
            export GOOGLE_APPLICATION_CREDENTIALS="/inputs/gcp/service_key"

            credentials=$(cat /inputs/target | docker-credential-gcr get)

            echo $credentials | jq -j .Username > /outputs/username
            echo $credentials | jq -j .Secret > /outputs/secret
        """#
	}
}
