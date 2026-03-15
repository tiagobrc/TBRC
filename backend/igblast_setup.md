# IGBlast And Clonality Setup Notes

If you want the optional Shiny `Run IGBlast annotation` and `Run clonality analysis from IGBlast` checkboxes to work, install and configure these pieces on the backend side.

The UI now lets you choose:

- species: `human` or `mouse`
- receptor scope:
  - `IgH only`
  - `Ig light only`
  - `All immunoglobulins`
  - `TCR alpha only`
  - `TCR beta only`
  - `All TCR`
  - `All TCR and immunoglobulins`

So the backend should be organized around a fixed database build layout, not manual per-run V/D/J paths.

## Required in the Snakemake environment

1. `igblastn`
2. `makeblastdb`
3. `edit_imgt_file.pl` from the standalone IgBlast distribution
3. R packages:
   - `clonality`
   - `ggplate`
   - `ggplot2`
   - `dplyr`
   - `readr`

Example Conda-side R package install:

```bash
conda activate snakemake
Rscript -e "install.packages(c('ggplate','ggplot2','dplyr','readr'), repos='https://cloud.r-project.org')"
```

If your `clonality_0.10.tar.gz` tarball is on the server, install it into the same environment with:

```bash
conda activate snakemake
R CMD INSTALL /path/to/clonality_0.10.tar.gz
```

## Required IGBlast reference setup

1. Put the raw IMGT germline FASTA sets under:
   - [`backend/igblast/db/human`](/Users/tiagobrc/Desktop/TBRC/backend/igblast/db/human)
   - [`backend/igblast/db/mouse`](/Users/tiagobrc/Desktop/TBRC/backend/igblast/db/mouse)
2. Put `edit_imgt_file.pl` under:
   - [`backend/igblast/bin/edit_imgt_file.pl`](/Users/tiagobrc/Desktop/TBRC/backend/igblast/bin)
   or make it available in `PATH`
3. Put optional auxiliary files under:
   - [`backend/igblast/refs/human.gl.aux`](/Users/tiagobrc/Desktop/TBRC/backend/igblast/refs)
   - [`backend/igblast/refs/mouse.gl.aux`](/Users/tiagobrc/Desktop/TBRC/backend/igblast/refs)
4. Build the combined panel databases with:

```bash
cd /path/to/TBRC/backend/igblast
bash setup_igblast_databases.sh
```

You can also build one subset only:

```bash
bash setup_igblast_databases.sh human ig_all
bash setup_igblast_databases.sh mouse tcr_all
```

The build script now:
- concatenates the relevant raw IMGT FASTAs for the selected panel
- runs `edit_imgt_file.pl` on the combined FASTA
- then runs `makeblastdb` on the edited FASTA

5. The built databases will appear under:
   - [`backend/igblast/work`](/Users/tiagobrc/Desktop/TBRC/backend/igblast/work)
6. Fill these fields in [`frontend/server_config.json`](/Users/tiagobrc/Desktop/TBRC/frontend/server_config.json):
   - `cluster.igblast_bin`
   - optionally `cluster.igblast_auxiliary_data` if you want to override the species-specific `refs/<species>.gl.aux` convention

Minimal command shape:

```bash
igblastn \
  -germline_db_V /path/to/V_db \
  -germline_db_J /path/to/J_db \
  -auxiliary_data /path/to/optional_file \
  -query sample.imgt.ready.fasta \
  -outfmt 19 \
  -out sample.igblast.tsv
```

The D database is optional and is only passed for scopes that include D segments, such as `IgH`, `TRB`, `All TCR`, or `All TCR and immunoglobulins`.

Raw-reference naming convention expected by the build script:

```bash
backend/igblast/db/human/IGHV.fasta
backend/igblast/db/human/IGHD.fasta
backend/igblast/db/human/IGHJ.fasta
backend/igblast/db/human/IGKV.fasta
backend/igblast/db/human/IGKJ.fasta
backend/igblast/db/human/IGLV.fasta
backend/igblast/db/human/IGLJ.fasta
backend/igblast/db/human/TRAV.fasta
backend/igblast/db/human/TRAJ.fasta
backend/igblast/db/human/TRBV.fasta
backend/igblast/db/human/TRBD.fasta
backend/igblast/db/human/TRBJ.fasta
```

## What the pipeline now does

- Produces `*.imgt.ready.fasta`
- Runs IGBlast optionally and writes `igblast/<sample>.igblast.tsv`
- Runs clonality optionally from the IGBlast AIRR-style TSV and writes:
  - `clonality/<sample>.clonality.tsv`
  - `clonality/<sample>.clonality.summary.tsv`
- Resolves IGBlast databases from the chosen species and receptor scope
- Generates plate read-depth heatmaps from FASTA header well IDs under `qc/plates/`
- Skips redundant `pre_trim` contig-length plots when primer trimming was not requested

## What still needs your server-specific decisions

- final auxiliary data files for human and mouse
- whether you want to expose additional narrow scopes like `TRG only` or `TRD only` later
- whether the clonality package tarball will live in the repo, home directory, or a shared software path
