package file

import (
	"stackbrew.io/bash"
	"stackbrew.io/fs"
)

TestRead: {
	read: Read & {
		source: fs.Directory & {
			local: "./testdata"
		}
		filename: "/file"
	}

	test: bash.BashScript & {
		input: "/test": read.contents
		code: """
        test "$(cat /test)" = "testfile"
        """
	}
}

TestCreate: {
	create: Create & {
		source: fs.Directory & {
			local: "./testdata"
		}
		filename:    "/new"
		contents:    "new file"
		permissions: 0o755
	}

	test: bash.BashScript & {
		input: "/test": create.result
		code: """
        test -x "/test/new"
        test "$(cat /test/new)" = "new file"
        """
	}
}

TestCreateNoSource: {
	create: Create & {
		filename: "/new"
		contents: "new file"
	}

	test: bash.BashScript & {
		input: "/test": create.result
		code: """
        test "$(cat /test/new)" = "new file"
        """
	}
}

TestAppend: {
	append: Append & {
		source: fs.Directory & {
			local: "./testdata"
		}
		filename: "/file"
		contents: "new content"
	}

	create: Append & {
		source: fs.Directory & {
			local: "./testdata"
		}
		filename:    "/new"
		contents:    "new file"
		permissions: 0o755
	}

	test: bash.BashScript & {
		input: "/append": append.result
		input: "/create": create.result
		code: """
        test "$(cat /append/file)" = "testfile\nnew content"

        test -x "/create/new"
        test "$(cat /create/new)" = "new file"
        """
	}
}

TestGlob: {
	glob: Glob & {
		source: fs.Directory & {
			local: "./testdata"
		}
		glob: "f*"
	}

	test: bash.BashScript & {
		input: "/result.json": glob.files[0]
		code: """
        test "$(cat /result.json)" = "file"
        """
	}
}
