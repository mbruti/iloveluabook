local screenX,screenY=1024,480
local gameStage
local gameStages={["POINTING"]=1,["FIRING"]=2,["HIT"]=3,["GAMEOVER"]=4}
local camionImg,camionBody,camionShape,camionFixture
local rimorchioImg,rimorchioBody,rimorchioShape,rimorchioFixture
local cloudImg,cloudBody,cloudShape,cloudFixture
local ballBody,ballShape,ballFixture
local missileImg,missileBody,missileShape,missileFixture
local startCamionX,startCamionY,startRimorchioX,startRimorchioY,startMissileX,startMissileY
local cannonImg
local level,score,hi=1,0,0
local font
local munizioni
local wind,angle=0,0

function sign(n)
  if (n<0) then
    return -1
  elseif (n>0) then
    return 1
  end
  return 0
end

function randomSign()
  if (math.random(2)==1) then
    return 1
  else
    return -1
  end
end

function replay()
  munizioni=5
  wind=randomSign()*math.random(10)
  cloudBody:setLinearVelocity(wind,0)
  camionBody:setPosition(startCamionX,startCamionY)
  camionBody:setLinearVelocity(-10-level*4,0)
  rimorchioBody:setPosition(startRimorchioX,startRimorchioY)
  rimorchioBody:setLinearVelocity(-10-level*4,0)
  missileBody:setPosition(startMissileX,startMissileY)
  missileBody:setLinearVelocity(-10-level*4,0)
  gameStage=gameStages["POINTING"]  
end

function resetGame()
  level=1
  score=0
  replay()
end

function destroyBall()
  ballBody:destroy()
  ballShape,ballFixture,ballBody=nil,nil,nil
end

function love.load()
  math.randomseed(os.time())
  love.physics.setMeter(16)
  world = love.physics.newWorld(0, 9.81*16, true)
  world:setCallbacks(beginContact)
  love.keyboard.setKeyRepeat(true)
  love.window.setMode(screenX,screenY)
  font=love.graphics.newFont("assets/kongtext.ttf")
  love.graphics.setFont(font)
  camionImg=love.graphics.newImage("assets/camion.png")
  rimorchioImg=love.graphics.newImage("assets/rimorchio.png")
  cloudImg=love.graphics.newImage("assets/cloud.png")
  cannonImg=love.graphics.newImage("assets/cannon.png")
  missileImg=love.graphics.newImage("assets/missile.png")
  startCamionX=screenX-camionImg:getWidth()/2
  startCamionY=screenY-camionImg:getHeight()/2
  camionBody=love.physics.newBody(world,startCamionX,startCamionY,"kinematic")
  camionShape=love.physics.newRectangleShape(camionImg:getWidth(),camionImg:getHeight())
  camionFixture=love.physics.newFixture(camionBody,camionShape,1)
  camionFixture:setUserData("camion")
  startRimorchioX=screenX+rimorchioImg:getWidth()/2
  startRimorchioY=screenY-rimorchioImg:getHeight()/2
  rimorchioBody=love.physics.newBody(world,startRimorchioX,startRimorchioY,"kinematic")
  rimorchioShape=love.physics.newRectangleShape(rimorchioImg:getWidth(),rimorchioImg:getHeight())
  rimorchioFixture=love.physics.newFixture(rimorchioBody,rimorchioShape,1)
  rimorchioFixture:setUserData("rimorchio")
  startMissileX=screenX+rimorchioImg:getWidth()/4+missileImg:getWidth()/2
  startMissileY=screenY-rimorchioImg:getHeight()-missileImg:getHeight()/2
  missileBody=love.physics.newBody(world,startMissileX,startMissileY,"kinematic")
  missileShape=love.physics.newRectangleShape(missileImg:getWidth(),missileImg:getHeight())
  missileFixture=love.physics.newFixture(missileBody,missileShape,1)
  missileFixture:setUserData("missile")
  cloudBody=love.physics.newBody(world,screenX/2,cloudImg:getHeight()/2,"kinematic")
  cloudShape=love.physics.newRectangleShape(cloudImg:getWidth(),cloudImg:getHeight())
  cloudFixture=love.physics.newFixture(cloudBody,cloudShape,1)
  cloudFixture:setSensor(true)
  resetGame()
end

