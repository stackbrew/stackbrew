
// Mock github API token
monorepo: token: {
	#ID: "5626725346723"
	encrypted: "VE9QU0VDUkVUCg=="
}


// Mock KMS
monorepo: token: #decrypt: {
	#run: stdout: "TOPSECRET"
	#run: error: null
}



// Mock linux local system

localhost: {
	#ls: #t: {
		stdout:
			"""
			ga
			bu
			zo
			meu
			"""
		error: null
	}
}
