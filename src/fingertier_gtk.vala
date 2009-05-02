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
using Config;

namespace Ft {

public const string default_cover_path = Config.PACKAGE_DATADIR 
		+ "/pixmaps/fingertier-256.png";


public class PlayerGTK : Player {
	
	private Gtk.Image cover;
	private Gtk.Label info_label;
	private Gtk.Label track_number_label;
	private Gtk.Image play_pause_img;
	private Gtk.HButtonBox volume_control;
	private Gtk.HButtonBox other_buttons;
	private Gtk.Label volume_label;
	private Gtk.Window window;
	private string last_cover_path; /* optimisation to avoid unneccessary cover reloads */

	public PlayerGTK (PlayList list) {
		base.init (list);
		create_widgets ();
		/* register signal handler */
		this.track_tags_changed += update_tag_widgets;
		this.track_cover_path_changed += update_cover_image;
		this.volume_changed += update_volume_label;
		track_tags_changed ();
		track_cover_path_changed ();
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
			if (play_pause () == PlayerState.PLAYING) {
				this.play_pause_img.set_from_stock (STOCK_MEDIA_PAUSE,
													Gtk.IconSize.DIALOG);
			} else {
				this.play_pause_img.set_from_stock (STOCK_MEDIA_PLAY,
													Gtk.IconSize.DIALOG);
			}
		};

		var next_button = new Gtk.Button ();
		var next_img = new Gtk.Image.from_stock (STOCK_MEDIA_NEXT,
												 Gtk.IconSize.DIALOG);
		next_button.set_image (next_img);
		next_button.set_size_request (100, 100);
		next_button.clicked += next;

		var bbox = new Gtk.HButtonBox ();
		bbox.set_layout (Gtk.ButtonBoxStyle.SPREAD);
		bbox.add (previous_button);
		bbox.add (play_button);
		bbox.add (next_button);
		
		info_label = new Gtk.Label (null);
		info_label.set_markup ("<span size=\"large\">Your playlist\nis empty.</span>\n");
		info_label.set_justify (Gtk.Justification.CENTER);

		track_number_label = new Gtk.Label ("");
		track_number_label.set_justify (Gtk.Justification.CENTER);
		
		this.cover = new Gtk.Image ();
		try {
			var pixbuf = new Gdk.Pixbuf.from_file_at_size (default_cover_path, 256, 256);
			this.cover.set_from_pixbuf (pixbuf);
		} catch (GLib.Error e) {
			GLib.warning ("%s: %s\n", e.message, default_cover_path);
		}
		
		var evbox = new Gtk.EventBox ();
		evbox.button_press_event += show_settings;
		evbox.add (cover);
		
		/* hidden settings widgets */
		var volup_button = new Gtk.Button ();
		var volup_img = new Gtk.Image.from_stock (STOCK_ADD,
												  Gtk.IconSize.DIALOG);
		volup_button.set_image (volup_img);
		volup_button.set_size_request (100, 100);
		volup_button.clicked += increase_volume;
		
		var voldown_button = new Gtk.Button ();
		var voldown_img = new Gtk.Image.from_stock (STOCK_REMOVE,
													Gtk.IconSize.DIALOG);
		voldown_button.set_image (voldown_img);
		voldown_button.set_size_request (100, 100);
		voldown_button.clicked += decrease_volume;
		
		volume_label = new Gtk.Label (null);
		volume_label.set_markup ("<span size=\"x-large\">%i %%</span>".printf
								((int) Math.round (this.volume * 100)));
		
		volume_control = new Gtk.HButtonBox ();
		volume_control.set_layout (Gtk.ButtonBoxStyle.SPREAD);
		volume_control.add (voldown_button);
		volume_control.add (volume_label);
		volume_control.add (volup_button);
		volume_control.set_no_show_all (true);
		
