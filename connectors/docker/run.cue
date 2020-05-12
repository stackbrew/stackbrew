
import (

)

#Engine: {
	#ID: string

	#Run: {
		#Tty: bool | *false
		#Stdin?: string
		#Image: string
		#Tag: string | *"latest"
		#Cmd: [...string]

		#exec: {
			@task(exec)

			Cmd: [
				"docker", "run", "\(#Image):\(#Tag)"
			]
			if (#Stdin & string != _|_) {
				Flag: "-i": true
				Stdin: #Stdin
			}
			if (Stdout & string) != _|_ {
				"Stdout": string
			}
			if (Stderr& string) != _|_ {
				"Stderr": string
			}
			Flag: "-t": #Tty
			Error: _
		}

		Error: #exec.Error
		Stdout?: #exec.Stdout
		Stderr?: #exec.Stderr
	}

	#ListContainers: {
		#OnlyRunning: bool | *false
		#Filter: [...string] | *[]

		#exec: {
			@task(exec)
			Cmd: ["docker", "container", "list"]
			Flag: "-a": !#OnlyRunning
			Error: _
			Stdout: string
		}

		Raw: #exec.Stdout
		Error: #exec.Error
	}
}
