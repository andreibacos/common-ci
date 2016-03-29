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

function archive_devstack_logs() {
    if [ ! -d "$LOG_DST_DEVSTACK" ]
    then
        mkdir -p "$LOG_DST_DEVSTACK" || emit_error "L30: Failed to create $LOG_DST_DEVSTACK"
    fi

    for i in `ls -A $DEVSTACK_LOGS`
    do
        echo "Doing $i"
        if [ -h "$DEVSTACK_LOGS/$i" ]
        then
                REAL=$(readlink "$DEVSTACK_LOGS/$i")
		echo "gzip file $REAL"
                $GZIP -c "$REAL" > "$LOG_DST_DEVSTACK/$i.gz" || emit_warning "L38: Failed to archive devstack logs: $i"
        fi
    done
    $GZIP -c /var/log/mysql/error.log > "$LOG_DST_DEVSTACK/mysql_error.log.gz"
    $GZIP -c /var/log/cloud-init.log > "$LOG_DST_DEVSTACK/cloud-init.log.gz"
    $GZIP -c /var/log/cloud-init-output.log > "$LOG_DST_DEVSTACK/cloud-init-output.log.gz"
    $GZIP -c /var/log/dmesg > "$LOG_DST_DEVSTACK/dmesg.log.gz"
    $GZIP -c /var/log/kern.log > "$LOG_DST_DEVSTACK/kern.log.gz"
    $GZIP -c /var/log/syslog > "$LOG_DST_DEVSTACK/syslog.log.gz"

    mkdir -p "$LOG_DST_DEVSTACK/rabbitmq"
    cp /var/log/rabbitmq/* "$LOG_DST_DEVSTACK/rabbitmq"
    sudo rabbitmqctl status > "$LOG_DST_DEVSTACK/rabbitmq/status.txt" 2>&1
    $GZIP $LOG_DST_DEVSTACK/rabbitmq/*
    mkdir -p "$LOG_DST_DEVSTACK/openvswitch"
    cp /var/log/openvswitch/* "$LOG_DST_DEVSTACK/openvswitch"
    $GZIP $LOG_DST_DEVSTACK/openvswitch/*
}

function archive_devstack_configs() {
    if [ ! -d "$CONFIG_DST_DEVSTACK" ]
    then
        mkdir -p "$CONFIG_DST_DEVSTACK" || emit_warning "L38: Failed to archive devstack configs"
    fi

    for i in cinder glance keystone neutron nova openvswitch
    do
        cp -r -L "/etc/$i" "$CONFIG_DST_DEVSTACK/$i" || continue
    done
    for file in `find "$CONFIG_DST_DEVSTACK/$i" -type f`
    do
        $GZIP $file
    done

    $GZIP -c /home/ubuntu/devstack/local.conf > "$CONFIG_DST_DEVSTACK/local.conf.gz"
    $GZIP -c /opt/stack/tempest/etc/tempest.conf > "$CONFIG_DST_DEVSTACK/tempest.conf.gz"
    df -h > "$CONFIG_DST_DEVSTACK/df.txt" 2>&1 && $GZIP "$CONFIG_DST_DEVSTACK/df.txt"
    cp /home/ubuntu/common-ci/devstack/tests/$PROJECT/included_tests.txt "$CONFIG_DST_DEVSTACK/included-tests.txt"
    cp /home/ubuntu/common-ci/devstack/tests/$PROJECT/excluded_tests.txt "$CONFIG_DST_DEVSTACK/excluded-tests.txt"
    cp /home/ubuntu/common-ci/devstack/tests/$PROJECT/isolated_tests.txt "$CONFIG_DST_DEVSTACK/isolated-tests.txt"
    iptables-save > "$CONFIG_DST_DEVSTACK/iptables.txt" 2>&1 && $GZIP "$CONFIG_DST_DEVSTACK/iptables.txt"
    dpkg-query -l > "$CONFIG_DST_DEVSTACK/dpkg-l.txt" 2>&1 && $GZIP "$CONFIG_DST_DEVSTACK/dpkg-l.txt"
    pip freeze > "$CONFIG_DST_DEVSTACK/pip-freeze.txt" 2>&1 && $GZIP "$CONFIG_DST_DEVSTACK/pip-freeze.txt"
    ps axwu > "$CONFIG_DST_DEVSTACK/pidstat.txt" 2>&1 && $GZIP "$CONFIG_DST_DEVSTACK/pidstat.txt"
    ifconfig -a -v > "$CONFIG_DST_DEVSTACK/ifconfig.txt" 2>&1 && $GZIP "$CONFIG_DST_DEVSTACK/ifconfig.txt"
    sudo ovs-vsctl -v show > "$CONFIG_DST_DEVSTACK/ovs_bridges.txt" 2>&1 && $GZIP "$CONFIG_DST_DEVSTACK/ovs_bridges.txt"
}

function archive_tempest_files() {
    for i in `ls -A $TEMPEST_LOGS`
    do
        $GZIP "$TEMPEST_LOGS/$i" -c > "$LOG_DST/$i.gz" || emit_error "L133: Failed to archive tempest logs"
    done
}

emit_info "Collecting devstack logs"
archive_devstack_logs
emit_info "Collecting devstack configs"
archive_devstack_configs
emit_info "Collecting tempest files"
archive_tempest_files
