-- miniELIZA (c)2020 Marco Bruti
local utf8 = require("utf8")
local vocab={}
local tokens={}
local avverbi={}
local screenX=640
local screenY=800
local question,prev_question, answer,curr_answer,prev_answer, prev_clean_answer,clean_answer="","","","","","",""
local fase
function love.load()
  vocab["verbi"]={}
  vocab["avverbi_interr"]={}
  vocab["pronomi"]={}
  vocab["saluti"]={}
  vocab["commiati"]={}
  vocab["statidanimo"]={}
  vocab["avverbi_aff_neg_dub"]={}
  vocab["ridondanti"]={}
  vocab["relazioni"]={}
  question,prev_question="Ciao, sono Eliza.",""
  answer,prev_answer,clean_answer,prev_clean_answer="","","",""
  love.window.setMode(screenX,screenY)  
  local file=io.open("vocabolario.txt","r")
  local stanzaCorrente=nil
  local primaPersona,secondaPersona
  for line in file:lines() do
    local stanza=string.match(line,"%[([%a_]+)%]")
    if (stanza~=nil) then
      stanzaCorrente=stanza
    else
      local posDelim=string.find(line,",")
      if (posDelim) then
        primaPersona=string.sub(line,1,posDelim-1)
        secondaPersona=string.sub(line,posDelim+1,#line)
        if (vocab[stanzaCorrente][primaPersona]==nil) then
          vocab[stanzaCorrente][primaPersona]=secondaPersona
        end
        if (vocab[stanzaCorrente][secondaPersona]==nil) and (stanzaCorrente~="statidanimo") then
          vocab[stanzaCorrente][secondaPersona]=primaPersona
        end
      else
        primaPersona=line
        vocab[stanzaCorrente][primaPersona]=primaPersona
      end 
    end
  end
  file:close()
  fase="answer"
end
function love.textinput(t)
    if (fase~="answer") then return end
    curr_answer = curr_answer..t
end
function love.keypressed(key)
  if (fase~="answer") then return end
  if (key == "backspace") then
    local byteoffset = utf8.offset(curr_answer, -1)
    if byteoffset then
      curr_answer = string.sub(curr_answer, 1, byteoffset - 1)
    end
  elseif (key=="return") then
    prev_answer=answer
    answer=curr_answer
    curr_answer=""
    fase="question"
  end
end
function love.update(dt)
  if (fase=="question") then
    local parolaSingola=false
    local saluti,commiati="",""
    local domanda=false
    local avv_interr,avv_aff_neg_dub,statodanimo_participio,statodanimo_sostantivo,relazione="","","","",""
    prev_question=question
    question=""
    tokens={}
    -- converte la risposta in token
    answer=string.lower(answer)
    for token in string.gmatch(answer,"[%w']+") do
      tokens[#tokens+1]=token
    end
    -- verifica se è una domanda
    if (string.find(answer,"?")) then domanda=true end
    -- verifica se sia una parola ridondante e la rimuove
    local i=1
    repeat
      local removeFlag=false
      for k,_ in pairs(vocab["ridondanti"]) do
        if (tokens[i]==k) then
          table.remove(tokens,i)
          removeFlag=true
          break
        end
      end
      if (not removeFlag) then i=i+1 end
    until i>#tokens
    -- verifica se sia un saluto e lo estrae
    i=1
    repeat
      local removeFlag=false
      for k,_ in pairs(vocab["saluti"]) do
        if (tokens[i]==k) then
          if (saluti=="") then
            saluti=k
          else
            saluti=saluti.." "..k
          end
          table.remove(tokens,i)
          removeFlag=true
          break
        end
      end
      if (not removeFlag) then i=i+1 end
    until i>#tokens
    -- verifica se sia un commiato e lo estrae
    i=1
    repeat
      local removeFlag=false
      for k,_ in pairs(vocab["commiati"]) do
        if (tokens[i]==k) then
          if (commiati=="") then
            commiati=k
          else
            commiati=commiati.." "..k
          end
          table.remove(tokens,i)
          removeFlag=true
          break
        end
      end
      if (not removeFlag) then i=i+1 end
    until i>#tokens
     -- verifica se vi sia un avverbio di affermazione/interrogazione/dubbio
    i=1
    repeat
      for k,_ in pairs(vocab["avverbi_aff_neg_dub"]) do
        if (tokens[i]==k) then
          if (avv_aff_neg_dub=="") then
            avv_aff_neg_dub=k
          else
            avv_aff_neg_dub=avv_aff_neg_dub.." "..k
          end
          break
        end
      end
      i=i+1
    until i>#tokens
    -- verifica se sia un avverbio interrogativo. se c'è prende l'ultimo
    i=1
    repeat
      for k,_ in pairs(vocab["avverbi_interr"]) do
        if (tokens[i]==k) then
          avv_interr=k
          break
        end
      end
      i=i+1
    until i>#tokens
    -- verifica se ci sia una relazione (padre, madre, ecc)
    i=1
    repeat
      for k,v in pairs(vocab["relazioni"]) do
        if (tokens[i]==k) then
          relazione=v.." "..k
          break
        end
      end
      i=i+1
    until i>#tokens
    -- creazione risposta depurata
    clean_answer=table.concat(tokens)
    -- identificazione stati d'animo
    for i=1,#tokens do
      for k,v in pairs(vocab["statidanimo"]) do
        if (tokens[i]==k) then
          statodanimo_participio=v
          break
        elseif (string.find(tokens[i],string.sub(v,1,#v-1))) then
          statodanimo_sostantivo=k
          break
        end
      end
    end
    -- cambia verbi e pronomi da prima persona a seconda, e viceversa
    for i=1,#tokens do
      for k,v in pairs(vocab["verbi"]) do
        if (tokens[i]==k) then
          tokens[i]=v 
          break
        end
      end
    end
    for i=1,#tokens do
      for k,v in pairs(vocab["pronomi"]) do
        if (tokens[i]==k) then
          tokens[i]=v
          break
        end
      end
    end
    -- Crea la risposta ribaltata
    if (#tokens>=1) then
      question=question..tokens[1]
      for i=2,#tokens do
        question=question.." "..tokens[i]
      end
    else
      parolaSingola=true
    end
    local choice=math.random(100)
    -- indentifica le ripetizioni
    if ((#clean_answer>0) and (string.lower(clean_answer)==string.lower(prev_clean_answer))) or (string.lower(prev_answer)==string.lower(answer)) then
      question="Perche' ti ripeti?"
    -- contiene un avverbio di affermazione, negazione, dubbio?
    elseif (parolaSingola) and (avv_aff_neg_dub~="") then
      if (choice<=20) then
        question="Capisco."
      elseif (choice<=40) then
        question="Continua..."
      elseif (choice<=60) then
        question=avv_aff_neg_dub.."?"
      elseif (choice<=80) then
        question="Sicuro?"
      else
        question="Non sono convinta."
      end
    elseif (parolaSingola) and (avv_interr~="") then
      question=avv_interr.."?"
    elseif (commiati~="") then
      question="Va bene, "..commiati..", mi dispiace te ne voglia andare così presto."
    -- solo saluti
    elseif (saluti~="") and (clean_answer=="") then
      question=saluti
    --stato d'animo
    elseif (statodanimo_participio~="") then
      question="Perche' ti senti "..statodanimo_participio.."?"
    elseif (statodanimo_sostantivo~="") then
      question="Perche' questo stato di "..statodanimo_sostantivo.."?"
    -- è una domanda e c'è avverbio interrogativo?
    elseif (domanda) and (avv_interr~="") then
        question="Perche' ti chiedi "..question.."?"
    else
    -- ci sono riferimenti a una relazione tipo padre, madre, ecc
      if (relazione~="") then
        question="Parlami di "..relazione.."."
      -- ci sono avverbi di affermazione/negazione/dubbio
      elseif (avv_aff_neg_dub~="") then
        if (avv_interr~="") then
          question=answer.." e' una domanda o un'affermazione?"
        else
          -- pone in forme interrogativa l'affermazione
          question="Perche' affermi che "..question.."?"
        end
      elseif (choice<=10)  then
        question="Continua..."
      elseif (choice<=20)  then
        question="Dimmi di piu'..."
      elseif (choice<=50) then
        if (question~="") then
          question=question.."?"
        else  
          question="Che intendi dire?"
        end
      elseif (choice<=80) then
        if (question~="") then
          question=question.."."
        else  
          question="Cosa vuoi dire?"
        end
      else
        if (question~="") then
          question="Cosa significa "..question.."?"
        else  
          question="Non mi e' chiaro."
        end
      end
    end
    question=string.gsub(question,"^%A*(%a?)", function(toUpper) return string.upper(toUpper) end) 
    fase="answer"
    prev_answer=answer
    prev_clean_answer=clean_answer
  end
end

function love.draw()
  love.graphics.clear(0,0,0)
  love.graphics.setColor(0,0,1,0.2)
  love.graphics.rectangle("fill",0,0,screenX,screenY/2)
  love.graphics.setColor(1,0,0,0.2)
  love.graphics.rectangle("fill",0,screenY/2,screenX,screenY/2)
  love.graphics.setColor(1,1,1,1)
  love.graphics.printf("<ELIZA> "..question,64,love.graphics.getHeight()*0.25,love.graphics.getWidth()/2-64,"center",0,2,2)
  love.graphics.printf("<YOU> "..curr_answer,64,love.graphics.getHeight()*0.6,love.graphics.getWidth()/2-64,"center",0,2,2)
  love.graphics.printf("mini-ELIZA CHATBOT",0,0,screenX/4,"center",0,4,4)
end
