package graphql

import (
	"encoding/json"

	"blocklayer.dev/unix"
)

#Endpoint : {
	#ID: string

	url: string
	header: [string]: string

	#Query: {
		#query: string

		result: json.Unmarshal(#curl.stdout).data
		error: #curl.error

		#host: unix.#Host

		#curl: #host.#exec & {
			name: "curl"
			args: [url]
			flag: {
				"-X": "POST"
				"--silent": true
				"-H": {
					for k, v in header {
						"\(k)": "\(v)": true
					}
				}
			}
			stdout: string
			error: _
		}
	}
}
