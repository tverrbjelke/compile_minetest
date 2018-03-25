# compile_minetest
some script so I can automate compiling that.

It places the minetest binaries locally,
under <minetest.x.y>/bin/ is minetest and minetestserver executables.

The needed debian packages are installed, needs sudo for this.

-------------------

It includes the minetest server, too.
And then it also "installs" (downloads to the global mod path) some mods.

read the bash script and tune if needed.

The client should run perfectly without much config.

The server and the mods [sh|c]ould be configured.

---------------------------
Tested with debian 9 stretch
