package github

// A client for the Github API v4, also known as the "Github GraphQL API"
// Reference: https://developer.github.com/v4/

import (
    "blocklayer.dev/bl"
    "stackbrew.io/graphql"
)

// GitHub v4 GraphQL Query
Query :: {
    token: bl.Secret

    graphql.Query & {
        url: "https://api.github.com/graphql"

        request: {
            "token": token
        }
    }
}
