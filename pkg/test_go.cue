package main

import (
	"blocklayer.dev/bl"

	"stackbrew.io/go"
)

pkg: "go": {

	testData: bl.Directory

	test: {

		"build": {
			run: go.App & {
				source: testData
			}
		
			test: bl.BashScript & {
				input: "/inputs/binary": run.binary
				code: #"""
		            [ "$(/inputs/binary)" = "hello world" ]
		        """#
			}

		}
	}
}
