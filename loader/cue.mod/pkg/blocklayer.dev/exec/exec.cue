package exec

import (
	"list"
)

#Exec: {
	cmd: [string, ...string]
	environment: [string]: string
	stdin?: string
	stdout?: string
	stderr?: string
	error?: null | string
	flag: [string]: #Flag

	#fullCommand: {
		#result: [cmd[0]] + #allFlags + cmd[1:]

		#allFlags: list.FlattenN(#boolFlags + #stringFlags + #multiStringFlags, 1)
		#boolFlags: [["\(name)"] for name, value in flag if (value & bool) != _|_]
		#stringFlags: [["\(name)", "\(value)"] for name, value in flag if (value & string) != _|_]
		#multiStringFlags: [
			list.FlattenN([
				["\(name)", "\(value)"]
				for value, _ in values
			], 1)
			for name, values in flag
			if (values & {...}) != _|_
		]
	}

	fullCommand: #fullCommand.#result
}

#Flag: bool | string | {[string]: bool}
