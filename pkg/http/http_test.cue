package http

import (
    "b.l/bl"
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
        input: "/content.json": req.response.body
        code: """
            test "$(cat /content.json | jq -r .current_user_url)" = "https://api.github.com/user"
            """
    }

    testJSON: bl.BashScript & {
        environment: CONTENT: json.Unmarshal(req.response.body).current_user_url
        code: """
            test "$CONTENT" = "https://api.github.com/user"
            """
    }
}
