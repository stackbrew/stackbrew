package github

import (
    "b.l/bl"
    "encoding/json"
)

TestConfig: githubToken: bl.Secret

TestPullRequest: {
    repository: Repository & {
        name:  "gh-test"
        owner: "stackbrew-test"
        token: TestConfig.githubToken
    }


    pr: repository.PullRequest & {
        number: 2
    }

    test: bl.BashScript & {
        runPolicy: "always"
        input: "/checkout": pr.checkout
        code: """
        grep -q "FROM PR2" /checkout/README.md
        """
    }

    comment: AddComment & {
        token:     TestConfig.githubToken
        subjectId: pr.info.pullRequest.id
        body:      #"""
        ## Stackbrew Test

        ```
        \#(json.Indent(
            json.Marshal(pr.info),
            "", "  "
        ))
        ```
        """#
    }

    updateComment: UpdateComment & {
        token:     TestConfig.githubToken
        commentId: comment.comment.id
        body:      #"""
        \#(comment.body)

        **UPDATED**
        """#
    }
}
