package elasticbeanstalk

import (
	"blocklayer.dev/bl"

	"stackbrew.io/aws"
)

// Elastic Beanstalk Application
Application :: {

	// AWS Config
	config: aws.Config

	// Beanstalk application name
	applicationName: string

	out: run.output["/outputs/out"]

	run: bl.BashScript & {
		input: {
			"/inputs/aws/access_key": config.accessKey
			"/inputs/aws/secret_key": config.secretKey
			"/cache/aws":             bl.Cache
		}

		output: "/outputs/out": string

		os: {
			package: {
				python:        true
				coreutils:     true
				"build-base":  true
				"python-dev":  true
				"libffi-dev":  true
				"openssl-dev": true
			}

			extraCommand: [
				"apk add --no-cache py-pip && pip install awsebcli==3.17.1 awscli==1.17.17",
			]
		}

		environment: {
			AWS_DEFAULT_REGION: config.region
			AWS_CONFIG_FILE:    "/cache/aws/config"
			AWS_DEFAULT_OUTPUT: "json"
			APPLICATION_NAME:   applicationName
		}

		code: #"""
            export AWS_ACCESS_KEY_ID="$(cat /inputs/aws/access_key)"
            export AWS_SECRET_ACCESS_KEY="$(cat /inputs/aws/secret_key)"

            # the platform arg -p is used to force the non-interactive mode but is only stored locally
            eb init -r "$AWS_DEFAULT_REGION" -p python "$APPLICATION_NAME"
            echo -n "$APPLICATION_NAME" > /outputs/out
        """#
	}
}

// Elastic Beanstalk Environment
Environment :: {

	// AWS Config
	config: aws.Config

	// Source code to deploy
	source: bl.Directory

	// Beanstalk environment name
	environmentName: string

	// Application name
	applicationName: string

	// Elastic Beanstalk platform to use
	platform: string

	// Environment create options; check `eb create --help`
	createOptions: {
		cname?:            string
		tier?:             string
		instance_type?:    string
		instance_profile?: string
		service_role?:     string
		keyname?:          string
		scale?:            string
		elb_type?:         string
	}

	out:   run.output["/outputs/out"]
	cname: run.output["/outputs/cname"]

	run: bl.BashScript & {
		input: {
			"/inputs/aws/access_key": config.accessKey
			"/inputs/aws/secret_key": config.secretKey
			"/cache/aws":             bl.Cache
			"/inputs/source":         source

			// Maps createOptions optionnally
			for k, v in createOptions {
				if (k & string) != _|_ {
					"/inputs/opts/\(k)": v
				}
			}
		}

		output: {
			"/outputs/out":   string
			"/outputs/cname": string
		}

		os: {
			package: {
				python:        true
				coreutils:     true
				"build-base":  true
				"python-dev":  true
				"libffi-dev":  true
				"openssl-dev": true
				jq:            true
			}

			extraCommand: [
				"apk add --no-cache py-pip && pip install awsebcli==3.17.1 awscli==1.17.17",
			]
		}

		environment: {
			AWS_DEFAULT_REGION: config.region
			AWS_CONFIG_FILE:    "/cache/aws/config"
			AWS_DEFAULT_OUTPUT: "json"
			APPLICATION_NAME:   applicationName
			ENVIRONMENT_NAME:   environmentName
			PLATFORM:           platform
		}

		code: #"""
            export AWS_ACCESS_KEY_ID="$(cat /inputs/aws/access_key)"
            export AWS_SECRET_ACCESS_KEY="$(cat /inputs/aws/secret_key)"

            application="$APPLICATION_NAME"
            application_arn=$(
                aws elasticbeanstalk describe-applications --application-names "$application" |
                jq -r '.Applications[].ApplicationArn'
            )
            if [ -z "$application_arn" ]; then
                echo "The application \"$application\" does not exist"
                exit 1
            fi

            # eb create --help
            args=()
            [ -f /inputs/opts/cname ] && args+=( --cname "$(cat /inputs/opts/cname)" )
            [ -f /inputs/opts/tier ] && args+=( --tier "$(cat /inputs/opts/tier)" )
            [ -f /inputs/opts/instance_type ] && args+=( --instance_type "$(cat /inputs/opts/instance-type)" )
            [ -f /inputs/opts/instance_profile ] && args+=( --instance_profile "$(cat /inputs/opts/instance-profile)" )
            [ -f /inputs/opts/service_role ] && args+=( --service-role "$(cat /inputs/opts/service-role)" )
            [ -f /inputs/opts/keyname ] && args+=( --keyname "$(cat /inputs/opts/keyname)" )
            [ -f /inputs/opts/scale ] && args+=( --scale "$(cat /inputs/opts/scale)" )
            [ -f /inputs/opts/elb-type ] && args+=( --elb-type "$(cat /inputs/opts/elb-type)" )

            environment="$ENVIRONMENT_NAME"
            platform="$PLATFORM"
            cp -r /inputs/source /tmp/code
            (
                cd /tmp/code
                # if it's a git repos, remove it to force the push to S3 (instead of CodeCommit)
                [ -d .git ] && rm -rf .git
                eb init -r "$AWS_DEFAULT_REGION" -p "$platform" "$application"

                env_arn=$(
                    aws elasticbeanstalk describe-environments \
                        --application-name "$application" \
                        --environment-names "$environment" |
                        jq -r '.Environments[].EnvironmentArn'
                )
                if [ -z "$env_arn" ]; then
                    # The env does not exist, create it
                    eb create -r "$AWS_DEFAULT_REGION" "${args[@]}" "$environment"
                else
                    # The env already exists, just do a deploy to avoid failure
                    eb deploy "$environment"
                fi
            )

            aws elasticbeanstalk describe-environments \
                --application-name "$application" \
                --environment-names "$environment" | \
                jq -r '.Environments[].CNAME' > /outputs/cname
             echo -n "$environment" > /outputs/out
        """#
	}
}

// Elastic Beanstalk Deployment
Deployment :: {

	// AWS Config
	config: aws.Config

	// Source code to deploy
	source: bl.Directory

	// Beanstalk environment name
	environmentName: string

	// Application name
	applicationName: string

	cname: run.output["/outputs/cname"]

	run: bl.BashScript & {
		input: {
			"/inputs/aws/access_key": config.accessKey
			"/inputs/aws/secret_key": config.secretKey
			"/cache/aws":             bl.Cache
			"/inputs/source":         source
		}

		output: "/outputs/cname": string

		os: {
			package: {
				python:        true
				coreutils:     true
				"build-base":  true
				"python-dev":  true
				"libffi-dev":  true
				"openssl-dev": true
			}

			extraCommand: [
				"apk add --no-cache py-pip && pip install setuptools awsebcli==3.17.1 awscli==1.17.17",
			]
		}

		environment: {
			AWS_DEFAULT_REGION: config.region
			AWS_CONFIG_FILE:    "/cache/aws/config"
			AWS_DEFAULT_OUTPUT: "json"
			APPLICATION_NAME:   applicationName
			ENVIRONMENT_NAME:   environmentName
		}

		code: #"""
            export AWS_ACCESS_KEY_ID="$(cat /inputs/aws/access_key)"
            export AWS_SECRET_ACCESS_KEY="$(cat /inputs/aws/secret_key)"

            application="$APPLICATION_NAME"
            environment="$ENVIRONMENT_NAME"
            platform=$(
                aws elasticbeanstalk describe-environments \
                    --application-name "$application" \
                    --environment-names "$environment" |
                    jq -r '.Environments[].PlatformArn'
            )
            if [ -z "$platform" ]; then
                echo "The application \"$application\" and/or environment \"$environment\" do not exist"
                exit 1
            fi

            cp -r /inputs/source /tmp/code
            (
                cd /tmp/code
                # if it's a git repos, remove it to force the push to S3 (instead of CodeCommit)
                [ -d .git ] && rm -rf .git
                eb init -r "$AWS_DEFAULT_REGION" -p "$platform" "$application"
                eb deploy "$environment"
            )

            aws elasticbeanstalk describe-environments \
                --application-name "$application" \
                --environment-names "$environment" | \
                jq -r '.Environments[].CNAME' > /outputs/cname
        """#
	}
}
