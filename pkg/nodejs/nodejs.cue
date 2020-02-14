package nodejs

Container :: {
	buildScript: string
	runScript: string
	environment: [string]: string
	source: Directory
	image: Directory
}
