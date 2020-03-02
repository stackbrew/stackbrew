package yarn

import (
	"strings"

	"b.l/bl"
)

// A javascript application built by Yarn
App :: {
	// Source code of the javascript application
	source: bl.Directory

	// Load the contents of `environment` into the yarn process?
	loadEnv: bool | *true

	// Set these environment variables during the build
	environment: [string]: string

	// Run this yarn script
	yarnScript: string | *"build"
	
	// Write the contents of `environment` to this file,
	// in the "envfile" format.
	writeEnvFile:   string | *""

	// Read build output from this directory
	// (path must be relative to working directory).
	buildDirectory: string | *"build"

	// Execute this script to build the app
	action: build: bl.BashScript & {
		code: """
			yarn install --network-timeout 1000000
			yarn run "$YARN_BUILD_SCRIPT"
			"""

		if loadEnv {
			environment: environment
		}
		environment: {
			YARN_BUILD_SCRIPT: yarnScript
			YARN_CACHE_FOLDER: "/cache/yarn"
		}

		workdir: "/src"
		mount: "/src": {
			type: "copy"
			from: source
		}
		mount: "/cache/yarn": {
			type: "cache"
		}

		if writeEnvFile != "" {
			mount: writeEnvFile: {
				type: "text"
				contents: strings.Join(["\(k)=\(v)" for k, v in environment], "\n")
			}
		}

		os: package: {
			rsync: true
			yarn: true
		}
	}

	// Output of yarn build
	// FIXME: prevent escaping /src with ..
	build: bl.Directory & {
		root: action.build.rootfs
		path: action.build.workdir + "/" + buildDirectory
	}
}

