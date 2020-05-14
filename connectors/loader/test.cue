import (
	"strings"
)

localhost: {
	#ID: string

	#ls: {
		#path: [...string]

		// FIXME: support tasks in definitions
		t: {
			error: _
			stdout: string
			cmd: ["/bin/ls", strings.Join(#path, "/")]
		} @task(exec)

		error: t.error
		files: strings.Split(t.stdout, "\n")
	}

	lsTmp: #ls & {
		#path: ["tmp"]
	}

	tmp: lsTmp.files
}

