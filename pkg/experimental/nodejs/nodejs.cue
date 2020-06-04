package nodejs

import (
	"blocklayer.dev/bl"
)

// Possible references to this location:
// aws/ecs/ecs.cue:39:15
// aws/ecs/ecs.cue:149:17
#Container: {
	buildScript: string
	runScript:   string
	environment: [string]: string
	source: bl.Directory
	image:  bl.Directory
}
Container: #Container @tmpNoExportNewDef(2b3e)
