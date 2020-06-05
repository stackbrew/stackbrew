package s3

import (
	"blocklayer.dev/bl"
	"stackbrew.io/aws"
)

// S3 file or Directory upload
#Put: {

	// AWS Config
	config: aws.#Config

	// Source Directory, File or String to Upload to S3
	source: string | bl.Directory

	// Target S3 URL (eg. s3://<bucket-name>/<path>/<sub-path>)
	target: string

	// URL of the uploaded S3 object
	url: run.output["/outputs/url"]

	run: bl.BashScript & {
		runPolicy: "always"

		input: {
			"/inputs/aws/access_key": config.accessKey
			"/inputs/aws/secret_key": config.secretKey
			"/inputs/source":         source
			"/inputs/target":         target
			"/cache/aws":             bl.Cache
		}

		output: "/outputs/url": string

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

		code: #"""
            export AWS_ACCESS_KEY_ID="$(cat /inputs/aws/access_key)"
            export AWS_SECRET_ACCESS_KEY="$(cat /inputs/aws/secret_key)"

            opts=""
            if [ -d /inputs/source ]; then
                opts="--recursive"
            fi
            aws s3 cp $opts /inputs/source "$(cat /inputs/target)"
            cat /inputs/target \
                | sed -E 's=^s3://([^/]*)/=https://\1.s3.amazonaws.com/=' \
                > /outputs/url
        """#
	}
}
