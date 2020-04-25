package github

import (
    "b.l/bl"
)

Repository :: {
    // Github repository name
    name: string

    // Github repository owner
    owner: string

    // Github API token
    token: bl.Secret

    "GetPullRequest" :: GetPullRequest & {
        "token": token
        repo: {
            "owner": owner
            "name":  name
        }
    }
}
