local MotorClass={}

local Veicolo={costruttore="", modello="", targa=""}

function Veicolo:new(o)
  o=o or {}
  self.__index=self
  setmetatable(o,self)
  return o
end

function Veicolo:printVeicolo()
  print(self.costruttore.." "..self.modello.." "..self.targa)
end

local Auto=Veicolo:new{numRuoteMotrici=4}

function Auto:printVeicolo()
  print(self.costruttore.." "..self.modello.." "..self.targa.." "..self.numRuoteMotrici)
end

MotorClass.Veicolo=Veicolo
MotorClass.Auto=Auto

return MotorClass