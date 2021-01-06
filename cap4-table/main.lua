-- Lista della Spesa (c)2020 Marco Bruti
local listaSpesa={}
function stampaOrdinata()
  local elemList={}
  for elem in pairs(listaSpesa) do
    elemList[#elemList+1]=elem
  end
  table.sort(elemList, function(a,b) return string.lower(a)<string.lower(b) end )
  for _,elem in ipairs(elemList) do
    io.write(elem..":"..listaSpesa[elem].."\n")
  end
end
function love.load()
  io.write("Inserisci la lista della spesa\n")
  repeat
    io.write("Inserisci cosa comprare (invio per finire): ")
    local quantita=nil
    local elem=io.read()
    if (elem ~= "") then
      while (quantita==nil) do
        io.write("Quantita: ")
        quantita=tonumber(io.read())
      end
      listaSpesa[elem]=quantita
    end
  until (elem=="")
  stampaOrdinata()
  io.write("Inserisci elementi da rimuovere\n")
  repeat
    io.write("Inserisci cosa rimuovere (invio per finire): ")
    local elem=io.read()
    if (elem~="") then
      if (listaSpesa[elem]==nil) then
        io.write(elem.." non e' in lista.\n")
      else
        listaSpesa[elem]=nil
      end
    end
  until (elem=="")
  stampaOrdinata()
end
function love.update(dt)
end
function love.draw()
end
