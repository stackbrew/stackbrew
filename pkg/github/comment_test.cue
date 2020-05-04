package github

import (
    "blocklayer.dev/bl"
    "encoding/json"
)

TestConfig: githubToken: bl.Secret

TestComment: {
    query: GetPullRequest & {
        token:  TestConfig.githubToken
        number: 2
        repo: {
            owner: "stackbrew-test"
            name:  "gh-test"
        }
    }

    addComment: AddComment & {
        token:     TestConfig.githubToken
        subjectId: query.pullRequest.id
        body:      #"""
        ## Stackbrew Test

        ```
        \#(json.Indent(
            json.Marshal(query.pullRequest),
            "", "  "
        ))
        ```
        """#
    }

    updateComment: UpdateComment & {
        token:     TestConfig.githubToken
        commentId: addComment.comment.id
        body:      #"""
        \#(addComment.body)

        **UPDATED**
        """#
    }
}
