package go

import (
	"stackbrew.io/bash"
	"stackbrew.io/fs"
)

testGoBuild: {
	run: App & {
		source: fs.Directory & {
			local: "./testdata"
		}
	}

	test: bash.BashScript & {
		input: "/inputs/binary": run.binary
		code: #"""
            [ "$(/inputs/binary)" = "hello world" ]
        """#
	}
}
