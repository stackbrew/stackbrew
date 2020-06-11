package shart

// This package is a copy of my generic bash library: https://github.com/dubo-dubon-duponey/sh-art that I the gandi shell API is based on

script:: #"""
##########################################################################
# lib-dc-sh-art, the library version
# Released under MIT License
# Copyright (c) 2020 Dubo Dubon Duponey
##########################################################################
DC_LIB_VERSION="v1.0.0-54-gd37bd73"
DC_LIB_REVISION="d37bd732c5b5db72f24a031c208a281abbddc78f"
DC_LIB_BUILD_DATE="Mon, 23 Mar 2020 16:27:09 -0700"
DC_LIB_BUILD_PLATFORM="Darwin TarMac.attlocal.net 17.7.0 Darwin Kernel Version 17.7.0: Sun Jun  2 20:31:42 PDT 2019; root:xnu-4570.71.46~1/RELEASE_X86_64 x86_64"

# This thing is not getting any better
haveBash(){
  local psout

  # The best approach requires procps to be installed
  if command -v ps > /dev/null; then
    # And this is good, but...
    if ! psout="$(ps -p $$ -c -o command= 2>/dev/null)"; then
      # busybox...
      # shellcheck disable=SC2009
      psout="$(ps -o ppid,comm | grep "^\s*$$ ")"
      psout="${psout##* }"
    fi
    if [ "$psout" != "bash" ]; then
      >&2 printf "[%s] %s\n" "$(date)" "This only works with bash"
      return 144
    fi
    return 0
  fi

  # This is really a survival fallback, and probably not that robust
  >&2 printf "[%s] %s\n" "$(date)" "Your system lacks ps"
  if [ ! "$BASH" ] || [ "$(command -v bash)" != "$BASH" ]; then
    >&2 printf "[%s] %s\n" "$(date)" "This only works with bash. BASH: $BASH - command -v bash: $(command -v bash)"
    return 144
  fi
  return 0
}

haveGrep(){
  # The reason we check that now is that grep is central to many validation mechanism
  # If we would check using the library itself, that would introduce circular deps (require vs. internal) and costly lookups
  if ! command -v "grep" >/dev/null; then
    >&2 printf "[%s] %s\n" "$(date)" "You need grep for this to work"
    return 144
  fi
}

# haveBash || exit
haveGrep || exit

