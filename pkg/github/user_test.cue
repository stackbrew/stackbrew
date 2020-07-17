package github

import (
	"blocklayer.dev/bl"
)

TestConfig: githubToken: bl.#Secret

TestViewer: {
	query: #GetViewer & {
		token: TestConfig.githubToken
	}

	test: bl.#BashScript & {
		runPolicy: "always"
		environment: login: query.user.login
		code: """
        test "$login" = "stackbrew-test"
        """
	}
}
