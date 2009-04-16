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

namespace Ft {
	
/* public struct Track { */ // TODO: should be a struct, but they are broken in Vala.
public class Track {
	public uint number;	/* [1, length] */
	public uint pl_len; /* length of the playlist */
	public string uri;
	public string cover_path;
	public string artist;
	public string title;
	public string album;

	public Track (uint n, uint l, string u, string cp) {
		number = n;
		pl_len = l;
		uri = u;
		cover_path = cp;
		artist = ""; title = ""; album = "";
	}
}	

public enum PlayListMode {
	NULL = 0,
	SORTED,
	SHUFFLED
}

/* Ft.Player implements a music player without gui */
public class Player : GLib.Object {

	private Gst.Element pipeline;   /* a Gstreamer playbin */
	private PlayList pl;			/* handles the state and the data of the player */
	public Track? track { get; private set; }

	construct {
		pl = new PlayList ();
		track = pl.get_current_track ();
		setup_pipeline ();
		track_data_changed ();
	}

	/* destructor */
	~Player () {
		this.pipeline.set_state (Gst.State.NULL);
	}

	private void setup_pipeline () {
		pipeline = ElementFactory.make ("playbin", "finger_playbin");

		var bus = pipeline.get_bus ();
		bus.add_signal_watch ();
		bus.message["tag"] += this.gst_tag_cb;
		bus.message["eos"] += this.gst_end_of_stream_cb;
		bus.message["error"] += this.gst_error_cb;
		
		if (track != null) {
			/* load the first track */
			this.pipeline.set ("uri", track.uri);
			this.pipeline.set_state (Gst.State.PAUSED);
		}
	}

	/* Callback if the end of a track is reached */
	private void gst_end_of_stream_cb (Gst.Bus bus, Gst.Message message) {
		GLib.message ("End of stream (eos) reached.");
		this.next();
	}

	/* Callback to collect tags from playbin */
	private void gst_tag_cb (Gst.Bus bus, Gst.Message message) {
		TagList tag_list;

		message.parse_tag (out tag_list);
		tag_list.foreach (this.save_tag); // NOTE: C warning: Bug filed upstream.
		track_data_changed ();
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
	private void save_tag (Gst.TagList list, string tag) {
		Gst.Value val;
		
		list.copy_value (out val, list, tag);
		switch (tag) {
			case ("title"):
				stdout.printf ("tag: %s: %s\n", tag, val.get_string ());
				this.track.title = val.get_string ();
				break;
			case ("artist"):
				stdout.printf ("tag: %s: %s\n", tag, val.get_string ());
				this.track.artist = val.get_string ();
				break;
			case ("album"):
				stdout.printf ("tag: %s: %s\n", tag, val.get_string ());
				this.track.album = val.get_string ();
				break;
		}
	}

	/* Protected functions and signals */
	protected signal void track_data_changed ();

	/* Public functions */
	public bool play_pause () {
		if (track == null)
			return false;
		
		Gst.State state;
		Gst.ClockTime time = Gst.util_get_timestamp ();
		this.pipeline.get_state (out state, null, time);
	
		// TODO: smooth transitions
		if (state == State.PLAYING) {
			this.pipeline.set_state (Gst.State.PAUSED);
		} else {
			this.pipeline.set ("uri", track.uri);
			this.pipeline.set_state (Gst.State.PLAYING);
		}
		return true;
	}

	public void next () {
		Track? t = pl.get_next_track ();
		if (t == null)
			return;
		
		track = t;
	
		Gst.State old_state;
		Gst.ClockTime time = Gst.util_get_timestamp ();
		this.pipeline.get_state (out old_state, null, time);

		this.pipeline.set_state (Gst.State.READY);
		this.pipeline.set ("uri", track.uri);
		track_data_changed ();
	
		if (old_state == State.PLAYING)
			this.pipeline.set_state (Gst.State.PLAYING);
		else
			this.pipeline.set_state (Gst.State.PAUSED);
	}

	public void previous () {
		Track? t = pl.get_previous_track ();
		if (t == null)
			return;
		
		track = t;

		Gst.State old_state;
		Gst.ClockTime time = Gst.util_get_timestamp ();
		this.pipeline.get_state (out old_state, null, time);

		this.pipeline.set_state (Gst.State.READY);
		pipeline.set ("uri", track.uri);
		track_data_changed ();

		if (old_state == State.PLAYING)
			this.pipeline.set_state (Gst.State.PLAYING);
		else
			this.pipeline.set_state (Gst.State.PAUSED);
	}
}

} /* namespace Ft end */

public static int main (string[] args) {
	Gst.init (ref args);
	
	Gtk.init (ref args);
	var player = new Ft.PlayerGTK ();
	player.draw ();
	Gtk.main ();
	
	return 0;
}
