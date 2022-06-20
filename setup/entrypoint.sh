#!/usr/bin/env bash

set -eu
set -o pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"


# --------------------------------------------------------
# Users declarations

declare -A users_passwords
users_passwords=(
	[kibana_system]="${KIBANA_SYSTEM_PASSWORD:-}"
)

# --------------------------------------------------------


echo "-------- $(date) --------"

state_file="$(dirname ${BASH_SOURCE[0]})/state/.done"
if [[ -e "$state_file" ]]; then
	log "State file exists at '${state_file}', skipping setup"
	exit 0
fi

log 'Waiting for availability of Elasticsearch'
wait_for_elasticsearch
sublog 'Elasticsearch is running'

for user in "${!users_passwords[@]}"; do
	log "User '$user'"
	if [[ -z "${users_passwords[$user]:-}" ]]; then
		sublog 'No password defined, skipping'
		continue
	fi

	declare -i user_exists=0
	user_exists="$(check_user_exists "$user")"

	if ((user_exists)); then
		sublog 'User exists, setting password'
		set_user_password "$user" "${users_passwords[$user]}"
	else
		if [[ -z "${users_roles[$user]:-}" ]]; then
			err '  No role defined, skipping creation'
			continue
		fi

		sublog 'User does not exist, creating'
		create_user "$user" "${users_passwords[$user]}" "${users_roles[$user]}"
	fi
done

mkdir -p "$(dirname "${state_file}")"
touch "$state_file"
