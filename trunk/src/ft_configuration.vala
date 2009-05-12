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

	public string library_path {
		get; set;
		default = Environment.get_home_dir () + "/Music";
	}
	public uint track_number { /* [0, length-1] */
		get; set; default = 0;
	}
	public PlayListMode mode {
		get; set; default = PlayListMode.NULL;
	}
	public double volume { /* [0.0, 1.0] linear, but player uses exp. volume control */
		get; set; default = 1.0;
	}
	public string[] covers; /* all accepted cover names */
	
	public static string path = GLib.Environment.get_home_dir ()
								+ "/.fingertier";
	private static string file_name = "fingertier.conf";
	
	construct {
		covers = new string[0] { };
		read ();
	}
	
	/* destructor */
	~Configuration () {
		write ();
	}
	
	public bool read () {
		var dir = GLib.File.new_for_path (this.path);
		if (!dir.query_exists (null)) {
    		GLib.message ("Directory '%s' doesn't exist.", dir.get_path ());
			try {
				dir.make_directory (null);
			} catch {
				GLib.error ("Could not create configuration directory.");
				return false;
			}
		}
		
		var file = dir.get_child (this.file_name);
		
		if (!file.query_exists (null)) {
    		GLib.message ("File '%s' doesn't exist.", file.get_path ());
			try {
				/* write defaults */
				var conf = new GLib.KeyFile ();
				conf.set_string ("settings", "LIBRARY_PATH", this.library_path);
				conf.set_integer ("settings", "MODE", (int) this.mode);
				conf.set_double ("settings", "VOLUME", this.volume);
				this.covers = new string[3] { "cover.jpg", "folder.jpg", "cover.png" };
				conf.set_string_list ("settings", "COVER_NAMES", this.covers); // NOTE: C warning: Bug filed upstream.
				
				conf.set_integer ("state", "TRACK_NUMBER", (int) this.track_number);
				GLib.FileUtils.set_contents (file.get_path (), conf.to_data(null));
				
			} catch (IOError e) {
				GLib.error ("Could not create configuration file.");
			}
			return false;
		}
		
		/* read */
		var conf = new GLib.KeyFile ();
		uint u;
		double d;
		string[] c;
		try {
			conf.load_from_file (file.get_path (), GLib.KeyFileFlags.NONE);
			this.library_path = conf.get_string ("settings", "LIBRARY_PATH");
			
			u = (uint) conf.get_integer ("settings", "MODE");
			if (u < 3)
				this.mode = (PlayListMode) u;
			else
				this.mode = PlayListMode.NULL;
			
			u = (uint) conf.get_integer ("state", "TRACK_NUMBER");
			if (u > 0)
				this.track_number = u - 1;
			else
				this.track_number = 0;
			
			d = conf.get_double ("settings", "VOLUME");
			if (d >= 0.0 && d <= 1.0)
				this.volume = d;
			else
				this.volume = 1.0;
			
			try {
				c = conf.get_string_list ("settings", "COVER_NAMES"); // NOTE: C warning: Bug filed upstream.
				this.covers = c;
				if (this.covers == null)
					this.covers = new string[0] { };
			} catch (GLib.KeyFileError e) {
				GLib.warning ("%s", e.message);
			}
			
			// Debug
			stdout.printf ("library_path = %s\n", this.library_path);
			stdout.printf ("mode = %u\n", this.mode);
			stdout.printf ("volume = %f\n", this.volume);
			stdout.printf ("track_number = %u (TRACK_NUMBER - 1)\n", this.track_number);
			stdout.printf ("cover_names = ");
			foreach(string s in this.covers)
				stdout.printf ("%s, ", s);
			stdout.printf ("\n\n");
			
		} catch (GLib.IOError e) {
    		GLib.warning ("%s", e.message);
			return false;
		}
		
		return true;
	}

	public bool write () {
		var file = GLib.File.new_for_path (this.path + "/" + this.file_name);
		var conf = new GLib.KeyFile ();
		conf.set_string ("settings", "LIBRARY_PATH", this.library_path);
		conf.set_integer ("settings", "MODE", (int) this.mode);
		conf.set_double ("settings", "VOLUME", this.volume);
		conf.set_string_list ("settings", "COVER_NAMES", this.covers); // NOTE: C warning: Bug filed upstream.
		
		conf.set_integer ("state", "TRACK_NUMBER", (int) (this.track_number  + 1));
		
		try {
			GLib.FileUtils.set_contents (file.get_path (), conf.to_data(null));
			
		} catch (IOError e) {
			GLib.error ("Could not write configuration file.");
			return false;
		}
		// Debug
		stdout.printf ("Configuration saved.\n");
		
		return true;
	}
}

} /* namespace Ft end */