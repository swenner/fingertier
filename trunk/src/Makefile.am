INCLUDES = -I$(top_srcdir)

BUILT_SOURCES = fingertier.vala.stamp

AM_CFLAGS = -Wall -pedantic -std=c99 @DEPENDENCIES_CFLAGS@

bin_PROGRAMS = fingertier

fingertier_VALASOURCES = \
	fingertier.vala \
	fingertier_gtk.vala \
	ft_configuration.vala \
	ft_play_list.vala \
	$(NULL)

fingertier_SOURCES = \
	$(fingertier_VALASOURCES:.vala=.c) \
	$(fingertier_VALASOURCES:.vala=.h) \
	$(NULL)

fingertier.vala.stamp: $(fingertier_VALASOURCES)
	$(VALAC) -c --pkg gtk+-2.0 --pkg gstreamer-0.10 --pkg gio-2.0 --save-temps --basedir $(top_srcdir) $^
	touch $@

fingertier_LDADD = \
	$(FINGERTIER_LIBS) \
	$(NULL)


MAINTAINERCLEANFILES  = config.h.in Makefile.in

