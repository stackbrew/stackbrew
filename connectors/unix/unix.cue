package unix

import (
	"strings"
)

mkdir : {

	request: {
		path: [string, ...string]
		create: bool | *true
	}

	// Exec is a builtin, always available
	exec: {
		#createArgs: ["-p"] | *[]
		if request.create {
			#createArgs: ["-p"]
		}
		cmd: ["mkdir", strings.Join(request.path, "/")] + #createArgs
		error: _
	}

	response: {
		error: exec.error
	}
}

ls: {

	request: {
		path: [string, ...string]
	}

	exec: {
		cmd: ["ls", strings.Join(request.path)]
		stdout: string
	}

	response: {
		files: strings.Split(stdout, "\n")
	}
}

run : {
	request: {
		cmd: [string, ...string]
		stdout: true
		stderr: true
	}

	exec: {
		cmd: request.cmd
		if request.stdout {
			stdout: string
		}
		if request.stderr {
			stderr: string
		}
		error: _
	}

	response: {
		error: exec.error
		if request.stdout {
			stdout: exec.stdout
		}
		if request.stderr {
			stderr: exec.stderr
		}
	}
}
