package git

import "blocklayer.dev/bl"

testClone: {
	run: #Repository & {
		url: "https://github.com/blocklayerhq/actions"
		ref: "2dd1ba045e7dc4e382ae89529b0e9e2107a076bb"
	}

	test: bl.BashScript & {
		input: {
			"/inputs/out":          run.out
			"/inputs/commit":       run.commit
			"/inputs/short-commit": run.shortCommit
		}

		code: #"""
            [ "$(cat /inputs/commit)" = "2dd1ba045e7dc4e382ae89529b0e9e2107a076bb" ]
            [ "$(cat /inputs/short-commit)" = "2dd1ba0" ]
            [ -f /inputs/out/README.md ]
            [ ! -d /inputs/out/.git ]
        """#
	}
}

testCloneWithGitDir: {
	run: #Repository & {
		url:        "https://github.com/blocklayerhq/actions"
		ref:        "2dd1ba045e7dc4e382ae89529b0e9e2107a076bb"
		keepGitDir: true
	}

	test: bl.BashScript & {
		input: "/inputs/out": run.out

		code: #"""
            [ -d /inputs/out/.git ]
        """#
	}
}

testPathCommit: {
	repos: #Repository & {
		url:        "https://github.com/blocklayerhq/actions"
		ref:        "2dd1ba045e7dc4e382ae89529b0e9e2107a076bb"
		keepGitDir: true
	}

	run: #PathCommit & {
		from: repos.out
	}

	test: bl.BashScript & {
		input: {
			"/inputs/commit":       run.commit
			"/inputs/short-commit": run.shortCommit
		}

		code: #"""
            [ "$(cat /inputs/commit)" = "2dd1ba045e7dc4e382ae89529b0e9e2107a076bb" ]
            [ "$(cat /inputs/short-commit)" = "2dd1ba0" ]
        """#
	}
}
