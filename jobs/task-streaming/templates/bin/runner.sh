#!/usr/bin/env bash
#
# Load job properties
source /var/vcap/jobs/task-streaming/data/properties.sh

TASK_FILE="${1:-$TASK_FILE}"
TASK_FILE_LOCK="${TASK_FILE_LOCK:-$TASK_FILE.lock}"
TASK_FILE_PID="${TASK_FILE_PID:-$TASK_FILE.pid}"
TASK_CTL_LOOP="${TASK_CTL_LOOP:-3}"
TASK_LOOP_TIME="${TASK_LOOP_TIME:-5}"

NAME="task-streaming"
COMPONENT="task-watcher"
HOME=${HOME:-/home/vcap}
JOB_DIR="/var/vcap/jobs/$NAME"
PACKAGES="$JOB_DIR/packages"

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
    # Python libs
    for package_lib_dir in $(ls -d ${package_dir}/lib/python*/lib-dynload 2>/dev/null); do
      LD_LIBRARY_PATH="${package_lib_dir}:${LD_LIBRARY_PATH}"
    done
    for package_lib_dir in $(ls -d ${package_dir}/lib/python*/site-packages 2>/dev/null); do
      LD_LIBRARY_PATH="${package_lib_dir}:${LD_LIBRARY_PATH}"
    done
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

# Python modules
PYTHONPATH=${PYTHONPATH:-''}
for python_mod_dir in $(ls -d $PACKAGES/*/lib/python*/site-packages 2>/dev/null); do
    PYTHONPATH="${python_mod_dir}:${PYTHONPATH}"
done
export PYTHONPATH

# Gem paths
GEM_PATH=${GEM_PATH:-''}
for gem_dir in $(ls -d $PACKAGES/*/lib/ruby/gems/*/ 2>/dev/null); do
    GEM_PATH="${gem_dir}:${GEM_PATH}"
done
export GEM_PATH

# Setup log and tmp folders
export TMPDIR="/var/vcap/sys/tmp/$NAME"
RUN_DIR="/var/vcap/sys/run/$NAME"
export PIDFILE="${RUN_DIR}/${COMPONENT}.pid"
echo $$ > $PIDFILE

mkdir -p "$(dirname ${TASK_FILE_LOCK})"
mkdir -p "$(dirname ${TASK_FILE_PID})"

touch "${TASK_FILE_LOCK}"
while [ -f "${TASK_FILE_LOCK}" ]; do
  if [ ! -f "${TASK_FILE}" ]; then
    date
    echo "No task ..."
  else
    (
      clear
      exec "${TASK_FILE}"
    ) &
    pid=$!
    echo $pid > "${TASK_FILE_PID}"
    wait $pid
    rc=$?
    rm -f "${TASK_FILE_PID}"
    case ${TASK_CTL_LOOP} in
      0)
        if [ "$rc" == 0 ]; then
          rm -f "${TASK_FILE_LOCK}"
          exit $rc
        fi
        ;;
      1)
        if [ "$rc" != 0 ]; then
          rm -f "${TASK_FILE_LOCK}"
          exit $rc
        fi
        ;;
      2)
        # keep in the loop
        ;;
      *)
        rm -f "${TASK_FILE_LOCK}"
        exit $rc
        ;;
    esac
    clear
    date
    echo
    echo "Waiting ..."
  fi
  sleep ${TASK_LOOP_TIME}
done

