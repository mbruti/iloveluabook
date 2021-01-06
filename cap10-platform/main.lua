local screenX,screenY=480,640
local scene={
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,9,0,9,8,0,0,0},
  {0,0,0,0,0,0,0,0,1,2,2,3,0,0,0},
  {0,0,9,8,9,0,0,0,0,0,0,0,0,0,0},
  {0,0,1,2,3,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,9,0,9,8,9,0},
  {0,0,0,0,0,0,0,0,0,1,2,2,2,3,0},
  {0,0,0,9,8,9,0,0,0,0,0,0,0,0,0},
  {0,0,0,1,2,3,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,9,0,9,8,9,0,0},  
  {0,0,0,0,0,0,0,0,1,2,2,2,3,0,0},
  {9,0,9,8,9,0,0,0,0,0,0,0,0,0,0},
  {1,2,2,2,3,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,9,8,9,0,0,0},
  {0,0,0,0,0,0,0,0,0,1,2,3,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,9,0,9,8,9,0,9,0,9,8,9,0,9,0},
  {1,2,2,2,2,2,2,2,2,2,2,2,2,2,3}
}  
--local hero=nil
local sceneObj,bombsObj,roboObj={},{},{}
local gameStage
local gameStages={["INTRO"]=1,["STARTPLAY"]=2,["PLAY"]=3,["HIT"]=4,["GAMEOVER"]=5}
local heroStatuses={["STOPPED"]=1,["MOVELEFT"]=2,["MOVERIGHT"]=3,["PREPAREFLYUP"]=4,["FLYUP"]=5,["PREPAREFLYDOWN"]=6,["FLYDOWN"]=7,["DIVE"]=8,["DEAD"]=9}
local frameSequence,roboLeftSequence,roboRightSequence={},{},{} 
local heroSheet,platSheet,bombSheet,roboSheet={},{},{},{}
local edgeTop,edgeBottom,edgeLeft,edgeRight
local level,score,lives,hi=0,0,0,0
local font
local sounds,imgs={},{}
local backgroundCanvas
local world, gl,physObj 
local heroFrames,heroFrame,platFrames,bombFrames,roboFrames
local timer=0
local heroFrameStart,heroFrameStop
local animBomb
local startTime,hitTime,finalTime,bestTime=0,0,0,99999.99

