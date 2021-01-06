local gl,MotorLibrary=nil,nil

function love.load()
  print("Esempio METATABLE __add: somma di vettori")
  local t1={x=10,y=20}
  local t2={x=5,y=25}
  local mt1={};
  mt1.__add=function(ta,tb)
    local tc={}
    tc.x=ta.x+tb.x
    tc.y=ta.y+tb.y
    return tc
  end
  setmetatable(t1,mt1)
  setmetatable(t2,mt1)
  local t3=t1+t2
  print("("..t1.x..","..t1.y..")+("..t2.x..","..t2.y..")=("..t3.x..","..t3.y..")\n") -- stampa 15 45
  print("Esempio METATABLE __index: campi mancanti c e d presenti nella metatable")
  local t1={x=10,y=20}
  local prototipo={a=1,b=2,c=3,d=4}
  local t={a=1,b=2}
  print("PRIMA DELLA __index: t.c="..tostring(t.c)..",t.d="..tostring(t.d))
  local mt={}
  mt.__index=prototipo
  setmetatable(t,mt)
  print("DOPO LA __index: t.c="..tostring(t.c)..",t.d="..tostring(t.d).."\n")
  print("Esempio CLASSI Veicolo E Auto")
  gl=require("gamelibrary")
  ml=require("motorlibrary")
  local veicolo=ml.Veicolo:new{costruttore="Harley-Davidson",modello="IRON-883",targa="AA12345"}
  local auto=ml.Auto:new({costruttore="Ford",modello="Focus",targa="AA123ZZ"})
  veicolo:printVeicolo()
  auto:printVeicolo()
  print("\nESEMPIO CHIAMATA FUNZIONE DI LIBRERIA: gl.getRandomDir()")
  dir=gl.getRandomDir()
  print("Direzione casuale="..gl.getRandomDir())
end

function love.update(delta)
end

function love.draw()
end  