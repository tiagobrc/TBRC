#!/bin/bash

set -euo pipefail

QUERY_FASTA="$1"
OUTPUT_DIR="$2"
SAMPLE_NAME="$3"
SPECIES="${4:-human}"
PANEL="${5:-ig_all}"
DB_V="${6:-}"
DB_D="${7:-}"
DB_J="${8:-}"
AUX_PATH="${9:-}"
ORGANISM="${10:-human}"
IGBLAST_BIN="${IGBLAST_BIN:-igblastn}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
IGBLAST_ROOT="${BACKEND_DIR}/igblast"
DB_BUILD_ROOT="${IGBLAST_ROOT}/work"
REFS_ROOT="${IGBLAST_ROOT}/refs"

if [[ "${ORGANISM}" == "NA" || -z "${ORGANISM}" ]]; then
    ORGANISM="${SPECIES}"
fi

if [[ -z "${DB_V}" || -z "${DB_J}" ]]; then
    PANEL_DIR="${DB_BUILD_ROOT}/${SPECIES}/${PANEL}"
    DB_V="${PANEL_DIR}/${SPECIES}_${PANEL}_V"
    DB_D="${PANEL_DIR}/${SPECIES}_${PANEL}_D"
    DB_J="${PANEL_DIR}/${SPECIES}_${PANEL}_J"
fi

if [[ -z "${AUX_PATH}" || "${AUX_PATH}" == "NA" ]]; then
    if [[ -f "${REFS_ROOT}/${SPECIES}.gl.aux" ]]; then
        AUX_PATH="${REFS_ROOT}/${SPECIES}.gl.aux"
    else
        AUX_PATH=""
    fi
fi

if [[ -z "${DB_V}" || -z "${DB_J}" ]]; then
    echo "IGBlast skipped: missing V/J database paths." >&2
    exit 2
fi

if ! command -v "${IGBLAST_BIN}" >/dev/null 2>&1; then
    echo "IGBlast skipped: igblastn binary not found (${IGBLAST_BIN})." >&2
    exit 2
fi

mkdir -p "${OUTPUT_DIR}"

IGBLAST_OUTPUT="${OUTPUT_DIR}/${SAMPLE_NAME}.igblast.tsv"
IGBLAST_ARGS=(
    -germline_db_V "${DB_V}"
    -germline_db_J "${DB_J}"
    -organism "${ORGANISM}"
    -query "${QUERY_FASTA}"
    -outfmt 19
    -out "${IGBLAST_OUTPUT}"
)

if [[ -n "${DB_D}" && "${DB_D}" != "NA" && -f "${DB_D}.nhr" ]]; then
    IGBLAST_ARGS+=(-germline_db_D "${DB_D}")
fi

if [[ -n "${AUX_PATH}" && "${AUX_PATH}" != "NA" ]]; then
    IGBLAST_ARGS+=(-auxiliary_data "${AUX_PATH}")
fi

if [[ ! -f "${DB_V}.nhr" || ! -f "${DB_J}.nhr" ]]; then
    echo "IGBlast skipped: built databases were not found for species=${SPECIES}, panel=${PANEL}. Run backend/igblast/setup_igblast_databases.sh first." >&2
    exit 2
fi

"${IGBLAST_BIN}" "${IGBLAST_ARGS[@]}"
echo "IGBlast output: ${IGBLAST_OUTPUT}"
