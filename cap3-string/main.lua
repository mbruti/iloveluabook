-- Conta-parole (c)2020 Marco Bruti
local nomeFile, contenutoFile, parola
local posizioneCorrente, posizioneIniziale, posizioneFinale=1,nil,nil
local numeroParole=0
local dizionario={}
local parolaTrovata
function love.load()
  print("Inserisci il nome del file")
  nomeFile=io.read()
  io.input(nomeFile)
  contenutoFile=io.read("*a")
  repeat 
    posizioneIniziale,posizioneFinale=string.find(contenutoFile,"%w+",posizioneCorrente)
    if (posizioneIniziale==nil) then break end
    parola=string.sub(contenutoFile,posizioneIniziale,posizioneFinale)
    print(parola)
    parolaTrovata=false
    for i=1,#dizionario do
      if dizionario[i]==parola then
        parolaTrovata=true
        break
      end
    end
    if not parolaTrovata then
      dizionario[#dizionario+1]=parola
    end
    numeroParole=numeroParole+1
    posizioneCorrente=posizioneFinale+1
  until (posizioneCorrente>#contenutoFile)
  print("Il numero di parole nel file e' "..numeroParole)
  print("Il numero di parole uniche nel file e' "..#dizionario)
end
function love.update(dt)
end
function love.draw()
end
