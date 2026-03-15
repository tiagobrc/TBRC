# TBRC

TBRC is an internal Shiny plus Snakemake workflow for plate-based TCR and BCR sequencing runs.

The project has two main parts:

- [`frontend/`](/Users/tiagobrc/Desktop/TBRC/frontend): the Shiny submission app
- [`backend/`](/Users/tiagobrc/Desktop/TBRC/backend): the Snakemake workflow and final packaging/export logic

## What It Does

The app lets lab users:

- submit runs from uploaded FASTQs or a storage server folder
- select barcode presets
- choose trimming and assembly options
- optionally run IGBlast
- optionally run clonality analysis from IGBlast

The backend then:

- detects paired `R1` and `R2` FASTQ files
- runs the core assembly workflow
- generates final FASTA outputs
- writes QC outputs
- optionally runs IGBlast and clonality
- packages the results into an archive
- transfers the archive to the configured storage server

## Current Output Bundle

The final bundle can contain:

- `<sample>.final.fasta`
- `<sample>.imgt.ready.fasta`
- `qc/`
- `igblast/`
- `clonality/`

Archive format is selectable in the UI:

- `zip` is the default
- `tar.gz` is optional

## Project Layout

- [`frontend/ui.R`](/Users/tiagobrc/Desktop/TBRC/frontend/ui.R): Shiny UI
- [`frontend/server.R`](/Users/tiagobrc/Desktop/TBRC/frontend/server.R): Shiny server logic
- [`frontend/global.R`](/Users/tiagobrc/Desktop/TBRC/frontend/global.R): shared app config/helpers
- [`frontend/server_config.json`](/Users/tiagobrc/Desktop/TBRC/frontend/server_config.json): storage server and cluster config
- [`backend/workflow/Snakefile`](/Users/tiagobrc/Desktop/TBRC/backend/workflow/Snakefile): workflow entry point
- [`backend/workflow/rules/final.smk`](/Users/tiagobrc/Desktop/TBRC/backend/workflow/rules/final.smk): final packaging/export rule
- [`backend/workflow/scripts/final.script.sh`](/Users/tiagobrc/Desktop/TBRC/backend/workflow/scripts/final.script.sh): final result handling
- [`backend/igblast/`](/Users/tiagobrc/Desktop/TBRC/backend/igblast): IGBlast references, build script, and working area

## IGBlast Setup

Species and receptor scope are now chosen in the UI.

Supported species:

- human
- mouse

Supported receptor scopes:

- IgH only
- Ig light only
- all immunoglobulins
- TCR alpha only
- TCR beta only
- all TCR
- all TCR and immunoglobulins

To build IGBlast databases on the server:

```bash
cd /path/to/TBRC/backend/igblast
bash setup_igblast_databases.sh
```

Important requirements:

- `igblastn`
- `makeblastdb`
- `edit_imgt_file.pl`
- species FASTAs under `backend/igblast/db/human` and `backend/igblast/db/mouse`
- optional auxiliary files under `backend/igblast/refs`

Detailed notes are in [`backend/igblast_setup.md`](/Users/tiagobrc/Desktop/TBRC/backend/igblast_setup.md).

## Deployment

A simple split deployment model is:

- deploy [`frontend/`](/Users/tiagobrc/Desktop/TBRC/frontend) to the Shiny server
- deploy [`backend/`](/Users/tiagobrc/Desktop/TBRC/backend) to the HPC pipeline location

Typical sync pattern:

```bash
rsync -aP -e "ssh -p <shiny-port>" frontend/ <shiny-user>@<shiny-host>:/path/to/shiny/app/
rsync -aP backend/ <hpc-user>@<hpc-host>:/path/to/hpc/pipeline/TBRC/
```

## Notes

- `zip` remains the safest default for Mac users
- server-side folder validation is checked before server-mode submission
- raw-data and results paths come from [`frontend/server_config.json`](/Users/tiagobrc/Desktop/TBRC/frontend/server_config.json)
- rsync transfer currently uses push mode by default
