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
using Gst;
using FtPlayList;

public class FtMusicPlayer : Gtk.Window {

	private FtPlayList pl;
	private Gst.Element pipeline;
	
	// just for prototyping. Will be moved into other classes.
	private GLib.List<string> playlist;
	private uint track;
	private uint track_count;
	private string music_path;
	private Gtk.Label label;
	private Gtk.Label label2;
	private Gtk.Button play_button; // TODO: use image pixbuf
	private Gdk.Pixbuf cover;
	// end

	construct {
		music_path = Environment.get_home_dir () + 
			"/Desktop/moko-player/fingertier/music";
		create_widgets ();
		build_playlist ();
		setup_gstreamer ();
	}

	private void create_widgets () {
		var vbox = new VBox (false, 0);

		var previous_button = new Button.from_stock (STOCK_MEDIA_PREVIOUS);
		previous_button.clicked += previous;
		this.play_button = new Button.from_stock (STOCK_MEDIA_PLAY);
		play_button.set_size_request(-1, 100);
		play_button.clicked += play_pause;
		var next_button = new Button.from_stock (STOCK_MEDIA_NEXT);
		next_button.clicked += next;

		var bbox = new Gtk.HButtonBox ();
		bbox.set_layout(Gtk.ButtonBoxStyle.CENTER);
		bbox.add (previous_button);
		bbox.add (play_button);
		bbox.add (next_button);
		
		label = new Gtk.Label ("");
		label.set_justify(Gtk.Justification.CENTER);
		
		label2 = new Gtk.Label ("");
		label2.set_justify(Gtk.Justification.CENTER);
		
		try {
			this.cover = new Gdk.Pixbuf.from_file_at_size (music_path + "/cover.jpg", 300, 300);
		} catch (GLib.Error e) {
			GLib.warning ("%s\n", e.message);
		}
		var image = new Image.from_pixbuf (cover);
		
		vbox.pack_start (image, false, true, 0);
		vbox.pack_end (bbox, false, true, 0);
		vbox.pack_end (label2, false, true, 0);
		vbox.pack_end (label, false, true, 0);
		this.add (vbox);
		
		this.title = "Fingertier Music Player";
		this.set_default_size (480, 600); /* OM GTA2 screen size: 480x640 */
		this.set_border_width (16);
		this.position = Gtk.WindowPosition.CENTER;
		this.destroy += (source) => {
			this.pipeline.set_state (State.NULL);
			Gtk.main_quit();
		};
	}

	private void setup_gstreamer () {
		pipeline = ElementFactory.make ("playbin", "finger_playbin");
		
		// TODO: read tags from the first track

		var bus = pipeline.get_bus ();
		bus.add_signal_watch ();
		bus.message["tag"] += this.gst_tag_cb;
		bus.message["eos"] += this.gst_end_of_stream_cb;
		bus.message["state-changed"] += this.gst_state_changed_cb;
		bus.message["error"] += this.gst_error_cb;
	}
	
	/* Callback for state-change in playbin */
	private void gst_state_changed_cb (Gst.Bus bus, Gst.Message message) {
		if (message.src != this.pipeline)
			return;
		
		State new_state;
		State old_state;

		message.parse_state_changed (out old_state, out new_state, null);
		stdout.printf ("state changed! old: %u new: %u \n", old_state, new_state);
		/* Possible states: VOID_PENDING, NULL, READY, PAUSED, PLAYING */
		
		//if (new_state == State.PAUSED && old_state == State.READY) {
			
		//}
	}

	/* Callback if the end of a track is reached */
	private void gst_end_of_stream_cb (Gst.Bus bus, Gst.Message message) {
		stdout.printf ("EOS reached\n");
		this.next();
	}

	/* Callback to collect tags from playbin */
	private void gst_tag_cb (Gst.Bus bus, Gst.Message message) {
		TagList tag_list;

		message.parse_tag (out tag_list);
		tag_list.foreach (this.foreach_tag);
		// TODO: C warning?
	}
	
	/* Callback for errors in playbin */
	private void gst_error_cb (Gst.Bus bus, Gst.Message message) {
		string debug;
		string msg = "";
		Error error = null;

		message.parse_error (out error, out debug);
		if (error != null) {
			msg = error.message;
		}
		
		critical ("GST playbin error: %s \nDebug: %s\n", msg, debug);
	}

	/* Fetch value of certain tags */
	private void foreach_tag (Gst.TagList list, string tag) {
		Gst.Value value;

		if (list.copy_value (out value, list, tag)) {
			if (tag == "title" || tag == "artist" || tag == "album") {
				stdout.printf ("tag: %s, %s\n", tag, value.get_string ());
				string info = "<span size=\"xx-large\">" + this.label.get_label() 
						+ value.get_string () + "</span>\n";
				this.label.set_markup (info);
			}
		}
	}

	/* a quick hack */
	private void build_playlist () {
		File dir;
		FileInfo fileInfo;
		
		playlist = new GLib.List<string> ();
		track = 0;
		
		dir = File.new_for_path (this.music_path);

		try {
			FileEnumerator enumerator = dir.enumerate_children ("*", FileQueryInfoFlags.NONE, null);

			while ((fileInfo = enumerator.next_file (null)) != null)
			{
				// TODO: check for music files and add them recursively
				playlist.append(fileInfo.get_name());
			}
			enumerator.close(null);

		} catch (GLib.Error e) {
			GLib.warning ("%s\n", e.message);
		}
		
		foreach (string song in playlist) {
			stdout.printf ("%s\n", song);
		}

		this.track_count = playlist.length ();
		string data = "<span size=\"xx-large\">1/%u</span>\n".printf (track_count);
		this.label2.set_markup (data);
	}

	/* GTK callbacks */
	public void play_pause () {
		Gst.State state;
		Gst.ClockTime time = Gst.util_get_timestamp ();
		
		this.pipeline.get_state (out state, null, time);
		
		// TODO: smooth transitions
		if (state == State.PLAYING) {
			//TODO: change button: this.play_button = new Button.from_stock (STOCK_MEDIA_PAUSE);
			this.pipeline.set_state (State.PAUSED);
		} else {
			this.pipeline.set ("uri", "file://" + this.music_path + "/" 
						  + this.playlist.nth_data (track));
			this.pipeline.set_state (State.PLAYING);
		}
	}

	public void next () {
		if (track >= playlist.length () - 1)
			return;
		
		track++;
		this.label.set_label ("");
		string data = "<span size=\"xx-large\">%u/%u</span>\n".printf (track+1, track_count);
		this.label2.set_markup (data);
		this.pipeline.set_state (State.READY);
		this.pipeline.set ("uri", "file://" + this.music_path + "/"
				+ this.playlist.nth_data (track) );
		this.pipeline.set_state (State.PLAYING);
		
	}
	
	public void previous () {
		if (track <= 0)
			return;
		
		track--;
		string data = "<span size=\"xx-large\">%u/%u</span>\n".printf (track+1, track_count);
		this.label2.set_markup (data);
		this.label.set_label ("");
		this.pipeline.set_state (State.READY);
		pipeline.set ("uri", "file://" + this.music_path + "/"
				+ this.playlist.nth_data (track) );
		this.pipeline.set_state (State.PLAYING);
	}
	
	/* GTK callbacks end */
	
	public static int main (string[] args) {
    	Gst.init (ref args);
    	Gtk.init (ref args);

    	var player_window = new FtMusicPlayer ();
		player_window.show_all ();

    	Gtk.main ();
    	return 0;
	}
}

