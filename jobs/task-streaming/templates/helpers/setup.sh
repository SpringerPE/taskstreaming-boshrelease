#!/usr/bin/env bash
set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

export NAME=${1:-$JOB_NAME}
export HOME=${HOME:-/home/vcap}
export JOB_DIR="/var/vcap/jobs/$NAME"
export PACKAGES="$JOB_DIR/packages"

export COMPONENT=${2:-$NAME}

# Setup the PATH and LD_LIBRARY_PATH
LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-''}
for package_dir in $(ls -d /var/vcap/packages/*); do
  has_busybox=0
  temp_path=${PATH}
  # Add all packages' /bin & /sbin into $PATH
  for package_bin_dir in $(ls -d ${package_dir}/*bin 2>/dev/null); do
    # Do not add any packages that use busybox, as impacts builtin commands and
    # is often used for different architecture (via containers)
    if [ -f ${package_bin_dir}/busybox ]; then
      has_busybox=1
    else
      temp_path=${package_bin_dir}:${temp_path}
    fi
  done
  if [ "$has_busybox" == "0" ]; then
    PATH=${temp_path}
    if [ -d ${package_dir}/lib ]; then
      LD_LIBRARY_PATH="${package_dir}/lib:$LD_LIBRARY_PATH"
    fi
  fi
done
export PATH="$PACKAGES/$NAME/embedded/bin:$PATH"
for package_lib_dir in $(ls -d $PACKAGES/$NAME/embedded/lib 2>/dev/null); do
    LD_LIBRARY_PATH="${package_lib_dir}:${LD_LIBRARY_PATH}"
done
for package_lib_dir in $(ls -d $PACKAGES/$NAME/embedded/lib/python*/lib-dynload 2>/dev/null); do
    LD_LIBRARY_PATH="${package_lib_dir}:${LD_LIBRARY_PATH}"
done
for package_lib_dir in $(ls -d $PACKAGES/$NAME/embedded/lib/python*/site-packages 2>/dev/null); do
    LD_LIBRARY_PATH="${package_lib_dir}:${LD_LIBRARY_PATH}"
done
export LD_LIBRARY_PATH

# Gem paths
GEM_PATH=${GEM_PATH:-''}
for gem_dir in $(ls -d $PACKAGES/*/lib/ruby/gems/*/ 2>/dev/null); do
    GEM_PATH="${gem_dir}:${GEM_PATH}"
done
export GEM_PATH

# Setup log and tmp folders
export LOG_DIR="/var/vcap/sys/log/$NAME"
mkdir -p "$LOG_DIR" && chmod 775 "$LOG_DIR" && chown vcap "$LOG_DIR"

export RUN_DIR="/var/vcap/sys/run/$NAME"
mkdir -p "$RUN_DIR" && chmod 775 "$RUN_DIR" && chown vcap "$RUN_DIR"

export TMP_DIR="/var/vcap/sys/tmp/$NAME"
mkdir -p "$TMP_DIR" && chmod 775 "$TMP_DIR" && chown vcap "$TMP_DIR"
export TMPDIR="$TMP_DIR"

