package cloudformation

import (
	"strings"

	"stackbrew.io/aws"
    "stackbrew.io/bash"
    "stackbrew.io/fs"
)

// AWS CloudFormation Stack
Stack :: {

	// AWS Config
	config: aws.Config

	// Source is the Cloudformation template, either a Cue struct or a JSON/YAML string
	source: string

	// Stackname is the cloudformation stack
	stackName: string

	// Stack parameters
	parameters: [string]: string

	// Output of the stack apply
	stackOutput: run.output["/outputs/stack_output"]

	run: bash.BashScript & {
		input: {
			"/inputs/aws/access_key": config.accessKey
			"/inputs/aws/secret_key": config.secretKey
			"/cache/aws":             fs.Cache
			"/inputs/source":         source
			"/inputs/stack_name":     stackName
			if len(parameters) > 0 {
				"/inputs/parameters": strings.Join([ "\(key)=\(val)" for key, val in parameters ], " ")
			}
		}

		output: "/outputs/stack_output": string

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

            aws cloudformation validate-template --template-body file:///inputs/source
            stack_name="$(cat /inputs/stack_name)"

            parameters=""
            if [ -f /inputs/parameters ]; then
                parameters="--parameter-overrides $(cat /inputs/parameters)"
            fi

            aws cloudformation deploy \
                --stack-name "$stack_name" \
                --template-file "/inputs/source" \
                --capabilities CAPABILITY_IAM \
                --no-fail-on-empty-changeset \
                $parameters \
            |& tee /tmp/out

            # Check if update-stack failed.
            # If it failed because there's nothing to update, carry on.
            # Otherwise, fail the task now.
            exit_code=${PIPESTATUS[0]}
            if [ $exit_code -ne 0 ]; then
                cat /tmp/out
                grep -q "No changes to deploy" /tmp/out
                [ $? -ne 0 ] && exit $exit_code
            fi

            aws cloudformation describe-stacks \
                --stack-name "$stack_name" \
                --query 'Stacks[].Outputs' \
                --output json > /outputs/stack_output
        """#
	}
}