dc::internal::parse_args(){
  # Flag parsing
  local isFlag=true
  local x=0
  local i
  local name
  local value

  for i in "$@"; do
    # First argument no starting with a dash means we are done with flags and processing arguments
    [ "${i:0:1}" == "-" ] || isFlag=false
    if [ "$isFlag" == "false" ]; then
      x=$(( x + 1 ))
      n=DC_PARGE_$x
      if [ ! "${!n}" ]; then
        # shellcheck disable=SC2140
        readonly "DC_PARGE_$x"=true
        # shellcheck disable=SC2140
        readonly "DC_PARGV_$x"="$i"
      fi
      continue
    fi

    # Otherwise, it's a flag, get everything after the leading -
    name="${i:1}"
    value=
    # Remove a possible second char -
    [ "${name:0:1}" != "-" ] || name=${name:1}
    # Get the value, if we have an equal sign
    [[ $name == *"="* ]] && value=${name#*=}
    # Now, Get the name
    name=${name%=*}
    # Clean up the name: replace dash by underscore and uppercase everything
    name=$(printf "%s" "$name" | tr "-" "_" | tr '[:lower:]' '[:upper:]')

    # Set the variable
    # shellcheck disable=SC2140
    readonly "DC_ARGV_$name"="$value"
    # shellcheck disable=SC2140
    readonly "DC_ARGE_$name"=true
  done
}

# Makes the named argument mandatory on the command-line
dc::args::flag::validate(){
  local var
  local varexist
  local regexp="$2"
  local optional="$3"
  local caseInsensitive="$4"

  local args=(-q)
  [ ! "$caseInsensitive" ] || args+=(-i)

  var="DC_ARGV_$(printf "%s" "$1" | tr "-" "_" | tr '[:lower:]' '[:upper:]')"
  varexist="DC_ARGE_$(printf "%s" "$1" | tr "-" "_" | tr '[:lower:]' '[:upper:]')"

  if [ ! "${!varexist}" ]; then
    [ "$optional" ] && return
    dc::error::detail::set "$(printf "%s" "$1" | tr "_" "-" | tr '[:upper:]' '[:lower:]')"
    return "$ERROR_ARGUMENT_MISSING"
  fi

  if [ "$regexp" ]; then
    [ "$regexp" == "^$" ] && [ ! "${!var}" ] && return
    if ! printf "%s" "${!var}" | dc::internal::grep "${args[@]}" "$regexp"; then
      dc::error::detail::set "$(printf "%s" "$1" | tr "_" "-" | tr '[:upper:]' '[:lower:]') (${!var} vs. $regexp)"
      return "$ERROR_ARGUMENT_INVALID"
    fi
  fi
}

dc::args::arg::validate(){
  local var="DC_PARGV_$1"
  local varexist="DC_PARGE_$1"
  local regexp="$2"
  local optional="$3"
  local caseInsensitive="$4"

  local args=(-q)
  [ ! "$caseInsensitive" ] || args+=(-i)

  if [ ! "${!varexist}" ]; then
    [ "$optional" ] && return
    dc::error::detail::set "$1"
    return "$ERROR_ARGUMENT_MISSING"
  fi

  if [ "$regexp" ]; then
    [ "$regexp" == "^$" ] && [ ! "${!var}" ] && return

    if ! printf "%s" "${!var}" | dc::internal::grep "${args[@]}" "$regexp"; then
      dc::error::detail::set "$1 (${!var} vs. $regexp)"
      return "$ERROR_ARGUMENT_INVALID"
    fi
  fi
}

# This method obviously does not check its own arguments
dc::argument::check(){
  local value="${!1}"
  local regexp="$2"

  dc::internal::grep -q "$regexp" <<< "$value" \
    || {
      dc::error::detail::set "$1 ($value - $regexp)"
      return "$ERROR_ARGUMENT_INVALID"
    }
}

export _DC_INTERNAL_CLI_USAGE=""
export _DC_INTERNAL_CLI_OPTS=()

# The method being called when the "help" flag is used (by default --help or -h) is passed to the script
# Override this method in your script to define your own help
dc::commander::help(){
  local name="$1"
  local license="$2"
  local shortdesc="$3"
  local shortusage="$4"
  local long="$5"
  local examples="$6"

  dc::output::h1 "$name"
  dc::output::quote "$shortdesc"

  dc::output::h2 "Usage"
  dc::output::text "$name $shortusage"
  dc::output::break
  dc::output::break
  dc::output::text "$name --help"
  dc::output::break
  dc::output::text "$name --version"
  dc::output::break

  # XXX annoying that -s and --insecure are first - fix it
  if [ "$long" ]; then
    dc::output::h2 "Arguments"
    local v
    while IFS= read -r v || [ "$v" ]; do
      [ ! "$v" ] || dc::output::bullet "$v"
    done <<< "$long"
    dc::output::break
  fi

  dc::output::h2 "Logging control"
  dc::output::bullet "$(printf "%s" "${name}" | tr "-" "_" | tr "[:lower:]" "[:upper:]")_LOG_LEVEL=(debug|info|warning|error) will adjust logging level (default to info)"
  dc::output::bullet "$(printf "%s" "${name}" | tr "-" "_" | tr "[:lower:]" "[:upper:]")_LOG_AUTH=true will also log sensitive/credentials information (CAREFUL)"

# This is visible through the --version flag anyway...
#  dc::output::h2 "Version"
#  dc::output::text "$version"
#  dc::output::break

  if [ "$examples" ]; then
    dc::output::h2 "Examples"
    local v
    while IFS= read -r v || [ "$v" ]; do
      if [ "${v:0:1}" == ">" ]; then
        printf "    %s\n" "$v"
      elif [ "$v" ]; then
        dc::output::bullet "$v"
      else
        dc::output::break
      fi
    done <<< "$examples"
    dc::output::break
  fi

  dc::output::h2 "License"
  dc::output::text "$license"
  dc::output::break
  dc::output::break

}

# The method being called when the "version" flag is used (by default --version or -v) is passed to the script
# Override this method in your script to define your own version output
dc::commander::version(){
  printf "%s %s\n" "$1" "$2"
}


dc::commander::declare::arg(){
  local number="$1"
  local validator="$2"
  local fancy="$3"
  local description="$4"
  local optional="$5"

  local long="$fancy"
  long=$(printf "%-20s" "$long")
  if [ "$optional" ]; then
    fancy="[$fancy]"
    long="$long (optional)"
  else
    long="$long           "
  fi

  if [ "${_DC_INTERNAL_CLI_USAGE}" ]; then
    fancy=" $fancy"
  fi

  _DC_INTERNAL_CLI_USAGE="${_DC_INTERNAL_CLI_USAGE}$fancy"
  _DC_INTERNAL_CLI_OPTS+=( "$long $description" )

  # Asking for help or version, do not validate
  if [ "${DC_ARGE_HELP}" ] || [ "${DC_ARGE_H}" ] || [ "${DC_ARGE_VERSION}" ]; then
    return
  fi

  # Otherwise, validate
  dc::args::arg::validate "$number" "$validator" "$optional" || exit
}

dc::commander::declare::flag(){
  local name="$1"
  local validator="$2"
  local description="$3"
  local optional="$4"
  local alias="$5"

  local display="--$name"
  local long="--$name"
  if [ "$alias" ]; then
    display="$display/-$alias"
    long="$long, -$alias"
  fi
  if [ "$validator" ] && [ "$validator" != "^$" ]; then
    display="$display=$validator"
    long="$long=value"
  fi
  long=$(printf "%-20s" "$long")
  if [ "$optional" ]; then
    display="[$display]"
    long="$long (optional)"
  else
    long="$long           "
  fi
  if [ "${_DC_INTERNAL_CLI_USAGE}" ]; then
    display=" $display"
  fi

  _DC_INTERNAL_CLI_USAGE="${_DC_INTERNAL_CLI_USAGE}$display"
  # XXX add padding
  _DC_INTERNAL_CLI_OPTS+=( "$long $description" )

  # Asking for help or version, do not validate
  if [ "${DC_ARGE_HELP}" ] || [ "${DC_ARGE_H}" ] || [ "${DC_ARGE_VERSION}" ]; then
    return
  fi

  local m
  local s

  # Otherwise, validate
  m="DC_ARGE_$(printf "%s" "$name" | tr "-" "_" | tr '[:lower:]' '[:upper:]')"
  s="DC_ARGE_$(printf "%s" "$alias" | tr "-" "_" | tr '[:lower:]' '[:upper:]')"

  # First make sure we do not have a double dip
  if [ "${!m}" ] && [ "${!s}" ]; then
    dc::logger::error "You cannot specify $name and $alias at the same time"
    return "$ERROR_ARGUMENT_INVALID"
  fi

  # Validate the alias or the main one
  if [ "${!s}" ]; then
    dc::args::flag::validate "$alias" "$validator" "$optional" || exit
  else
    dc::args::flag::validate "$name" "$validator" "$optional" || exit
  fi
}

# This is the entrypoint you should call in your script
# It will take care of hooking the --help/-h and --version flags, and configure logging according to
# environment variables (by default LOG_LEVEL and LOG_AUTH).
# It will honor the "--insecure" flag to ignore TLS errors
# It will honor the "-s/--silent" flag to silent any output to stderr
# You should define CLI_VERSION, CLI_LICENSE, CLI_DESC and CLI_USAGE before calling init
# You may define CLI_NAME if you want your name to be different from the script name (not recommended)
# This method will use the *CLI_NAME*_LOG_LEVEL (debug, info, warning, error) environment variable to set the logger
# If you want a different environment variable to be used, pass its name as the first argument
# The same goes for the *CLI_NAME*_LOG_AUTH environment variable

# shellcheck disable=SC2120
dc::commander::initialize(){
  dc::commander::declare::flag "silent" "^$" "no logging (overrides log level)" optional "s"

  local loglevelvar
  local logauthvar
  local level
  loglevelvar="$(printf "%s" "${CLI_NAME:-${DC_DEFAULT_CLI_NAME}}" | tr "-" "_" | tr "[:lower:]" "[:upper:]")_LOG_LEVEL"
  logauthvar="$(printf "%s" "${CLI_NAME:-${DC_DEFAULT_CLI_NAME}}" | tr "-" "_" | tr "[:lower:]" "[:upper:]")_LOG_AUTH"

  [ ! "${1}" ] || loglevelvar="$1"
  [ ! "${2}" ] || logauthvar="$2"

  # If we have a log level, set it
  if [ "${!loglevelvar}" ]; then
    # Configure the logger from the LOG_LEVEL env variable
    level="$(printf "DC_LOGGER_%s" "${!loglevelvar}" | tr '[:lower:]' '[:upper:]')"
    dc::internal::logger::setlevel "${!level}"
  fi

  # If the LOG_AUTH env variable is set, honor it and leak
  if [ "${!logauthvar}" ]; then
    dc::configure::http::leak
  fi

  # If the "-s" flag is passed, mute the logger entirely
  if [ -n "${DC_ARGV_SILENT+x}" ] || [ -n "${DC_ARGV_S+x}" ]; then
    dc::configure::logger::mute
  fi

  # If the --insecure flag is passed, allow insecure TLS connections
  if [ "${DC_ARGV_INSECURE+x}" ]; then
    dc::configure::http::insecure
  fi
}

dc::commander::boot(){
  # If we have been asked for --help or -h, show help
  if [ "${DC_ARGE_HELP}" ] || [ "${DC_ARGE_H}" ]; then

    local opts=
    local i
    for i in "${_DC_INTERNAL_CLI_OPTS[@]}"; do
      opts="$opts$i"$'\n'
    done

    dc::commander::help \
      "${CLI_NAME:-${DC_DEFAULT_CLI_NAME}}" \
      "${CLI_LICENSE:-${DC_DEFAULT_CLI_LICENSE}}" \
      "${CLI_DESC:-${DC_DEFAULT_CLI_DESC}}" \
      "${CLI_USAGE:-${_DC_INTERNAL_CLI_USAGE}}" \
      "${CLI_OPTS:-$opts}" \
      "${CLI_EXAMPLES}"
    exit
  fi

  # If we have been asked for --version, show the version
  if [ "${DC_ARGE_VERSION}" ]; then
    dc::commander::version "${CLI_NAME:-${DC_DEFAULT_CLI_NAME}}" "${CLI_VERSION:-${DC_DEFAULT_CLI_VERSION}}"
    exit
  fi

}

_DC_INTERNAL_ERROR_CODEPOINT=143
_DC_INTERNAL_ERROR_APPCODEPOINT=2
_DC_INTERNAL_ERROR_DETAIL=

dc::error::register(){
  local name="$1"

  dc::argument::check name "$DC_TYPE_VARIABLE"

  _DC_INTERNAL_ERROR_CODEPOINT=$(( _DC_INTERNAL_ERROR_CODEPOINT + 1 ))

  # XXX bash3
  # declare -g "${name?}"="$_DC_INTERNAL_ERROR_CODEPOINT"
  read -r "${name?}" <<<"$_DC_INTERNAL_ERROR_CODEPOINT"
  export "${name?}"
  readonly "${name?}"
}

dc::error::appregister(){
  local name="$1"

  dc::argument::check name "$DC_TYPE_VARIABLE"

  _DC_INTERNAL_ERROR_APPCODEPOINT=$(( _DC_INTERNAL_ERROR_APPCODEPOINT + 1 ))

  read -r "${name?}" <<<"$_DC_INTERNAL_ERROR_APPCODEPOINT"
  export "${name?}"
  readonly "${name?}"
}

dc::error::lookup(){
  local code="$1"
  local errname

  dc::argument::check code "$DC_TYPE_UNSIGNED"

  errname="$(env | dc::internal::grep "^ERROR_[^=]+=$code$")"
  printf "%s" "${errname%=*}"
}

dc::error::detail::set(){
  _DC_INTERNAL_ERROR_DETAIL="$1"
}

dc::error::detail::get(){
  printf "%s" "$_DC_INTERNAL_ERROR_DETAIL"
}

dc::fs::rm(){
  local f="$1"

  rm -f "$f" 2>/dev/null \
    || {
      dc::error::detail::set "$f"
      return "$ERROR_FILESYSTEM"
    }
}

dc::fs::mktemp(){
  mktemp -q "${TMPDIR:-/tmp}/$1.XXXXXX" 2>/dev/null || mktemp -q || return "$ERROR_FILESYSTEM"
}

dc::fs::isdir(){
  local path="$1"
  local writable="$2"
  local createIfMissing="$3"

  [ ! "$createIfMissing" ] || mkdir -p "$path" 2>/dev/null || return "$ERROR_FILESYSTEM"
  if [ ! -d "$path" ] || [ ! -r "$path" ] || { [ "$writable" ] && [ ! -w "$path" ]; }  ; then
    dc::error::detail::set "$path"
    return "$ERROR_FILESYSTEM"
  fi
}

dc::fs::isfile(){
  local path="$1"
  local writable=$2
  local createIfMissing=$3
  [ ! "$createIfMissing" ] || touch "$path"
  if [ ! -f "$path" ] || [ ! -r "$path" ] || { [ "$writable" ] && [ ! -w "$path" ]; }  ; then
    dc::error::detail::set "$path"
    return "$ERROR_FILESYSTEM"
  fi
}

#####################################
# Private
#####################################

_DC_INTERNAL_HTTP_REDACT=true
# Given the nature of the matching we do, any header that contains these words will match, including proxy-authorization and set-cookie
_DC_INTERNAL_HTTP_PROTECTED_HEADERS=( authorization cookie user-agent )

DC_HTTP_STATUS=
DC_HTTP_REDIRECTED=
DC_HTTP_HEADERS=()

dc::wrapped::curl(){
  local err
  local ex
  local line
  local key
  local value
  local isRedirect

  # Reset everything
  local i
  for i in "${DC_HTTP_HEADERS[@]}"; do
    read -r "DC_HTTP_HEADER_$i" <<< ""
  done
  DC_HTTP_HEADERS=()
  DC_HTTP_STATUS=
  DC_HTTP_REDIRECTED=

  exec 3>&1
  err="$(curl "$@" 2>&1 1>&3)"
  ex="$?"
  if [ "$ex" != 0 ]; then
    exec 3>&-
    [ "$ex" == 7 ] && return "$ERROR_CURL_CONNECTION_FAILED"
    [ "$ex" == 6 ] && return "$ERROR_CURL_DNS_FAILED"
    dc::error::detail::set "$err"
    return "$ERROR_BINARY_UNKNOWN_ERROR"
  fi

  while read -r line; do
    # > request
    # } bytes sent
    # { bytes received
    # * info
    [ "${line:0:1}" != "<" ] && continue

    # Ignoring the leading character, and trim for content
    line=$(printf "%s" "${line:1}" | sed -E "s/^[[:space:]]*//" | sed -E "s/[[:space:]]*\$//")

    # Ignore empty content
    [ "$line" ] || continue

    # Is it a status line
    if printf "%s" "$line" | dc::internal::grep -q "^HTTP/[0-9.]+ [0-9]+"; then
      isRedirect=
      line="${line#* }"
      DC_HTTP_STATUS="${line%% *}"
      [ "${DC_HTTP_STATUS:0:1}" == "3" ] && isRedirect=true
      dc::logger::debug "[dc-http] STATUS: $DC_HTTP_STATUS"
      dc::logger::debug "[dc-http] REDIRECTED: $isRedirect"
      continue
    fi

    # Not a header? Move on
    [[ "$line" == *":"* ]] || continue

    # Parse header
    key="$(printf "%s" "${line%%:*}" | tr "-" "_" | tr '[:lower:]' '[:upper:]')"
    value="${line#*: }"

    # Expunge what we log
    [ "$_DC_INTERNAL_HTTP_REDACT" ] && [[ "${_DC_INTERNAL_HTTP_PROTECTED_HEADERS[*]}" == *"$key"* ]] && value=REDACTED
    dc::logger::debug "[dc-http] $key | $value"

    if [ "$isRedirect" ]; then
      [ "$key" == "LOCATION" ] && export DC_HTTP_REDIRECTED="$value"
      continue
    fi
    DC_HTTP_HEADERS+=("$key")
    read -r "DC_HTTP_HEADER_$key" <<<"$value"

  done < <(printf "%s" "$err")

  exec 3>&-
}

##########################################################################
# HTTP client
# ------
# From a call to dc::http::request consumer gets the following variables:
# - DC_HTTP_STATUS: 3 digit status code after redirects
# - DC_HTTP_REDIRECTED: final redirect location, if any
# - DC_HTTP_HEADERS: list of the response headers keys
# - DC_HTTP_HEADER_XYZ - where XYZ is the header key, for all headers that have been set
# - DC_HTTP_BODY: temporary filename containing the raw body
#
# This module depends only on logger
# Any non http failure will result in an empty status code

#####################################
# Configuration hooks
#####################################

dc::configure::http::leak(){
  dc::logger::warning "[dc-http] YOU ASKED FOR FULL-BLOWN HTTP DEBUGGING: THIS WILL LEAK SENSITIVE INFORMATION TO STDERR."
  dc::logger::warning "[dc-http] Unless you are debugging actively and you really know what you are doing, you MUST STOP NOW."
  _DC_INTERNAL_HTTP_REDACT=
}

dc::configure::http::insecure(){
  dc::logger::warning "[dc-http] YOU ARE USING THE INSECURE FLAG."
  dc::logger::warning "[dc-http] This basically means your communication with the server is as secure as if there was NO TLS AT ALL."
  dc::logger::warning "[dc-http] Unless you really, really, REALLY know what you are doing, you MUST RECONSIDER NOW."
  _DC_PRIVATE_HTTP_INSECURE=true
}

#####################################
# Public API
#####################################

# Dumps all relevant data from the last HTTP request to the logger (warning)
# XXX fixme: this will dump sensitive information and should be
dc::http::dump::headers() {
  dc::logger::warning "[dc-http] status: $DC_HTTP_STATUS"
  dc::logger::warning "[dc-http] redirected to: $DC_HTTP_REDIRECTED"
  dc::logger::warning "[dc-http] headers:"

  # shellcheck disable=SC2034
  local redacted=REDACTED
  local value
  local i

  for i in "${DC_HTTP_HEADERS[@]}"; do
    value=DC_HTTP_HEADER_$i
    [ "$_DC_INTERNAL_HTTP_REDACT" ] && [[ "${_DC_INTERNAL_HTTP_PROTECTED_HEADERS[*]}" == *"$i"* ]] && value=redacted
    dc::logger::warning "[dc-http] $i: ${!value}"
  done
}

dc::http::request(){
  dc::require curl || return

  # Grab the named parameters first
  local url="$1"
  local method="${2:-HEAD}"
  local payloadFile="$3"
  local outputFile="${4:-/dev/stdout}"
  shift
  shift
  shift
  shift

  # Build the curl request
  local curlOpts=( "$url" "-v" "-L" "-s" )
  local output="curl"

  # Special case HEAD, damn you curl
  [ "$method" == "HEAD" ]           && curlOpts+=("-I" "-o/dev/null") \
                                    || curlOpts+=("-X" "$method" "-o$outputFile")

  [ "$payloadFile" ]                && curlOpts+=("--data-binary" "@$payloadFile")
  [ "$_DC_PRIVATE_HTTP_INSECURE" ]  && curlOpts+=("--insecure" "--proxy-insecure")

  # Add in all remaining parameters as additional headers
  for i in "$@"; do
    curlOpts+=("-H" "$i")
  done

  # Log the command
  for i in "${curlOpts[@]}"; do
    # -args are logged as-is
    [ "${i:0:1}" == "-" ] && output="$output $i" && continue

    # If we redact, filter out sensitive headers
    # XXX this is overly aggressive, and will match any header that is a substring of one of the protected headers
    [ "$_DC_INTERNAL_HTTP_REDACT" ] && [[ "${_DC_INTERNAL_HTTP_PROTECTED_HEADERS[*]}" == *$(printf "%s" "${i%%:*}" | tr '[:upper:]' '[:lower:]')* ]] \
      && output="$output \"${i%%:*}: REDACTED\"" \
      && continue

    # Otherwise, pass them in as-is
    output="$output \"$i\" "
  done

  dc::logger::debug "[dc-http] $output"

  dc::wrapped::curl "${curlOpts[@]}"
}

# Used solely below - as a caching mechanism so not to query grep every time preflight
dc::internal::isgnugrep(){
  local gver
  if [ ! "${_DC_INTERNAL_NOT_GNUGREP+x}" ]; then
    _DC_INTERNAL_NOT_GNUGREP=1
    gver="$(grep --version 2>/dev/null)"
    _="$(grep -q "gnu" <<<"$gver")" && _DC_INTERNAL_NOT_GNUGREP=0
    export _DC_INTERNAL_NOT_GNUGREP
  fi
  return $_DC_INTERNAL_NOT_GNUGREP
}

# XXX this will freeze if there is no stdin and only one argument for example
# Also, we do not do any effort to have fine-grained erroring here (everything wonky ends-up with BINARY_UNKNOWN_ERROR)
# Finally, we of course do not try to validate arguments since that would introduce a circular dep
dc::internal::grep(){
  local extended="-E"
  local res

  # If gnu grep, use -P for extended
  dc::internal::isgnugrep && extended="-P"

  res="$(grep "$extended" "$@" 2>/dev/null)"
  case $? in
    0)
      printf "%s" "$res"
      return 0
    ;;
    1)
      return "$ERROR_GREP_NO_MATCH"
    ;;
    *)
      return "$ERROR_BINARY_UNKNOWN_ERROR"
    ;;
  esac
}

