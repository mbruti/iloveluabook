local physObj={}

local gameObj={body=nil,shape=nil,fixture=nil,x=0,y=0,w=0,h=0,frame=1,status=1,frameTime=0,isSensor=false,isAnimated=false,frameDuration=0.2,dir=0}
local edgeObj={body=nil,shape=nil,fixture=nil,x1=0,y1=0,x2=0,x2=0}

-- new(world,bodyType,x,y,w,h,isSensor,isAnimated,frameDuration)
function gameObj:new(world, bodyType,...)
  local o={}
  setmetatable(o,self)
  self.__index=self
  for i,v in ipairs({...}) do
    if (i==1) then
      o.x=v
    elseif (i==2) then
      o.y=v
    elseif (i==3) then
      o.w=v
    elseif (i==4) then  
      o.h=v
    elseif (i==5) then
      o.isSensor=v
    elseif (i==6) then
      o.isAnimated=v
    elseif (i==7) then
      o.frameDuration=v
    end
  end
  o.body=love.physics.newBody(world,o.x,o.y,bodyType)
  o.shape=love.physics.newRectangleShape(o.w-4,o.h-4)
  o.fixture=love.physics.newFixture(o.body,o.shape,1)
  o.fixture:setSensor(o.isSensor)
  return o
end

function edgeObj:new(world,x1,y1,x2,y2)
  local o={}
  setmetatable(o,self)
  self.__index=self
  o.x1=x1
  o.y1=y1
  o.x2=x2
  o.y2=y2
  o.body=love.physics.newBody(world,o.x,o.y,"static")
  o.shape=love.physics.newEdgeShape(o.x1,o.y1,o.x2,o.y2)
  o.fixture=love.physics.newFixture(o.body,o.shape,1)
  return o
end

physObj.gameObj=gameObj
physObj.edgeObj=edgeObj
return physObj