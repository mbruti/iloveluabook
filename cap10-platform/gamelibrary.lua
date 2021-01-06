local gl={}

function gl.checkCollision(obj1, obj2)
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

function gl.playSound(sound)
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
gl.getRandomDir=getRandomDir

return gl