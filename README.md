# waxweaver
this is the source code for waxweaver<br/>
it uses c++ gdextension, so it must be opened in godot 4.2 or it won't work<br/>
just the "theSandbox" folder is required if you would like to open the project<br/>
"src" contains the c++ code which pertains to blocks and world generation and other intensive stuff<br/>

## dependencies
- [godot 4.2](https://godotengine.org/download/archive/4.2-stable/)
- `godot-cpp` (makefile handles automatically)
- `scons`

## building
1. run `make` to download **godot-cpp 4.2** and compile c++ objects
2. open project (`theSandbox/project.godot`) in **godot 4.2** and debug/export

for a release build, invoke `scons` directly with your target before exporting
> e.g. for a Windows release: `scons platform=windows target=template_release` <br/>
