#!/bin/bash

BASEDIR=$(dirname $0)
DEVSTACK_LOGS="/opt/stack/logs/screen"
DEVSTACK_LOG_DIR="/opt/stack/logs"

HYPERV_LOGS="/openstack/logs"
TEMPEST_LOGS="/home/ubuntu/tempest"
HYPERV_CONFIGS="/openstack/config"

LOG_DST="/home/ubuntu/aggregate"
LOG_DST_DEVSTACK="$LOG_DST/devstack-logs"
LOG_DST_HV="$LOG_DST/Hyper-V-logs"
CONFIG_DST_DEVSTACK="$LOG_DST/devstack-config"
CONFIG_DST_HV="$LOG_DST/Hyper-V-config"

TAR="tar"
GZIP="gzip -f"

source $BASEDIR/utils.sh

function help() {
    echo "Required parameters:"
    echo "    --project: ZUUL_PROJECT"
    echo "    --change: ZUUL_CHANGE"
    echo "    --patchset: ZUUL_PATCHSET"
}

while [ $# -gt 0 ]
do
    case $1 in
        --project)
            PROJECT=$(basename $2)
            shift;;
        --change)
            CHANGE=$2
            shift;;
        --patchset)
            PATCHSET=$2
            shift;;
        *)
            echo "no such option"
            help
    esac
    shift
done

if [ -z "$PROJECT" ]; then echo "--project option not defined"; exit 1; fi
if [ -z "$CHANGE" ]; then echo "--change option not defined"; exit 1; fi
if [ -z "$PATCHSET" ]; then echo "--patchset option not defined"; exit 1; fi

emit_info "Collecting devstack logs"
archive_devstack_logs
emit_info "Collecting devstack configs"
archive_devstack_configs
emit_info "Collecting tempest files"
archive_tempest_files
