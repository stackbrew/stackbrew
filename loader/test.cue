import (
	"blocklayer.dev/github"
	"blocklayer.dev/unix"
)

monorepo: github.#Repository & {
	owner: "blocklayerhq"
	name: "acme-clothing"
	token: encrypted: "kjhsdfkjshdfkjsdfjk"
}

#say: unix.#Host.#exec & {
	name: "echo"
	#message: string
	args: [#message]
}

hello: #say & { #message: "hello" }
