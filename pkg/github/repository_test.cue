package github

import (
    "stackbrew.io/bash"
    "stackbrew.io/secret"
)

TestConfig: githubToken: secret.Secret

TestRepository: {
    repository: Repository & {
        name:  "gh-test"
        owner: "stackbrew-test"
        token: TestConfig.githubToken
    }

    pr: repository.GetPullRequest & {
        number: 2
    }

    checkout: CheckoutPullRequest & {
        pullRequest: pr.pullRequest
        token: TestConfig.githubToken
    }

    test: bash.BashScript & {
        runPolicy: "always"
        input: "/checkout": checkout.out
        code: """
        grep -q "FROM PR2" /checkout/README.md
        """
    }
}
