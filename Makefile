# Fingertier Makefile

PKG_NAME="fingertier"
VERSION=0.0.0

all:
	valac --pkg gtk+-2.0 --pkg gstreamer-0.10 --pkg gio-2.0 -o $(PKG_NAME) \
			fingertier.vala fingertier_gtk.vala ft_play_list.vala ft_configuration.vala

clean:
	rm -f $(PKG_NAME)
	
test:
	./$(PKG_NAME)

install:
	#TODO