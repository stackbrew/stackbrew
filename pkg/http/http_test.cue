package http

import (
    "b.l/bl"
    "encoding/json"
)

TestRequest: {
    req: Get & {
        header: "Accept": "application/json"
        header: "Test": ["A", "B"]
        url: "https://api.github.com/"
    }

    testRaw: bl.BashScript & {
        input: "/content.json": req.response
        code: """
            test "$(cat /content.json | jq -r .current_user_url)" = "https://api.github.com/user"
            """
    }

    testJSON: bl.BashScript & {
        environment: CONTENT: json.Unmarshal(req.response).current_user_url
        code: """
            test "$CONTENT" = "https://api.github.com/user"
            """
    }
}
