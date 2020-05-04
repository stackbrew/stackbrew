package github

import (
    "stackbrew.io/secret"
)

Repository :: {
    // Github repository name
    name: string

    // Github repository owner
    owner: string

    // Github API token
    token: secret.Secret

    "GetPullRequest" :: GetPullRequest & {
        "token": token
        repo: {
            "owner": owner
            "name":  name
        }
    }
}
