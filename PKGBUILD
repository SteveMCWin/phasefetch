# Maintainer: Stevan <stevp003@gmail.com>
pkgname=phasefetch
pkgver=0.9.1
pkgrel=3
pkgdesc="Calculates the current moon phase and writes corresponding art to a file, designed for use with FastFetch"
arch=("any")
url="https://github.com/SteveMCWin/phasefetch"
license=("MIT")
depends=("bash" "awk" "file" "coreutils")
optdepends=("fastfetch: display moon phase in terminal fetch")
source=("$pkgname-$pkgver.tar.gz::https://github.com/SteveMCWin/$pkgname/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('eb8eba30cdb0200f9b1db340bd69ede2219968f99a6159de8125848c1a2e847b')

package() {
    cd "$srcdir/$pkgname-$pkgver"

    # Install the script as the binary
    install -Dm755 phasefetch.sh "$pkgdir/usr/bin/$pkgname"

    # Install mode data directories
    for mode_dir in */; do
        mode_name="${mode_dir%/}"
        # Only install directories that look like mode folders
        if [ -f "$mode_dir/full_moon" ] || [ -f "$mode_dir/new_moon" ]; then
            install -dm755 "$pkgdir/usr/share/$pkgname/$mode_name"
            for file in "$mode_dir"*; do
                install -Dm644 "$file" "$pkgdir/usr/share/$pkgname/$mode_name/$(basename "$file")"
            done
        fi
    done

    # Install license
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"

    # Install readme
    install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
}
