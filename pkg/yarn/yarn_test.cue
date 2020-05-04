package yarn

import (
    "stackbrew.io/bash"
    "stackbrew.io/fs"
)

TestYarn : {
	run: App & {
		source: fs.Directory & {
			local: "./testdata/src"
		}
	}

	test: bash.BashScript & {
		input: "/build": run.build
		code: """
        test "$(cat /build/test)" = "output"
        """
	}
}

TestYarnEnvFile : {
	run: App & {
		source: fs.Directory & {
			local: "./testdata/src"
		}
		loadEnv: true
		environment: FOO: "BAR"
		writeEnvFile: ".env"
	}

	test: bash.BashScript & {
		input: "/build": run.build
		code: """
        grep "FOO=BAR" /build/.env
        """
	}
}
