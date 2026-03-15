#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${FRONTEND_DIR}/.." && pwd)"
BACKEND_DIR="${REPO_ROOT}/backend"
CONFIG_FILE="${FRONTEND_DIR}/server_config.json"

require_tool() {
    local tool_name="$1"

    if ! command -v "${tool_name}" >/dev/null 2>&1; then
        echo "Required command not found: ${tool_name}" >&2
        exit 1
    fi
}

json_get_storage_field() {
    local server_name="$1"
    local field_name="$2"

    jq -r --arg server_name "${server_name}" --arg field_name "${field_name}" '
        .storage_server[$server_name] as $entry
        | if $entry == null then
              empty
          elif ($entry | type) == "string" then
              if $field_name == "rawdata_path" then
                  $entry
              elif $field_name == "results_path" then
                  ($entry | sub("rawdata/?$"; "results/"))
              else
                  empty
              end
          else
              ($entry[$field_name] // empty)
          end
    ' "${CONFIG_FILE}"
}

json_get_cluster_field() {
    local field_name="$1"

    jq -r --arg field_name "${field_name}" '.cluster[$field_name] // empty' "${CONFIG_FILE}"
}

rsync_transport_args() {
    local ssh_port="$1"

    if [[ -n "${ssh_port}" && "${ssh_port}" != "null" ]]; then
        printf -- "-e 'ssh -p %s'" "${ssh_port}"
    fi
}

ensure_remote_directory() {
    local remote_spec="$1"
    local remote_parent="${remote_spec%/}"
    local remote_host="${remote_parent%%:*}"
    local remote_path="${remote_parent#*:}"

    if [[ "${remote_host}" == "${remote_path}" ]]; then
        echo "Remote destination is missing host:path format: ${remote_spec}" >&2
        exit 1
    fi

    ssh "${remote_host}" "mkdir -p '${remote_path}'"
}
