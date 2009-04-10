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

	//private FtPlayList pl;
	private Gst.Element pipeline;
	
	// just for prototyping. Will be moved into other classes.
	private GLib.List<string> playlist;
	public uint track;
	public uint track_count;
	public string track_info;
	public string music_path;
	// end

	construct {
		music_path = Environment.get_home_dir () + 
			"/Desktop/moko-player/music";
		track_info = "";
		build_playlist ();
		setup_gstreamer ();
	}

	private void setup_gstreamer () {
		pipeline = ElementFactory.make ("playbin", "finger_playbin");

		var bus = pipeline.get_bus ();
		bus.add_signal_watch ();
		bus.message["tag"] += this.gst_tag_cb;
		bus.message["eos"] += this.gst_end_of_stream_cb;
		bus.message["state-changed"] += this.gst_state_changed_cb;
		bus.message["error"] += this.gst_error_cb;
		
		/* hack to read the tags from the first track */
		this.pipeline.set ("uri", "file://" + this.music_path + "/" 
						  + this.playlist.nth_data (this.track));
		this.pipeline.set_state (Gst.State.PLAYING);
		this.pipeline.set_state (Gst.State.PAUSED);
	}
	
	/* Callback for state-change in playbin */
	private void gst_state_changed_cb (Gst.Bus bus, Gst.Message message) {
		if (message.src != this.pipeline)
			return;
		
		Gst.State new_state;
		Gst.State old_state;
		message.parse_state_changed (out old_state, out new_state, null);
		//stdout.printf ("state changed! old: %u new: %u \n", old_state, new_state);
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
		tag_list.foreach (this.save_tags); // TODO: C warning?
		update_track (this.track_count, this.track, this.track_info);
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
	private void save_tags (Gst.TagList list, string tag) {
		Gst.Value value;

		if (list.copy_value (out value, list, tag)) {
			if (tag == "title" || tag == "artist" || tag == "album") {
				stdout.printf ("tag: %s: %s\n", tag, value.get_string ());
				this.track_info += value.get_string () + "\n";
			}
		}
	}

	// REMOVE: it's a quick hack
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
			stdout.printf ("track: %s\n", song);
		}

		this.track_count = playlist.length ();
		update_track (track_count, 1, track_info);
	}
	
	/* Public signals */
	public signal void update_track (uint track_count, uint track, string info);
	
	/* Public functions */
	public void stop () { // TODO: public? stop? unload?
		this.pipeline.set_state (Gst.State.NULL);
	}

	public void play_pause () {
		Gst.State state;
		Gst.ClockTime time = Gst.util_get_timestamp ();
		
		this.pipeline.get_state (out state, null, time);
		
		// TODO: smooth transitions
		if (state == State.PLAYING) {
			this.pipeline.set_state (Gst.State.PAUSED);
		} else {
			this.pipeline.set ("uri", "file://" + this.music_path + "/" 
						  + this.playlist.nth_data (track));
			this.pipeline.set_state (Gst.State.PLAYING);
		}
	}

	public void next () {
		if (track >= playlist.length () - 1)
			return;
		
		track++;
		track_info = "";
		update_track (track_count, track, track_info);
		this.pipeline.set_state (Gst.State.READY);
		this.pipeline.set ("uri", "file://" + this.music_path + "/"
				+ this.playlist.nth_data (track) );
		this.pipeline.set_state (Gst.State.PLAYING);
		// TODO: preserve state
	}
	
	public void previous () {
		if (track <= 0)
			return;
		
		track--;
		track_info = "";
		update_track (track_count, track, track_info);
		this.pipeline.set_state (Gst.State.READY);
		pipeline.set ("uri", "file://" + this.music_path + "/"
				+ this.playlist.nth_data (track) );
		this.pipeline.set_state (Gst.State.PLAYING);
		// TODO: preserve state
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
