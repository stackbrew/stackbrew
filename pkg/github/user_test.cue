package github

import (
    "stackbrew.io/bash"
    "stackbrew.io/secret"
)

TestConfig: githubToken: secret.Secret

TestViewer: {
    query: GetViewer & {
        token: TestConfig.githubToken
    }

    test: bash.BashScript & {
        runPolicy: "always"
        environment: login: query.user.login
        code: """
        test "$login" = "stackbrew-test"
        """
    }
}
