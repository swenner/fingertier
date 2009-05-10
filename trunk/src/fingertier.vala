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
	
public struct Track {
	public uint number;	 /* [1, pl_len] */
	public uint pl_len;	 /* length of the playlist */
	public string uri;	 /* uri to the track */
	public string cover_path;
	public string artist;
	public string title;
	public string album;
}	

public enum PlayListMode {
	NULL = 0,
	SORTED,
	SHUFFLED
}

public enum PlayListType {
	SIMPLE = 0
}

public enum PlayerState {
	NULL = 0,
	PAUSED,
	PLAYING
}

/* Ft.Player implements a music player without gui */
public class Player : GLib.Object {

	private Gst.Element pipeline;   /* a Gstreamer playbin TODO: should be Gst.PlayBin2 */
	private PlayList pl;		/* handles the state and the data of the player */
	public Track? track {
		get;
		private set;
	}
	public double track_position {
		get;
		private set;
		default = 0.0;
	}
	public Configuration conf {
		get;
		private set;
	}
	
	/* constructor */
	public Player (PlayListType type) {
		init (type);
	}

	/* destructor */
	~Player () {
		this.pipeline.set_state (Gst.State.NULL);
	}
	
	/* Protected functions and signals */
	protected signal void track_tags_changed ();
	protected signal void track_cover_path_changed ();
	protected signal void volume_changed (double volume);
	
	protected void init (PlayListType type) {
		conf = new Configuration ();
		pl = new PlayListSimple (this.conf);
		track = pl.get_current_track ();
		setup_pipeline ();
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
		
		GLib.Value val = GLib.Value (typeof(double));
		val.set_double ((Math.exp (conf.volume) - 1) / (Math.E - 1));
		pipeline.set_property ("volume", val);
	}

	/* Callback if the end of a track is reached */
	private void gst_end_of_stream_cb (Gst.Bus bus, Gst.Message message) {
		GLib.message ("End of stream (eos) reached.");
		this.next ();
	}

	/* Callback to collect tags from playbin */
	private void gst_tag_cb (Gst.Bus bus, Gst.Message message) {
		Gst.TagList tag_list;

		message.parse_tag (out tag_list);
		tag_list.foreach (this.save_tag); // NOTE: C warning: Bug filed upstream.
		track_tags_changed ();
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

	/* Public functions */
	public PlayerState play_pause () {
		if (track == null)
			return PlayerState.NULL;
		
		Gst.State state;
		Gst.ClockTime time = Gst.util_get_timestamp ();
		this.pipeline.get_state (out state, null, time);
	
		// TODO: smooth transitions
		if (state == State.PLAYING) {
			this.pipeline.set_state (Gst.State.PAUSED);
			return PlayerState.PAUSED;
		}
		this.pipeline.set ("uri", track.uri);
		this.pipeline.set_state (Gst.State.PLAYING);
		return PlayerState.PLAYING;
	}

	public void next () {
		Track? t = pl.get_next_track ();
		if (t == null) {
			/* cyclic play list */
			t = pl.get_first_track ();
			if (t == null)
				return;
		}
		track = t;

		Gst.State old_state;
		Gst.ClockTime time = Gst.util_get_timestamp ();
		this.pipeline.get_state (out old_state, null, time);
	
		this.pipeline.set_state (Gst.State.READY);
		this.pipeline.set ("uri", track.uri);
		
		if (old_state == State.PLAYING)
			this.pipeline.set_state (Gst.State.PLAYING);
		else
			this.pipeline.set_state (Gst.State.PAUSED);
		
		track_tags_changed ();
		track_cover_path_changed ();
	}

	public void previous () {
		Track? t = pl.get_previous_track ();
		if (t == null) {
			/* cyclic play list */
			t = pl.get_last_track ();
			if (t == null)
				return;
		}
		track = t;

		Gst.State old_state;
		Gst.ClockTime time = Gst.util_get_timestamp ();
		this.pipeline.get_state (out old_state, null, time);

		this.pipeline.set_state (Gst.State.READY);
		pipeline.set ("uri", track.uri);

		if (old_state == State.PLAYING)
			this.pipeline.set_state (Gst.State.PLAYING);
		else
			this.pipeline.set_state (Gst.State.PAUSED);
		
		track_tags_changed ();
		track_cover_path_changed ();
	}
	
	public void increase_volume () {
		GLib.Value val = GLib.Value (typeof(double));
		
		if (conf.volume < 0.9) {
			conf.volume += 0.1;
			val.set_double ((Math.exp (conf.volume) - 1) / (Math.E - 1));
			pipeline.set_property ("volume", val);
			volume_changed (conf.volume);
		} else if (conf.volume >= 0.9) {
			conf.volume = 1.0;
			val.set_double (conf.volume);
			pipeline.set_property ("volume", val);
			volume_changed (conf.volume);
		}
	}
	
	public void decrease_volume () {
		GLib.Value val = GLib.Value (typeof(double));
		
		if (conf.volume > 0.1) {
			conf.volume -= 0.1;
			val.set_double ((Math.exp (conf.volume) - 1) / (Math.E - 1));
			pipeline.set_property ("volume", val);
			volume_changed (conf.volume);
		} else if (conf.volume <= 0.1) {
			conf.volume = 0.0;
			val.set_double (conf.volume);
			pipeline.set_property ("volume", val);
			volume_changed (conf.volume);
		}
	}
}

} /* namespace Ft end */

public static int main (string[] args) {
	Gst.init (ref args);
	
	Gtk.init (ref args);
	var player = new Ft.PlayerGTK (Ft.PlayListType.SIMPLE);
	player.draw ();
	Gtk.main ();
	
	return 0;
}
