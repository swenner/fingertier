#! /bin/sh

srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.

PKG_NAME="fingertier"

(test -f $srcdir/configure.ac) || {
	echo -n "**Error**: Directory "\`$srcdir\'" does not look like the"
	echo " top-level $PKG_NAME directory"
	exit 1
}

which gnome-autogen.sh || {
	echo "You need to install gnome-common from the GNOME SVN"
	exit 1
}

REQUIRED_AUTOMAKE_VERSION=1.11 USE_GNOME2_MACROS=0 REQUIRED_GETTEXT_VERSION=0.10.36 . gnome-autogen.sh
