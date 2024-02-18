# PKGBUILD for example-service

pkgname=pac-updater
pkgver=1.0.0
pkgrel=1
pkgdesc="Pacman Update Scheduling and Notification"
arch=('any')
url="https://github.com/kwiksand/pac-updater-aur.git"
license=('MIT')

depends=('systemd' 'pacman-contrib')

noextract=()
sha256sums=()
validpgpkeys=()


# Source files
source=("pac-updater.service" "pac-updater.timer" "pacman-system-updater")

package() {
  # Install the systemd service file
  install -Dm644 "$srcdir/pac-updater.service" "$pkgdir/usr/lib/systemd/system/pac-updater.service"
  install -Dm644 "$srcdir/pac-updater.timer" "$pkgdir/usr/lib/systemd/system/pac-updater.timer"
  install -Dm755 "$srcdir/pacman-system-updater" "$pkgdir/usr/bin/pacman-system-updater"
}

# Verification steps (optional)
#sha256sums=0('SKIP')


# Post-installation steps
post_install() {
  echo "Enabling and starting pac-updater.service..."
  systemctl enable pac-updater.service
  systemctl start pac-updater.service
}

# Pre-removal steps
pre_remove() {
  echo "Stopping and disabling pac-updater.service..."
  systemctl stop pac-updater.service
  systemctl disable pac-updater.service
}

# Post-upgrade steps
post_upgrade() {
  post_install
}

# Pre-upgrade steps
pre_upgrade() {
  pre_remove
}
