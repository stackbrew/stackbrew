package graphql

import (
	"encoding/json"
	"stackbrew.io/http"
)

Query :: {
	// Contents of the graphql query
	query: string
	// graphql variables
	variable: [key=string]: _

	http.Post & {
		request: {
			body: json.Marshal({
				"query":   query
				variables: json.Marshal(variable)
			})
			header: "Content-Type": "application/json"
		}
	}

	response: body: string
	payload: {
		data: {...}
		errors?: {...}
	}
	payload: json.Unmarshal(response.body)
	data:    payload.data
	errors?: payload.errors
}
