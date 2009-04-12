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
using Gst;

public class FtPlayer : GLib.Object {

	private Gst.Element pipeline;
	
	public string track_info; // TODO: remove me
	public FtPlayList pl { get; private set; }

	construct {
		track_info = "";
		pl = new FtPlayList ();
		setup_pipeline ();
	}
	
	/* destructor */
	~FtPlayer () {
		unload_pipeline ();
	}

	private void setup_pipeline () {
		pipeline = ElementFactory.make ("playbin", "finger_playbin");

		var bus = pipeline.get_bus ();
		bus.add_signal_watch ();
		bus.message["tag"] += this.gst_tag_cb;
		bus.message["eos"] += this.gst_end_of_stream_cb;
		bus.message["error"] += this.gst_error_cb;
		
		/* hack to read the tags of the first track */
		this.pipeline.set ("uri", pl.get_current_track_uri ());
		this.pipeline.set_state (Gst.State.PLAYING);
		this.pipeline.set_state (Gst.State.PAUSED);
	}
	
	private void unload_pipeline () {
		this.pipeline.set_state (Gst.State.NULL);
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
		tag_list.foreach (this.save_tags); // NOTE: C warning: Bug filed upstream.
		track_data_changed (pl.length, pl.track_number, this.track_info);
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
		
		GLib.critical ("GST playbin error: %s \nDebug: %s\n", msg, debug);
	}

	/* Fetch the value of certain tags */
	private void save_tags (Gst.TagList list, string tag) {
		Gst.Value val;

		if (list.copy_value (out val, list, tag)) {
			if (tag == "title" || tag == "artist" || tag == "album") {
				stdout.printf ("tag: %s: %s\n", tag, val.get_string ());
				this.track_info += val.get_string () + "\n";
			}
		}
	}
	
	/* Protected functions and signals */
	protected signal void track_data_changed (uint track_count, uint track, string info);
	
	/* Public functions */
	public void play_pause () {
		Gst.State state;
		Gst.ClockTime time = Gst.util_get_timestamp ();
		this.pipeline.get_state (out state, null, time);
		
		// TODO: smooth transitions
		if (state == State.PLAYING) {
			this.pipeline.set_state (Gst.State.PAUSED);
		} else {
			this.pipeline.set ("uri", pl.get_current_track_uri ());
			this.pipeline.set_state (Gst.State.PLAYING);
		}
	}

	public void next () {
		string uri = pl.get_next_track_uri ();
		if (uri == "")
			return;
		
		Gst.State old_state;
		Gst.ClockTime time = Gst.util_get_timestamp ();
		this.pipeline.get_state (out old_state, null, time);
		
		track_info = "";
		this.pipeline.set_state (Gst.State.READY);
		this.pipeline.set ("uri", uri);
		track_data_changed (pl.length, pl.track_number, this.track_info);
		
		if (old_state == State.PLAYING)
			this.pipeline.set_state (Gst.State.PLAYING);
		else
			this.pipeline.set_state (Gst.State.PAUSED);
	}
	
	public void previous () {
		string uri = pl.get_previous_track_uri ();
		if (uri == "")
			return;
		
		Gst.State old_state;
		Gst.ClockTime time = Gst.util_get_timestamp ();
		this.pipeline.get_state (out old_state, null, time);
		
		track_info = "";
		this.pipeline.set_state (Gst.State.READY);
		pipeline.set ("uri", uri);
		track_data_changed (pl.length, pl.track_number, this.track_info);

		if (old_state == State.PLAYING)
			this.pipeline.set_state (Gst.State.PLAYING);
		else
			this.pipeline.set_state (Gst.State.PAUSED);
	}
}


public static int main (string[] args) {
	Gst.init (ref args);
	
	Gtk.init (ref args);
	var player = new FtPlayerGTK ();
	player.draw ();
	Gtk.main ();
	
	return 0;
}
