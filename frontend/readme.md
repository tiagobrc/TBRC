# TBRCa shiny pipeline

Shiny app to interactively control the TBRCa (T/B Receptor Cell assembly) snakemake pipeline.

## Portability notes

Machine-specific settings now live in [`server_config.json`](/Users/tiagobrc/Desktop/TBRC/frontend/server_config.json):

- `storage_server.*.rawdata_path`: source location for FASTQ discovery or pull
- `storage_server.*.results_path`: destination location for zipped results
- `cluster.*`: HPC entry points, pipeline root, and environment details

To move this app to a different VM or lab server, update the JSON file instead of editing the Shiny code or shell scripts.

## Script behavior

The launcher scripts in [`frontend/scripts`](/Users/tiagobrc/Desktop/TBRC/frontend/scripts) now resolve paths relative to the repository, so they no longer depend on `/home/.../ShinyApps/...` being identical on every machine.

Important assumption:

- The final results export uses the configured `results_path` and will create `results/<user_id>/` remotely before running `rsync`.

