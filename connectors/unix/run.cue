import (
	"strings"
)

// Platform-intependent interface to Unix operating system functionality.
#Host: {
	#ID: string

	// Best-effort storage of performance-sensitive data
	cache: {

	}

	// Runtime interface (core primitives)
	// Runtime is not sandboxed.
	runtime: _

	// Internal variables
	var: {
		
	}

	// Connector configuration
	config: {

	}

	#mkdir : {
		#path: [string, ...string]
		#create: bool | *true

		error: {
			@task(exec)

			if #create {
				flag: "-p": true
			}
			cmd: ["mkdir", strings.Join(#path, "/")]
			error: _
		}.error
	}
	
	#ls: {
		#path: [string, ...string]
	
		#exec: {
			@task(exec)
			cmd: ["ls", strings.Join(#path, "/")]
			stdout: string
		}
	
		files: strings.Split(#exec.stdout, "\n")
	}
	
	#run : {
		cmd: [string, ...string] | string

		#stdin?: string
	
		#exec: {
			@task(exec)
			if (cmd & string) != _|_ {
				"cmd": ["sh", "-c", cmd]
			}
			if (cmd & [...string]) != _|_ {
				"cmd": cmd
			}
			if (#stdin & string) != _|_ {
				"stdin": #stdin
			}
			if (stdout & string) != _|_ {
				"stdout": stdout
			}
			if (stderr & string) != _|_ {
				"stderr": stderr
			}
			error: _
		}
	
		error: #exec.error
		stdout?: string
		stderr?: string
	}
}
