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
using Gtk;

namespace Ft {

public class PlayerGTK : Player {
	
	private Gtk.Label info_label;
	private Gtk.Label track_label;
	private Gtk.Image play_pause_img;
	private Gdk.Pixbuf cover;
	private Gtk.Window window;

	construct {
		create_widgets ();
		/* register signal handler */
		this.track_data_changed += update_widgets;
	}
	
	private void create_widgets () {
		var vbox = new Gtk.VBox (false, 0);

		var previous_button = new Gtk.Button ();
		var previous_img = new Gtk.Image.from_stock (STOCK_MEDIA_PREVIOUS, 
													 Gtk.IconSize.DIALOG);
		previous_button.set_image (previous_img);
		previous_button.set_size_request (100, 100);
		previous_button.clicked += previous;
		
		var play_button = new Gtk.Button ();
		this.play_pause_img = new Gtk.Image.from_stock (STOCK_MEDIA_PLAY, 
														Gtk.IconSize.DIALOG);
		play_button.set_image (play_pause_img);
		play_button.set_size_request (100, 100);
		play_button.clicked += (s) => {
			string stock_id;
			// NOTE: C warning: Patch submitted upstream.
			this.play_pause_img.get_stock (out stock_id, null);
			if (stock_id == STOCK_MEDIA_PLAY)
				this.play_pause_img.set_from_stock (STOCK_MEDIA_PAUSE, Gtk.IconSize.DIALOG);
			else
				this.play_pause_img.set_from_stock (STOCK_MEDIA_PLAY, Gtk.IconSize.DIALOG);
			play_pause ();
		};

		var next_button = new Gtk.Button ();
		var next_img = new Gtk.Image.from_stock (STOCK_MEDIA_NEXT, 
												 Gtk.IconSize.DIALOG);
		next_button.set_image (next_img);
		next_button.set_size_request (100, 100);
		next_button.clicked += next;

		var bbox = new Gtk.HButtonBox ();
		bbox.set_layout (Gtk.ButtonBoxStyle.SPREAD); //CENTER
		bbox.add (previous_button);
		bbox.add (play_button);
		bbox.add (next_button);
		
		info_label = new Gtk.Label ("");
		info_label.set_justify (Gtk.Justification.CENTER);
		
		track_label = new Gtk.Label ("");
		track_label.set_justify (Gtk.Justification.CENTER);
		
		try {
			this.cover = new Gdk.Pixbuf.from_file_at_size (track.cover_path, 300, 300);
		} catch (GLib.Error e) {
			try {
				/* fallback image */
				// TODO: move into playlist
				this.cover = new Gdk.Pixbuf.from_file_at_size (
					"/usr/share/icons/Tango/scalable/mimetypes/audio-x-generic.svg", 250, 250);
			} catch (GLib.Error e) {
				GLib.warning ("%s\n", e.message);
			}		
		}
		var image = new Gtk.Image.from_pixbuf (cover);
		
		vbox.pack_start (image, false, true, 0);
		vbox.pack_end (bbox, false, true, 0);
		vbox.pack_end (track_label, false, true, 0);
		vbox.pack_end (info_label, false, true, 0);
		this.window = new Gtk.Window (Gtk.WindowType.TOPLEVEL);
		this.window.add (vbox);
		
		this.window.title = "Fingertier Music Player";
		this.window.set_default_size (480, 600); /* OM GTA02 screen size: 480x640 */
		this.window.set_border_width (16);
		this.window.position = Gtk.WindowPosition.CENTER;
		this.window.destroy += Gtk.main_quit;
		
		track_data_changed ();
	}
	
	private void update_widgets () {
		string data; 
		data = "<span size=\"xx-large\">%s</span>\n".printf (track.info);
		this.info_label.set_markup (data);
		
		data = "<span size=\"xx-large\">%u/%u</span>\n".printf (track.number+1, track.pl_len);
		this.track_label.set_markup (data);
	}
	
	public void draw () {
		this.window.show_all ();
	}
	
}

} /* namespace Ft end */