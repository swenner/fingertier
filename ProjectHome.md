Fingertier (German for the [Aye-eye](http://en.wikipedia.org/wiki/Aye-aye)) is a minimal finger friendly music player for mobile devices. It is optimised for smart phones with small touch screens, like the [OpenMoko](http://www.openmoko.com/) Freerunner. It is implemented in Vala and uses GLib, GTK and Gstreamer.

![http://fingertier.googlecode.com/svn/wiki/images/fingertier-0.1.0_sml.png](http://fingertier.googlecode.com/svn/wiki/images/fingertier-0.1.0_sml.png)

Features:
  * supports mp3, ogg and flac (in theory any format supported by Gstreamer)
  * play/pause, previous, next
  * sorted playlist
  * volume control
  * tags and album cover display
  * player prevents the phone from sleeping while running

Roadmap:
  * shuffled playlist
  * store playlist(s)
  * player should pause on call
  * OpenMoko: 'Aux' button should play next song if phone is locked
  * (maybe) your idea ;-)

Configuration:
  * Edit 'LIBRARY\_PATH' in ~/.fingertier/fingertier.conf to setup your music library folder. The default music folder is ~/Music.
  * Files called 'cover.jpg' or 'folder.jpg' in the same folder as your track are displayed by the player. The list of accepted cover file names can be configured in ~/.fingertier/fingertier.conf too.
  * A click on the cover reveals the configuration menu, where you can change the volume.