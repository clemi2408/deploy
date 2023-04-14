# Install Ubuntu Core 20

## Create Ubuntu 20.04 SD Card

### Get Image:

curl https://cdimage.ubuntu.com/releases/20.04.4/release/ubuntu-20.04.4-preinstalled-server-arm64+raspi.img.xz \
-o ubuntu-20.04.4-preinstalled-server-arm64+raspi.img.xz


unzip ubuntu-20.04.4-preinstalled-server-arm64+raspi.img.xz


### write to sd-card:
Unmount all volumes on /dev/disk2 (disk util)

sudo dd if=ubuntu-20.04.3-preinstalled-server-arm64+raspi.img of=/dev/disk2

or use balenaEtcher to write to SD

## Add Cloud Init boot files
Place the Files in the / of the SD Card Fat32

### user-data

### network-config

### meta-data

### vendor-data


