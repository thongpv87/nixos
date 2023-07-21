set -e

DISK=$1

sgdisk --zap-all $DISK

sgdisk -n 0:0:+1GiB -t 0:ef00 -c 0:boot $DISK
sgdisk -n 0:0:+20GiB -t 0:8200 -c 0:swap $DISK
sgdisk -n 0:0:0 -t 0:8200 -c 0:zfs $DISK


printf 'Disk is nvme (y/n)? '
old_stty_cfg=$(stty -g)
stty raw -echo
answer=$(while ! head -c 1 | grep -i '[ny]' ;do true ;done )
stty $old_stty_cfg
if [ "answer" != "${answer#[Yy]}" ]; then
  BOOT=${DISK}p1
  SWAP=${DISK}p2
  ZFS=${DISK}p3
else
  BOOT=${DISK}1
  SWAP=${DISK}2
  ZFS=${DISK}3
fi

mkfs.vfat -n BOOT $BOOT
mkswap $SWAP

zpool create \
  -f \
  -o ashift=12 \
  -o autotrim=on \
  -R /tmp/mnt \
  -O canmount=off \
  -O mountpoint=none \
  -O acltype=posixacl \
  -O compression=zstd \
  -O dnodesize=auto \
  -O normalization=formD \
  -O relatime=on \
  -O xattr=sa \
  -O encryption=aes-256-gcm \
  -O keylocation=prompt \
  -O keyformat=passphrase \
  rpool \
  $ZFS

# Reserve 1GB to allow ZFS operations
zfs create -o refreservation=1G -o mountpoint=none rpool/reserved

# Base mount
zfs create -p -o canmount=on -o mountpoint=legacy rpool/local
zfs snapshot rpool/local@blank

# Home mount
zfs create -p -o canmount=on -o mountpoint=legacy rpool/local/home
zfs snapshot rpool/local/home@blank

# Nix store mounts
zfs create -p -o canmount=on -o mountpoint=legacy rpool/persist/nix

# Root mounts (erased every boot)
zfs create -p -o canmount=on -o mountpoint=legacy rpool/local/root
zfs create -p -o canmount=on -o mountpoint=legacy rpool/backup/root
zfs create -p -o canmount=on -o mountpoint=legacy rpool/persist/root

zfs snapshot rpool/local/root@blank

# Data pool, part of service being backed up
zfs create -p -o canmount=on -o mountpoint=legacy rpool/persist/data
zfs create -p -o canmount=on -o mountpoint=legacy rpool/backup/data


install_jd() {
  zfs create -p -o canmount=on -o mountpoint=legacy rpool/local/home/thongpv87
  zfs create -p -o canmount=on -o mountpoint=legacy rpool/persist/home/thongpv87
  zfs create -p -o canmount=on -o mountpoint=legacy rpool/backup/home/thongpv87

  zfs snapshot rpool/local/home/thongpv87@blank
}

printf 'Make jd pool (y/n)? '
old_stty_cfg=$(stty -g)
stty raw -echo
answer=$(while ! head -c 1 | grep -i '[ny]' ;do true ;done )
stty $old_stty_cfg
if [ "answer" != "${answer#[Yy]}" ]; then
  install_jd
fi

mount -t zfs rpool/local /tmp/mnt

mkdir /tmp/mnt/boot
mount $BOOT /tmp/mnt/boot

mkdir /tmp/mnt/home
mount -t zfs rpool/local/home /tmp/mnt/home

mkdir /tmp/mnt/root
mount -t zfs rpool/local/root /tmp/mnt/root

mkdir /tmp/mnt/nix
mount -t zfs rpool/persist/nix /tmp/mnt/nix

mkdir -p /tmp/mnt/persist/root
mount -t zfs rpool/persist/root /tmp/mnt/persist/root

mkdir -p /tmp/mnt/persist/data
mount -t zfs rpool/persist/data /tmp/mnt/persist/data

mkdir -p /tmp/mnt/backup/root
mount -t zfs rpool/backup/root /tmp/mnt/backup/root

mkdir -p /tmp/mnt/backup/data
mount -t zfs rpool/backup/data /tmp/mnt/backup/data
