# GableBee

> Gandi Api BlockLayer Bot

This is a cuelang module for BlockLayer meant to manipulate DNS zones through Gandi LiveDNS.

Additionally, it provides agnostic base cue building blocks making it easy to add support for other DNS providers.

## TL;DR

Create your `main.cue`:

```
package foo

import (    
  "blocklayer.dev/gandidns"
)

yourDomain: gandidns.Zone & {
  // Your super domain name
  domain: "yourdomainname.tld"
  // By default, this will REPLACE your existing zone with this one - alternatively, set this to "merge"
  mode: "replace"

  provider: {
    settings: {
      // Pass your Gandi API key
      apikey: "gandikey"
    }
  }

  // Add as many DNS records as you want
  records: [
    // Here is an A record for @ to point to 1.1.1.1
    gandidns.Records.A & {
      name: "@"
      value: "1.1.1.1"
    }
  ]
}
```

## Moar

Check the `EXAMPLE.md` file for a more involved example.

## Requirements

 * BlockLayer alpha 3
 * a domain name on `gandi.net` with livedns enabled
 * a working Gandi API key for your account

## API

### Zone

```
Zone:: {
  // An optional ttl to apply to all records in the zone by default (can be overriden per record)
  ttl: uint32 | * 300

  // The domain name to which this zone will be attached
  domain: string

  // By default ("replace"), the entire zone is being replaced by the provided records.
  // In the "merge" mode, only the records that have the same "type" and "name" will be replaced,
  // and the others will be kept.
  // Note that NS records are ALWAYS left untouched and you can't specify them right now
  mode: =~ "^(replace|merge)$" | * "replace"

  provider: {
    settings: {
      // Your Gandi API key - see Gandi documentation
      apikey: string
      // Desired log level for the bot
      log_level: =~ "^(debug|info|warning|error)$" | *"info"
    }
  }

  records: [...Record]
```

### Record

All records share a common definition.

```
Record:: {
  // The target of the record - typically a subdomain name, or @, *
  name: string
  // The optional time to live for the record (will default to the zone TTL, or if unspecified, to 300)
  ttl: uint32
  // The "value" of the record. Specialized record types may present different interfaces for value (see below for detail)
  value: string | [...] | {}
}
```

Concrete record types additionally implement a specialized "value" field:
```

A:: Record & {
  value: types.IPv4
}

CNAME:: Record & {
  value: types.DomainWithTrailingDot | types.DomainFragment
}

MX:: Record & {
  value: [...{
    domain: types.DomainWithTrailingDot,
    weight: uint8
  } ]
}

TXT:: Record & {
  value: [...string]
}

SRV:: Record & {
  # Use these two instead of "name"
  srv: string
  protocol: string
  value: {
    priority: uint8
    weight: uint8
    port: uint16
    target: types.DomainWithTrailingDot
  }
}
```

## Disclaimer

For now, this is meant to fulfill my own needs.
