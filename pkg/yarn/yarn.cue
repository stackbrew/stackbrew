package yarn

import (
	"strings"

	"blocklayer.dev/bl"
)

// A javascript application built by Yarn
App :: {
	// Source code of the javascript application
	source: bl.Directory

	// Load the contents of `environment` into the yarn process?
	loadEnv: bool | *true

	// Set these environment variables during the build
	appEnv=environment: [string]: string

	// Run this yarn script
	yarnScript: string | *"build"

	// Write the contents of `environment` to this file,
	// in the "envfile" format.
	writeEnvFile: string | *""

	// Read build output from this directory
	// (path must be relative to working directory).
	buildDirectory: string | *"build"

	// Execute this script to build the app
	action: build: bl.BashScript & {
		code: """
			yarn install --network-timeout 1000000
			yarn run "$YARN_BUILD_SCRIPT"
			mv "$YARN_BUILD_DIRECTORY" /app/build
			"""

		if loadEnv {
			environment: appEnv
		}
		environment: {
			YARN_BUILD_SCRIPT:    yarnScript
			YARN_CACHE_FOLDER:    "/cache/yarn"
			YARN_BUILD_DIRECTORY: buildDirectory
		}

		workdir: "/app/src"

		input: {
			"/app/src": source
			// FIXME: set a cache key?
			"/cache/yarn": bl.Cache
			if writeEnvFile != "" {
				"/app/src/\(writeEnvFile)": strings.Join([ for k, v in appEnv { "\(k)=\(v)" } ], "\n")
			}
		}

		output: "/app/build": bl.Directory

		os: package: {
			rsync: true
			yarn:  true
		}
	}

	// Output of yarn build
	// FIXME: prevent escaping /src with ..
	build: action.build.output["/app/build"]
}
