import (
	"blocklayer.dev/github"
	"blocklayer.dev/unix"
)

monorepo: github.#Repository & {
	owner: "blocklayerhq"
	name: "acme-clothing"
	token: encrypted: "kjhsdfkjshdfkjsdfjk"
}


localhost: unix.#Host

hello: localhost.#exec & {
	name: "echo"
	args: ["hello, world!"]
	stdout: string
}
