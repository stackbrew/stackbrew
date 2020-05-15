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
		value: decrypt.stdout

		// FIXME: support tasks in definitions
		decrypt: {
			flag: "--decrypt": true
			cmd: ["gpg"]
			stdin: encrypted
			stdout: string
		} @task(exec)
	}
	
	pr: listPullRequests.result

	// FIXME: move to reference
	listPullRequests: {

		result: graphqlReq.result

		graphqlReq: {
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

			result: json.Unmarshal(httpReq.response.body)
			result: {
				[prNumber=string]: {
					...
				}
			}

			httpReq: {
				#url: "\(#endpoint)/query"
				#method: "POST"
				#header: Authorization: "Bearer \(#token.value)"
				#body:
					"""
					{"query": "query \(#query)"}
					"""
				err: t.err
				response: {
					body: t.stdout
					code: int
					header: [string]: string
				}

				// Actual task executing curl
				t: {
					cmd: ["curl", #url]
					flag: {
						"-s": true
						"-X": #method
					}
					err: _
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

localhost: {
	#ID: "324786327846328742"

	#say: {
		#message: string
		t: {
			cmd: ["echo", #message]
		} @task(exec)
	}

	#ls: {
		#path: [...string]

		// FIXME: support tasks in definitions
		t: {
			error: _
			stdout: string
			cmd: ["/bin/ls", strings.Join(#path, "/")]
		} @task(exec)

		error: t.error
		files: strings.Split(t.stdout, "\n")
	}

	lsTmp: #ls & {
		#path: ["tmp"]
	}

	tmp: lsTmp.files

	sayHello: #say & { #message: "hello!" }
}

