
function get_ancestry() {
    local raw_fq_dir=$1

    local ancestry_file=$raw_fq_dir/ancestry
    if [ ! -e "$ancestry_file" ]; then
        >&2 echo "Error ancestry file not found at ${ancestry_file}"
        return 5
    fi
    local ancestry=$(cat $ancestry_file)
    if [ -z "$ancestry" ]; then
        >&2 echo "No ancestry data found in file ${ancestry_file}"
        return 5
    fi
    echo "${ancestry}"
}

function get_sex() {
    local raw_fq_dir=$1

    local sex_file=$raw_fq_dir/sex
    if [ ! -e "$sex_file" ]; then
        >&2 echo "Error sex file not found at ${sex_file}"
        return 5
    fi
    local sex=$(cat $sex_file)
    if [ -z "$sex" ]; then
        >&2 echo "No sex data found in file ${sex_file}"
        return 5
    fi
    echo "${sex}"
}

function get_ancestry_1000genome() {
    local sample=$1

    local ancestry_file=$raw_fq_dir/$sample/ancestry
    if [ ! -e "$ancestry_file" ]; then
        >&2 echo "Error ancestry file not found at ${ancestry_file}"
        return 5
    fi
    local ancestry=$(cat $ancestry_file)
    if [ -z "$ancestry" ]; then
        >&2 echo "No ancestry data found in file ${ancestry_file}"
        return 5
    fi
    echo "${ancestry}"
}

function get_sex_1000genome() {
    local sample=$1

    local sex_file=$raw_fq_dir/$sample/sex
    if [ ! -e "$sex_file" ]; then
        >&2 echo "Error sex file not found at ${sex_file}"
        return 5
    fi
    local sex=$(cat $sex_file)
    if [ -z "$sex" ]; then
        >&2 echo "No sex data found in file ${sex_file}"
        return 5
    fi
    echo "${sex}"
}

function get_slurm_memory_limit_bytes() {
  cgroup_id=$(cat /proc/self/cgroup | awk -F: '/^[0-9]+:memory:/ { print $3; }')
  cat /sys/fs/cgroup/memory/$cgroup_id/memory.stat | awk '/hierarchical_memory_limit/{print $2}'
}

function run_beastie_image() {
  singularity run -e \
    -B $(echo "${singularity_mount_paths[@]}" | tr ' ' ',') \
    $beastie_singularity_image \
    $*
}

function wait_for_jobs() {
  local job_ids=$*
  
  local job_name="check-jobs"
  if [ -n "${SLURM_JOB_NAME-}" ]; then
      job_name="${SLURM_JOB_NAME}-check"
  fi

  local status_file=$(mktemp -p "$run_dir")
  
  sbatch \
      --dependency=afterany:$(echo $job_ids | tr ' ' ':') \
      --job-name="$job_name" \
      $scripts_dir/ensure_dependencies.slurm -f "$status_file"
      echo "Now waiting for jobs: $job_ids"

  while [ ! -s "$status_file" ]; do sleep 1; done

  local status=$(cat $status_file)
  rm "$status_file"

  if [ -z "$status" ]; then
      echo "ERROR: no status from status file.  Using code 15"
      status=15
  fi

  return "$status"
}