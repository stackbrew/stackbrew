package gcr

import (
	"encoding/base64"

	"stackbrew.io/bash"
	"stackbrew.io/container"
	"stackbrew.io/googlecloud"
	"stackbrew.io/secret"
)

// Credentials retriever for GCR
Credentials :: {

	// GCP Config
	config: googlecloud.Config

	// Target is the GCR image
	target: string

	// Registry Credentials
	credentials: container.RegistryCredentials & {
		username: output["/outputs/username"]
		"secret":   secret.Secret & {
			// FIXME: we should be able to output a secret.Secret directly
			value: base64.Encode(null, output["/outputs/secret"])
		}
	}

	// Authentication for GCR Registries
	auth: container.RegistryAuth
	auth: "\(target)": credentials

	helperUrl:
		"https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v2.0.1/docker-credential-gcr_linux_amd64-2.0.1.tar.gz"

	output: _
	bash.BashScript & {
		runPolicy: "always"

		input: {
			"/inputs/gcp/service_key": config.serviceKey
			"/inputs/target":          target
		}

		output: {
			"/outputs/username": string

			// FIXME: this should be secret.Secret
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
