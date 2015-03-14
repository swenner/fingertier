# Fingertier cookbook for Debian on the OpenMoko Freerunner #

Date: 2009-04-18

Author: Christian Wäckerlin

Starting from a debian on your device/computer. Assuming you have space to waste on your device.
```
apt-get install valac build-essential subversion gnome-common
```

checkout:
```
svn checkout http://fingertier.googlecode.com/svn/trunk/ fingertier
```

run the cursed autogen:
```
cd fingertier
./autogen.sh
```

build dependencies:
```
apt-get install libgtk2.0-dev libgstreamer0.10-dev
```

build:
```
./configure
make
```

if you want to listen some real music (you want):
```
apt-get install gstreamer0.10-plugins-bad
apt-get install gstreamer0.10-ffmpeg gstreamer-tools
apt-get install gstreamer0.10-plugins-good
```

run it:
```
export DISPLAY=0:0
./src/fingertier
```

or install it:
```
make install
# and run it
fingertier
```