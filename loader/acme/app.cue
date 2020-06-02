package app

import (
	"blocklayer.dev/fs"
)

shortname: #Settings.shortName
web: {
	source: fs.#Directory & {
		path: #Settings.webPath
	}
	url: string
}
api: {
	source: fs.#Directory & {
		path: #Settings.apiPath
	}
	url: string
}

#Settings: {
	// Human-friendly name for this deployment
	appName: string

	// Path to WEB frontend source code (relative to context)
	webPath: string | *"./crate/code/web"

	// Path to API source code (relative to context)
	apiPath: string | *"./crate/code/api"
}
