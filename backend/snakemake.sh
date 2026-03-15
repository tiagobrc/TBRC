#Script
snakemake -j 9999 --cluster-config config/cluster.json --cluster "sbatch --partition {cluster.partition} --job-name {cluster.name} -o {cluster.output} -e {cluster.error} --ntasks-per-node  1"
