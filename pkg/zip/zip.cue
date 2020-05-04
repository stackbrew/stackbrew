package zip

import (
    "stackbrew.io/bash"
    "stackbrew.io/fs"
)

// Zip archive
Archive :: {

	// Source Directory, File or String to Zip from
	source: fs.Directory | string

	// Archive file output
	archive: {
		from: run.output["/outputs/out"]
		path: "file.zip"
	}

	run: bash.BashScript & {
		input: "/inputs/source": source

		output: "/outputs/out": fs.Directory

		os: package: zip: true

		code: #"""
            mkdir -p /outputs/out
            zip /outputs/out/file.zip /inputs/source
        """#
	}
}
