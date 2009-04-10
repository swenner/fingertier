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

	//private FtConfiguration config;

	construct {
		// TODO: generate playlist if needed. read the library folder recursively
		// creates two files one with sorted paths, one with shuffled paths
		// (~/.fingertier/playlist-sorted, ~/.fingertier/playlist-shuffled)
		
	}
	
	public void set_type (int type) { // use enumeration not int
		// TODO
	}
	
	public bool do_shuffle () {
		// TODO: shuffle on demand
		return false;
	}
	
	public bool is_shuffle () {
		// TODO
		return false;
	}
	
	public string get_current_track_uri () {
		// TODO
		return "";
	}
	
	public string get_next_track_uri () {
		// TODO
		return "";
	}
	
	public string get_last_track_uri () {
		// TODO
		return "";
	}
	
	public string get_cover_path () {
		// TODO
		return "";
	}
	
	public int get_tracknumber () {
		// TODO
		return 0;
	}
	
	public int get_length () {
		// TODO
		return 0;
	}
}
