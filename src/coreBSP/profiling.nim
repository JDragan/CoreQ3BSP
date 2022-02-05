import times, strutils
export strutils


type 
    FpsTimer* = object
        deltaTime: float
        lastFrame: float
        currentFrame: float

        count: int32
        fps_accum: float


proc getFrameTime(t: var FpsTimer): float =
    
    t.currentFrame = epochTime()
    t.deltaTime = t.currentFrame - t.lastFrame
    t.lastFrame = t.currentFrame
    t.deltaTime

proc reset(t: var FpsTimer) =
    t.count = 0
    t.fps_accum = 0

proc getFps*(t: var FpsTimer, interval: int32 = 100) =

    let fps = getFrameTime(t)
    inc t.count
    t.fps_accum += fps

    if t.count == interval:

        let formated = 1000 / (t.fps_accum / interval.float * 1000)
        echo formated.formatFloat(ffDecimal, 1)

        t.reset()



template benchmark*(benchmarkName: string, code: untyped) =
    block:
        let t0 = epochTime()
        code
        let elapsed = epochTime() - t0
        let elapsedStr = elapsed.formatFloat(format = ffDecimal, precision = 3)
        echo "CPU Time [", benchmarkName, "] ", elapsedStr, "s"
