#!/bin/bash
#SBATCH --get-user-env
#SBATCH --out=log/ensure_dependencies-%j.out
#SBATCH --error=log/ensure_dependencies-%j.out
#SBATCH -p scavenger
#SBATCH -c 1
#SBATCH --mem=512M
#SBATCH --time=00:05:00

set -u

exit_code_file=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--exit-code-file) exit_code_file="$2"; shift ;;
        # -f|--force) force=1 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

job_ids=$(echo $SLURM_JOB_DEPENDENCY | sed -e 's/afterany//g' | tr ':' ' ')

echo "dependency job ids"
echo $job_ids

jobstr=$(echo $job_ids | tr ' ' ',')
non_completed_jobs=$(sacct -j $jobstr -n -o JobID,JobName%-30,State,End | grep -v "extern\|batch\|\.[0-9]" | grep -v "COMPLETED" | awk '{print $1}' | uniq)

if [ -n "$non_completed_jobs" ]; then
    echo "JOBIDs that didn't complete successfully:"
    for jobid in $non_completed_jobs
    do
        echo $jobid
    done

	# write failure to file
    if [ -n "$exit_code_file" ]; then
        echo 1 >> "$exit_code_file"
    fi
    exit 1
else
    echo "all jobs completed successfully"
    # write to success to file
    if [ -n "$exit_code_file" ]; then
        echo 0 >> "$exit_code_file"
    fi
fi
