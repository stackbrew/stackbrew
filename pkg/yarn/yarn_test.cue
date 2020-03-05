package yarn

import "b.l/bl"

TestYarn : {
	run: App & {
		source: bl.Directory & {
			local: "./testdata/src"
		}
	}

	test: bl.BashScript & {
		input: "/build": run.build
		code: """
        test "$(cat /build/test)" = "output"
        """
	}
}

TestYarnEnvFile : {
	run: App & {
		source: bl.Directory & {
			local: "./testdata/src"
		}
		loadEnv: true
		environment: FOO: "BAR"
		writeEnvFile: ".env"
	}

	test: bl.BashScript & {
		input: "/build": run.build
		code: """
        grep "FOO=BAR" /build/.env
        """
	}
}
