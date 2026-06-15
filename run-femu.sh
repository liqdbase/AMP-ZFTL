#!/bin/bash
# FEMU ZNS Mode with ARC Cache Integration - Final Configuration

FEMU_DIR=~/FEMU
IMGDIR=~/images
OSIMGF=$IMGDIR/u20s.qcow2
ZNSIMGF=$IMGDIR/zns.raw
FEMU_BIN=$FEMU_DIR/build-femu/qemu-system-x86_64

# 공유 메모리 정리 (선택)
echo "Cleaning shared memory..."
sudo rm -f /dev/shm/femu_zns_shm

# 백엔드 이미지 확인
if [[ ! -e "$ZNSIMGF" ]]; then
    echo "Creating ZNS backend image: $ZNSIMGF (10GB)"
    dd if=/dev/zero of=$ZNSIMGF bs=1M count=8192  # ★ 10GB (안전한 zone 개수 확보)
else
    echo "Using existing ZNS image: $ZNSIMGF"
fi

echo "=== FEMU ARC-ZNS Starting ==="
echo "OS Image: $OSIMGF"
echo "ZNS Image: $ZNSIMGF"
echo "Device Size: 10GB"
echo "Expected Zones: 16+ (ZenFS compatible)"
echo "=============================="

# FEMU 실행
sudo $FEMU_BIN \
    -name "femu-arc-zns-vm" \
    -enable-kvm \
    -cpu host \
    -smp 4 \
    -m 6G \
    -device virtio-scsi-pci,id=scsi0 \
    -device scsi-hd,drive=hd0 \
    -drive file=$OSIMGF,if=none,aio=threads,cache=none,format=qcow2,id=hd0 \
    -device femu,devsz_mb=8192,femu_mode=3 \
    -net user,hostfwd=tcp::2222-:22 \
    -net nic,model=virtio \
    -nographic \
    -qmp unix:./qmp-sock,server,nowait 2>&1 | tee femu-arc-zns.log