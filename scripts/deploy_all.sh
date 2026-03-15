#!/bin/bash
set -euo pipefail

ROOT="/Users/tiagobrc/Desktop/TBRC"
SHINY_TARGET="<shiny-user>@<shiny-host>:/path/to/shiny/app/"
HPC_TARGET="<hpc-user>@<hpc-host>:/path/to/hpc/pipeline/TBRC/"

rsync -aP -e "ssh -p 6123" \
  "${ROOT}/frontend/" \
  "${SHINY_TARGET}"

rsync -aP \
  "${ROOT}/backend/" \
  "${HPC_TARGET}"
