#!/bin/bash

function emit_error() {
    echo "ERROR: $1"
    exit 1
}

function emit_warning() {
    echo "WARNING: $1"
    return 0
}

function emit_info() {
    echo "INFO: $1"
    return 0
}

function push_dir() {
    pushd . > /dev/null
}

function pop_dir() {
    popd > /dev/null
}

function check_copy_dir() {
    local src_dir=$1
    local dest_dir=$2

    if [ -d "$src_dir" ]; then
        cp -r "$src_dir" "$dest_dir"
    fi
}

function exec_with_retry () {
    local max_retries=$1
    local interval=${2}
    local cmd=${@:3}

    local counter=0
    while [ $counter -lt $max_retries ]; do
        local exit_code=0
        eval $cmd || exit_code=$?
        if [ $exit_code -eq 0 ]; then
            return 0
        fi
        let counter=counter+1

        if [ -n "$interval" ]; then
            sleep $interval
        fi
    done
    return $exit_code
}
