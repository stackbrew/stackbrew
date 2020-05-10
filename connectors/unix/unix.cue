package unix

import (
	"strings"
)

// A connector is a program which can execute tasks specified in Cue definitions,
// and return the result as another, more complete definition.
#Connector: {

	// ID of the current connector instance
	ID: string

	// Best-effort storage of performance-sensitive data
	cache: {

	}

	// Reliable storage of internal variables
	var: {

	}

	// Connector configuration
	config: {

	}

	#mkdir : {
	
		#path: [string, ...string]
		#create: bool | *true
	
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
}