#####################################
# Configuration hooks
#####################################

dc::internal::logger::setlevel() {
  local level="$1"

  dc::argument::check level "$DC_TYPE_INTEGER" && [ "$level" -ge "$DC_LOGGER_ERROR" ] && [ "$level" -le "$DC_LOGGER_DEBUG" ] || level="$DC_LOGGER_INFO"

  _DC_INTERNAL_LOGGER_LEVEL="$level"
  if [ "$_DC_INTERNAL_LOGGER_LEVEL" == "$DC_LOGGER_DEBUG" ]; then
    dc::logger::warning "[Logger] YOU ARE LOGGING AT THE DEBUG LEVEL. This is NOT recommended for production use, and WILL LIKELY LEAK sensitive information to stderr."
  fi
}

dc::internal::logger::log(){
  local prefix="$1"
  shift

  local level="DC_LOGGER_$prefix"
  local style="DC_LOGGER_STYLE_${prefix}[@]"
  local i

  [ "$_DC_INTERNAL_LOGGER_LEVEL" -lt "${!level}" ] && return

  [ "$TERM" ] && [ -t 2 ] && >&2 tput "${!style}"
  for i in "$@"; do
    >&2 printf "[%s] [%s] %s\n" "$(date)" "$prefix" "$i"
  done
  [ "$TERM" ] && [ -t 2 ] && >&2 tput op || true
}

