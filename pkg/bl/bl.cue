package bl

// Directory is a core type representing a directory.
//
// There are multiple implementations of directory, a directory can map to a
// registry, to the local filesystem, and so on.
Directory :: {
	$bl: "bl.Directory"

	// Source for the directory.
	// FIXME: Source types should be structures rather than strings with a schema.
	// However, disjunctions between structures is currently broken:
	// https://github.com/cuelang/cue/issues/342
	Registry :: =~"^registry://"
	Context ::  =~"^context://"
	source:     Registry | Context | Directory

	path: string | *"/"
}

// Secret is a core type holding a secret value.
//
// Secrets are encrypted at rest and only decrypted on demand when passed as an
// input to a Run
Secret :: {
	$bl:   "bl.Secret"
	value: string
}

// Cache is a core type. It behaves like a directory but it's content is
// persistenly cached between runs
Cache :: {
	$bl: "bl.Cache"
	key: string | *""
}

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
	context?:    Directory
	dockerfile?: string

	// credentials for the registry (optional)
	// used to pull images in `FROM` statements
	auth: RegistryAuth

	platform?: string | [...string]
	buildArg?: [string]: string
	label?: [string]:    string
	secret?: [string]:   Secret

	image: Directory
}

// Run executes `command` inside the filesystem `fs`
Run :: {
	Task & {
		$bl: "bl.Run"
	}

	fs: Directory

	command: string | [...string]
	environment: [string]: string
	workdir:   string | *"/"
	runPolicy: *"onChange" | "always" | "never"

	input: [path=string]:  Directory | string | bytes | Cache | Secret
	output: [path=string]: Directory | string | bytes
}

// Push exports the `source` directory to the `target` registry
Push :: {
	Task & {
		$bl: "bl.Push"
	}

	source: Directory
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
	image: Directory
}

// RegistryCredentials encodes Docker Registry credentials
RegistryCredentials :: {
	username: string
	secret:   Secret
}

// RegistryAuth maps registry hosts to credentials
RegistryAuth :: [host=string]: RegistryCredentials
