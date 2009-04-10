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

public class FtConfiguration : GLib.Object {
/*
	private string library_path;
	private int playlist_generation_timestamp;
	private int playlist_type;
	private int playlist_current_track;
*/
	construct {
		// TODO: read config file
		
		// Environment.get_home_dir ()
	}

	public void set_library_path (string path) {
		// TODO
	}

	public string get_library_path () {
		// TODO
		return "";
	}

	public bool save() {
		// TODO: save all members to disk (~/.fingertier/config)
		return false;
	}

}