dc::configure::logger::setlevel::debug(){
  dc::internal::logger::setlevel "$DC_LOGGER_DEBUG"
}

dc::configure::logger::setlevel::info(){
  dc::internal::logger::setlevel "$DC_LOGGER_INFO"
}

dc::configure::logger::setlevel::warning(){
  dc::internal::logger::setlevel "$DC_LOGGER_WARNING"
}

dc::configure::logger::setlevel::error(){
  dc::internal::logger::setlevel "$DC_LOGGER_ERROR"
}

dc::configure::logger::mute() {
  _DC_INTERNAL_LOGGER_LEVEL=0
}

#####################################
# Public API
#####################################

dc::logger::debug(){
  dc::internal::logger::log "DEBUG" "$@"
}

dc::logger::info(){
  dc::internal::logger::log "INFO" "$@"
}

dc::logger::warning(){
  dc::internal::logger::log "WARNING" "$@"
}

dc::logger::error(){
  dc::internal::logger::log "ERROR" "$@"
}

# Output fancy shit. Used by the output module.
dc::internal::style(){
  local vName="DC_OUTPUT_$1[@]"
  local i
  for i in "${!vName}"; do
    # shellcheck disable=SC2086
    [ "$TERM" ] && [ -t 1 ] && >&1 tput $i
  done
}

