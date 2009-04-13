/*
    Fingertier is a finger friendly music player for mobile devices.
    Copyright (C) 2009  Simon Wenner <simon@wenner.ch>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using GLib;

namespace Ft {

public class PlayList : GLib.Object {

	private Configuration conf;
	private GLib.List<string> playlist; /* contains paths relative to the library path */
	private uint length;

	construct {
		conf = new Configuration ();
		build_playlist ();
		
		// TODO: generate playlist files if needed. 
		// read the library folder recursively
		// creates two files: one with sorted paths, one with shuffled paths
		// (~/.fingertier/playlist-sorted, ~/.fingertier/playlist-shuffled)
		
	}
	
	public void set_mode (PlayListMode mode) {
		// TODO: shuffled or sorted
	}
	
	public PlayListMode get_mode () {
		return conf.mode;
	}
	
	public bool do_shuffle () {
		// TODO: shuffle on demand
		return false;
	}
	
	public Track? get_current_track () {
		if (length <= 0)
			return null;
		return build_track ();
	}
	
	public Track? get_next_track () { // TODO: C warning! Vala bug?
		if (conf.track_number >= length - 1) {
			return null;
		}
		
		conf.track_number++;
		return build_track ();
	}
	 
	public Track? get_previous_track () { // TODO: C warning! Vala bug?
		if (conf.track_number <= 0)
			return null;
		
		conf.track_number--;
		return build_track ();
	}
	
	/* Private functions */
	private Track build_track () {
		Track t = Track () {
			number = conf.track_number + 1,
			pl_len = length,
			uri = "file://" + conf.library_path + "/" + 
				  this.playlist.nth_data (conf.track_number),
			cover_path = get_cover_path (),
			info = ""
		};
		return t;
	}
	
	private string get_cover_path () {
		// TODO: make it dynamic and robust
		string path = conf.library_path + "/cover.jpg";
		return path;
	}
	
	// TODO: it should check subfolders too!
	private void build_playlist () {
		GLib.File dir;
		GLib.FileInfo fileInfo;
		
		playlist = new GLib.List<string> ();
		
		dir = File.new_for_path (conf.library_path);

		try {
			FileEnumerator enumerator = dir.enumerate_children ("*", FileQueryInfoFlags.NONE, null);

			while ((fileInfo = enumerator.next_file (null)) != null)
			{
				string p = fileInfo.get_name ();
				if (is_music (p))
					playlist.append (p);
			}
			enumerator.close(null);

		} catch (GLib.Error e) {
			GLib.warning ("%s\n", e.message);
		}
		
		// DEBUG
		stdout.printf ("Generated PlayList:\n");
		foreach (string song in playlist) {
			stdout.printf ("track: %s\n", song);
		}

		this.length = playlist.length ();
	}
	
	private bool is_music (string path) {
		if (path.has_suffix ("mp3"))
			return true;
		if (path.has_suffix ("ogg"))
			return true;
		if (path.has_suffix ("flac"))
			return true;
		return false;
	}
}

} /* namespace Ft end */