import (
	"strings"
	"encoding/json"
)



monorepo: {
	#ID: string

	owner: "blocklayerhq"
	name: "acme-clothing"
	token: {
		#ID: string

		encrypted: string

		// FIXME: support tasks in definitions
		#decrypt: {
			#run: #Exec & {
				cmd: ["base64", "-d"]
				stdin: encrypted
				stdout: string
				error: _
			}
			result: #run.stdout
			error: #run.error
		}
	}

	pr: listPullRequests.result

	// FIXME: move to reference
	listPullRequests: {

		result: #graphqlReq.result

		#graphqlReq: {
			#token: token
			#endpoint: "https://api.github.com/graphql"
			#query:
				"""
				repository(owner:\(owner), name:\(name)) {
					pullRequests(states=OPEN) [
						nodes {
							number
							title
						}
					}

				}
				"""

			result: json.Unmarshal(#httpReq.response.body)
			result: {
				[prNumber=string]: {
					...
				}
			}

			#httpReq: {
				#url: "\(#endpoint)/query"
				#method: "POST"
				#header: Authorization: "Bearer \(#token.#decrypt.result)"
				#body:
					"""
					{"query": "query \(#query)"}
					"""
				error: #t.error
				response: {
					body: #t.stdout
					code: int
					header: [string]: string
				}

				// Actual task executing curl
				#t: {
					cmd: ["curl", #url]
					flag: {
						"-s": true
						"-X": #method
					}
					error: _
					// FIXME: we are mocking output here
					#mockResponse: {
						"42": {
							"title": "do something great"
						},
						"43": {
							"title": "do something even more great"
						}
					}
					stdout: json.Marshal(#mockResponse)
				} @task(exec)
			}
		}
	}
}

localhost: #linuxHost & {
	#ID: "sdfsdfdsfsdfd"
}

#linuxHost: {
	#ID: string

	#say: {
		#message: string
		t: {
			cmd: ["echo", #message]
		} @task(exec)
	}

	#ls: {
		#path: [...string]

		// FIXME: support tasks in definitions
		#t: {
			error: _
			stdout: string
			cmd: ["/bin/ls", strings.Join(#path, "/")]
		} @task(exec)

		error: #t.error
		files: strings.Split(#t.stdout, "\n")
	}

	lsTmp: #ls & {
		#path: ["tmp"]
	}

	tmp: lsTmp.files

	sayHello: #say & { #message: "hello!" }
}

