
bin_PROGRAMS = fingertier

fingertier_SOURCES = \
	fingertier.vala \
	fingertier_gtk.vala \
	ft_configuration.vala \
	ft_play_list.vala \
	ft_play_list_simple.vala \
	config.vapi \
	$(NULL)

fingertier_CFLAGS = \
	$(FINGERTIER_CFLAGS) \
	-Wall -pedantic -std=c99 -DPACKAGE_DATADIR=\""$(datadir)"\" \
	$(NULL)

fingertier_LDADD = \
	$(FINGERTIER_LIBS) \
	$(NULL)

fingertier_VALAFLAGS = \
	--pkg gtk+-2.0 --pkg dbus-glib-1 --pkg gstreamer-0.10 --pkg gio-2.0

EXTRA_DIST = 

CLEANFILES = \
	*.c \
	*.h 

MAINTAINERCLEANFILES  = \
	Makefile.in


