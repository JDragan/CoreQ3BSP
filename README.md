# CoreQ3BSP

Modern Quake 3 BSP viewer written in Nim

## Usage
- Install [Nim](https://nim-lang.org/)
- Clone this repo and navigate to the root folder
- Compile and Run with:
```sh
nim -d:release c -r -o:coreBSP src\coreBSP.nim baseq3\maps\Level.bsp
```
or
```sh
nimble buildandrun
```
for production version (fastest build, smallest mem footprint) use:
```sh
nimble buildandrun_gc_arc
```
![Imported level (apdm3)](https://i.postimg.cc/Jzwh10Xq/screen01.png)
