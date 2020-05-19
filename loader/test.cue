import (
	"blocklayer.dev/github"
)

monorepo: github.#Repository & {
	owner: "blocklayerhq"
	name: "acme-clothing"
	token: encrypted: "kjhsdfkjshdfkjsdfjk"
}

////////// MOCK VALUES
// Mock github API token
monorepo: token: {
	#ID: "5626725346723"
}


// Mock KMS
monorepo: token: #decrypt: {
	#run: stdout: "TOPSECRET"
	#run: error: null
}

monorepo: {
	#endpoint: {
		#Query: {
			#curl: {
				error: null
				stdout:
					"""
					{
						"data": {
							"repository": {
								"pullRequests": {
									"nodes": [
										{"number": 42, "title": "do something cool"},
										{"number": 43, "title": "do something even cooler"}
									]
								}
							}
						}
					}
					"""
			}
		}
	}
}
