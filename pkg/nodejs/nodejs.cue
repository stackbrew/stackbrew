package nodejs

import (
	"b.l/bl"
)

Container :: {
	buildScript: string
	runScript: string
	environment: [string]: string
	source: bl.Directory
	image: bl.Directory
}
