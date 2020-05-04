package http

import (
    "blocklayer.dev/bl"
    "encoding/json"
)

TestRequest: {
    req: Get & {
        url: "https://api.github.com/"
        request: header: {
            "Accept": "application/json"
            "Test": ["A", "B"]
        }
    }

    testRaw: bl.BashScript & {
        environment: STATUS: "\(req.response.statusCode)"
        input: "/content.json": req.response.body
        code: """
            test "$STATUS" = 200
            test "$(cat /content.json | jq -r .current_user_url)" = "https://api.github.com/user"
            """
    }

    testJSON: bl.BashScript & {
        environment: STATUS: "\(req.response.statusCode)"
        environment: CONTENT: json.Unmarshal(req.response.body).current_user_url
        code: """
            test "$STATUS" = 200
            test "$CONTENT" = "https://api.github.com/user"
            """
    }
}
