package gandi

// A gandi cli client, based on the sh-art library

script:: #"""
##########################################################################
# lib-dc-sh-art-extensions, extensions
# Released under MIT License
# Copyright (c) 2020 Dubo Dubon Duponey
##########################################################################

# XXXXXXX all this doesn't error as it should when curl is missing

export DC_PRIVATE_APIKEY="you need to set this to your gandi API key by calling gandi::requestor::init"

readonly GANDI_API_SERVICE="https://api.gandi.net/v5"

readonly GANDI_HTTP_GET="GET"
readonly GANDI_HTTP_POST="POST"
readonly GANDI_HTTP_DELETE="DELETE"
readonly GANDI_HTTP_PATCH="PATCH"
readonly GANDI_HTTP_PUT="PUT"

readonly GANDI_TYPE_ENDPOINT="^[a-z_.-]+(/[a-z_.-]+)*(\?[a-z=&_.-])?$"
readonly GANDI_TYPE_DOMAIN="^.+$"
readonly GANDI_TYPE_UUID="^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
readonly GANDI_TYPE_METHOD="^($GANDI_HTTP_GET|$GANDI_HTTP_POST|$GANDI_HTTP_DELETE|$GANDI_HTTP_PATCH|$GANDI_HTTP_PUT)$"

dc::error::register ERROR_GANDI_NETWORK
dc::error::register ERROR_GANDI_AUTHORIZATION
dc::error::register ERROR_GANDI_BROKEN
dc::error::register ERROR_GANDI_GENERIC

gandi::requestor::init(){
  export DC_PRIVATE_APIKEY="$1"
#  gandi::requestor::api "livedns/dns/rrtypes" || return
  gandi::requestor::api "livedns/domains" > /dev/null || return
}

gandi::requestor::api(){
  local endpoint="$1"
  local method="${2:-GANDI_HTTP_GET}"
  local fdin="${3:-}"
  shift
  shift
  shift

  method="${!method}"
  dc::argument::check endpoint "$GANDI_TYPE_ENDPOINT" || return
  dc::argument::check method "$GANDI_TYPE_METHOD" || return

  local out
  # XXX http has to be redone - not really usable right now because of headers strategy
  dc::http::request "$GANDI_API_SERVICE/$endpoint" "$method" "$fdin" /dev/stdout "Authorization: Apikey $DC_PRIVATE_APIKEY" "Content-type: application/json" "$@" || {
    # XXX error out appropriately here with meaningful and actionnable feedback
    dc::error::detail::set "Gandi server unreachable. You may have no network connection, or their service is down / unreachable."
    dc::logger::error "No net"
    return "$ERROR_GANDI_NETWORK"
  }

  [ "$DC_HTTP_STATUS" != "404" ] || {
    dc::error::detail::set 404
    return "$ERROR_GANDI_BROKEN"
  }

  [ "$DC_HTTP_STATUS" != "403" ] || {
    dc::error::detail::set 403
    return "$ERROR_GANDI_AUTHORIZATION"
  }

  [ "$DC_HTTP_STATUS" != "401" ] || {
    dc::error::detail::set 401
    return "$ERROR_GANDI_AUTHORIZATION"
  }

  [ "$DC_HTTP_STATUS" == "200" ] || [ "$DC_HTTP_STATUS" == "201" ] || {
    dc::error::detail::set "$DC_HTTP_STATUS"
    return "$ERROR_GANDI_GENERIC"
  }
  printf "$out"
}

gandi::requestor::livedns(){
  local domain="${1:-}"
  local sub="${2:-}"
  local method="${3:-}"
  local fdin="${4:-}"
  local endpoint="livedns/domains"

  [ ! "$domain" ] || {
    dc::argument::check domain "$GANDI_TYPE_DOMAIN" || return
    endpoint="$endpoint/$domain"
  }

  [ ! "$sub" ] || endpoint="$endpoint/$sub"

  gandi::requestor::api "$endpoint" "$method" "$fdin" || return
}

#########################################################
# Domains
#########################################################
gandi::api::domains::list(){
  gandi::requestor::livedns
}

gandi::api::domains::create(){
  local fd="$1"

  gandi::requestor::livedns "" "" GANDI_HTTP_POST "$fd" || return
}

gandi::api::domains::read(){
  local domain="$1"

  gandi::requestor::livedns "$domain" || return
}

gandi::api::domains::update(){
  local domain="$1"
  local fd="$2"

  gandi::requestor::livedns "$domain" "" GANDI_HTTP_PATCH "$fd" || return
}

#########################################################
# Per domain, DNSSEC keys
#########################################################
gandi::api::keys::list(){
  local domain="$1"

  gandi::requestor::livedns "$domain" "keys" || return
}

gandi::api::keys::create(){
  local domain="$1"
  local fd="$2"

  gandi::requestor::livedns "$domain" "keys" GANDI_HTTP_POST "$fd" || return
}

gandi::api::keys::read(){
  local domain="$1"
  local id="$2"

  dc::argument::check id "$GANDI_TYPE_UUID" || return

  gandi::requestor::livedns "$domain" "keys/$id" || return
}

gandi::api::keys::delete(){
  local domain="$1"
  local id="$2"

  dc::argument::check id "$GANDI_TYPE_UUID" || return

  gandi::requestor::livedns "$domain" "keys/$id" GANDI_HTTP_DELETE || return
}

#########################################################
# Per domain, nameservers
#########################################################
gandi::api::nameservers::list(){
  local domain="$1"

  gandi::requestor::livedns "$domain" "nameservers" || return
}

#########################################################
# Per domain, records
#########################################################
gandi::api::records::list(){
  local domain="$1"

  gandi::requestor::livedns "$domain" "records" || return
}

gandi::api::records::replace(){
  local domain="$1"
  local fd="$2"

  gandi::requestor::livedns "$domain" "records" GANDI_HTTP_PUT "$fd" || return
}

# Do we need this? What about replace with "empty content"?
gandi::api::records::purge(){
  local domain="$1"

  gandi::requestor::livedns "$domain" "records" GANDI_HTTP_DELETE "" || return
}

gandi::api::snapshots::list(){
  local domain="$1"

  gandi::requestor::livedns "$domain" "snapshots" || return
}

gandi::api::snapshots::create(){
  local domain="$1"
  local id="$2"
  local fd="$3"

  dc::argument::check id "$GANDI_TYPE_UUID" || return

  gandi::requestor::livedns "$domain" "snapshots/$id" GANDI_HTTP_POST "$fd" || return
}

gandi::api::snapshots::read(){
  local domain="$1"
  local id="$2"

  dc::argument::check id "$GANDI_TYPE_UUID" || return

  gandi::requestor::livedns "$domain" "snapshots/$id" || return
}

gandi::api::snapshots::delete(){
  local domain="$1"
  local id="$2"

  dc::argument::check id "$GANDI_TYPE_UUID" || return

  gandi::requestor::livedns "$domain" "snapshots/$id" GANDI_HTTP_DELETE "" || return
}

"""#
