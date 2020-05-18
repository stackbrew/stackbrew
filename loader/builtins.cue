
// Platform builtins
// (matched against definition name)

#Exec: {
	cmd: [string, ...string]
	environment: [string]: string
	stdin?: string
	stdout?: string
	stderr?: string
	error?: null | string
}
