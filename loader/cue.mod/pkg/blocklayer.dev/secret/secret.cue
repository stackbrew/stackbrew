package secret

import (
	"blocklayer.dev/unix"
)

#Secret: {
	encrypted: string

	#host: unix.#Host

	#decrypt: {
		#base64: #host.#exec & {
			name: "base64"
			flag: "-d": true
			stdin: encrypted
			stdout: string
			error: _
		}
		result: #base64.stdout
		error: #base64.error
	}
}

