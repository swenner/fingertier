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

public class PlayListSimple : GLib.Object, PlayList {

	private weak Configuration conf;
	private GLib.List<string> playlist; /* contains paths relative to the library path */
	private uint length;

	public PlayListSimple (Configuration c) {
		conf = c;
		build_playlist ();
		
		if (conf.track_number >= length)
			conf.track_number = 0;
		
		// TODO: generate playlist files if needed (timestamp).
		// creates two files: one with sorted paths, one with shuffled paths
		// (~/.fingertier/playlist-sorted, ~/.fingertier/playlist-shuffled)
		
	}
	
	public void set_mode (PlayListMode mode) {
		conf.mode = mode;
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
	
	public Track? get_next_track () {
		if (conf.track_number + 1 >= length) {
			return null;
		}
		
		conf.track_number++;
		return build_track ();
	}
	 
	public Track? get_previous_track () {
		if (conf.track_number <= 0)
			return null;
		
		conf.track_number--;
		return build_track ();
	}
	
	// not used atm
	public Track? get_track (uint number) { /* number [1:length] */
		if (length <= 0 || number <= 0 || number > length)
			return null;
		conf.track_number = number - 1;
		return build_track ();
	}
	
	public Track? get_first_track () {
		if (length <= 0)
			return null;
		conf.track_number = 0;
		return build_track ();
	}
	
	public Track? get_last_track () {
		if (length <= 0)
			return null;
		conf.track_number = length - 1;
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
			artist = "", title = "", album = ""
		};
		return t;
	}
	
	private string get_cover_path () {
		string suffix;
		string path;
		uint slash = 0;
		uint pos = 0;
		/* remove track name from path */
		suffix = this.playlist.nth_data (conf.track_number);
		weak string it = suffix;
		
		while (it.len () > 0) {
			if (it.get_char () == '/')
				slash = pos;
			pos++;
			it = it.next_char ();
		}
		
		string s = suffix.substring (0, slash + 1);
		var base_path = conf.library_path + "/" + s;
		/* default path is an invalid one for taking default icon */
		path = base_path + "no_cover";
		foreach (string file_name in conf.covers) {
			var file = File.new_for_path (base_path + file_name);
			if (file.query_exists (null)) {
				path = file.get_path ();
				break;
			}
		}
		
		return path;
	}
	
	private void build_playlist () {
		playlist = new GLib.List<string> ();
		GLib.TimeVal mod_time_folder = TimeVal ();
		GLib.TimeVal mod_time_pl = TimeVal ();
		
		var dir = File.new_for_path (conf.library_path);
		var pl = File.new_for_path (conf.path + "/playlist-sorted");
		// TODO: FileInputStream
		
		try {
			var info = dir.query_info (GLib.FILE_ATTRIBUTE_TIME_MODIFIED, 
									   GLib.FileQueryInfoFlags.NONE, null);
			info.get_modification_time (out mod_time_folder);
			stdout.printf ("Modification Time: Folder: %ld\n", mod_time_folder.tv_sec);
			
			if (pl.query_exists (null)) {
				info = pl.query_info (GLib.FILE_ATTRIBUTE_TIME_MODIFIED, 
									  GLib.FileQueryInfoFlags.NONE, null);
				info.get_modification_time (out mod_time_pl);
				stdout.printf ("Modification Time: Playlist: %ld\n", mod_time_pl.tv_sec);
			}
		} catch (GLib.Error e) {
			GLib.warning ("%s\n", e.message);
		}
		
		process_directory (dir, "");
		
		// DEBUG
		stdout.printf ("Generated PlayList:\n");
		foreach (string song in playlist) {
			stdout.printf ("track: %s\n", song);
		}

		this.length = playlist.length ();
	}
	
	private void process_directory (GLib.File dir, string path) {
		GLib.FileInfo fileInfo;
		
		try {
			GLib.FileEnumerator enumerator = dir.enumerate_children ("*", 
					GLib.FileQueryInfoFlags.NONE, null);
			
			while ((fileInfo = enumerator.next_file (null)) != null) {
				if (fileInfo.get_file_type () == GLib.FileType.DIRECTORY) {
					string name = fileInfo.get_name ();
					var child = dir.get_child (name);
					process_directory (child, path + name + "/");
				} else {
					string p = fileInfo.get_name ();
					if (is_music (p))
						playlist.append (path + p);
				}
			}
			enumerator.close(null);

		} catch (GLib.Error e) {
			GLib.warning ("%s\n", e.message);
		}
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
