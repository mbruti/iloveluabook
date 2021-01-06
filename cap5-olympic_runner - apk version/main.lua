-- Olympic Runner - apk version (c)2020 Marco Bruti
local runnerImg,speedbarImg
local elapsed, frameElapsed, pressTime,speedStepTime
local runnerSheet={}
local currentFrame
local myCanvas
local gameStages={["START"]="1",["RUN"]="2",["STOP"]="3"}
local gameStage
local counter, speed, runnerX, runnerY, distance
local screenX,screenY=800,480
local record=1000

function initGame()
  elapsed=0
  speed=0
  counter=5
  currentFrame=1
  runnerY=176
  runnerX=0
  distance=100
  gameStage=gameStages["START"]
end

function love.keypressed(key,scancode,isrepeat)
  if (gameStage==gameStages["RUN"]) then
    if (key=="space") then 
      local diff=math.abs(love.timer.getTime()-speedStepTime)
      if (diff>0.20) and (diff<0.30) then 
        if (speed<10) then speed=speed+1 end
      elseif (speed>0) then 
        speed=speed-1
      end
      speedStepTime=love.timer.getTime()
    end
  elseif (gameStage==gameStages["STOP"]) then
    if (key=="escape") then
      os.exit()
    elseif (key=="return") then
      initGame()
    end
  end
end

function love.mousepressed(x,y,button, istouch,presses)
  if (gameStage==gameStages["RUN"]) then
    local diff=math.abs(love.timer.getTime()-speedStepTime)
    if (diff>0.20) and (diff<0.30) then 
      if (speed<10) then speed=speed+1 end
    elseif (speed>0) then 
      speed=speed-1
    end
    speedStepTime=love.timer.getTime()
  elseif (gameStage==gameStages["STOP"]) then
    if (y>=(screenY-192)) and (y<=(screenY-160)) then
      if (x>=screenX/4) and (x<=(screenX/4+128)) then
        initGame()
      elseif (x>=screenX*0.5) and (x<=(screenX*0.5+128)) then
        os.exit()
      end
    end
  end
end

function showScoreboard(cnt,time,stage)
  love.graphics.setColor(0, 0, 0, 1)
  if (stage==gameStages["START"]) then
    love.graphics.printf(string.format("READY TO START! %1d SECONDS.",cnt),0,myCanvas:getHeight()*0.70,myCanvas:getWidth()/2,"center",0,2,2)
  end
  if (stage==gameStages["RUN"]) then  
    love.graphics.printf("GO!",0,myCanvas:getHeight()*0.80,myCanvas:getWidth()/2,"center",0,2,2)
  end  
  if (stage==gameStages["RUN"]) or (stage==gameStages["STOP"]) then
    love.graphics.printf(string.format("TIME: %06.2f s",time),0,myCanvas:getHeight()*0.70,myCanvas:getWidth()/2,"center",0,2,2)
    love.graphics.print(string.format("Distance: %3dm ",distance),0,myCanvas:getHeight()/2+32)
  end  
  if (stage==gameStages["STOP"]) then
    love.graphics.printf("GAME OVER (ENTER TO RESTART/ESC TO EXIT)",0,myCanvas:getHeight()/2,myCanvas:getWidth()/2,"center",0,2,2)
    love.graphics.printf(string.format("BEST TIME: %06.2f s",record),0,myCanvas:getHeight()*0.8,myCanvas:getWidth()/2,"center",0,2,2)
  end
end

function showSpeedBar()
  love.graphics.setColor(1,1,1,1)
  love.graphics.rectangle("line",screenX/2-4-5*32,runnerY+112,324,40)
  for i=0,math.floor(speed)-1 do
    love.graphics.draw(speedbarImg,screenX/2+(i-5)*32,runnerY+116)
  end
end
  
function love.load()
  love.window.setMode(screenX,screenY)
  runnerImg=love.graphics.newImage("runner.png")
  speedbarImg=love.graphics.newImage("speedbar.png")
  myCanvas=love.graphics.newCanvas(screenX,screenY)
  love.graphics.setCanvas(myCanvas)
  love.graphics.setColor(195/255,195/255,195/255,1)
  love.graphics.rectangle("fill",0,0,myCanvas:getWidth(),myCanvas:getHeight()/4-1)
  love.graphics.setColor(0.5,0.5,0,1)
  love.graphics.rectangle("fill",0,myCanvas:getHeight()/4,myCanvas:getWidth(),myCanvas:getHeight()*0.75)
  love.graphics.setColor(0,0.5,0,1)
  love.graphics.rectangle("fill",0,myCanvas:getHeight()/2-32,myCanvas:getWidth(),64)
  love.graphics.setColor(1,0.5,0,1)
  love.graphics.setLineWidth(4)
  love.graphics.line(0,myCanvas:getHeight()/2,myCanvas:getWidth(),myCanvas:getHeight()/2)
  for x=8,screenX-8,16 do
    for y=8,myCanvas:getHeight()/4-8,16 do
      love.graphics.setColor(love.math.random(255)/255,love.math.random(255)/255,love.math.random(255)/255,1)
      love.graphics.circle("fill",x,y,8)
    end
  end
  love.graphics.setCanvas()
  for i=1,runnerImg:getWidth()/32 do
    runnerSheet[i]=love.graphics.newQuad((i-1)*32,0,32,32,runnerImg:getDimensions())
  end
  initGame()
end

function love.update(dt)
  if gameStage==gameStages["START"] then
    elapsed=elapsed+dt
    if (elapsed>=1) then 
      counter=counter-1
      elapsed=0   
    end
    if (counter==0) then
      gameStage=gameStages["RUN"]
      elapsed=0
      speedStepTime=love.timer.getTime()
    end
  elseif gameStage==gameStages["RUN"] then
    if ((love.timer.getTime()-speedStepTime)>0.5) and (speed>0) then 
      speed=speed-1
      speedStepTime=love.timer.getTime()
    end
    runnerX=runnerX+speed*dt*10
    elapsed=elapsed+dt
    if (runnerX>=screenX) then
      if (distance<400) then
         runnerX=(runnerX-screenX)
         distance=distance+100
      else 
        if (record>elapsed) then record=elapsed end
        gameStage=gameStages["STOP"]
      end  
    end
    if (speed==0) then
      frameElapsed=0
    else
      frameElapsed=frameElapsed+dt
      if (frameElapsed>0.5/speed) then
        frameElapsed=0
        currentFrame=((currentFrame+1) % 6)
      end
    end
  end
end 

function love.draw()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(myCanvas,0,0)
  if (gameStage==gameStages["START"]) then
    showScoreboard(counter,0,gameStage)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(runnerImg,runnerSheet[currentFrame],runnerX,runnerY,0,2,2)
  elseif (gameStage==gameStages["RUN"]) then
    showScoreboard(0,elapsed,gameStage)
    love.graphics.setColor(1, 1, 1, 1)
    showSpeedBar(speed)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(runnerImg,runnerSheet[currentFrame+1],runnerX,runnerY,0,2,2)
  elseif (gameStage==gameStages["STOP"]) then
     showScoreboard(0,elapsed,gameStage)
     love.graphics.setColor(0,1,0,1)
     love.graphics.rectangle("fill",screenX/4,screenY-192,128,32)
     love.graphics.rectangle("fill",screenX*0.5,screenY-192,128,32)
     love.graphics.setColor(0,0,0,1)
     love.graphics.printf("RESTART",screenX/4,screenY-192,64,"center",0,2,2)
     love.graphics.printf("QUIT",screenX*0.5,screenY-192,64,"center",0,2,2)
  end   
end
