local screenX,screenY
local ship, shipBullet,enemies,enemyBullets={},{},{},{}
local gameStage
local gameStages={["INTRO"]="0",["STARTPLAY"]="1",["LEVELCHANGE"]="2",["PLAY"]="3",["HIT"]="4",["GAMEOVER"]="5"}
local enemyStatus={["LARGE"]="1",["SPLIT"]="2",["DESTROYED"]="3"}
local level,score,lives,hi=0,0,0,0
local font, fuelText, fuelTextWidth,fuelTextHeight, fuel,fuelScaleX
local startTime
local demonImg,demonSplitImg={},{}
local shipImg,shipBulletImg,enemyBulletImg,score50Img,score100Img,explosionImg
local sounds={}
local backgroundCanvas
local bonusShipFlag

function playSound(sound)
   if (love.audio.getActiveSourceCount()>0) then
     love.audio.stop()
   end
   love.audio.play(sound)
end

function getRandomDir()
  if (math.random()<0.5) then
    return -1
  else
    return 1
  end
end
function createEnemyWave(lv)
  if (#enemies>0) then 
    for i=1,#enemies do
      if (enemies[i].status==enemyStatus["SPLIT"]) then
        enemies[i].y=32
      end
    end
    return
  end
  for i=1,lv+1 do
    local enemy={x=math.random(screenX-demonImg[1]:getWidth()),y=math.random(screenY/2),img=demonImg[1],w=demonImg[1]:getWidth(),h=demonImg[1]:getHeight(),status=enemyStatus["LARGE"],dir=getRandomDir(),alpha=1.0,frame=1,flapTime=0}
    if (i<=4) then
      enemy.splittable=false
    else
      enemy.splittable=true
    end   
    table.insert(enemies,enemy)
  end
end
function resetGraphics()
  ship={x=screenX/2,y=screenY-shipImg:getHeight()-fuelTextHeight-2,img=shipImg, w=shipImg:getWidth(),h=shipImg:getHeight(),alpha=1.0}
  shipBullet={x=ship.x+shipImg:getWidth()/2-shipBulletImg:getWidth()/2,y=screenY-shipImg:getHeight()-fuelTextHeight-2,img=shipBulletImg,w=shipBulletImg:getWidth(),h=shipBulletImg:getHeight(), launched=false}
  enemyBullets={}
  createEnemyWave(level)
  fuel=50
  fuelScaleX=(screenX-fuelTextWidth-8)/fuel
end

function resetGame()
  level=1
  score=0
  lives=3
  bonusShipFlag=false
  startTime=-1
  resetGraphics()
  gameStage=gameStages["STARTPLAY"]
end

function love.load()
  math.randomseed(os.time())
  screenX, screenY=love.graphics.getDimensions()
  font=love.graphics.newFont("assets/kongtext.ttf")
  love.graphics.setFont(font)
  sounds.explosion=love.audio.newSource("assets/explosion.wav","static")
  sounds.fire=love.audio.newSource("assets/fire.wav","static")
  sounds.enemyexplosion=love.audio.newSource("assets/enemyexplosion.wav","static")
  sounds.fuel=love.audio.newSource("assets/fuel.wav","static")
  demonImg[1]=love.graphics.newImage("assets/demon1.png")
  demonImg[2]=love.graphics.newImage("assets/demon2.png")
  demonSplitImg[1]=love.graphics.newImage("assets/demonsplit1.png")
  demonSplitImg[2]=love.graphics.newImage("assets/demonsplit2.png")
  shipImg=love.graphics.newImage("assets/ship.png")
  shipBulletImg=love.graphics.newImage("assets/bullet.png")
  enemyBulletImg=love.graphics.newImage("assets/enemybullet.png")
  score50Img=love.graphics.newImage("assets/50.png")
  score100Img=love.graphics.newImage("assets/100.png")
  explosionImg=love.graphics.newImage("assets/explosion.png")
  fuelText=love.graphics.newText(font,{ {1,0,0}, "FUEL"})
  fuelTextWidth=fuelText:getWidth()
  fuelTextHeight=fuelText:getHeight()
  backgroundCanvas=love.graphics.newCanvas(screenX,screenY)
  love.graphics.setCanvas(backgroundCanvas)
  love.graphics.clear()
  love.graphics.setBackgroundColor(0,0,0,1)
  for i=1,1000 do
    love.graphics.setColor(math.random(),math.random(),math.random(),1)
    love.graphics.points(math.random(screenX),math.random(screenY))
  end
  love.graphics.setCanvas()
  gameStage=gameStages["INTRO"]
end

function resetPositionShipBullet()
  shipBullet.launched=false
  shipBullet.x=ship.x+ship.w/2-shipBullet.w/2
  shipBullet.y=screenY-ship.h-fuelTextHeight-2
end

function checkCollision(obj1, obj2)
  if (obj1.x>(obj2.x+obj2.w)) then
    return false
  elseif (obj2.x>(obj1.x+obj1.w)) then
    return false
  elseif (obj1.y>(obj2.y+obj2.h)) then
    return false
  elseif (obj2.y>(obj1.y+obj1.h)) then
    return false
  end
  return true
end

function moveEnemies(dt)
  for i=1,#enemies do
    if (enemies[i].status~=enemyStatus["DESTROYED"]) then
      if (math.random(500)<=level) then
        enemies[i].dir=-enemies[i].dir
      end
      enemies[i].x=enemies[i].x+enemies[i].dir*50*math.floor(1+level/2)*dt
      if (enemies[i].x<0) then
        enemies[i].x=0
        enemies[i].dir=1
      elseif (enemies[i].x>(screenX-enemies[i].w)) then
        enemies[i].x=screenX-enemies[i].w
        enemies[i].dir=-1
      end
      if (enemies[i].status==enemyStatus["SPLIT"]) then
        enemies[i].y=enemies[i].y+dt*math.random(level)*30
        if (enemies[i].y>(screenY-fuelTextHeight)) then enemies[i].y=0 end
      else
        enemies[i].y=enemies[i].y+getRandomDir()*dt*math.random(level)*30
        if (enemies[i].y>(screenY-fuelTextHeight)) or (enemies[i].y<32) then
          enemies[i].y=32
        end
      end
      enemies[i].flapTime=enemies[i].flapTime+dt
      if (enemies[i].flapTime>0.25) then
        enemies[i].frame=(enemies[i].frame % 2)+1
        if (enemies[i].status==enemyStatus["LARGE"]) then
          enemies[i].img=demonImg[enemies[i].frame]
        else
          enemies[i].img=demonSplitImg[enemies[i].frame]
        end
        enemies[i].flapTime=0
      end
    end
  end
end

function moveEnemyBullets(dt)
  local i=1
  while (i<=#enemyBullets) do
    enemyBullets[i].y=enemyBullets[i].y+256*dt
    if (enemyBullets[i].y>(screenY-fuelTextHeight)) then
      table.remove(enemyBullets,i)
    else
      i=i+1
    end
  end
end

function fireEnemies()
  if (#enemies<=0) then return end
  if (math.random(200)<=level) then
    local enemyBullet={}
    local enemyFiring=math.random(#enemies)
    if (enemies[enemyFiring].status==enemyStatus["DESTROYED"]) then return end
    enemyBullet.img=enemyBulletImg
    enemyBullet.w=enemyBullet.img:getWidth()
    enemyBullet.h=enemyBullet.img:getHeight()
    enemyBullet.x=enemies[enemyFiring].x+enemies[enemyFiring].w/2-enemyBullet.w/2
    enemyBullet.y=enemies[enemyFiring].y+enemies[enemyFiring].h/2
    table.insert(enemyBullets,enemyBullet)
  end
end

function fadeExplosions(dt)
  local i=1
  while (i<=#enemies) do
    if (enemies[i].status==enemyStatus["DESTROYED"]) then
      enemies[i].alpha=enemies[i].alpha-dt
      if (enemies[i].alpha<0) then 
        table.remove(enemies,i)
      else
        i=i+1
      end
    else
      i=i+1
    end
  end
end

function fadeShipExplosion(dt)
  ship.alpha=ship.alpha-dt
  if (ship.alpha<0) then
    lives=lives-1
    if (lives>0) then
      resetGraphics()
      gameStage=gameStages["PLAY"]
    else
      enemies={}
      enemyBullets={}
      gameStage=gameStages["GAMEOVER"]
      if (hi<score) then hi=score end
    end
  end
end
      
function manageCollisionsShipBullet()
  if (not shipBullet.launched) then return end
  for i=1,#enemies do
    if (enemies[i].status~=enemyStatus["DESTROYED"]) and (checkCollision(shipBullet,enemies[i])) then
      playSound(sounds.enemyexplosion)
      resetPositionShipBullet()
      if (enemies[i].status==enemyStatus["LARGE"]) and (enemies[i].splittable) then
        score=score+50
        local enemySplit1={}
        local enemySplit2={}
        enemySplit1.frame,enemySplit2.frame=1,1
        enemySplit1.img,enemySplit2.img=demonSplitImg[1],demonSplitImg[1]
        enemySplit1.x,enemySplit2.x=enemies[i].x,enemies[i].x+enemies[i].w/2
        enemySplit1.y,enemySplit2.y=enemies[i].y,enemies[i].y
        enemySplit1.w,enemySplit2.w=enemySplit1.img:getWidth(),enemySplit2.img:getWidth()
        enemySplit1.h,enemySplit2.h=enemySplit1.img:getHeight(),enemySplit2.img:getHeight()
        enemySplit1.alpha,enemySplit2.alpha=1.0,1.0
        enemySplit1.flapTime,enemySplit2.flapTime=0,0
        enemySplit1.splittable,enemySplit2.splittable=false,false
        enemySplit1.dir=-1
        enemySplit2.dir=1
        enemySplit1.status,enemySplit2.status=enemyStatus["SPLIT"],enemyStatus["SPLIT"]
        enemies[i].status=enemyStatus["DESTROYED"]
        enemies[i].alpha=1.0
        enemies[i].img=score50Img
        table.insert(enemies,enemySplit1)
        table.insert(enemies,enemySplit2)
        return
      elseif (enemies[i].status==enemyStatus["SPLIT"]) or (not enemies[i].splittable) then
        if (enemies[i].status==enemyStatus["LARGE"]) then
          score=score+50
          enemies[i].img=score50Img
        else
          score=score+100
          enemies[i].img=score100Img
        end  
        enemies[i].status=enemyStatus["DESTROYED"]
        enemies[i].alpha=1.0
      end
    end
  end
end

function hitShip()
  gameStage=gameStages["HIT"]
  ship.img=explosionImg
  shipBullet=nil
  playSound(sounds.explosion)
end

function manageCollisionsEnemyBullet()
  for i=1,#enemyBullets do
    if (checkCollision(ship,enemyBullets[i])) then
      table.remove(enemyBullets,i)
      hitShip()
      return
    end
  end
end

function manageCollisionsEnemies()
  for i=1,#enemies do
    if (enemies[i].status~=enemyStatus["DESTROYED"]) then
      if (checkCollision(ship,enemies[i])) then
        table.remove(enemyBullets,i)
        hitShip()
        return
      end
    end
  end
end

function checkLevelCompleted()
  if (#enemies==0) then
    enemyBullets={}
    resetPositionShipBullet()
    gameStage=gameStages["LEVELCHANGE"]
    startTime=-1
    playSound(sounds.fuel)
  end
end

function love.update(delta)
  if (gameStage==gameStages["INTRO"]) then
    if (love.keyboard.isScancodeDown("space")) then
      gameStage=gameStages["STARTPLAY"]
    end  
  elseif (gameStage==gameStages["STARTPLAY"]) then
      resetGame()
      gameStage=gameStages["PLAY"]
  elseif (gameStage==gameStages["LEVELCHANGE"]) then
    if (fuel>0) then
      fuel=fuel-delta*20
      score=score+200*delta
    else
      if (startTime<0) then 
        startTime=love.timer.getTime()
        score=math.floor(score/10)*10
      else
        if ((love.timer.getTime()-startTime)>3) then
          love.audio.stop()
          level=level+1
          gameStage=gameStages["PLAY"]
          resetGraphics()
        end
      end
    end
  elseif (gameStage==gameStages["PLAY"]) then
    if (love.keyboard.isScancodeDown("left")) then
      ship.x=ship.x-256*delta
      if (not shipBullet.launched) then
        shipBullet.x=shipBullet.x-256*delta
      end
      if (ship.x<0) then
        ship.x=0
        if (not shipBullet.launched) then
          shipBullet.x=ship.x+ship.w/2-shipBullet.w/2
        end
      end
    elseif (love.keyboard.isScancodeDown("right")) then
      ship.x=ship.x+256*delta
      if (not shipBullet.launched) then
        shipBullet.x=shipBullet.x+256*delta
      end
      if (ship.x>(screenX-ship.img:getWidth())) then
        ship.x=screenX-ship.img:getWidth()
        if (not shipBullet.launched) then
          shipBullet.x=ship.x+ship.w/2-shipBullet.w/2
        end
      end
    elseif (love.keyboard.isScancodeDown("space")) then
      if (not shipBullet.launched) then
        shipBullet.launched=true
        playSound(sounds.fire)
      end
    end
    if (shipBullet.launched) then
      shipBullet.y=shipBullet.y-512*delta
      if (shipBullet.y<(32-shipBullet.h)) then
        resetPositionShipBullet()
      end
    end 
    moveEnemies(delta)
    fireEnemies()
    moveEnemyBullets(delta)
    fadeExplosions(delta)
    manageCollisionsShipBullet()
    manageCollisionsEnemyBullet()
    manageCollisionsEnemies()
    checkLevelCompleted()
    fuel=fuel-delta/2
    if (fuel<=0) then hitShip() end
    if (score>=5000) and (not bonusShipFlag) then
      lives=lives+1
      bonusShipFlag=true
      playSound(sounds.fuel)
    end
  elseif (gameStage==gameStages["HIT"]) then
    fadeShipExplosion(delta)
  elseif (gameStage==gameStages["GAMEOVER"]) then
    if (love.keyboard.isScancodeDown("space")) then
      resetGame()
    elseif (love.keyboard.isScancodeDown("escape")) then
      os.exit()
    end
  end
end

function love.draw()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(backgroundCanvas)
  if (gameStage==gameStages["GAMEOVER"]) then
    love.graphics.setColor(1,0,0,1)
    love.graphics.printf("GAME OVER", 0, screenY/4,screenX/4,"center",0,4,4)
    love.graphics.setColor(0,0,1,1)
    love.graphics.printf("<BAR> to REPLAY", 0, screenY/2,screenX/2,"center",0,2,2)
    love.graphics.printf("<ESC> to QUIT", 0, screenY/2+64,screenX/2,"center",0,2,2)
  elseif (gameStage==gameStages["LEVELCHANGE"]) then
    love.graphics.setColor(0,0.5,1,1)
    love.graphics.printf("Congrats! Next Level Ahead!", 0, screenY/2,screenX/2,"center",0,2,2)
  elseif  (gameStage==gameStages["INTRO"]) then 
    love.graphics.setColor(1,0,0,1)
    love.graphics.printf("ALIEN ATTACK", 0, screenY/8,screenX/4,"center",0,4,4)
    love.graphics.setColor(0,1,1,1)
    love.graphics.printf("(c)2020 M.Bruti/Texasoft Reloaded", 0, screenY-32,screenX*0.66,"center",0,1.5,1.5)
    love.graphics.setColor(1,1,0,1)
    love.graphics.printf("Bonus Ship @ 5000 pts\n\nPress <BAR> To Start", 0, screenY/2+128,screenX/2,"center",0,2,2)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(demonImg[1],screenX/3,screenY/4+64)
    love.graphics.printf("50 pts", screenX/2, screenY/4+64,screenX/8,"right",0,2,2)
    love.graphics.setColor(1,1,0,1)
    love.graphics.draw(demonImg[1],screenX/3,screenY/4+128)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("50 pts", screenX/2, screenY/4+128,screenX/8,"right",0,2,2)
    love.graphics.draw(demonSplitImg[1],screenX/3+16,screenY/4+192)
    love.graphics.printf("100 pts", screenX/2, screenY/4+192,screenX/8,"right",0,2,2)
  end
  if (gameStage~=gameStages["INTRO"]) and (gameStage~=gameStages["STARTPLAY"]) then
    love.graphics.setColor(0,1,0,1)
    love.graphics.printf(string.format("SCORE:%08d",score),screenX*0.75,0,screenX/4,"right")
    love.graphics.printf(string.format("HI:%08d",hi),screenX/3,0,screenX/4,"right")
    love.graphics.printf(string.format("LEVEL:%03d",level),screenX/9,0,screenX/4,"left")
    love.graphics.setColor(1,1,1,ship.alpha)
    love.graphics.draw(ship.img, ship.x, ship.y)
    love.graphics.setColor(1, 1, 1, 1)
    if (shipBullet) then love.graphics.draw(shipBullet.img, shipBullet.x, shipBullet.y) end
    for i=1,#enemies do
      if (enemies[i].splittable) then
        love.graphics.setColor(1,1,0,enemies[i].alpha)
      else
        love.graphics.setColor(1,1,1,enemies[i].alpha)
      end  
      love.graphics.draw(enemies[i].img, enemies[i].x,enemies[i].y)
    end
    love.graphics.setColor(1, 1, 1, 1)
    for i=1,#enemyBullets do
      love.graphics.draw(enemyBullets[i].img, enemyBullets[i].x,enemyBullets[i].y)
    end
    for i=1,lives do
      love.graphics.draw(shipImg,(ship.w/2+4)*(i-1),0,0,0.5,0.5)
    end
    love.graphics.draw(fuelText,0,screenY-fuelText:getHeight(),0)
    love.graphics.setColor(0,0,1,1)
    love.graphics.rectangle("line",fuelText:getWidth()+7, screenY-fuelText:getHeight()-2,screenX-(fuelText:getWidth()+7),fuelText:getHeight()+2)
    if (fuel>0) then
      love.graphics.setColor(0,1,0,1)
      love.graphics.rectangle("fill",fuelText:getWidth()+8, screenY-fuelText:getHeight()-1,fuel*fuelScaleX,fuelText:getHeight())
    end
  end
end  