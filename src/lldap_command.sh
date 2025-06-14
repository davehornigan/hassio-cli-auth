DEBUG_ENABLED=${args[--debug]:-0}
REQUEST_TIMEOUT=${args[--timeout]}
SERVER_URL=${args[server-url]:-}
SKIP_VERIFY=${args[--insecure]:-0}

eval "USER_GROUPS=(${args[user-groups]:-})"
eval "ADMIN_GROUPS=(${args[--admin-group]:-})"
eval "LOCAL_GROUPS=(${args[--local-group]:-})"

CURL_OPTIONS="--fail --silent --max-time $REQUEST_TIMEOUT"
if [ $SKIP_VERIFY = 1 ]; then
  CURL_OPTIONS="$CURL_OPTIONS -k"
fi

ADMIN_USER_GROUP="system-admin"
REGULAR_USER_GROUP="system-users"

log() {
  if [ $DEBUG_ENABLED = 1 ]; then
	  echo "$1" >&2
	fi
}
has_group() {
  local USER=$1
  local FIND_GROUPS=${2:-}
  if [[ ! -z "$FIND_GROUPS" ]]; then
    for g in "${FIND_GROUPS[@]}"; do
      if jq -e --arg group "$g" '.groups[].displayName == $group | select(.)' <<< "$USER" > /dev/null; then
        echo 1
        return
      fi
    done
  fi

  echo 0
}
is_admin() {
  IS_ADMIN=`has_group "$1" "${ADMIN_GROUPS}"`
  log "IS_ADMIN: $IS_ADMIN"
}
is_local() {
  IS_LOCAL=`has_group "$1" "${LOCAL_GROUPS}"`
  log "IS_LOCAL: $IS_LOCAL"
}
log "`inspect_args`"

log "Try to login"
RESPONSE=`curl $CURL_OPTIONS -H "Content-type: application/json" -d '{"username":"'"$USERNAME"'","password":"'"$PASSWORD"'"}' "$SERVER_URL/auth/simple/login"`
log "Response: $RESPONSE"
if [[ $? -ne 0 ]]; then
    log "Auth failed"
    exit 1
fi

log "Get token"
TOKEN=`jq -e -r .token <<< $RESPONSE`
if [[ $? -ne 0 ]]; then
    log "Failed to parse token"
    exit 1
fi

log "Get User"
RESPONSE=`curl -f $CURL_OPTIONS -m "$REQUEST_TIMEOUT" -H "Content-type: application/json" -H "Authorization: Bearer ${TOKEN}" -d '{"variables":{"id":"'"$USERNAME"'"},"query":"query($id:String!){user(userId:$id){displayName groups{displayName}}}"}' "$SERVER_URL/api/graphql"`
log "Response: $RESPONSE"
if [[ $? -ne 0 ]]; then
    log "Failed to get user"
    exit 1
fi
USER_JSON=`jq -e .data.user <<< $RESPONSE`
if [[ $? -ne 0 ]]; then
    log "Failed to parse user json"
    exit 1
fi

DISPLAY_NAME=`jq -r .displayName <<< $USER_JSON`
is_admin "$USER_JSON"
is_local "$USER_JSON"
HASSIO_GROUP="$REGULAR_USER_GROUP"
if [[ "$IS_ADMIN" = 1 ]]; then
  HASSIO_GROUP="$ADMIN_USER_GROUP"
fi

if [[ ! -z "$DISPLAY_NAME" ]]; then
  echo "name = $DISPLAY_NAME"
fi
echo "group = $HASSIO_GROUP"
echo "local_only = $IS_LOCAL"
