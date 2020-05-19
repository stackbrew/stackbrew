import (
	"blocklayer.dev/github"
)

monorepo: github.#Repository & {
	owner: "blocklayerhq"
	name: "acme-clothing"
	token: encrypted: "kjhsdfkjshdfkjsdfjk"
}

foo: {
	for number, pr in monorepo.pr {
		hello: "world"
	}
}