# Centering is tricky to get right with unicode chars - both wc and printf will count octets...
dc::output::h1(){
  local i="$1"
  local width
  local even
  local ln

  width=$(tput cols)
  ln=${#i}
  even=$(( (ln + width) & 1 ))

  printf "\n"
  printf " %.s" $(seq -s" " $(( width / 4 )))
  dc::internal::style H1_START
  printf " %.s" $(seq -s" " $(( width / 4 )))
  printf " %.s" $(seq -s" " $(( width / 4 )))
  dc::internal::style H1_END
  printf " %.s" $(seq -s" " $(( width / 4 + even )))
  printf "\n"

  printf " %.s" $(seq -s" " $(( (width - ln) / 2)))
  printf "%s" "$i" | tr '[:lower:]' '[:upper:]'
  printf " %.s" $(seq -s" " $(( (width - ln) / 2)))
  printf "\n"
  printf "\n"
}

dc::output::h2(){
  local i="$1"
  local width

  width=$(tput cols)

  printf "\n"
  printf "  "

  dc::internal::style H2_START
  printf "%s" "  $i"
  printf " %.s" $(seq -s" " $(( width / 2 - ${#i} - 4 )))
  dc::internal::style H2_END

  printf "\n"
  printf "\n"
}

dc::output::emphasis(){
  local i

  dc::internal::style EMPHASIS_START
  for i in "$@"; do
    printf "%s " "$i"
  done
  dc::internal::style EMPHASIS_END
}

dc::output::strong(){
  local i

  dc::internal::style STRONG_START
  for i in "$@"; do
    printf "%s " "$i"
  done
  dc::internal::style STRONG_END
}

dc::output::bullet(){
  local i

  for i in "$@"; do
    printf "    • %s\n" "$i"
  done
}

#dc::output::code(){
#}

#dc::output::table(){
#}

dc::output::quote(){
  local i

  dc::internal::style QUOTE_START
  for i in "$@"; do
    printf "  > %s\n" "$i"
  done
  dc::internal::style QUOTE_END
}

dc::output::text(){
  local i

  printf "    "
  for i in "$@"; do
    printf "%s " "$i"
  done
}

dc::output::rule(){
  local width

  dc::argument::check width "$DC_TYPE_INTEGER"

  width=$(tput cols)
  dc::internal::style RULE_START
  printf " %.s" $(seq -s" " "$width")
  dc::internal::style RULE_END
}

dc::output::break(){
  printf "\n"
}

dc::output::json() {
  # No jq? Just echo the stuff
  if ! dc::require jq; then
    printf "%s" "$1"
    return
  fi

  # Otherwise, print through jq and return on success
  printf "%s" "$1" | jq "." 2>/dev/null \
    || { dc::error::detail::set "$1" && return "$ERROR_ARGUMENT_INVALID"; }
}

dc::prompt::input(){
  local varname="$1"
  local message="$2"
  local silent="$3"
  local timeout="${4:-1000}"
  local args=("-r")

  # Arg validation
  dc::argument::check varname "$DC_TYPE_VARIABLE" || return
  dc::argument::check timeout "$DC_TYPE_UNSIGNED" || return

  # Arg processing
  [ ! "$silent" ]   || args+=("-s")
  [ ! "$timeout" ]  || args+=("-t" "$timeout")

  # Prompt and read
  [ ! -t 2 ] || >&2 printf "%s" "$message"
  # shellcheck disable=SC2162
  if ! read "${args[@]}" "${varname?}"; then
    dc::error::detail::set "$timeout"
    return "$ERROR_ARGUMENT_TIMEOUT"
  fi

  [ ! "$silent" ] || [ ! -t 2 ] || >&2 printf "\n"
}

dc::prompt::question() {
  local message="$1"
  local varname="$2"

  dc::argument::check varname "$DC_TYPE_VARIABLE" || return

  dc::prompt::input "$varname" "$message"
}

dc::prompt::password() {
  local message="$1"
  local varname="$2"

  dc::argument::check varname "$DC_TYPE_VARIABLE" || return

  dc::prompt::input "$varname" "$message" silent
}

dc::prompt::credentials() {
  local message="$1"
  local varname="$2"
  local pmessage="$1"
  local pvarname="$2"

  dc::argument::check varname "$DC_TYPE_VARIABLE" || return
  dc::argument::check pvarname "$DC_TYPE_VARIABLE" || return

  dc::prompt::question "$message" "$varname"

  # No answer? Stay anonymous
  [ ! "${!varname}" ] && return

  # Otherwise, ask for password
  dc::prompt::password "$pmessage" "$pvarname"
}

dc::prompt::confirm(){
  local message="$1"
  local _

  # Flash it
  >&2 tput bel
  >&2 tput flash

  # Don't care about the return value
  dc::prompt::input _ "$message"
}

dc::require::platform(){
  [[ "$*" == *"$(uname)"* ]] || return "$ERROR_REQUIREMENT_MISSING"
}

dc::require::platform::mac(){
  dc::error::detail::set "macOS"
  dc::require::platform "$DC_PLATFORM_MAC"
}

dc::require::platform::linux(){
  dc::error::detail::set "linux"
  dc::require::platform "$DC_PLATFORM_LINUX"
}

dc::require::version(){
  local binary="$1"
  local versionFlag="$2"
  local varname

  dc::argument::check binary "^.+$" || return
  dc::argument::check versionFlag "^.+$" || return

  varname=DC_DEPENDENCIES_V_$(printf "%s" "$binary" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  if [ ! ${!varname+x} ]; then
    while read -r line; do
      if printf "%s" "$line" | grep -qE "^[^0-9.]*([0-9]+[.][0-9]+).*"; then
        # Duh shit is harder with bash3
        read -r "${varname?}" <<<"$(sed -E 's/^[^0-9.]*([0-9]+[.][0-9]+).*/\1/' <<<"$line")"
        # XXX bash 4+ only?
        # declare -g "${varname?}"="$(printf "%s" "$line" | sed -E 's/^[^0-9.]*([0-9]+[.][0-9]+).*/\1/')"
        break
      fi
    # XXX interestingly, some application will output the result on stderr/stdout (jq version 1.3 is such an example)
    # We do not try to workaround here
    done <<< "$($binary "$versionFlag" 2>/dev/null)"
  fi
  printf "%s" "${!varname}"
}

dc::require(){
  local binary="$1"
  local versionFlag="$2"
  local version="$3"
  local provider="$4"
  [ "$provider" ] && provider="$(printf " (provided by: %s)" "$provider")"
  local varname
  local cVersion

  dc::argument::check binary "^.+$" || return

  varname=_DC_DEPENDENCIES_B_$(printf "%s" "$binary" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  if [ ! ${!varname+x} ]; then
    command -v "$binary" >/dev/null \
      || {
        dc::error::detail::set "$binary${provider}"
        return "$ERROR_REQUIREMENT_MISSING"
      }
    read -r "${varname?}" <<<"true"
    # XXX
    # declare -g "${varname?}"=true
  fi

  [ "$versionFlag" ] || return 0
  dc::argument::check version "$DC_TYPE_FLOAT" || return

  cVersion="$(dc::require::version "$binary" "$versionFlag")"
  [ "${cVersion%.*}" -gt "${version%.*}" ] \
    || { [ "${cVersion%.*}" == "${version%.*}" ] && [ "${cVersion#*.}" -ge "${version#*.}" ]; } \
    || {
      dc::error::detail::set "$binary$provider version $version (now: ${!varname})"
      return "$ERROR_REQUIREMENT_MISSING"
    }
}

# Bash reserved exit codes

#1	Catchall for general errors	let "var1 = 1/0"	Miscellaneous errors, such as "divide by zero" and other impermissible operations
#2	Misuse of shell builtins (according to Bash documentation)	empty_function() {}	Missing keyword or command, or permission problem (and diff return code on a failed binary file comparison).
#126	Command invoked cannot execute	/dev/null	Permission problem or command is not an executable
#127	"command not found"	illegal_command	Possible problem with $PATH or a typo
#128	Invalid argument to exit	exit 3.14159	exit takes only integer args in the range 0 - 255 (see first footnote)
#128+n	Fatal error signal "n"	kill -9 $PPID of script	$? returns 137 (128 + 9)
#130	Script terminated by Control-C	Ctl-C	Control-C is fatal error signal 2, (130 = 128 + 2, see above)
#255*	Exit status out of range	exit -1	exit takes only integer args in the range 0 - 255

# Signals

#0	0	On exit from shell
#1	SIGHUP	Clean tidyup
#2	SIGINT	Interrupt
#3	SIGQUIT	Quit
#6	SIGABRT	Abort
#9	SIGKILL	Die Now (cannot be trapped)
#14	SIGALRM	Alarm Clock
#15	SIGTERM	Terminate

# Important...
# Basically, sending a signal manually, bash will wait for the current command to return (also a direct CTRL+C will not kill subprocesses...)
# https://apple.stackexchange.com/questions/123631/why-does-a-shell-script-trapping-sigterm-work-when-run-manually-but-not-when-ru

# $$ to get the current process pid btw
# $! to get the pid of the process that just launched
# otherwise pid="$(ps -fu "$USER" | grep "whatever" | grep -v "grep" | awk '{print $2}')"

# XXX none of this checks arguments

# Mechanism to register "cleanup" methods
_DC_INTERNAL_TRAP_CLEAN=()
_DC_INTERNAL_TRAP_NO_TERM=

dc::trap::register(){
  _DC_INTERNAL_TRAP_CLEAN+=( "$1" )
}

# Trap signals
_DC_INTERNAL_SIGNALS=("" "SIGHUP" "SIGINT" "SIGQUIT" "" "" "SIGABRT" "" "" "SIGKILL" "" "" "" "" "SIGALRM" "SIGTERM")

# Unfortunately, manually sent signals do not forward the exit code for some reason, hence the separate trap declarations
dc::trap::signal::HUP(){
  dc::trap::signal "$1" 129 "$3"
}

dc::trap::signal::INT(){
  dc::trap::signal "$1" 130 "$3"
}

dc::trap::signal::QUIT(){
  dc::trap::signal "$1" 131 "$3"
}

dc::trap::signal::ABRT(){
  dc::trap::signal "$1" 134 "$3"
}

dc::trap::signal::KILL(){
  dc::trap::signal "$1" 137 "$3"
}

dc::trap::signal::ALRM(){
  dc::trap::signal "$1" 142 "$3"
}

dc::trap::signal::TERM(){
  [ "$_DC_INTERNAL_TRAP_NO_TERM" ] && return
  dc::trap::signal "$1" 143 "$3"
}

dc::trap::signal() {
  # Drop the line number, it's always 1 with signals
  local _="$1"
  local ex="${2}"
  local idx

  idx=$(( ex - 128 ))
  dc::logger::error "Interrupted by signal $idx (${_DC_INTERNAL_SIGNALS[idx]}). Last command was: $3"

  exit "$ex"
}

# Trap exit for the actual cleanup
dc::trap::exit() {
  local lineno="$1"
  local ex="$2"
  local i

  if [ "$ex" == 0 ]; then
    dc::logger::debug "Exiting normally"
    return
  fi

  dc::logger::debug "Error!"
  # XXX should kill possible subprocesses hanging around
  # This would SIGTERM the process group (unfortunately means we would catch it again
  # Prevent re-entrancy with SIGTERM
  #sleep 10 &
  # _DC_INTERNAL_TRAP_NO_TERM=true
  # kill -TERM -$$

  for i in "${_DC_INTERNAL_TRAP_CLEAN[@]}"; do
    dc::logger::debug "Cleaning-up: $i"
    "$i" "$ex" "$(dc::error::detail::get)" "$3"
  done

  exit "$ex"
}

dc::trap::err() {
  set +x
  local lineno="$1"
  local code
  code="$(cat -n "$0" |  grep -E "^\s+$lineno\s")"
  dc::logger::error "Error at line $lineno" "Command was: $3" "Code was: $code" "Exception: $(dc::error::lookup "$2")" "Exit: $2"
  exit "$2"
}

true

# shellcheck disable=SC2034
readonly DC_DEFAULT_CLI_NAME=$(basename "$0")
# shellcheck disable=SC2034
readonly DC_DEFAULT_CLI_VERSION="$DC_VERSION (dc: $DC_LIB_VERSION)"
# shellcheck disable=SC2034
readonly DC_DEFAULT_CLI_LICENSE="MIT License"
# shellcheck disable=SC2034
readonly DC_DEFAULT_CLI_DESC="A fancy piece of shcript"

true

# shellcheck disable=SC2034
readonly DC_COLOR_BLACK=0
# shellcheck disable=SC2034
readonly DC_COLOR_RED=1
# shellcheck disable=SC2034
readonly DC_COLOR_GREEN=2
# shellcheck disable=SC2034
readonly DC_COLOR_YELLOW=3
# shellcheck disable=SC2034
readonly DC_COLOR_BLUE=4
# shellcheck disable=SC2034
readonly DC_COLOR_MAGENTA=5
# shellcheck disable=SC2034
readonly DC_COLOR_CYAN=6
# shellcheck disable=SC2034
readonly DC_COLOR_WHITE=7
# shellcheck disable=SC2034
readonly DC_COLOR_DEFAULT=9

true

# shellcheck disable=SC2034
readonly DC_CRYPTO_SHASUM_1=1
# shellcheck disable=SC2034
readonly DC_CRYPTO_SHASUM_224=224
# shellcheck disable=SC2034
# shellcheck disable=SC2034
readonly DC_CRYPTO_SHASUM_256=256
# shellcheck disable=SC2034
readonly DC_CRYPTO_SHASUM_384=384
# shellcheck disable=SC2034
readonly DC_CRYPTO_SHASUM_512=512
# shellcheck disable=SC2034
readonly DC_CRYPTO_SHASUM_512224=512224
# shellcheck disable=SC2034
readonly DC_CRYPTO_SHASUM_512256=512256

# System requirements
dc::error::register ERROR_REQUIREMENT_MISSING

# Generic error to denote that the operation has failed. More specific errors may be provided instead
dc::error::register ERROR_FAILED

# Should be used to convey that a certain operation is not supported
dc::error::register ERROR_UNSUPPORTED

# wrapped grep will return with this if there is no match
dc::error::register ERROR_GREP_NO_MATCH

# any wrapped binary erroring out with an unhandled exception will return this
dc::error::register ERROR_BINARY_UNKNOWN_ERROR

# Any method may return this on argument validation, specifically the ::flag and ::arg validation methods
# shellcheck disable=SC2034
dc::error::register ERROR_ARGUMENT_INVALID

# Thrown if a required argument is missing
dc::error::register ERROR_ARGUMENT_MISSING

# Interactive prompts may timeout and return this
# shellcheck disable=SC2034
dc::error::register ERROR_ARGUMENT_TIMEOUT

# Expectations failed on a file (not readable, writable, doesn't exist, can't be created)
# shellcheck disable=SC2034
dc::error::register ERROR_FILESYSTEM

################## LIBRARY
# Crypto
dc::error::register ERROR_CRYPTO_SHASUM_WRONG_ALGORITHM
dc::error::register ERROR_CRYPTO_SHASUM_FILE_ERROR
dc::error::register ERROR_CRYPTO_SSL_INVALID_KEY
dc::error::register ERROR_CRYPTO_SSL_WRONG_PASSWORD
dc::error::register ERROR_CRYPTO_SSL_WRONG_ARGUMENTS
dc::error::register ERROR_CRYPTO_SHASUM_VERIFY_ERROR
dc::error::register ERROR_CRYPTO_PEM_NO_SUCH_HEADER

# Encoding
dc::error::register ERROR_ENCODING_CONVERSION_FAIL
dc::error::register ERROR_ENCODING_UNKNOWN

# HTTP
dc::error::register ERROR_CURL_CONNECTION_FAILED
dc::error::register ERROR_CURL_DNS_FAILED


export ERROR_SYSTEM_1=1
export ERROR_SYSTEM_2=2
export ERROR_SYSTEM_126=126
export ERROR_SYSTEM_127=127
export ERROR_SYSTEM_128=128
export ERROR_SYSTEM_255=255

readonly ERROR_SYSTEM_1
readonly ERROR_SYSTEM_2
readonly ERROR_SYSTEM_126
readonly ERROR_SYSTEM_127
readonly ERROR_SYSTEM_128
readonly ERROR_SYSTEM_255

export ERROR_SYSTEM_SIGHUP=129
export ERROR_SYSTEM_SIGINT=130
export ERROR_SYSTEM_SIGQUIT=131
export ERROR_SYSTEM_SIGABRT=134
export ERROR_SYSTEM_SIGKILL=137
export ERROR_SYSTEM_SIGALRM=142
export ERROR_SYSTEM_SIGTERM=143

readonly ERROR_SYSTEM_SIGHUP
readonly ERROR_SYSTEM_SIGINT
readonly ERROR_SYSTEM_SIGQUIT
readonly ERROR_SYSTEM_SIGABRT
readonly ERROR_SYSTEM_SIGKILL
readonly ERROR_SYSTEM_SIGALRM
readonly ERROR_SYSTEM_SIGTERM

dc::error::handler(){
  set +x
  local exit="$1"
  local detail="$2"
  case "$exit" in
    # https://www.tldp.org/LDP/abs/html/exitcodes.html
    1)
      dc::logger::error "Generic bash error that should have been caught"
      dc::logger::error "Generic script failure"
    ;;
    2)
      dc::logger::error "Generic bash error that should have been caught"
      dc::logger::error "Misused shell builtin is a likely explanation"
      dc::logger::error "Last good command was: $3"
    ;;
    126)
      dc::logger::error "Generic bash error that should have been caught"
      dc::logger::error "Permission issue, or cannot execute command"
    ;;
    127)
      dc::logger::error "Generic bash error that should have been caught"
      dc::logger::error "Missing binary or a typo in a command name"
    ;;
    # none of these two will be triggered with bash apparently
    128)
      dc::logger::error "XXXSHOULDNEVERHAPPENXXX"
      dc::logger::error "XXXSHOULDNEVERHAPPENXXX Invalid argument to exit"
    ;;
    255)
      dc::logger::error "XXXSHOULDNEVERHAPPENXXX"
      dc::logger::error "Additionally, the exit code we got ($exit) is out of range (0-255). We will exit 1."
    ;;

    ##################################
    # Basic core: none of that should ever happen uncaught. Caller should always catch and do something useful with it.
    "$ERROR_BINARY_UNKNOWN_ERROR")
      dc::logger::error "UNCAUGHT EXCEPTION: generic binary failure $detail"
    ;;
    "$ERROR_GREP_NO_MATCH")
      dc::logger::error "UNCAUGHT EXCEPTION: grep not matching"
    ;;

    ##################################
    # Basic core: these could bubble up

    # This is a lazy catch-all for non specific problems.
    "$ERROR_FAILED")
      dc::logger::error "Script failed: $detail"
    ;;
    # Denotes that something is not implemented or unsupported on the given platform
    "$ERROR_UNSUPPORTED")
      dc::logger::error "The requested operation is not supported: $detail"
    ;;
    # Some requirements are missing
    "$ERROR_REQUIREMENT_MISSING")
      dc::logger::error "Sorry, you need $detail for this to work."
    ;;
    # Typical filesystem errors: file does not exist, is unreadable, or permission denied
    "$ERROR_FILESYSTEM")
      dc::logger::error "Filesystem error: $detail"
    ;;
    # Provided argument doesn't validate
    "$ERROR_ARGUMENT_INVALID")
      dc::logger::error "Provided argument $detail is invalid"
    ;;
    # We waited for the user for too long
    "$ERROR_ARGUMENT_TIMEOUT")
      dc::logger::error "Timed-out waiting for user input after $detail seconds"
    ;;
    # Something is amiss
    "$ERROR_ARGUMENT_MISSING")
      dc::logger::error "Required argument $detail is missing"
    ;;

    ##################################
    # Lib: these should be caught
    "$ERROR_CRYPTO_SHASUM_WRONG_ALGORITHM")
      dc::logger::error "UNCAUGHT EXCEPTION: shasum wrong algorithm used"
    ;;
    "$ERROR_CRYPTO_SHASUM_FILE_ERROR")
      dc::logger::error "UNCAUGHT EXCEPTION: failed to read file"
    ;;
    "$ERROR_CRYPTO_SSL_INVALID_KEY")
      dc::logger::error "UNCAUGHT EXCEPTION: invalid key"
    ;;
    "$ERROR_CRYPTO_SSL_WRONG_PASSWORD")
      dc::logger::error "UNCAUGHT EXCEPTION: wrong password"
    ;;
    "$ERROR_CRYPTO_SSL_WRONG_ARGUMENTS")
      dc::logger::error "UNCAUGHT EXCEPTION: wrong arguments"
    ;;

    # Crypto
    "$ERROR_CRYPTO_SHASUM_VERIFY_ERROR")
      dc::logger::error "Shasum failed verification: $detail"
    ;;
    "$ERROR_CRYPTO_PEM_NO_SUCH_HEADER")
      dc::logger::error "Pem file has no such header: $detail"
    ;;
    # Encoding
    "$ERROR_ENCODING_CONVERSION_FAIL")
      dc::logger::error "Failed to convert file $detail"
    ;;
    "$ERROR_ENCODING_UNKNOWN")
      dc::logger::error "Failed to guess encoding for $detail"
    ;;
    # HTTP
    "$ERROR_CURL_DNS_FAILED")
      dc::logger::error "Failed to resolve domain name $detail"
    ;;
    "$ERROR_CURL_CONNECTION_FAILED")
      dc::logger::error "Failed to connect to server at $detail"
    ;;

    *)
      if [ "$exit" -lt 129 ] || [ "$exit" -gt 143 ]; then
        dc::logger::error "UNCAUGHT EXCEPTION $exit $(dc::error::lookup "$exit"): $detail"
      fi
    ;;
  esac

  dc::logger::debug "Build information" \
    "DC_VERSION: $DC_VERSION" \
    "DC_REVISION: $DC_REVISION" \
    "DC_BUILD_DATE: $DC_BUILD_DATE" \
    "DC_BUILD_PLATFORM: $DC_BUILD_PLATFORM" \
    "DC_LIB_VERSION: $DC_LIB_VERSION" \
    "DC_LIB_REVISION: $DC_LIB_REVISION" \
    "DC_LIB_BUILD_DATE: $DC_LIB_BUILD_DATE" \
    "DC_LIB_BUILD_PLATFORM: $DC_LIB_BUILD_PLATFORM"

  dc::logger::debug "Runtime information" \
    "uname: $(uname -a)" \
    "bash: $(command -v bash) $(dc::require::version bash --version)" \
    "curl: $(command -v curl) $(dc::require::version curl --version)" \
    "grep: $(command -v grep) $(dc::require::version grep --version)" \
    "jq: $(command -v jq) $(dc::require::version jq --version)" \
    "openssl: $(command -v openssl) $(dc::require::version openssl version)" \
    "shasum: $(command -v shasum) $(dc::require::version shasum --version)" \
    "sqlite3: $(command -v sqlite3) $(dc::require::version sqlite3 --version)" \
    "uchardet: $(command -v uchardet) $(dc::require::version uchardet --version)" \
    "make: $(command -v make) $(dc::require::version make --version)" \
    "git: $(command -v git) $(dc::require::version git --version)" \
    "gcc: $(command -v gcc) $(dc::require::version gcc --version)" \
    "ps: $(command -v ps)" \
    "[: $(command -v \[)" \
    "tput: $(command -v tput)" \
    "PATH: $PATH" \
    "ENV: $(env)"
}

