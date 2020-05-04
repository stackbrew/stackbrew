package go

import "blocklayer.dev/bl"

testGoBuild: {
	run: App & {
		source: bl.Directory & {
			local: "./testdata"
		}
	}

	test: bl.BashScript & {
		input: "/inputs/binary": run.binary
		code: #"""
            [ "$(/inputs/binary)" = "hello world" ]
        """#
	}
}
