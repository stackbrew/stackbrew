package http

import (
    "blocklayer.dev/bl"
    "encoding/json"
    "strconv"
)

Get:    Do & {method: "GET"}
Post:   Do & {method: "POST"}
Put:    Do & {method: "PUT"}
Delete: Do & {method: "DELETE"}

Do :: {
    url:  string
    method: "GET" | "POST" | "PUT" | "DELETE" | "PATH" | "HEAD"

    request: {
        body: string | *""
        header: [string]: string | [...string]
        token?: bl.Secret
    }

    output: [string]: string
    response: {
        body: output["/response"]
        statusCode: strconv.Atoi(output["/status"])
    }

    bl.BashScript & {
        runPolicy: "always"
        os: package: curl: true
        input: {
            "/method":  method
            "/headers": json.Marshal(request.header)
            if (request.token & bl.Secret) != _|_ {
                "/token": request.token
            }
            "/body": request.body
            "/url":  url
        }
        output: {
            "/response": string
            "/status": string
        }
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

            curl "${curlArgs[@]}" > /status
            """#
    }
}
