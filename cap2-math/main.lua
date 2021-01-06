-- Love Time&Strings (c)2020 Marco Bruti
time=0.0
nCycles=0
function love.load()
end
function love.update(dt)
  time=time+dt
  nCycles=nCycles+1
end
function love.draw()
  local s=string.format("#Cycles:%06d --- Time:%05.2f --- Cycles/sec:%02d",nCycles,time,math.floor(nCycles/time))
  love.graphics.print(s)
end
