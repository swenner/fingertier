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

public class FtPlayList : GLib.Object {

	//TODO: private FtConfiguration config;
	
	private GLib.List<string> playlist;
	private string music_path;
	
	public uint track_number { get; private set; default = 0; } /* [0, length-1] */
	public uint length { get; private set; default = 0; }

	construct {
		music_path = Environment.get_home_dir () + 
			"/Desktop/moko-player/music";
		
		build_playlist ();
		
		// TODO: generate playlist if needed. 
		// read the library folder recursively
		// creates two files: one with sorted paths, one with shuffled paths
		// (~/.fingertier/playlist-sorted, ~/.fingertier/playlist-shuffled)
		
	}
	
	public void set_mode (int type) { // use typed enumeration not int
		// TODO: shuffled or sorted
	}
	
	public int get_mode () { // use typed enumeration not int
		// TODO: shuffled or sorted
		return 0;
	}
	
	public bool do_shuffle () {
		// TODO: shuffle on demand
		return false;
	}
	
	public string get_current_track_uri () {
		string uri = "file://" + this.music_path + "/" + 
					 this.playlist.nth_data (this.track_number);
		return uri;
	}
	
	public string get_next_track_uri () {
		if (track_number >= length - 1)
			return "";
		
		track_number++;
		string uri = "file://" + this.music_path + "/" + 
					 this.playlist.nth_data (this.track_number);
		return uri;
	}
	
	public string get_previous_track_uri () {
		if (track_number <= 0)
			return "";
		
		track_number--;
		string uri = "file://" + this.music_path + "/" + 
					 this.playlist.nth_data (this.track_number);
		return uri;
	}
	
	public string get_cover_path () {
		// TODO: make it dynamic
		string path = this.music_path + "/cover.jpg";
		return path;
	}
	
	// TODO: it should check subfolders too!
	private void build_playlist () {
		File dir;
		FileInfo fileInfo;
		
		playlist = new GLib.List<string> ();
		
		dir = File.new_for_path (this.music_path);

		try {
			FileEnumerator enumerator = dir.enumerate_children ("*", FileQueryInfoFlags.NONE, null);

			while ((fileInfo = enumerator.next_file (null)) != null)
			{
				// TODO: check if it could be a music file
				playlist.append(fileInfo.get_name());
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
}
