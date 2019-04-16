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