		var back_button = new Gtk.Button ();
		var back_img = new Gtk.Image.from_stock (STOCK_CANCEL,
												 Gtk.IconSize.DIALOG);
		back_button.set_image (back_img);
		back_button.set_size_request (80, 80);
		back_button.clicked += hide_settings;
		
		other_buttons = new Gtk.HButtonBox ();
		other_buttons.set_layout (Gtk.ButtonBoxStyle.SPREAD);
		other_buttons.add (back_button);
		other_buttons.set_no_show_all (true);
		/* hidden settings widgets end */
		
		vbox.pack_start (other_buttons, false, true, 10);
		vbox.pack_start (volume_control, false, true, 0);
		vbox.pack_start (evbox, false, true, 0);
		vbox.pack_end (bbox, false, true, 0);
		vbox.pack_end (track_number_label, false, true, 0);
		vbox.pack_end (info_label, false, true, 0);
		
		this.window = new Gtk.Window (Gtk.WindowType.TOPLEVEL);
		this.window.add (vbox);
		
		this.window.title = "Fingertier Music Player";
		this.window.set_default_size (480, 512); /* OM GTA02 screen size: 480x640 */
		this.window.set_border_width (16);
		this.window.position = Gtk.WindowPosition.CENTER;
		this.window.destroy += Gtk.main_quit;
	}
	
	private void update_tag_widgets () {
		string data; 
		string artist, title, album;
		
		if (track == null)
			return;
		
		if (track.artist.len() > 37)
			artist = GLib.Markup.escape_text (track.artist.substring (0, 33), -1)
					+ "...";
		else
			artist = GLib.Markup.escape_text (track.artist, -1);
		
		if (track.title.len() > 37)
			title = GLib.Markup.escape_text (track.title.substring (0, 33), -1)
					+ "...";
		else
			title = GLib.Markup.escape_text (track.title, -1);
		
		if (track.album.len() > 37)
			album = GLib.Markup.escape_text (track.album.substring (0, 33), -1)
					+ "...";
		else
			album = GLib.Markup.escape_text (track.album, -1);
		
		data = "<span size=\"large\">%s\n%s\n%s</span>\n".printf (artist,
																  title,
																  album);
		this.info_label.set_markup (data);
		
		data = "<span size=\"large\">%u/%u</span>\n".printf (track.number, track.pl_len);
		this.track_number_label.set_markup (data);
	}
		
	private void update_cover_image () {
		if (track == null)
			return;
		
		if (this.last_cover_path != track.cover_path) {
			try {
				var dir = File.new_for_path (track.cover_path);
				Gdk.Pixbuf pixbuf;
				if (!dir.query_exists (null)) {
					/* fallback image */
					pixbuf = new Gdk.Pixbuf.from_file_at_size (default_cover_path, 256, 256);
					this.last_cover_path = "";
				} else {
					pixbuf = new Gdk.Pixbuf.from_file_at_size (track.cover_path, 256, 256);
					this.last_cover_path = track.cover_path;
				}
				this.cover.set_from_pixbuf (pixbuf);
			} catch (GLib.Error e) {
				GLib.warning ("%s\n", e.message);
			}
		}
	}
	
	private void update_volume_label (double volume) {
		this.volume_label.set_markup ("<span size=\"x-large\">%i %%</span>".printf
									 ((int)(Math.round (volume * 100))));
	}
	
	private bool show_settings () {
		this.cover.set_no_show_all (true);
		this.cover.hide ();
		this.volume_control.set_no_show_all (false);
		this.volume_control.show_all ();
		this.other_buttons.set_no_show_all (false);
		this.other_buttons.show_all ();
		
		return true;
	}
	
	private void hide_settings () {
		this.volume_control.hide_all ();
		this.volume_control.set_no_show_all (true);
		this.other_buttons.hide_all ();
		this.other_buttons.set_no_show_all (true);
		this.cover.set_no_show_all (false);
		this.cover.show ();
	}
	
	public void draw () {
		this.window.show_all ();
	}
	
}

} /* namespace Ft end */