# Package

version        = "0.1.0"
author         = "Dragan Janushevski"
description    = "Quake 3 BSP viewer"
license        = "MIT"

srcDir         = "src"
bin            = @["coreBSP"]

# Dependencies
requires "nim >= 0.19.4"
requires "sdl2"
requires "opengl"
requires "stb_image"
requires "glm"

# Tasks

task buildandrun, "Build Release version and run the example Level.bsp":
  exec "nim -d:release --opt:size --passl:-s c -r --parallelBuild:4 -o:coreBSP src/coreBSP.nim baseq3/maps/Level.bsp"
  
task dbuildandrun, "Build Release version and run the example Level.bsp":
  exec "nim --passl:-s c -r --parallelBuild:4 -o:coreBSP src/coreBSP.nim baseq3/maps/Level.bsp"