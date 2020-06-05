package github

import (
    "blocklayer.dev/bl"
)

TestConfig: githubToken: bl.Secret

TestGetPullRequestMerged: {
    query: #GetPullRequest & {
        token:  TestConfig.githubToken
        number: 1
        repo: {
            owner: "stackbrew-test"
            name:  "gh-test"
        }
    }

    test: bl.BashScript & {
        runPolicy: "always"
        environment: state: query.pullRequest.state
        code: """
        test "$state" = "MERGED"
        """
    }
}

TestGetPullRequestOpen: {
    query: #GetPullRequest & {
        token:  TestConfig.githubToken
        number: 2
        repo: {
            owner: "stackbrew-test"
            name:  "gh-test"
        }
    }

    test: bl.BashScript & {
        runPolicy: "always"
        environment: {
            state:  query.pullRequest.state
            gitUrl: query.pullRequest.headRepository.url
            commit: query.pullRequest.headRef.target.oid
        }
        code: """
        test "$state" = "OPEN"
        test "$gitUrl" = "https://github.com/stackbrew-test/gh-test"
        test "$commit" = "16a9a0fffda42bfbab40cfba79ecef61c7343e65"
        """
    }
}

TestCheckoutPullRequest: {
    query: #GetPullRequest & {
        token:  TestConfig.githubToken
        number: 2
        repo: {
            owner: "stackbrew-test"
            name:  "gh-test"
        }
    }

    checkout: #CheckoutPullRequest & {
        token: TestConfig.githubToken
        pullRequest: query.pullRequest
    }

    test: bl.BashScript & {
        runPolicy: "always"
        input: "/checkout": checkout.out
        code: """
        grep -q "FROM PR2" /checkout/README.md
        """
    }
}

TestListPullRequests: {
    query: #ListPullRequests & {
        token:    TestConfig.githubToken
        pageSize: 10
        states:   ["MERGED"]
        repo: {
            owner: "stackbrew-test"
            name:  "gh-test"
        }
    }

    test: bl.BashScript & {
        runPolicy: "always"
        environment: {
            FIRST_PR_STATE: "\(query.pullRequests[0].state)"
            for pr in query.pullRequests {
                "PR_\(pr.number)_STATE": pr.state
            }
        }
        code: """
        env
        test "$FIRST_PR_STATE" = "MERGED"
        test "$PR_1_STATE" = "MERGED"
        test -z "$PR_2_STATE"
        """
    }
}
