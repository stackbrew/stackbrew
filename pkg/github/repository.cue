package github

import (
    "b.l/bl"
    "stackbrew.io/git"
)

Repository :: {
    // Github repository name
    name: string

    // Github repository owner
    owner: string

    // Github API token
    token: bl.Secret

    PullRequest :: {
        number: int

        checkout: gitCloneAndCheckout.out

        info: GetPullRequest & {
            "number": number
            "token":  token
            repo: {
                "owner": owner
                "name":  name
            }
        }

        gitCloneAndCheckout: git.Repository & {
            url:          info.pullRequest.headRepository.url
            ref:          info.pullRequest.headRef.target.oid
            username:     "apikey"
            httpPassword: token
        }
    }
}
