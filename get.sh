#!/bin/bash

set -eEo pipefail

required_bin() (
    set -eEo pipefail
    local loc="$(which "$1")"
    if [ "$loc" = "" ]; then
        echo "ERROR: Binary \"$1\" is required, but not found in PATH"
        exit 1
    fi
)
required_sudo_bin() (
    set -eEo pipefail
    local loc="$(sudo which "$1")"
    if [ "$loc" = "" ]; then
        echo "ERROR: Binary \"$1\" is required under sudo (!), but not found in sudo (!) PATH"
        exit 1
    fi
)
required_bins() (
    set -eEo pipefail
    for name in "$@"; do 
        required_bin $name
    done
)
required_sudo_bins() (
    set -eEo pipefail
    for name in "$@"; do 
        required_sudo_bin $name
    done
)

required_bins pwd ls du cp mkdir rm curl grep sed mkdir 7z
required_sudo_bins mkdir rm mount umount cp tar xz

main() {
    set -eEo pipefail

    local cwd="$(pwd)"
    local init_sys="dinit" # variants: dinit openrc runit s6

    local xz_level="$1"
    if [ "$xz_level" = "" ]; then
        echo "ERROR: Provide xz_level"
        exit 1
    fi

    local xz_threads="$2"
    if [ "$xz_threads" = "" ]; then
        echo "ERROR: Provide xz_threads"
        exit 1
    fi

    echo "- Getting the latest Artix version..."
    local ver=$( curl "https://mirror1.artixlinux.org/weekly-iso/" 2>&1 | grep -F 'href="artix-base-dinit-' 2>&1 | sed -r "s/^.*href=\"artix-base-dinit-([0-9]+)-x86_64.iso\".*/\1/")
    export ARTIX_VERSION="$ver"

    echo "- Downloading Artix latest ($ver) release..."
    local iso_name="artix-base-$init_sys-$ver-x86_64.iso"
    local iso_url="https://mirror1.artixlinux.org/weekly-iso/$iso_name"
    local download_status=$( curl "$iso_url" -D /dev/stdout -o "$iso_name" -sL | grep -F 'HTTP/' 2>&1 | sed -r "s/^.*HTTP\/[0-9\.]+ ([0-9]+).*$/\1/" )
    if [[ "$download_status" != 200 ]]; then
        echo "ERROR: Wrong respone status code ($download_status), check your internet connection & file ($iso_url) availability"
        exit 1
    fi

    echo "- Extracting $iso_name ..."
    local iso_x_path="$cwd/artix_iso_x"
    mkdir "$iso_x_path" || exit 1
    cp $iso_name "$iso_x_path" || exit 1
    cd "$iso_x_path" || exit 1
    7z x $iso_name -y > /dev/null || exit 1
    cd "$cwd" || exit 1
    local rootfs_og_path="$iso_x_path/LiveOS/rootfs.img"
    ls "$rootfs_og_path" > /dev/null || exit 1

    echo "- Mounting rootfs.img ..."
    local mnt_img_path="/mnt/artix_rootfs_img"
    sudo mkdir $mnt_img_path || exit 1
    sudo mount -o loop "$rootfs_og_path" $mnt_img_path || exit 1

    echo "- Copying files..."
    local copy_path="$cwd/artix_rootfs_copy"
    mkdir "$copy_path" || exit 1
    sudo cp -r $mnt_img_path/* "$copy_path" || exit 1

    echo "- Unmounting and cleaning extracted from .iso files ..."
    sudo umount "$mnt_img_path" || exit 1
    sudo rm -rf "$mnt_img_path" || exit 1
    rm -rf $iso_x_path || exit 1

    echo "- Creating tarball..."
    cd "$copy_path"
    sudo tar -cf ../artix_rootfs.tar * || exit 1
    cd "$cwd"
    echo $(du -h artix_rootfs.tar)
    sudo xz -$xz_level -T$xz_threads artix_rootfs.tar || exit 1
    echo $(du -h artix_rootfs.tar.xz)

    echo "- Cleaning up..."
    cd "$cwd"
    rm $iso_name
    sudo rm -rf "$copy_path"
    rm -rf artix_rootfs.tar
 
    echo "SUCCESS"
}

main "$@" || exit 1
