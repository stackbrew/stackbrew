package git

import (
	"strings"

	"blocklayer.dev/bl"
)

// Git repository
#Repository: {

	// URL of the Repository
	url: string

	// SSH key for private repositories
	sshKey?: bl.#Secret

	// SSH or HTTP username to use in the git URL
	username?: string

	// HTTP password
	httpPassword?: bl.#Secret

	// Git Ref to checkout
	ref: *"master" | string

	// Keep .git directory after clone
	keepGitDir: *false | bool

	output: _
	// Output directory of the `git clone`
	out: output["/outputs/out"]

	// Output commit ID of the Repository
	commit: strings.TrimRight(output["/outputs/commit"], "\n")

	// Output short-commit ID of the Repository
	shortCommit: strings.TrimRight(output["/outputs/short-commit"], "\n")

	bl.#BashScript & {
		os: package: {
			git:     true
			openssh: true
		}

		workdir: "/workdir"

		input: {
			"/inputs/url": url
			"/inputs/ref": ref
			if (sshKey & bl.Secret) != _|_ {
				"/inputs/ssh-key": sshKey
			}
			if keepGitDir {
				"/inputs/keep-gitdir": "true"
			}
			if (username & string) != _|_ {
				"/inputs/username": username
			}
			if (httpPassword & bl.Secret) != _|_ {
				"/inputs/http-password": httpPassword
			}
			"/cache/git": bl.#Cache
		}

		output: {
			"/outputs/out":          bl.#Directory
			"/outputs/commit":       string
			"/outputs/short-commit": string
		}

		code: #"""
            export GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no'

            if [ -f "/inputs/ssh-key" ]; then
                # FIXME: ssh wants this. There must be a better way.
                cp /inputs/ssh-key /tmp/ssh-key
                chmod 0600 /tmp/ssh-key

                export GIT_SSH_COMMAND="$GIT_SSH_COMMAND -i /tmp/ssh-key"
            fi

            url="$(cat /inputs/url)"

            if [ -f /inputs/username ]; then
                creds="$(cat /inputs/username)"
                if [ -f /inputs/http-password ]; then
                    creds="$creds:$(cat /inputs/http-password)"
                fi
                url="${url/\/\////$creds@}"
            fi

            ref="$(cat /inputs/ref)"

            cache_key="$(base64 < /inputs/url)"
            mirror="/cache/git/${cache_key}"

            # Set up a mirror as a cache
            if [ ! -d "$mirror" ]; then
                git clone --progress --verbose --mirror "$url" -- "$mirror"
            fi
            # Refresh the cache.
            git -C "$mirror" remote update

            # Fetch the repository, using the cache
            git clone --dissociate --reference "$mirror" -- "$url" /outputs/out

            # Checkout ref
            git -C /outputs/out reset --hard "$ref"

            # Extract the revision
            git -C /outputs/out rev-parse "$ref" > /outputs/commit
            git -C /outputs/out rev-parse --short "$ref" > /outputs/short-commit

            if [ ! -f /inputs/keep-gitdir ]; then
                # Remove gitdir by default
                rm -rf /outputs/out/.git
            fi
        """#
	}
}

// Retrieve commit IDs from a git working copy (ie. cloned repository)
#PathCommit: {

	// Source Directory (git working copy)
	from: bl.#Directory

	// Optional path to retrieve git commit IDs from
	path: *"./" | string

	// Output commit ID of the Repository
	commit: strings.TrimRight(pathCommit.output["/outputs/commit"], "\n")

	// Output short-commit ID of the Repository
	shortCommit: strings.TrimRight(pathCommit.output["/outputs/short-commit"], "\n")

	pathCommit: bl.#BashScript & {
		os: package: git: true

		workdir: "/workdir"

		input: {
			"/inputs/from": from
			"/inputs/path": path
		}

		output: {
			"/outputs/commit":       string
			"/outputs/short-commit": string
		}

		code: #"""
            git -C /inputs/from log -n 1 --format="%H" -- "$(cat /inputs/path)" > /outputs/commit
            git -C /inputs/from log -n 1 --format="%h" -- "$(cat /inputs/path)" > /outputs/short-commit
            if ! [ -s /outputs/commit ]; then
                echo "path not found in git repos" 1>&2
                exit 1
            fi
        """#
	}
}
