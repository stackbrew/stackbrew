// info  [localhost lsTmp files ()/1 ./0 ./0 files ()/1 ./0 ./0 files ()/1 ./0 ./0 files ()/1 ./0 ./0 files ()/1 ./0 ./0 files ()/1 ./0 ./0 files ()/1 ./0 ./0 files ()/1 ./0 ./0 files ()/0 ./0 MinRunes] -> false

import (
	"strings"
)

	// E: localhost.lsTmp.files.asFuncCall(1).asSelector(0).asSelector(0)
	#ls: {

		// D: localhost.lsTmp.files.asFuncCall(1).asSelector(0)
		#exec: {
			// D: localhost.lsTmp.files.asFuncCall(1)
			stdout: string
		}

		// C: localhost.lsTmp.files
		files: strings.Split(#exec.stdout, "\n")
	}

	// B: localhost.lsTmp
	#lsTmp: #ls & {
		#path: ["tmp"]
	}


	a: {
		b: string
	}

	c: a.b