function createScene()
  edgeTop=physObj.edgeObj:new(world,-4,-4,screenX+4,-4)
  edgeBottom=physObj.edgeObj:new(world,-4,screenY+4,screenX+4,screenY+4)
  edgeLeft=physObj.edgeObj:new(world,-4,-4,-4,screenY)
  edgeRight=physObj.edgeObj:new(world,screenX+4,-4,screenX+4,screenY+4)
  for i=1,#scene do
    sceneObj[i]={}
    for j=1,#scene[i] do
      if (scene[i][j]~=0) then
        if (scene[i][j]==8) then
          roboObj[#roboObj+1]=physObj.gameObj:new(world,"kinematic",(j-1)*32+16,(i-1)*32+16,32,32)
          roboObj[#roboObj].dir=gl.getRandomDir()
          roboObj[#roboObj].fixture:setUserData("robot")
        elseif (scene[i][j]~=9) then
          sceneObj[i][j]=physObj.gameObj:new(world,"static",(j-1)*32+16,(i-1)*32+16,32,32)
          sceneObj[i][j].fixture:setUserData("platform")
        end
      else  
        sceneObj[i][j]=nil
      end
    end
  end
end

function createBombs()
  for i=1,#scene do
    for j=1,#scene[i] do
      if (scene[i][j]==9) then
        bombsObj[#bombsObj+1]=physObj.gameObj:new(world,"kinematic",(j-1)*32+16,(i-1)*32+16,32,32,true)
        bombsObj[#bombsObj].fixture:setUserData("bomb")
      end
    end
  end
  animBomb=math.random(1,#bombsObj)
  bombsObj[animBomb].isAnimated=true
  bombsObj[animBomb].frameDuration=0.2
  bombsObj[animBomb].frameTime=love.timer.getTime()
end

function createHero()
  hero=physObj.gameObj:new(world,"dynamic",16,16,32,32)
  hero.fixture:setUserData("hero")
  hero.body:setPosition(16,16)
  hero.status=heroStatuses["STOPPED"]
  hero.frameTime=love.timer.getTime()
end 

function drawBombs()
  for i=1,#bombsObj do
    if (animBomb==i) then
      if ((love.timer.getTime()-bombsObj[i].frameTime)>bombsObj[i].frameDuration) then
        bombsObj[i].frame=bombsObj[i].frame+1
        bombsObj[i].frameTime=love.timer.getTime()
        if (bombsObj[i].frame>bombFrames) then bombsObj[i].frame=1 end
      end
    end
    love.graphics.draw(imgs.bombSheetImg,bombSheet[bombsObj[i].frame],bombsObj[i].body:getX()-16,bombsObj[i].body:getY()-16)
  end
end

function destroyBombs()
  for i=1,#bombsObj do
    bombsObj[i].body:destroy()
  end
end  

function drawRobo()
  for i=1,#roboObj do
    if ((love.timer.getTime()-roboObj[i].frameTime)>roboObj[i].frameDuration) then
        if (roboObj[i].dir<0) then
          if (roboObj[i].frame==#roboLeftSequence) then
            roboObj[i].frame=1
          else
            roboObj[i].frame=roboObj[i].frame+1
          end
        else
          if (roboObj[i].frame==#roboRightSequence) then
            roboObj[i].frame=1
          else
            roboObj[i].frame=roboObj[i].frame+1
          end
        end
        roboObj[i].frameTime=love.timer.getTime()
    end
    if (roboObj[i].dir<0) then
      love.graphics.draw(imgs.roboSheetImg,roboSheet[roboLeftSequence[roboObj[i].frame]],roboObj[i].body:getX()-16,roboObj[i].body:getY()-16)
    else
      love.graphics.draw(imgs.roboSheetImg,roboSheet[roboRightSequence[roboObj[i].frame]],roboObj[i].body:getX()-16,roboObj[i].body:getY()-16)
    end
  end
end

function drawScene()
  for i=1,#scene do
    for j=1,#scene[i] do
      if (sceneObj[i][j]~=nil) then
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(imgs.platSheetImg,platSheet[scene[i][j]],sceneObj[i][j].body:getX()-16,sceneObj[i][j].body:getY()-16)
      end
    end
  end
end

function resetGraphics()
  createScene()
  replay()
end

function replay()
  createBombs()
  gameStage=gameStages["STARTPLAY"]
end

function love.load()
  gl=require("gamelibrary")
  physObj=require("physObj")
  math.randomseed(os.time())
  love.physics.setMeter(16)
  world = love.physics.newWorld(0, 9.81*16, true)
  world:setCallbacks(beginContact)
  love.keyboard.setKeyRepeat(false)
  love.window.setMode(screenX,screenY)
  font=love.graphics.newFont("assets/kongtext.ttf")
  imgs.heroSheetImg=love.graphics.newImage("assets/hero_spritesheet.png")
  imgs.platSheetImg=love.graphics.newImage("assets/platforms.png")
  imgs.bombSheetImg=love.graphics.newImage("assets/bomb.png")
  imgs.roboSheetImg=love.graphics.newImage("assets/robot.png")
  heroFrames=imgs.heroSheetImg:getWidth()/32
  bombFrames=imgs.bombSheetImg:getWidth()/32
  roboFrames=imgs.bombSheetImg:getWidth()/32
  platFrames=imgs.platSheetImg:getWidth()/32
  frameSequence[heroStatuses["STOPPED"]]={1}
  frameSequence[heroStatuses["MOVERIGHT"]]={2,3,4,5}
  frameSequence[heroStatuses["MOVELEFT"]]={6,7,8,9}
  frameSequence[heroStatuses["PREPAREFLYUP"]]={10}
  frameSequence[heroStatuses["FLYUP"]]={11}
  frameSequence[heroStatuses["PREPAREFLYDOWN"]]={12}
  frameSequence[heroStatuses["FLYDOWN"]]={13}
  frameSequence[heroStatuses["DEAD"]]={14,15}
  frameSequence[heroStatuses["DIVE"]]={16}
  roboRightSequence={1,2,3}
  roboLeftSequence={4,5,6}
  for i=1,heroFrames do
    heroSheet[i]=love.graphics.newQuad((i-1)*32,0,32,32,imgs.heroSheetImg:getDimensions())
  end
  for i=1,platFrames do
    platSheet[i]=love.graphics.newQuad((i-1)*32,0,32,32,imgs.platSheetImg:getDimensions())
  end
  for i=1,bombFrames do
    bombSheet[i]=love.graphics.newQuad((i-1)*32,0,32,32,imgs.bombSheetImg:getDimensions())
  end
  for i=1,roboFrames do
    roboSheet[i]=love.graphics.newQuad((i-1)*32,0,32,32,imgs.roboSheetImg:getDimensions())
  end
  love.graphics.setFont(font)
  resetGraphics()
  gameStage=gameStages["INTRO"]
end

function moveRobo(dt)
  for i=1,#roboObj do
    local x,y=roboObj[i].body:getPosition()
    local gridX,gridY=math.floor(x/32)+1,math.floor(y/32)+2
    if (roboObj[i].dir>0) then
      if (scene[gridY][gridX]==0) then
        roboObj[i].dir=-1
        roboObj[i].body:setPosition(x-1,y)
      end 
    else
      if (scene[gridY][gridX]==0) then
        roboObj[i].dir=1
        roboObj[i].body:setPosition(x+1,y)
      end
    end
    if (x<=0) then
      roboObj[i].dir=1
    elseif (x>=screenX) then
      roboObj[i].dir=-1
    end
    if (gameStage==gameStages["PLAY"]) or (gameStage==gameStages["GAMEOVER"])  or (gameStage==gameStages["INTRO"]) then
      roboObj[i].body:setLinearVelocity(roboObj[i].dir*20,0)
    else
      roboObj[i].body:setLinearVelocity(0,0)
    end  
  end
end

function animateHero()
  if ((love.timer.getTime()-hero.frameTime)>0.2) then
    hero.frameTime=love.timer.getTime()
    if (hero.frame==heroFrameStop) then
      hero.frame=heroFrameStart
    else
      hero.frame=hero.frame+1
    end
  end
end

function setHeroStatus(status)
  hero.status=heroStatuses[status]
  heroFrameStart=frameSequence[hero.status][1]
  heroFrameStop=frameSequence[hero.status][#frameSequence[hero.status]]
  hero.frame=heroFrameStart
end  

function beginContact(a, b, coll)
  if (gameStage~=gameStages["PLAY"]) then return end
  if (a:getUserData()=="hero") or (b:getUserData()=="hero") then
    local h,other
    if (a:getUserData()=="hero") then
      h,other=a,b
    else
      other,h=a,b
    end
    if (animBomb~=0) then
      if (other==bombsObj[animBomb].fixture) then
        bombsObj[animBomb].body:destroy()
        table.remove(bombsObj,animBomb)
        if (#bombsObj>0) then
          animBomb=math.random(1,#bombsObj)
          bombsObj[animBomb].isAnimated=true
          bombsObj[animBomb].frameDuration=0.2
          bombsObj[animBomb].frameTime=love.timer.getTime()
        else
          animBomb=0
          hero.body:destroy()
          hero=nil
          finalTime=love.timer.getTime()-startTime
          gameStage=gameStages["GAMEOVER"]
          if (bestTime>finalTime) then bestTime=finalTime end
        end
        return
      end
    end
    if (other:getUserData()=="robot") then
      gameStage=gameStages["HIT"]
      setHeroStatus("DEAD")
      hitTime=love.timer.getTime()
    end
  end
end
  
function love.keypressed(key)
  if (key=="space") and (gameStage==gameStages["PLAY"]) then
    hero.body:setLinearVelocity(0,-150)
    setHeroStatus("FLYUP")
  end
end

function love.update(delta)
  world:update(delta)
  if (gameStage==gameStages["INTRO"]) then
    if (love.keyboard.isDown("space")) then gameStage=gameStages["STARTPLAY"] end
  elseif (gameStage==gameStages["STARTPLAY"]) then
    startTime=love.timer.getTime()
    createHero()
    gameStage=gameStages["PLAY"]
  elseif (gameStage==gameStages["GAMEOVER"]) then
    if love.keyboard.isDown("space") then
      replay()
    elseif love.keyboard.isDown("escape") then
      os.exit()
    end
  elseif (gameStage==gameStages["PLAY"]) then
    local vx,vy=hero.body:getLinearVelocity()
    if love.keyboard.isDown("left") then
      hero.body:applyForce(-800,0)
      if (math.abs(vy)<1) and (hero.status~=heroStatuses["MOVELEFT"]) then
        setHeroStatus("MOVELEFT")
      end
    elseif love.keyboard.isDown("right") then
      hero.body:applyForce(800,0)
      if (math.abs(vy)<1) and (hero.status~=heroStatuses["MOVERIGHT"]) then
        setHeroStatus("MOVERIGHT")
      end
    elseif (hero.status==heroStatuses["DIVE"]) then
      setHeroStatus("PREPAREFLYDOWN")
    end
    if love.keyboard.isDown("down") then
      hero.body:applyForce(0,800)
      setHeroStatus("DIVE")
    elseif (math.abs(vy)<5) and (math.abs(vx)<=10) then
      setHeroStatus("STOPPED")
    elseif (hero.status==heroStatuses["STOPPED"]) then
      if (vy<0) then 
        setHeroStatus("PREPAREFLYUP")
      elseif (vy>0) then
        setHeroStatus("PREPAREFLYDOWN")
      end
    elseif (hero.status==heroStatuses["FLYUP"]) then
      if (vy>-100) then
        setHeroStatus("PREPAREFLYUP")
      end  
    elseif (hero.status==heroStatuses["PREPAREFLYUP"]) then
      if (vy<=-100) then
        setHeroStatus("FLYUP")
      elseif (vy>=0) then
        setHeroStatus("PREPAREFLYDOWN")
      end
    elseif (hero.status==heroStatuses["PREPAREFLYDOWN"]) then
      if (vy>150) then
        setHeroStatus("FLYDOWN")
      end
    elseif (hero.status==heroStatuses["MOVELEFT"]) or (hero.status==heroStatuses["MOVERIGHT"])  then
      if (math.abs(vy)>5) then
        setHeroStatus("STOPPED")
      end
    end
  elseif (gameStage==gameStages["HIT"]) then
    if ((love.timer.getTime()-hitTime)>3) then
      gameStage=gameStages["PLAY"]
      setHeroStatus("STOPPED")
      hero.body:setPosition(0,0)
    end
  end
  moveRobo()
  if (gameStage==gameStages["HIT"]) or (gameStage==gameStages["PLAY"]) then
    animateHero()
  end
end

function love.draw()
  love.graphics.setBackgroundColor(0,1,1,1)
  love.graphics.setColor(1,1,1,1)
  drawScene()
  drawBombs()
  drawRobo()
  if (gameStage==gameStages["INTRO"]) then 
    love.graphics.setColor(1,0,0,1)
    love.graphics.printf("SUPER JACK", 0, 0,screenX/4,"center",0,4,4)
    love.graphics.setColor(0,0,1,1)
    love.graphics.printf("Press SPACE BAR", 0, screenY/2+132,screenX/2,"center",0,2,2)
  elseif (gameStage==gameStages["GAMEOVER"]) then
    love.graphics.setColor(1,0,0,1)
    love.graphics.printf(string.format("TIME: %08.2f",finalTime),0,0,screenX/2,"center",0,2,2)
    love.graphics.setColor(0,0,1,1)
    love.graphics.printf("<BAR> to REPLAY", 0, screenY/2,screenX/2,"center",0,2,2)
    love.graphics.printf("<ESC> to QUIT", 0, screenY/2+64,screenX/2,"center",0,2,2)
  end
  if (gameStage==gameStages["PLAY"]) or (gameStage==gameStages["HIT"]) then
    love.graphics.setColor(1,0,0,1)
    love.graphics.printf(string.format("TIME: %08.2f",love.timer.getTime()-startTime),0,0,screenX/2,"center",0,2,2)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(imgs.heroSheetImg,heroSheet[hero.frame],hero.body:getX()-16,hero.body:getY()-16)
  end
  love.graphics.setColor(1,0,0,1)
  love.graphics.printf("(c)2020 M.Bruti/Texasoft Reloaded", 0, screenY-14,screenX,"center")
  love.graphics.setColor(0,0.5,0,1)
  love.graphics.printf(string.format("BEST TIME: %08.2f",bestTime),0,screenY-30,screenX,"center")
end  