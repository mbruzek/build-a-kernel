#!/usr/bin/env bash

# Build a vanilla Linux kernel for Enterprise Linux with only one argument the version.

if [ `id -u` -ne 0 ] ; then
  echo "This script needs to be run as root, or using sudo."
  exit 1;
fi

START=$(date +%s)
ORIGINAL_DIRECTORY=$(pwd)
pushd $ORIGINAL_DIRECTORY
# Where to store the files, alternate locations are /build/kernel or /usr/src
OUTPUT_DIRECTORY=/usr/src

# The first argument is the version.
KERNEL_VERSION=$1
KERNEL_VERSION="${KERNEL_VERSION#[vV]}"
KERNEL_VERSION_MAJOR="${KERNEL_VERSION%%\.*}"
KERNEL_VERSION_MINOR="${KERNEL_VERSION#*.}"
KERNEL_VERSION_MINOR="${KERNEL_VERSION_MINOR%.*}"
KERNEL_VERSION_PATCH="${KERNEL_VERSION##*.}"

echo "Linux kernel version: $KERNEL_VERSION"
echo "Linux kernel major version: $KERNEL_VERSION_MAJOR"
echo "Linux kernel minor version: $KERNEL_VERSION_MINOR"
echo "Linux kernel patch version: $KERNEL_VERSION_PATCH"

echo "Install software needed to build a kernel"
dnf --assumeyes groupinstall 'Development Tools'
dnf --assumeyes install elfutils-libelf-devel ncurses-devel openssl-devel python3 wget
dnf config-manager --set-enabled powertools
dnf --assumeyes dwarves

echo "Downloading the Linux kernel version $KERNEL_VERSION from kernel.org to $OUTPUT_DIRECTORY"
wget --no-clobber https://kernel.org/pub/linux/kernel/v$KERNEL_VERSION_MAJOR.x/linux-$KERNEL_VERSION.tar.xz --directory-prefix $OUTPUT_DIRECTORY
echo "Downloading the Linux kernel signature from kernel.org to $OUTPUT_DIRECTORY"
wget --no-clobber https://kernel.org/pub/linux/kernel/v$KERNEL_VERSION_MAJOR.x/linux-$KERNEL_VERSION.tar.sign --directory-prefix $OUTPUT_DIRECTORY

echo "Checking the validity of the downloaded kernel file"
unxz --stdout $OUTPUT_DIRECTORY/linux-$KERNEL_VERSION.tar.xz | gpg --verify $OUTPUT_DIRECTORY/linux-$KERNEL_VERSION.tar.sign -

echo "Uncompressing kernel archive to $OUTPUT_DIRECTORY/linux-$KERNEL_VERSION"
tar --extract --auto-compress --file $OUTPUT_DIRECTORY/linux-$KERNEL_VERSION.tar.xz --directory $OUTPUT_DIRECTORY
cd $OUTPUT_DIRECTORY/linux-$KERNEL_VERSION
echo "Clean up the build environment"
make mrproper
make clean

CURRENT_KERNEL=$(uname -r)
echo "The current kernel version is: $CURRENT_KERNEL"

echo "Copy the previous kernel config from /boot/$CURRENT_KERNEL"
cp --verbose /boot/config-$CURRENT_KERNEL .config
echo "Output newline characters to accept defaults for make oldconfig"
yes "" | make oldconfig

# Edit the configuration in place to enable or disable some options.
sed --in-place -r '/CONFIG_SYSTEM_TRUSTED_KEYS/s/=.+/=""/g' .config
# Add the "-custom" string to the kernel version to differentiate.
sed --in-place 's/EXTRAVERSION =/EXTRAVERSION = -custom/' .config

BUILD_START=$(date +%s)
NPROC=$(nproc)
echo "Starting compile of the kernel with $NPROC processors"
nice make -j$NPROC

BUILD_END=$(date +%s)
DIFFERENCE=$(($BUILD_END - $BUILD_START))
echo "Build took $DIFFERENCE seconds with $NPROC processors"

echo "Installing the kernel modules with INSTAL_MOD_STRIP=1"
INSTALL_MOD_STRIP=1 make modules_install

echo "Copy and rename the bzImage into /boot/vmlinuz-$KERNEL_VERSION"
cp --verbose bzImage /boot/vmlinuz-$KERNEL_VERSION

echo "Copy and rename the System.map to /boot/System.map-$KERNEL_VERSION"
cp --verbose System.map /boot/System.map-$KERNEL_VERSION

echo "Installing the kernel on this system with kernel-install"
echo "Creating the initramfs file, running depmod and updating the boot loader"
/usr/bin/kernel-install add $KERNEL_VERSION /boot/vmlinuz-$KERNEL_VERISON

END=$(date +%s)
DIFFERENCE=$(($END - $START))
echo "The entire process took $DIFFERENCE seconds"
echo "Script complete at $(date)"
popd

