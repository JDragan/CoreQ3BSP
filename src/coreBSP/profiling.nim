import times, os, strutils


var deltaTime: float
var lastFrame: float
var currentFrame: float

proc getFrameTime(): float =
  currentFrame = cpuTime()
  deltaTime = currentFrame - lastFrame
  lastFrame = currentFrame
  deltaTime

proc getFps*() =
  var fps = getFrameTime()
  echo fps

template benchmark*(benchmarkName: string, code: untyped) =
  block:
    let t0 = epochTime()
    code
    let elapsed = epochTime() - t0
    let elapsedStr = elapsed.formatFloat(format = ffDecimal, precision = 3)
    echo "CPU Time [", benchmarkName, "] ", elapsedStr, "s"
