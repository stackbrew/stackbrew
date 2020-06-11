package dns

// This package defines generic DNS cue types, specifically:
// - a number of record types (A, CNAME, MX, TXT, SRV)
// - a generic AbstractRecord to extend in case more specialized record types are needed
// - an AbstractZone meant to be extended with a concrete implementation for "provider" (in particular provider: action: and provider: settings:)
// This package is not tied to a specific provider, and doesn't do anything besides representing a DNS zone in an
// expressive way and providing hooks to communicate with a remote service to push zones

import (
  "loop-dev.com/bash/shart"
  "loop-dev.com/types"
  "blocklayer.dev/bl"
  "encoding/json"
)

// An abstract record is meant to be extended by concrete record types (A, CNAME, etc)
abstractRecord: {
  // @, *, or any sub domain name like "foo" or "_srv._bar"
  name: string
  // MX, TXT, etc
  type: =~ "^(A|CNAME|MX|TXT|SRV)$"
  // Time to live for the records
  // TODO enforce being >300
  ttl: uint32
  // Value type is left to the specialized record to design
  value: string | [...] | {}
  // How value is actually turned into a list of strings is left to the specialized record to design
  _values: [...string]
}

// TBD: SPF NS PTR and the remainders
Records:: {
  A:: abstractRecord & {
    name: "@" | "*" | types.DomainFragment
    type: "A"
    value: types.IPv4
    _values: [value]
  }

  CNAME:: abstractRecord & {
    name: types.DomainFragment
    type: "CNAME"
    value: types.DomainWithTrailingDot | types.DomainFragment
    _values: [value]
  }

  MX:: abstractRecord & {
    name: "@"
    type: "MX"
    value: [...{
      domain: types.DomainWithTrailingDot,
      weight: uint8
    } ]
    _values: ["\(item.weight) \(item.domain)" for k, item in value]
  }

  TXT:: abstractRecord & {
    name: "@" | types.DomainFragment
    type: "TXT"
    value: [...string]
    // XXX might need quoting? or not?
    _values: value
  }

  SRV:: abstractRecord & {
    srv: string
    protocol: string
    name: "\(srv).\(protocol)"
    type: "SRV"
    value: {
      priority: uint8
      weight: uint8
      port: uint16
      target: types.DomainWithTrailingDot
    }
    _values: ["\(value.priority) \(value.weight) \(value.port) \(value.target)"]
  }
}

trixcue: {
  action: string | *"""
    printf "%s\n" "You must implement a concrete action to communicate with your DNS provider, by attaching an action script to your specialized Zone"
    exit 1
  """,
  settings: {}
}

// An abstract zone just represents a DNS Zone containing Records, but does not interact with any service
// Specialized implementation are expected to implement the mechanics to query provider APIs using the provided "action" hook
AbstractZone:: {
  _ttl=ttl: uint32 | * 300

  domain: string

  mode: *"replace" | "merge"

  provider: trixcue

  script: bl.BashScript & {
    os: {
      package: {
      // BL provide these already
      //        bash: true,
      //        jq: true,
        ncurses: true,
        curl: true,
      }
    },

    input: "/records.json": json.Marshal([
      {
        rrset_type: item.type,
        rrset_ttl: item.ttl,
        rrset_name: item.name,
        rrset_values: item._values,
      } for key, item in records
    ])

    output: {
      "zone": string
    }
    code: provider.action
  }

  // Struct API instead
  // records2: [type=string]: [name=string]: (abstractRecord & {
  //  ttl: uint32 | *_ttl
  // })

  records: ([...abstractRecord & {
              ttl: uint32 | *_ttl
  }])
}
