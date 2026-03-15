# TBRC ( T and B Receptor Clonality )

This is a snakemake pipeline that processes amplicon sequencing of T or B cell receptor.

## Setup expectations

The workflow is launched by the Shiny frontend and depends on these environment variables:

- `DATA_TABLE`: path to the generated `sample.tsv`
- `INPUTPATH`: directory containing the run FASTQ files

Result delivery is configured upstream in [`frontend/server_config.json`](/Users/tiagobrc/Desktop/TBRC/frontend/server_config.json), and the final step now exports to the configured `results_path` instead of hardcoded host/IP pairs.

## Pull Mode

Storage servers can now use `transfer_mode = "pull"` in [`frontend/server_config.json`](/Users/tiagobrc/Desktop/TBRC/frontend/server_config.json).

In pull mode:

- the pipeline still builds the final `.tar.gz` archive in the HPC results folder
- the final step skips outbound rsync to the storage server
- Synology or another trusted machine should pull the archive on a schedule

Example Synology-side pull command:

```bash
rsync -avP -e "ssh -p <hpc-port>" trezende@login06-hpc.rockefeller.edu:/lustre/fs4/vict_lab/scratch/trezende/pipelines/TBRC/results/trezende/ /volume1/victoracfs/pipelines/tbrc/results/trezende/
```