function beginContact(a, b, coll)
  if (gameStage~=gameStages["FIRING"]) then return end
  if (a:getUserData()=="ball") or (b:getUserData()=="ball") then
    local h,other
    if (a:getUserData()=="ball") then
      h,other=a,b
    else
      other,h=a,b
    end
    if ((other:getUserData()=="camion") or (other:getUserData()=="rimorchio")) then
      destroyBall()
      if (munizioni==0) then 
        gameStage=gameStages["GAMEOVER"]
      else
        gameStage=gameStages["POINTING"]
      end
    elseif (other:getUserData()=="missile") then
      gameStage=gameStages["HIT"]
    end
  end
end
  
function love.keypressed(key)
  if (gameStage==gameStages["POINTING"]) then
    if (key=="left") then
      angle=angle-1
      if (angle<0) then angle=0 end
    elseif (key=="right") then
      angle=angle+1
      if (angle>90) then angle=90 end
    elseif (key=="space") then
      munizioni=munizioni-1
      gameStage=gameStages["FIRING"]
      ballBody=love.physics.newBody(world,32,screenY-32,"dynamic")
      ballShape=love.physics.newCircleShape(8)
      ballFixture=love.physics.newFixture(ballBody,ballShape,1)
      ballFixture:setUserData("ball")
      ballBody:applyLinearImpulse(330*math.cos(math.pi/2-angle/180*math.pi),-330*math.sin(math.pi/2-angle/180*math.pi))
    end
  elseif (gameStage==gameStages["GAMEOVER"]) then 
    if (key=="space") then 
      if (hi<score) then hi=score end
      resetGame() 
    end
  end
end

function love.update(delta)
  world:update(delta)
  if (gameStage==gameStages["GAMEOVER"]) then return end
  if (gameStage==gameStages["FIRING"]) then
    ballBody:applyForce(sign(wind)*wind^2/10,0)
    local bx,by=ballBody:getPosition()
    if (by>screenY) or (bx>screenX) then
      destroyBall()
      if (munizioni==0) then 
        gameStage=gameStages["GAMEOVER"]
        return
      else
        gameStage=gameStages["POINTING"]
      end
    end
  elseif (gameStage==gameStages["HIT"]) then
    score=score+(munizioni+1)*100
    level=level+1
    replay()
  end
  local cloudX,cloudY=cloudBody:getPosition()
  if (cloudX>screenX+cloudImg:getWidth()/2) then
    cloudX=-cloudImg:getWidth()/2
  elseif (cloudX<-cloudImg:getWidth()/2) then
    cloudX=screenX+cloudImg:getWidth()/2
  end
  cloudBody:setPosition(cloudX,cloudY)
  local camionX,_=camionBody:getPosition()
  if (camionX<32) then gameStage=gameStages["GAMEOVER"] end
end

function love.draw()
  love.graphics.setBackgroundColor(0,1,1,1)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(camionImg,camionBody:getX()-camionImg:getWidth()/2,camionBody:getY()-camionImg:getHeight()/2)
  love.graphics.draw(rimorchioImg,rimorchioBody:getX()-rimorchioImg:getWidth()/2,rimorchioBody:getY()-rimorchioImg:getHeight()/2)
  love.graphics.draw(missileImg,missileBody:getX()-missileImg:getWidth()/2,missileBody:getY()-missileImg:getHeight()/2)
  love.graphics.draw(cloudImg,cloudBody:getX()-cloudImg:getWidth()/2,cloudBody:getY()-cloudImg:getHeight()/2)
  love.graphics.setColor(0,0,0,1)
  love.graphics.circle("fill",0,screenY,64)
  love.graphics.setColor(0,0,1,1)
  for i=1,munizioni do
    love.graphics.circle("fill",(i-1)*16+8,8,8)
  end
  if (gameStage==gameStages["FIRING"]) then
    love.graphics.circle("line",ballBody:getX(),ballBody:getY(),8)
  elseif (gameStage==gameStages["GAMEOVER"]) then
    love.graphics.printf("GAME OVER - PRESS SPACE TO REPLAY",0,screenY/2,screenX/2,"center",0,2,2)    
  end
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(cannonImg,32,screenY-32,angle/360*math.pi*2,2,2,16,32)
  love.graphics.setColor(1,0,0,1)
  love.graphics.printf(string.format("HI:%06d  LEVEL:%02d  SCORE:%06d",hi,level, score),0,0,screenX/2,"center",0,2,2)
end  