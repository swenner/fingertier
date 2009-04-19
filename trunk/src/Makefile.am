
INCLUDES = \
	$(FINGERTIER_CFLAGS) \
	$(NULL)

BUILT_SOURCES = fingertier.vala.stamp

AM_CFLAGS = -Wall -pedantic -std=c99 -DPACKAGE_DATADIR=\""$(datadir)"\"

bin_PROGRAMS = fingertier

fingertier_VALASOURCES = \
	fingertier.vala \
	fingertier_gtk.vala \
	ft_configuration.vala \
	ft_play_list.vala \
	config.vapi \
	$(NULL)

nodist_fingertier_SOURCES = \
	$(fingertier_VALASOURCES:.vala=.c) \
	$(NULL)

fingertier.vala.stamp: $(fingertier_VALASOURCES)
	$(VALAC) -C --pkg gtk+-2.0 --pkg gstreamer-0.10 --pkg gio-2.0 --save-temps --basedir $(top_srcdir) $^
	touch $@

fingertier_LDADD = \
	$(FINGERTIER_LIBS) \
	$(NULL)

EXTRA_DIST = \
	$(fingertier_VALASOURCES) \
	$(NULL)

CLEANFILES = \
	fingertier.vala.stamp \
	*.c

MAINTAINERCLEANFILES  = \
	Makefile.in


