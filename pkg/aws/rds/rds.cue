package rds

import (
	"blocklayer.dev/bl"
	"stackbrew.io/aws"
)

CreateDB :: {
	// AWS Config
	config: aws.Config

	// DB name
	name: string

	// ARN of the database instance
	dbArn: string

	// ARN of the database secret (for connecting via rds api)
	secretArn: string

	dbCreated: output["/outputs/dbCreated"]

	output: _

	bl.BashScript & {
		input: {
			"/inputs/aws/access_key": config.accessKey
			"/inputs/aws/secret_key": config.secretKey
			"/inputs/name":           name
			"/inputs/db_arn":         dbArn
			"/inputs/secret_arn":     secretArn
		}

		output: {
			"/outputs/dbCreated": string
		}

		os: {
			package: {
				python:    true
				coreutils: true
			}

			extraCommand: [
				"apk add --no-cache py-pip && pip install awscli && apk del py-pip",
			]
		}

		environment: AWS_DEFAULT_REGION: config.region

		code: #"""
            set +o pipefail

            export AWS_ACCESS_KEY_ID="$(cat /inputs/aws/access_key)"
            export AWS_SECRET_ACCESS_KEY="$(cat /inputs/aws/secret_key)"

            aws rds-data execute-statement \
                --resource-arn "$(cat /inputs/db_arn)" \
                --secret-arn "$(cat /inputs/secret_arn)" \
                --sql "CREATE DATABASE \`$(cat /inputs/name)\`" \
                --no-include-result-metadata \
            |& tee /tmp/out
            exit_code=${PIPESTATUS[0]}
            if [ $exit_code -ne 0 ]; then
                cat /tmp/out
                grep -q "database exists" /tmp/out
                [ $? -ne 0 ] && exit $exit_code
            fi
            cp /inputs/name /outputs/dbCreated
            """#
	}
}

CreateUser :: {
	// AWS Config
	config: aws.Config

	// Username
	username: string

	// Password
	password: string

	// ARN of the database instance
	dbArn: string

	// ARN of the database secret (for connecting via rds api)
	secretArn: string

	grantDatabase: string | *""

	output: _

	bl.BashScript & {
		input: {
			"/inputs/aws/access_key": config.accessKey
			"/inputs/aws/secret_key": config.secretKey
			"/inputs/username":       username
			"/inputs/password":       password
			"/inputs/db_arn":         dbArn
			"/inputs/secret_arn":     secretArn
			"/inputs/grant_database": grantDatabase
		}

		output: {
			"/outputs/username": string
			"/outputs/password": string
		}

		os: {
			package: {
				python:    true
				coreutils: true
			}

			extraCommand: [
				"apk add --no-cache py-pip && pip install awscli && apk del py-pip",
			]
		}

		environment: AWS_DEFAULT_REGION: config.region

		code: #"""
            set +o pipefail

            export AWS_ACCESS_KEY_ID="$(cat /inputs/aws/access_key)"
            export AWS_SECRET_ACCESS_KEY="$(cat /inputs/aws/secret_key)"

            aws rds-data execute-statement \
                --resource-arn "$(cat /inputs/db_arn)" \
                --secret-arn "$(cat /inputs/secret_arn)" \
                --sql "CREATE USER '$(cat /inputs/username)'@'%' IDENTIFIED BY '$(cat /inputs/password)'" \
                --no-include-result-metadata \
            |& tee tmp/out
            exit_code=${PIPESTATUS[0]}
            if [ $exit_code -ne 0 ]; then
                cat tmp/out
                grep -q "Operation CREATE USER failed for" tmp/out
                [ $? -ne 0 ] && exit $exit_code
            fi
            cp /inputs/username /outputs/username
            cp /inputs/password /outputs/password
            
            aws rds-data execute-statement \
                --resource-arn "$(cat /inputs/db_arn)" \
                --secret-arn "$(cat /inputs/secret_arn)" \
                --sql "SET PASSWORD FOR '$(cat /inputs/username)'@'%' = PASSWORD('$(cat /inputs/password)')" \
                --no-include-result-metadata
            
            if [ -s /inputs/grant_database ]; then
                aws rds-data execute-statement \
                    --resource-arn "$(cat /inputs/db_arn)" \
                    --secret-arn "$(cat /inputs/secret_arn)" \
                    --sql "GRANT ALL ON \`$(cat /inputs/grant_database)\`.* to '$(cat /inputs/username)'@'%'" \
                    --no-include-result-metadata
            fi
            """#
	}
}

Instance :: {
	// AWS Config
	config: aws.Config

	// ARN of the database instance
	dbArn: string

	hostname: output["/outputs/hostname"]
	port: output["/outputs/port"]

	output: _

	bl.BashScript & {
		input: {
			"/inputs/aws/access_key": config.accessKey
			"/inputs/aws/secret_key": config.secretKey
			"/inputs/db_arn":         dbArn
		}

		output: {
			"/outputs/hostname": string
			"/outputs/port": string
		}

		os: {
			package: {
				python:    true
				coreutils: true
			}

			extraCommand: [
				"apk add --no-cache py-pip && pip install awscli && apk del py-pip",
			]
		}

		environment: AWS_DEFAULT_REGION: config.region

		code: #"""
            export AWS_ACCESS_KEY_ID="$(cat /inputs/aws/access_key)"
            export AWS_SECRET_ACCESS_KEY="$(cat /inputs/aws/secret_key)"

            db_arn="$(cat /inputs/db_arn)"
            data=$(aws rds describe-db-clusters --filters "Name=db-cluster-id,Values=$db_arn" )
            echo "$data" | jq -j '.DBClusters[].Endpoint' > /outputs/hostname
            echo "$data" | jq -j '.DBClusters[].Port' > /outputs/port
            """#
	}
}
