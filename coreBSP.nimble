# Package
version        = "0.1.0"
author         = "Dragan Janushevski"
description    = "Quake 3 BSP viewer"
license        = "MIT"

srcDir         = "src"
bin            = @["coreBSP"]

# Dependencies
requires "nim >= 1.6.2"
requires "sdl2"
requires "opengl"
requires "stb_image"
requires "glm"

# Tasks

task prod, "Build Release version and run the example Level.bsp":
  exec "nim -d:release -d:danger --passl:-s c -r --gc:orc -o:coreBSP src/coreBSP.nim baseq3/maps/Level.bsp"

task clean, "":
  exec "rm coreBSP"
