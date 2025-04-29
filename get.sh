#!/bin/bash
set -eEo pipefail

main() {
    set -eEo pipefail

    local cwd=$(pwd)
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

    echo "- Getting the latest Artix version ..."
    local ver=$( curl "https://mirror1.artixlinux.org/weekly-iso/" 2>&1 | grep -F 'href="artix-base-dinit-' 2>&1 | sed -r "s/^.*href=\"artix-base-dinit-([0-9]+)-x86_64.iso\".*$/\1/")
    export ARTIX_VERSION="$ver"

    local iso_dir="$cwd/artix_iso"
    mkdir $iso_dir || exit 1
    cd $iso_dir

    echo "- Downloading Artix latest ($ver) release ..."
    local iso_name="artix-base-$init_sys-$ver-x86_64.iso"
    local iso_url="https://mirror1.artixlinux.org/weekly-iso/$iso_name"
    local download_status=$( curl "$iso_url" -D /dev/stdout -o "$iso_name" -sL | grep -F 'HTTP/' 2>&1 | sed -r "s/^.*HTTP\/[0-9\.]+ ([0-9]+).*$/\1/" )
    if [[ "$download_status" != 200 ]]; then
        echo "ERROR: Wrong respone status code ($download_status), check your internet connection & file ($iso_url) availability"
        rm -rf $iso_dir
        cd $cwd
        exit 1
    fi
    rm -rf ./efi ./boot ./[BOOT] ./boot.catalog ./LiveOS/rootfs.img.md5
    local rootfs_og_path="$iso_dir/LiveOS/rootfs.img"

    echo "- Extracting $iso_name ..."
    7z x $iso_name -y > /dev/null || exit 1
    cd $cwd || exit 1

    echo "- Mounting rootfs.img ..."
    local mnt_img_path="/mnt/artix_rootfs_img"
    sudo mkdir $mnt_img_path || exit 1
    sudo mount -o loop $rootfs_og_path $mnt_img_path || exit 1

    echo "- Creating tarball..."
    cwd=$(pwd)
    cd $mnt_img_path
    sudo tar -cf $cwd/artix_rootfs.tar * || exit 1
    cd $cwd
    echo $(du -h artix_rootfs.tar)

    echo "- Unmounting and cleaning up ..."
    sudo umount $mnt_img_path || exit 1
    sudo rm -rf $mnt_img_path || exit 1
    rm -rf $iso_dir || exit 1

    echo "- Compressing ..."
    sudo xz -$xz_level -T$xz_threads artix_rootfs.tar || exit 1
    echo $(du -h artix_rootfs.tar.xz)
    rm -rf artix_rootfs.tar || exit 1
 
    echo "SUCCESS"
}

main "$@" || exit 1
