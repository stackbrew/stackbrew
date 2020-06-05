package github

// A client for the Github API v4, also known as the "Github GraphQL API"
// Reference: https://developer.github.com/v4/
//
// This package matches the raw Github types and queries as closely as possible.
// For a higher-level package, see the top-level `github` package.

User :: {
	id:    string
	login: string
}

UserFragment :: """
    fragment UserParts on User {
        id
        login
    }
    """

GetViewer :: {
	Query & {
		query: """
        query {
            viewer {
                ...UserParts
            }
        }
        \(UserFragment)
        """
	}

	data: _
	user: data.viewer
}
