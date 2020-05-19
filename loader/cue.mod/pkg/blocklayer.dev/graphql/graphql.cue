package graphql

import (
	"encoding/json"

	"blocklayer.dev/exec"
)

#Endpoint : {
	#ID: string

	url: string
	header: [string]: string

	#Query: {
		#query: string

		result: json.Unmarshal(#curl.stdout).data
		error: #curl.error

		#curl: exec.#Exec & {
			flag: "-X": "POST"
			flag: "--silent": true
			for k, v in header {
				flag: "-H": "\(k): \(v)": true
			}
			cmd: ["curl", url] 
			stdout: string
			error: _
		}
	}
}
