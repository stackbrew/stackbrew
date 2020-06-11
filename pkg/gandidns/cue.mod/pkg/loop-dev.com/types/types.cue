package types

// This is meant to provide proper RFC grammar to manipulate domain names
// XXX right now, this is just risible B.S. because I don't have time for this :-)
DomainFragment:: string
DomainFragment:: =~ "^[a-z_-]+(?:[.][a-z_-]+)?$"

IPv4:: =~ "^[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+$"

DomainWithTrailingDot:: =~ "^[a-z_-]+(?:[.][a-z_-]+)*[.]$"
