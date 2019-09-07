--convenience module to load when running Lua scripts with F5 from SciTE.
io.stdout:setvbuf'no'
io.stderr:setvbuf'no'
pp = require'pp'
require'terra'
glue = require'glue'
pr = terralib.printraw
