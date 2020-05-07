package ecr

import (
	"blocklayer.dev/bl"
	"stackbrew.io/aws"
	"encoding/base64"
)

// Credentials retriever for ECR
Credentials :: {

	// AWS Config
	config: aws.Config

	// Target is the ECR image
	target: string

	// ECR credentials
	credentials: bl.RegistryCredentials & {
		username: output["/outputs/username"]
		secret:   bl.Secret & {
			// FIXME: we should be able to output a bl.Secret directly
			value: base64.Encode(null, output["/outputs/secret"])
		}
	}

	// Authentication for ECR Registries
	auth: bl.RegistryAuth
	auth: "\(target)": credentials

	helperUrl:
		"https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/0.4.0/linux-amd64/docker-credential-ecr-login"

	output: _

	bl.BashScript & {
		runPolicy: "always"

		input: {
			"/inputs/aws/access_key": config.accessKey
			"/inputs/aws/secret_key": config.secretKey
			"/inputs/target":         target
		}

		output: {
			"/outputs/registry": string
			"/outputs/username": string

			// FIXME: this should be bl.Secret
			"/outputs/secret": string
		}

		os: {
			package: curl: true

			extraCommand: [
				#"""
                curl -o "/usr/local/bin/docker-credential-ecr-login" \
                    "\#(helperUrl)" && \
                    chmod +x "/usr/local/bin/docker-credential-ecr-login"
                """#,
			]
		}

		environment: AWS_DEFAULT_REGION: config.region

		code: #"""
            export AWS_ACCESS_KEY_ID="$(cat /inputs/aws/access_key)"
            export AWS_SECRET_ACCESS_KEY="$(cat /inputs/aws/secret_key)"

            credentials=$(cat /inputs/target | docker-credential-ecr-login get)

            echo $credentials | jq -j .Username > /outputs/username
            echo $credentials | jq -j .Secret > /outputs/secret
            echo $credentials | \
                jq -j .ServerURL | \
                sed "s=http[s]*://==" | \
                cut -d'/' -f1 > /outputs/registry
        """#
	}
}
