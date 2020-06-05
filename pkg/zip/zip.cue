package zip

import "blocklayer.dev/bl"

// Zip archive
#Archive: {

	// Source Directory, File or String to Zip from
	source: bl.Directory | string

	// Archive file output
	archive: bl.Directory & {
		source: run.output["/outputs/out"]
		path:   "file.zip"
	}

	run: bl.BashScript & {
		input: "/inputs/source": source

		output: "/outputs/out": bl.Directory

		os: package: zip: true

		code: #"""
            mkdir -p /outputs/out
            zip /outputs/out/file.zip /inputs/source
        """#
	}
}
