package ssh

import (
	"strings"

	"stackbrew.io/bash"
	"stackbrew.io/secret"
)

// A SSH endpoint
Endpoint :: {
	// Endpoint hostname
	host: string

	// Endpoint TCP port
	port: int | *22

	// Endpoint user
	user: string

	// Endpoint private key
	key: secret.Secret

	// Run a command remotely on this endpoint
	RunCommand :: {
		cmd: [...string]
		stdout: output["/output/stdout"]
		stderr: output["/output/stderr"]

		output: _

		bash.BashScript & {
			input: {
				"/key": key
			}
			output: {
				"/output/stdout": string
				"/output/stderr": string
			}
			environment: {
				SSH_USER: user
				SSH_HOST: host
				SSH_PORT: "\(port)"
			}
			code:
				#"""
				ssh \
					-i /key \
					-p "$SSH_PORT" \
					-o StrictHostKeyChecking=accept-new \
					"$SSH_USER@$SSH_HOST" \
					\#(strings.Join(cmd, " ")) \
					> /output/stdout \
					2> /output/stderr
				"""#
			os: package: openssh: true
		}
	}
}
