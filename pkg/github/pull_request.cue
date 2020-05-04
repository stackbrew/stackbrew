package github

import (
    "stackbrew.io/git"
    "stackbrew.io/secret"
)

PullRequest :: {
    id:     string
    state:  string
    number: int
    title:  string
    headRepository: {
        sshUrl: string
        url:    string
    }
    headRef: {
        name:   string
        prefix: string
        target: oid: string
    }
}

// INTERNAL: GraphQL fragment shared across queries related to PullRequest
PullRequestParts :: """
    fragment PullRequestParts on PullRequest {
        id
        state
        number
        title
        headRepository {
            sshUrl
            url
        }
        headRef {
            name
            prefix
            target {
                oid
            }
        }
    }
    """

GetPullRequest :: {
    number: int

    repo: {
        owner: string
        name:  string
    }

    Query & {
        query:
            """
            query($owner: String!, $name: String!, $number: Int!) {
                repository(owner: $owner, name: $name) {
                    pullRequest(number: $number) {
                        ...PullRequestParts
                    }
                }
            }
            \(PullRequestParts)
            """
        variable: {
            owner:    repo.owner
            name:     repo.name
            "number": number
        }
    }

    data:        _
    pullRequest: PullRequest
    pullRequest: data.repository.pullRequest
}

// FIXME: this should be PullRequest::Checkout
CheckoutPullRequest :: {
    pullRequest: PullRequest

    // Github API token
    token: secret.Secret

    git.Repository & {
        url:          pullRequest.headRepository.url
        ref:          pullRequest.headRef.target.oid
        username:     "apikey"
        httpPassword: token
    }
}

ListPullRequests :: {
    repo: {
        owner: string
        name:  string
    }
    pageSize: int | *25
    states:   [string] | *[]

    Query & {
        query:
            """
            query($owner: String!, $name: String!, $last: Int, $states: [PullRequestState!]) {
                repository(owner: $owner, name: $name) {
                    pullRequests(last: $last, states: $states) {
                        nodes {
                            ...PullRequestParts
                        }
                    }
                }
            }
            \(PullRequestParts)
            """
        variable: {
            owner:    repo.owner
            name:     repo.name
            last:     pageSize
            "states": states
        }
    }

    data: _
    pullRequests: [...PullRequest]
    pullRequests: data.repository.pullRequests.nodes
}