# Set up the traps
trap 'dc::trap::signal::HUP     "$LINENO" "$?" "$BASH_COMMAND"' 1
trap 'dc::trap::signal::INT     "$LINENO" "$?" "$BASH_COMMAND"' 2
trap 'dc::trap::signal::QUIT    "$LINENO" "$?" "$BASH_COMMAND"' 3
trap 'dc::trap::signal::ABRT    "$LINENO" "$?" "$BASH_COMMAND"' 6
trap 'dc::trap::signal::ALRM    "$LINENO" "$?" "$BASH_COMMAND"' 14
trap 'dc::trap::signal::TERM    "$LINENO" "$?" "$BASH_COMMAND"' 15
trap 'dc::trap::exit            "$LINENO" "$?" "$BASH_COMMAND"' EXIT
trap 'dc::trap::err             "$LINENO" "$?" "$BASH_COMMAND"' ERR

# Attach the error handler
dc::trap::register dc::error::handler

# Parse arguments
dc::internal::parse_args "$@"

true

# shellcheck disable=SC2034
readonly DC_LOGGER_DEBUG=4
# shellcheck disable=SC2034
readonly DC_LOGGER_INFO=3
# shellcheck disable=SC2034
readonly DC_LOGGER_WARNING=2
# shellcheck disable=SC2034
readonly DC_LOGGER_ERROR=1

export DC_LOGGER_STYLE_DEBUG=( setaf "$DC_COLOR_WHITE" )
export DC_LOGGER_STYLE_INFO=( setaf "$DC_COLOR_GREEN" )
export DC_LOGGER_STYLE_WARNING=( setaf "$DC_COLOR_YELLOW" )
export DC_LOGGER_STYLE_ERROR=( setaf "$DC_COLOR_RED" )

dc::configure::logger::setlevel::info


"""#
