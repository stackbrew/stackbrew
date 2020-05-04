package nodejs

import (
	"stackbrew.io/fs"
)

Container :: {
	buildScript: string
	runScript:   string
	environment: [string]: string
	source: fs.Directory
	image:  fs.Directory
}
