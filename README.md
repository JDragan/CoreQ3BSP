# CoreQ3BSP

Modern Quake 3 BSP viewer written in Nim

## Usage
- Install [Nim](https://nim-lang.org/)
- Clone this repo and navigate to the root folder
- Compile and Run with
```sh
nim -d:release --opt:size --passl:"-s" c -r --parallelBuild:4 -o:coreBSP src\coreBSP.nim baseq3\maps\Level.bsp
```


![Imported level (apdm3)](https://i.postimg.cc/Jzwh10Xq/screen01.png)
