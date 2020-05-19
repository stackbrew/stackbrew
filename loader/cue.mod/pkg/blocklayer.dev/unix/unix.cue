package unix

import (
	"list"
)

// A simple interface to a Unix host
#Host: {
	#ID: string

	#exec: {
		name: string
		args: [...string]
		environment: [string]: string
		stdin?: string
		stdout?: string
		stderr?: string
		error?: null | string
		flag: [string]: #Flag

		#flagArgs: {
			#all: list.FlattenN(#bools + #singleStrings + #multiStrings, 1)

			#bools: [["\(name)"] for name, value in flag if (value & bool) != _|_]
			#singleStrings: [["\(name)", "\(value)"] for name, value in flag if (value & string) != _|_]
			#multiStrings: [
				list.FlattenN([
					["\(name)", "\(value)"]
					for value, _ in values
				], 1)
				for name, values in flag
				if (values & {...}) != _|_
			]
		}

		#cmd: [name] + #flagArgs.#all + args
	}
}

#Flag: bool | string | {[string]: bool}
