package file

import (
	"b.l/bl"
)

TestRead: {
	read: Read & {
		source: bl.Directory & {
			local: "./testdata"
		}
		filename: "/file"
	}

	test: bl.BashScript & {
		input: "/test": read.contents
		code: """
        test "$(cat /test)" = "testfile"
        """
	}
}

TestCreate: {
	create: Create & {
		source: bl.Directory & {
			local: "./testdata"
		}
		filename:    "/new"
		contents:    "new file"
		permissions: 0o755
	}

	test: bl.BashScript & {
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

	test: bl.BashScript & {
		input: "/test": create.result
		code: """
        test "$(cat /test/new)" = "new file"
        """
	}
}

TestAppend: {
	append: Append & {
		source: bl.Directory & {
			local: "./testdata"
		}
		filename: "/file"
		contents: "new content"
	}

	create: Append & {
		source: bl.Directory & {
			local: "./testdata"
		}
		filename:    "/new"
		contents:    "new file"
		permissions: 0o755
	}

	test: bl.BashScript & {
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
		source: bl.Directory & {
			local: "./testdata"
		}
		glob: "f*"
	}

	test: bl.BashScript & {
		input: "/result.json": glob.files[0]
		code: """
        test "$(cat /result.json)" = "file"
        """
	}
}
