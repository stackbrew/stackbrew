package github

Comment :: {
    id:   string
    body: string
}

CommentFragment :: """
    fragment CommentParts on IssueComment {
        id
        body
    }
    """

AddComment :: {
    subjectId: string
    body:      string

    data: _
    comment: Comment
    comment: data.addComment.commentEdge.node

    Query & {
        query: """
        mutation ($input: AddCommentInput!) {
            addComment(input: $input) {
                subject {
                    id
                }
                commentEdge {
                    node {
                        ...CommentParts
                    }
                }
            }
        }
        \(CommentFragment)
        """

        variable: input: {
            "subjectId": subjectId
            "body":      body
        }
    }
}

UpdateComment :: {
    commentId: string
    body:      string

    data: _
    comment: Comment
    comment: data.updateIssueComment.issueComment

    Query & {
        query: """
        mutation ($input: UpdateIssueCommentInput!) {
            updateIssueComment(input: $input) {
                issueComment {
                    ...CommentParts
                }
            }
        }
        \(CommentFragment)
        """

        variable: input: {
            id:     commentId
            "body": body
        }
    }
}
