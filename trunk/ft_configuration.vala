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

public class Configuration : GLib.Object {

	public string library_path { get; set; 
			default = Environment.get_home_dir () + "/music"; }
	public uint track_number { get; set; default = 0; } /* [0, length-1] */
	public PlayListMode mode { get; set; default = PlayListMode.NULL;}
	public uint playlist_generation_timestamp { get; set; default = 0; }

	construct {
		read ();
	}
	
	public bool read () {
		// TODO: optimise this horrible function
		var dir = File.new_for_path (Environment.get_home_dir () + 
										"/.fingertier");
		if (!dir.query_exists (null)) {
    		GLib.message ("Directory '%s' doesn't exist.", dir.get_path ());
			try {
				dir.make_directory (null);
			} catch {
				GLib.error ("Could not create directory.");
				return false;
			}
		}
		
		var file = dir.get_child ("fingertier.conf");
		
		if (!file.query_exists (null)) {
    		GLib.message ("File '%s' doesn't exist.", file.get_path ());
			try {
				var ostream = file.create (FileCreateFlags.NONE, null);
				var data_stream = new DataOutputStream (ostream);
				/* write defaults */
				data_stream.put_string ("LIBRARY_PATH=%s\n".printf (library_path), null);
				data_stream.put_string ("TRACK_NUMBER=%u\n".printf (track_number), null);
				data_stream.put_string ("MODE=%u\n".printf (mode), null);
				data_stream.put_string ("TIMESTAMP=%u\n".printf (playlist_generation_timestamp), null);
				data_stream.close (null);
				ostream.close (null);
			} catch (IOError e) {
				GLib.error ("Could not create file.");
			}
			return false;
		}
		/* read */
		string line;
		try {
			var istream = new DataInputStream (file.read (null));
			while ((line = istream.read_line (null, null)) != null) {
				if (line.has_prefix ("LIBRARY_PATH=")) {
					this.library_path = line.substring (13, -1);
					stdout.printf ("%s\n", this.library_path);
				} else if (line.has_prefix ("TRACK_NUMBER=")) {
					this.track_number = line.substring (13, -1).to_int ();
					stdout.printf ("%u\n", this.track_number);
				} else if (line.has_prefix ("MODE=")) {
					this.mode = (PlayListMode) line.substring (5, -1).to_int ();
					stdout.printf ("%u\n", this.mode);
				} else if (line.has_prefix ("TIMESTAMP=")) {
					this.playlist_generation_timestamp = line.substring (10, -1).to_int ();
					stdout.printf ("%u\n", this.playlist_generation_timestamp);
				} else {
					GLib.message ("This configuration file contains garbage.");
				}
			}
			istream.close (null);
        } catch (IOError e) {
    		GLib.warning ("%s", e.message);
			return false;
		}
		return true;
	}

	public bool write () {
		// TODO: save all members to disk (~/.fingertier/fingertier.conf), which does exist.
		return false;
	}

}

} /* namespace Ft end */