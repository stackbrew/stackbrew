Here is a more involved example, defining a mildly complex zone

```
package main

import (
  "blocklayer.dev/gandidns"
)

// Add your secret key here
secrets: {
  apikey: "XXXXX"
}

definitions: {
  domain: "supersecret.space"

  staticIP: "1.203.51.218"
  dynName: "somedyndns.me."

  protonMX1: "mail.protonmail.ch."
  protonMX2: "mailsec.protonmail.ch."
  dmarcMailTo: "me+dmarc@pm.me"

  protonVerification: "abcd"
  protonDkim: "MIGfMA0GCSqGSIb3DQEB"
}

hostBastionRecord: gandidns.Records.A & {
  name: "host-bastion"
  value: definitions.staticIP
  ttl: 300
}

hostHomeRecord: gandidns.Records.CNAME & {
  name: "host-home"
  value: definitions.dynName
  ttl: 300
}

// samalba and Roger Peppe who think lists are evil :)
jsbootSpace: gandidns.Zone & {

  // Set a default global TTL (can be overridden per record)
  ttl: 300

  // Pass your api key
  provider: {
    settings: {
      apikey: secrets.apikey
      loglevel: "info"
    }
  }

  // What domain is that
  domain: definitions.domain

  // DNS records
  records: [

    gandidns.Records.A & {
      name: "@"
      value: definitions.staticIP
    },

    gandidns.Records.A & {
      name: "*"
      value: definitions.staticIP
    },

    hostBastionRecord,

    hostHomeRecord,

    gandidns.Records.CNAME & {
      name: "dns"
      value: hostBastionRecord.name
    },

    gandidns.Records.CNAME & {
      name: "dev"
      value: hostBastionRecord.name
    },

    gandidns.Records.CNAME & {
      name: "registry.dev"
      value: hostBastionRecord.name
    },

    gandidns.Records.CNAME & {
      name: "apt.dev"
      value: hostBastionRecord.name
    },

    gandidns.Records.CNAME & {
      name: "sinema"
      value: hostHomeRecord.name
    },

    gandidns.Records.CNAME & {
      name: "roon"
      value: hostHomeRecord.name
    },

    gandidns.Records.CNAME & {
      name: "vpn"
      value: hostHomeRecord.name
    },

    gandidns.Records.CNAME & {
      name: "router"
      value: hostHomeRecord.name
    },

    gandidns.Records.CNAME & {
      name: "printer"
      value: hostHomeRecord.name
    },

    gandidns.Records.CNAME & {
      name: "monitor"
      value: hostHomeRecord.name
    },

    gandidns.Records.CNAME & {
      name: "lights"
      value: hostHomeRecord.name
    },

    gandidns.Records.CNAME & {
      name: "home"
      value: hostHomeRecord.name
    },

    gandidns.Records.MX & {
      value: [
        {
          domain: definitions.protonMX1,
          weight: 10
        },
        {
          domain: definitions.protonMX2,
          weight: 20
        },
      ],
      ttl: 1800
    },

    gandidns.Records.TXT & {
      name: "@"
      value: [
        "protonmail-verification=\(definitions.protonVerification)",
        "v=spf1 include:_spf.protonmail.ch mx ~all",
      ]
    },

    gandidns.Records.TXT & {
      name: "_dmarc"
      value: [
        "v=DMARC1; p=none; rua=mailto:\(definitions.dmarcMailTo)",
      ]
    },

    gandidns.Records.TXT & {
      name: "protonmail._domainkey"
      value: [
        "v=DKIM1; k=rsa; p=\(definitions.protonDkim)",
      ]
    },
  ]
}

```
