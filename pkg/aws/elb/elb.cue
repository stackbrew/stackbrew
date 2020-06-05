package elb

import (
	"strconv"
	"strings"

	"blocklayer.dev/bl"
	"stackbrew.io/aws"
)

// Returns a non-taken rule priority
NextRulePriority :: {

	// AWS Config
	config: aws.Config

	// ListenerArn
	listenerArn: string

	// Optional vhost for reusing priorities
	vhost: string | *""

	// Priority number
	priority: strconv.Atoi(strings.TrimRight(output["/outputs/priority"], "\n"))

	output: _
	bl.BashScript & {
		runPolicy: "always"

		input: {
			"/inputs/aws/access_key": config.accessKey
			"/inputs/aws/secret_key": config.secretKey
			"/inputs/listenerArn":    listenerArn
			"/inputs/vhost":          vhost
			"/cache/aws":             bl.Cache
		}

		output: "/outputs/priority": string

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

            if [ -s /inputs/vhost ]; then
                # We passed a vhost as input, try to recycle priority from previously allocated vhost
                vhost="$(cat /inputs/vhost)"

                priority=$(aws elbv2 describe-rules --no-paginate \
                    --listener-arn "$(cat /inputs/listenerArn)" | \
                    jq -r --arg vhost "$vhost" '.Rules[] | select(.Conditions[].HostHeaderConfig.Values[] == $vhost) | .Priority')

                if [ -n "${priority}" ]; then
                    echo -n "${priority}" > /outputs/priority
                    exit 0
                fi
            fi

            # Find the next priority available that we can allocate
            aws elbv2 describe-rules --no-paginate \
                --listener-arn "$(cat /inputs/listenerArn)" \
                | jq '[ .Rules[].Priority | select(. != "default") | tonumber ] | max + 1' \
                > /outputs/priority
            """#
	}
}
