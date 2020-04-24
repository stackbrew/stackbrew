package http

import (
	"b.l/bl"
	"encoding/json"
)

Get:    Request & {method: "GET"}
Post:   Request & {method: "POST"}
Put:    Request & {method: "PUT"}
Delete: Request & {method: "DELETE"}

Request :: {
	url:  string
	body: string | *""
	header: [string]: string | [...string]
	token?: bl.Secret
	method: "GET" | "POST" | "PUT" | "DELETE" | "PATH" | "HEAD"

	output: [string]: string
	response: output["/response"]

	bl.BashScript & {
		runPolicy: "always"
		os: package: curl: true
		input: {
			"/method":  method
			"/headers": json.Marshal(header)
			if (token & bl.Secret) != _|_ {
				"/token": token
			}
			"/body": body
			"/url":  url
		}
		output: "/response": string
		code:
			#"""
			curlArgs=(
				"$(cat /url)"
				-L --fail --silent --show-error
				--write-out "%{http_code}"
				-X "$(cat /method)"
				-d "$(cat /body)"
				-o /response
			)

			headers="$(cat /headers | jq -r 'to_entries | map(.key + ": " + (.value | tostring) + "\n") | add')"
			while read h; do
				curlArgs+=("-H" "$h")
			done <<< "$headers"

			if [ -e /token ]; then
				curlArgs+=("-H" "Authorization: bearer $(cat /token)")
			fi

			curl "${curlArgs[@]}"
			"""#
	}
}
