#!/bin/bash
set -euo pipefail

ROOT="/Users/tiagobrc/Desktop/TBRC"

rsync -aP -e "ssh -p 6123" \
  "${ROOT}/frontend/" \
  trezende@epsilon.rockefeller.edu:/home/trezende/ShinyApps/tbrc/

rsync -aP \
  "${ROOT}/backend/" \
  trezende@login06-hpc.rockefeller.edu:/lustre/fs4/vict_lab/scratch/trezende/pipelines/TBRC/

