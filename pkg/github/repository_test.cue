package github

import (
    "b.l/bl"
)

TestConfig: githubToken: bl.Secret

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

    test: bl.BashScript & {
        runPolicy: "always"
        input: "/checkout": checkout.out
        code: """
        grep -q "FROM PR2" /checkout/README.md
        """
    }
}
