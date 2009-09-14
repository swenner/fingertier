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

public interface PlayList : GLib.Object {
	
	// TODO: do we really neeed these interfaces?
	public abstract void set_mode (PlayListMode mode);
	public abstract PlayListMode get_mode ();
	public abstract bool do_shuffle ();
	// needed interfaces:
	public abstract Track? get_current_track ();
	public abstract Track? get_next_track ();
	public abstract Track? get_previous_track ();
	public abstract Track? get_first_track ();
	public abstract Track? get_last_track ();
	// not used atm
	public abstract Track? get_track (uint number); /* number [1:length] */
}

} /* namespace Ft end */