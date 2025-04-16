all: godot-cpp scons

godot-cpp:
	# ensure clean
	if [ -d 'godot-cpp/' ]; then rm -r godot-cpp; fi
	# download and install
	curl -Lo godot-4.2-stable.tar.gz https://github.com/godotengine/godot-cpp/archive/refs/tags/godot-4.2-stable.tar.gz
	tar xvf godot-4.2-stable.tar.gz
	mv godot-cpp-godot-4.2-stable/ godot-cpp/
	# cleanup
	rm godot-4.2-stable.tar.gz

scons:
	scons
