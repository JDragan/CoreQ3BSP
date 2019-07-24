import strutils
import os


let TAB : string = "\t"
let BRACKETOPEN : string = "{"
let BRACKETCLOSED : string = "}"

proc parseq3shader*(mapname: string): seq[string] =
    let q3shaderfile = getAppDir() / "baseq3" / "scripts" / mapname & ".shader"

    var skyblock: seq[string]
    var previousLine : string
    if existsFile(q3shaderfile):
        echo "Q3SHADER: ", q3shaderfile
        for line in lines open(q3shaderfile):
            if line.startsWith("//") or line.startsWith(TAB & "q3map_sunExt"): continue
            if line.contains("skyparms "):
                echo "{LINE}"
                for s in line.split:
                    if s.startsWith("env/"):
                        skyblock.add(s & "_lf") # add left skybox for now

            previousLine = line

    return skyblock
