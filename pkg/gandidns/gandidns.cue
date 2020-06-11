package gandidns

// This is the main cue object for the gablebee module
// It leverages the DNS cue types (blocklayer.dev/gandidns/helpers/dns), implementing a concrete Zone that actually communicate with gandi API using the gandi cli (blocklayer.dev/gandidns/helpers/bash/gandi)

import (
  "loop-dev.com/bash/shart"
  "loop-dev.com/bash/gandi"
  "loop-dev.com/dns"
)

// Just surface the records types
Records:: dns.Records

// Implement a concrete zone
Zone:: dns.AbstractZone & {
  // domain name for the zone
  domain: string

  // whether to replace the zone entirely, or merge with existing records
  mode: =~ "^(replace|merge)$" | * "replace"

  provider: {
    // ApiKey for gandi service, and log level for our internal library
    settings: {
      apikey: string
      loglevel: =~ "^(debug|info|warning|error)$" | *"info"
    }

    // Publication implem
    action: #"""
    #!/bin/bash
    set +x
    set -o pipefail

    # Source our shit
    \#(shart.script)
    \#(gandi.script)

    # Boilerplate for sh-art
    readonly CLI_NAME="in_bl_we_trust"
    IN_BL_WE_TRUST_LOG_LEVEL=\#(settings.loglevel)
    dc::commander::initialize
    dc::commander::boot

    # Pull in the settings and serialized zone
    apikey=\#(settings.apikey)
    domain=\#(domain)
    mode=\#(mode)
    records="$(cat /records.json)"

    # Preflight
    gandi::requestor::init "$apikey" || {
      dc::logger::error "Authentication or network connection failed. Check that your ApiKey is valid and that you do have connectivity."
      exit 1
    }

    dc::logger::info "ApiKey is valid and communication with Gandi API is working."

    # Really really preflight
    domains="$(gandi::api::domains::list | jq -rc .[].fqdn)" || {
      dc::logger::error "Failed retrieving domain list for this apikey - should never happen. Is your apikey really valid?"
      exit 1
    }

    dc::logger::info "Domains list retrieved"
    dc::logger::debug "Domains:" "$domains"

    # Check that the domain is there (should be if livedns enabled for this domain - but untested against a freshly registered domain...)
    printf "%s" "$domains" | grep -q "$domain" || {
      dc::logger::error "The requested domain ($domain) is not in your list of domains. You may need to enable livedns for this domain first."
      exit 1
    }

    dc::logger::info "Requested domain is livedns enabled."

    # If we merge, retrieve the existing records
    if [ "$mode" == "merge" ]; then
      dc::logger::info "Going to merge new records into existing zone."

      # Read old records
      oldrecords="$(gandi::api::records::list "$domain" | jq .)" || {
        dc::logger::error "Failed reading records for the domain. WTF."
      }

      dc::logger::info "Existing records retrieved."

      # Bite me jq
      records="$(jq --argjson oldr "$oldrecords" --argjson newr "$records" -n '$oldr + $newr | group_by( [.rrset_type, .rrset_name]) | map(if (.[1] == null) then .[0] else .[1] end)')"
    fi

    # Push the new (or aggregated records)
    gandi::api::records::replace "$domain" <(printf "%s" "$records" | jq '{"items": .}') | jq . || {
      dc::logger::error "Failed updating records for this domain. See error above."
      exit 1
    }

    dc::logger::info "Successfully updated your DNS zone."
    dc::logger::info "Here is what your zone looks like now:"

    # Spit out the final zone
    gandi::api::records::list "$domain" | jq . | tee /zone

    dc::logger::info " Exiting in 3... 2... 1..."
    """#
  }
}
