masm piano.asm;
link piano.obj;
exe2bin piano.exe piano.com
del piano.obj
del piano.exe
echo Build complete. Run piano.com
