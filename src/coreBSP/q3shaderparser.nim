import strutils
import os


type
    shdBlock* = object
        bsptexture*: string
        blockstrings*: seq[string]
        internalstrings*: seq[string]

proc parseq3shader*(mapname: string): seq[shdBlock] =
    var q3shaderblocks: seq[shdBlock]

    for q3shaderfile in walkFiles getAppDir() / "baseq3" / "scripts" / "*.shader":

        var InBLOCK: bool = false
        var InSMBLOCK: bool = false
        var q3shdr: shdBlock


        if fileExists(q3shaderfile):
            for line in lines open(q3shaderfile):

                if line.startsWith("//"): continue
                if line.startsWith("textures"):
                    q3shdr.bsptexture = line.strip()
                    continue
                if line.startsWith("{") and not InBLOCK: # we are in block
                    InBLOCK = true
                    continue
                else:
                    if not line.contains("{") and InBLOCK and not InSMBLOCK:
                        if not line.contains("}"):
                            q3shdr.blockstrings.add(line.strip())
                    if line.contains("{") and InBLOCK:
                        InSMBLOCK = true
                        continue
                    if InSMBLOCK and not line.contains("}"):
                        if line.strip().startsWith("map ") and line.strip().endsWith(".tga"):
                            q3shdr.internalstrings.add(line.strip())
                    if line.contains("}") and InSMBLOCK:
                        InSMBLOCK = false
                        continue
                    if line.startsWith("}"):
                        InBLOCK = false
                        q3shaderblocks.add(q3shdr)
                        q3shdr.bsptexture = ""
                        q3shdr.blockstrings = @[]
                        q3shdr.internalstrings = @[]
                        continue

        else:
            echo q3shaderfile & " not found"

    return q3shaderblocks
