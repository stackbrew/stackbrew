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
		body: json.Marshal({
			"query":   query
			variables: json.Marshal(variable)
		})
		header: "Content-Type": "application/json"
	}

	response: string
	payload: {
		data?: {...}
		errors?: {...}
	}
	payload: json.Unmarshal(response)
	data?:   payload.data
	errors?: payload.errors
}
