package secret

import (
	"blocklayer.dev/exec"
)

#Secret: {
	encrypted: string
	#decrypt: {
		#run: exec.#Exec & {
			cmd: ["base64", "-d"]
			stdin: encrypted
			stdout: string
			error: _
		}
		result: #run.stdout
		error: #run.error
	}
}

