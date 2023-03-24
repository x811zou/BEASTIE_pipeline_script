#!/bin/bash

set -u
set -e

# TODO param or env variable?
run_dir="/hpc/group/allenlab/scarlett/pipeline_working/run"

function get_script_dir() {
    local script_path
    if [ -n "${SLURM_JOB_ID-}" ] ; then
        script_path=$(realpath $(scontrol show job $SLURM_JOB_ID | awk -F= '/Command=/{print $2}' | cut -d' ' -f1 ))
    else
        script_path=$(realpath $0)
    fi
    echo $(dirname "$script_path")
}
scripts_dir=$( get_script_dir )

if [ $# -lt 1 ]; then
    echo "USAGE $0 jobid [...jobid]"
    exit 1
fi

job_ids=$*

if [ -n "${SLURM_JOB_NAME-}" ]; then
    job_name="${SLURM_JOB_NAME}-check"
else
    job_name="check-jobs"
fi

status_file=$(mktemp -p "$run_dir")

sbatch \
    --dependency=afterany:$(echo $job_ids | tr ' ' ':') \
    --job-name="$job_name" \
    $scripts_dir/ensure_dependencies.slurm -f "$status_file"

echo "Now waiting for jobs: $job_ids"

while [ ! -s "$status_file" ]; do sleep 1; done

status=$(cat $status_file)
rm "$status_file"

if [ -z "$status" ]; then
    echo "ERROR: no status from status file.  Using code 15"
    status=15
fi

exit "$status"

