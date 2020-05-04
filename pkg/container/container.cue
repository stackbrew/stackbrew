// Run, build and transfer linux containers
package container

import (
	"stackbrew.io/fs"
	"stackbrew.io/secret"
)

// Task is the interface implemented by the core actions (Build, Run, Push).
Task :: {
	$bl: string

	status: "completed" | "error" | "cancelled" | "cached" | "skipped"
}

// Build takes a Dockerfile and/or a build context and produces an OCI image as
// a Directory.
Build :: {
	Task & {
		$bl: "bl.Build"
	}

	// We accept either a context, a Dockerfile or both together
	context?:    fs.Directory
	dockerfile?: string

	// credentials for the registry (optional)
	// used to pull images in `FROM` statements
	auth: RegistryAuth

	platform?: string | [...string]
	buildArg?: [string]: string
	label?: [string]:    string
	secret?: [string]:   secret.Secret

	image: fs.Directory
}

// Run executes `command` inside the filesystem `fs`
Run :: {
	Task & {
		$bl: "bl.Run"
	}

	"fs": fs.Directory

	command: string | [...string]
	environment: [string]: string
	workdir:   string | *"/"
	runPolicy: *"onChange" | "always" | "never"

	input: [path=string]:  fs.Directory | string | bytes | fs.Cache | secret.Secret
	output: [path=string]: fs.Directory | string | bytes
}

// Push exports the `source` directory to the `target` registry
Push :: {
	Task & {
		$bl: "bl.Push"
	}

	source: fs.Directory
	target: string

	// credentials for the registry (optional)
	auth: RegistryAuth

	// ref will be filled in with the canonical push reference
	ref: string
}

// Push exports the `source` directory to the `target` registry
Pull :: {
	Task & {
		$bl: "bl.Pull"
	}

	// registry ref to pull
	ref: string

	// credentials for the registry (optional)
	auth: RegistryAuth

	// image will be filled with the container image
	image: fs.Directory
}

// RegistryCredentials encodes Docker Registry credentials
RegistryCredentials :: {
	username: string
	secret:   secret.Secret
}

// RegistryAuth maps registry hosts to credentials
RegistryAuth :: [host=string]: RegistryCredentials
