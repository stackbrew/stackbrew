package bl

import (
	"strings"
)

// BashScript is a helper to run bash scripts within an alpine environment.
BashScript :: {
	code: string
	os: {
		alpineVersion: "latest"
		alpineDigest:  "sha256:ab00606a42621fb68f2ed6ad3c88be54397f981a7b70a79db3d1172b11c4367d"

		package: [pkg=string]: true
		package: bash:         true // always install bash
		package: jq:           true // always install jq

		extraCommand: [...string]
	}

	Run & {
		fs: build.image
		input: "/entrypoint.sh": code
		command: [
			"/bin/bash",
			"--noprofile",
			"--norc",
			"-xeo",
			"pipefail",
			"/entrypoint.sh",
		]
	}

	build: {
		// FIXME: this should be Build &``
		// However, this doesn't work with cue 0.0.15
		Build

		dockerfile: """
			from alpine:\(os.alpineVersion)@\(os.alpineDigest)

			\(strings.Join([ for pkg, _ in os.package {
				"run apk add -U --no-cache \(pkg)" }
		], "\n"))

			\(strings.Join([ for cmd in os.extraCommand {
			"run \(cmd)" }
		], "\n"))
			"""
	}
}
