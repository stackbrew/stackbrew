package mysql

Database :: {
	name:   string
	create: *true | bool
	server: Server
}

Server :: {
	host:          string
	port:          *3306 | int
	adminUser:     string
	adminPassword: string
}
