function love.load()

  require("enemy")
  require("map")

  love.window.setFullscreen(true)

  tiles = {}
  tileset = love.graphics.newImage("tileset.png")
  for rowsDown = 0, (tileset:getHeight() / 128) - 1 do
    for tilesAcross = 0, (tileset:getWidth() / 64) - 1 do
      tiles[rowsDown * (tileset:getWidth() / 64) + tilesAcross + 1] = love.graphics.newQuad(tilesAcross * 64, rowsDown * 128, 64, 128, tileset:getDimensions())
    end
  end

  scout = love.graphics.newImage("scout.png")

  tank = love.graphics.newImage("tank.png")

  sniper = love.graphics.newImage("sniper.png")

  healer = love.graphics.newImage("healer.png")

  stormtrooper = love.graphics.newImage("stormtrooper.png")

  laser = love.graphics.newImage("laser.png")

  bluelaser = love.graphics.newImage("bluelaser.png")

  rock = love.graphics.newImage("rock.png")

  dtTotal = 0

  w = love.graphics.getWidth ()
  h = love.graphics.getHeight ()

  fontBig = love.graphics.newFont("font.ttf", 96)
  font = love.graphics.newFont("font.ttf", 18)

  loadMap()
  tileType = {0, 1, 0, 1}
  xV = 0
  yV = 0
  dX = 0
  dY = 0
  selected = 1 -- 1 is scout, 2 is tank, 3 is sniper,
  chars = {{(#map[1] / 2) * 64, (#map / 2) * 64, (#map[1] / 2) * 64, (#map / 2) * 64, 10, 100},
  {((#map[1] - 2) / 2) * 64, (#map / 2) * 64, ((#map[1] - 2) / 2) * 64, (#map / 2) * 64, 10, 200},
  {(#map[1] / 2) * 64, ((#map + 1) / 2) * 64, (#map[1] / 2) * 64, ((#map - 2) / 2) * 64, 10, 100},
  {((#map[1] - 2) / 2) * 64, ((#map - 2) / 2) * 64, ((#map[1] - 2) / 2) * 64, ((#map - 2) / 2) * 64, 10, 100}}
  charMove = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}}
  dead = {0, 0, 0, 0}
  images = {scout, tank, sniper, healer}
  mode = 1
  specialCost = {5, 3, 10, 8}
  enemies = {}
  enemyMove = {}
  orderE = {}
  enemyToMove = 1
  alreadyMoved = {}
  alreadyAttacked = {}
  lasers = {}
  laserMove = {}
  x = chars[selected][1] - round(w / 2)
  y = chars[selected][2] - round(h / 2)
  enemyTurn = false
  generateEnemies(20)
end

function round(n, deci) deci = 10^(deci or 0) return math.floor(n*deci+.5)/deci end

function noOverlap(x1, y1, x2, y2)
  for i = 1, 4 do
    if x2 == round(chars[i][3]) and y2 == round(chars[i][4]) then
      return false
    end
  end
  for i = 1, #enemies do
    if x2 == round(enemies[i][3]) and y2 == round(enemies[i][4]) then
      return false
    end
  end
  distance = math.sqrt((y2 - y1) * (y2 - y1) + (x2 - x1) * (x2 - x1))
  return true
end

function enemyOnTile(x, y)
  for i = 1, #enemies do
    if x == round(enemies[i][3]) and y == round(enemies[i][4]) then
      return true
    end
  end
  return false
end

function enoughActions(x1, y1, x2, y2)
  distance = math.sqrt((y2 - y1) * (y2 - y1) + (x2 - x1) * (x2 - x1))
  if chars[selected][5] - round(distance / 64) < 0 then
    return false
  end
  return true
end

function moveValid(x1, y1, x2, y2)
  distance = math.sqrt((y2 - y1) * (y2 - y1) + (x2 - x1) * (x2 - x1))
  for rowsDown = 0, #map - 1 do
    for tilesAcross = 0, #map[1] - 1 do
      if tileType[map[rowsDown + 1][tilesAcross + 1]] == 1 then
        lineDistance = math.sqrt((rowsDown * 64 - y1) * (rowsDown * 64 - y1) + (tilesAcross * 64 - x1) * (tilesAcross * 64 - x1))
        distanceToLine = math.abs((y2 - y1) * (tilesAcross * 64) - (x2 - x1) * (rowsDown * 64) + x2 * y1 - y2 * x1) / distance
        if distanceToLine < 32 and distance - lineDistance >= 0 then
          tileOkay = false
          if x2 >= x1 and tilesAcross * 64 >= x1 then
          elseif x2 <= x1 and tilesAcross * 64 <= x1 then
          else
            tileOkay = true
          end
          if y2 >= y1 and rowsDown * 64 >= y1 then
          elseif y2 <= y1 and rowsDown * 64 <= y1 then
          else
            tileOkay = true
          end
          if tileOkay == false then
            return false
          end
        end
      end
    end
  end
  return true
end

function revealMap(i, vision)
  cX = chars[i][1]
  cY = chars[i][2]
  for rowsDown = 0, #map - 1 do
    for tilesAcross = 0, #map[1] - 1 do
      if mapRevealed[rowsDown + 1][tilesAcross + 1] == 0 and math.sqrt((rowsDown * 64 - cY) * (rowsDown * 64 - cY) + (tilesAcross * 64 - cX) * (tilesAcross * 64 - cX)) < vision then
        mapRevealed[rowsDown + 1][tilesAcross + 1] = 1
      end
    end
  end
end

function movePlayer(i)
  if charMove[i][3] > 0 then
    chars[i][1] = chars[i][1] + charMove[i][1]
    chars[i][2] = chars[i][2] + charMove[i][2]
    charMove[i][3] = charMove[i][3] - 1
  else
    chars[i][1] = chars[i][3]
    chars[i][2] = chars[i][4]
  end
end

function moveEnemy(i)
  if enemyMove[i][3] > 0 then
    enemies[i][1] = enemies[i][1] + enemyMove[i][1]
    enemies[i][2] = enemies[i][2] + enemyMove[i][2]
    enemyMove[i][3] = enemyMove[i][3] - 1
  else
    enemies[i][1] = enemies[i][3]
    enemies[i][2] = enemies[i][4]
  end
end

function moveLaser(i)
  if laserMove[i][3] > 0 then
    lasers[i][1] = lasers[i][1] + laserMove[i][1]
    lasers[i][2] = lasers[i][2] + laserMove[i][2]
    laserMove[i][3] = laserMove[i][3] - 1
  else
    lasers[i][1] = lasers[i][3]
    lasers[i][2] = lasers[i][4]
  end
end

function newLaser(x1, y1, x2, y2, target, team)
  table.insert(lasers, {x1, y1, x2, y2, target, team})
  table.insert(laserMove, {0, 0, 0})
  laserMove[#laserMove][3] = round(math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)) / 16)
  laserMove[#laserMove][1] = (x2 - x1) / laserMove[#laserMove][3]
  laserMove[#laserMove][2] = (y2 - y1) / laserMove[#laserMove][3]
end

function love.update(dt)
  dtTotal = dtTotal + dt
  if love.keyboard.isDown("w") then
    yV = yV - 1
  end
  if love.keyboard.isDown("a") then
    xV = xV - 1
  end
  if love.keyboard.isDown("s") then
    yV = yV + 1
  end
  if love.keyboard.isDown("d") then
    xV = xV + 1
  end
  xV = xV * 0.8
  yV = yV * 0.8
  x = x + round(xV)
  y = y + round(yV)

  mX, mY = love.mouse.getPosition()

  for i = 1, 4 do
    movePlayer(i)
    revealMap(i, 300)
    if dead[i] == 1 then
      chars[i][5] = 0
    end
  end

  while dead[selected] == 1 or selected > 4 do
    if dead[selected] == 1 then
      selected = selected + 1
    end
    if selected > 4 then
      selected = selected - 4
    end
  end

  for i = 1, #enemies do
    moveEnemy(i)
  end

  if #lasers > 0 then
    if lasers[1][6] == 1 or lasers[1][6] == 3 or lasers[1][6] == 4 then
      if lasers[1][3] ~= enemies[lasers[1][5]][3] or lasers[1][4] ~= enemies[lasers[1][5]][4] then
        table.remove(lasers, 1)
        table.remove(laserMove, 1)
      end
    else
      if dead[lasers[1][5]] == 1 then
        table.remove(lasers, 1)
        table.remove(laserMove, 1)
      end
    end
    if #lasers > 0 then
      moveLaser(1)
      if laserMove[1][3] == 0 then
        if lasers[1][6] == 1 then
          enemies[lasers[1][5]][6] = enemies[lasers[1][5]][6] - 10
        elseif lasers[1][6] == 2 then
          chars[lasers[1][5]][6] = chars[lasers[1][5]][6] - 10
          if chars[lasers[1][5]][6] < 1 then
            dead[lasers[1][5]] = 1
          end
        elseif lasers[1][6] == 3 then
          enemies[lasers[1][5]][6] = enemies[lasers[1][5]][6] - 25
        elseif lasers[1][6] == 4 then
          enemies[lasers[1][5]][6] = enemies[lasers[1][5]][6] - 100
        end
        if lasers[1][6] == 1 or lasers[1][6] == 3 or lasers[1][6] == 4 then
          if enemies[lasers[1][5]][6] <= 0 then
            table.remove(enemies, lasers[1][5])
            table.remove(enemyMove, lasers[1][5])
            table.remove(playersSpotted, lasers[1][5])
            alreadyMoved[target] = nil
          end
        end
        table.remove(lasers, 1)
        table.remove(laserMove, 1)
      end
    end
  end

  if chars[1][5] == 0 and chars[2][5] == 0 and chars[3][5] == 0 and chars[4][5] == 0 then
    if #enemies > 0 then
      enemyTurn = true
      for i = 1, 4 do
        if charMove[i][3] ~= 0 then
          enemyTurn = false
        end
      end
      if alreadyMoved[enemyToMove] == 0 and #lasers == 0 and enemyTurn == true then
        spotPlayers(enemyToMove)
        getEnemyMoves(enemyToMove)
        chooseEnemyMove(enemyToMove)
        alreadyMoved[enemyToMove] = 1
      end
      if enemyToMove <= #enemies and enemyMove[enemyToMove][3] == 0 and alreadyAttacked[enemyToMove] == 0 and #lasers == 0 and enemyTurn == true then
        enemyAttack(enemyToMove)
        alreadyAttacked[enemyToMove] = 1
        enemyToMove = enemyToMove + 1
      end
      if enemyToMove == #enemies + 1 and enemyTurn == true and #lasers == 0 then
        chars[1][5] = 10
        chars[2][5] = 10
        chars[3][5] = 10
        chars[4][5] = 10
        enemyToMove = 1
        alreadyMoved = {}
        alreadyAttacked = {}
        enemyTurn = false
        for i = 1, #enemies do
          table.insert(alreadyMoved, 0)
          table.insert(alreadyAttacked, 0)
        end
      end
    else
      chars[1][5] = 10
      chars[2][5] = 10
      chars[3][5] = 10
      chars[4][5] = 10
    end
  end

  love.graphics.setLineWidth(math.sin(dtTotal) * 5)


  if love.keyboard.isDown("escape") then
    love.event.quit()
  end
  if dead[1] == 1 and dead[2] == 1 and dead[3] == 1 and dead[4] == 1 then
    love.event.quit()
  end
end

function love.mousepressed(mX, mY, button)
  if chars[selected][3] - chars[selected][1] < 1 and chars[selected][4] - chars[selected][2] < 0.5 then
    if mode == 1 then
      if moveValid(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true
      and noOverlap(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true
      and enoughActions(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true then
        chars[selected][5] = chars[selected][5] - round(distance / 64)
        chars[selected][3] = round((mX - 32 + x) / 64) * 64
        chars[selected][4] = round((mY - 32 + y) / 64) * 64
        charMove[selected][3] = round(distance / 4)
        charMove[selected][1] = (round((mX - 32 + x) / 64) * 64 - round(chars[selected][1])) / charMove[selected][3]
        charMove[selected][2] = (round((mY - 32 + y) / 64) * 64 - round(chars[selected][2])) / charMove[selected][3]
      end
    elseif mode == 2 then
      attackDistance = math.sqrt((round((mX - 32 + x) / 64) * 64 - round(chars[selected][1])) * (round((mX - 32 + x) / 64) * 64 - round(chars[selected][1])) + (round((mY - 32 + y) / 64) * 64 - round(chars[selected][2])) * (round((mY - 32 + y) / 64) * 64 - round(chars[selected][2])))
      if selected == 1 or selected == 3 then
        if moveValid(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true and chars[selected][5] >= 2
        and enemyOnTile(round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) and attackDistance <= 512 then
          if selected == 1 or selected == 3 then
            for i = 1, #enemies do
              if enemies[i][3] == round((mX - 32 + x) / 64) * 64 and enemies[i][4] == round((mY - 32 + y) / 64) * 64 then
                target = i
              end
            end
            newLaser(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64, target, 1)
            chars[selected][5] = chars[selected][5] - 2
          end
        end
      elseif selected == 2 or selected == 4 then
        if moveValid(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true and chars[selected][5] >= 2
        and enemyOnTile(round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) and attackDistance <= 96 then
          for i = 1, #enemies do
            if enemies[i][3] == round((mX - 32 + x) / 64) * 64 and enemies[i][4] == round((mY - 32 + y) / 64) * 64 then
              target = i
            end
          end
          enemies[target][6] = enemies[target][6] - 20
          chars[selected][5] = chars[selected][5] - 2
          if enemies[target][6] <= 0 then
            table.remove(enemies, target)
            table.remove(enemyMove, target)
            table.remove(playersSpotted, target)
            alreadyMoved[target] = nil
          end
        end
      end
    elseif mode == 3 then
      attackDistance = math.sqrt((round((mX - 32 + x) / 64) * 64 - round(chars[selected][1])) * (round((mX - 32 + x) / 64) * 64 - round(chars[selected][1])) + (round((mY - 32 + y) / 64) * 64 - round(chars[selected][2])) * (round((mY - 32 + y) / 64) * 64 - round(chars[selected][2])))
      if selected == 2 then
        if moveValid(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true and chars[selected][5] >= specialCost[selected]
        and enemyOnTile(round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) and attackDistance <= 384 then
          for i = 1, #enemies do
            if enemies[i][3] == round((mX - 32 + x) / 64) * 64 and enemies[i][4] == round((mY - 32 + y) / 64) * 64 then
              target = i
            end
          end
          newLaser(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64, target, 3)
          chars[selected][5] = chars[selected][5] - specialCost[selected]
        end
        move = 1
      elseif selected == 3 then
        if moveValid(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true and chars[selected][5] >= specialCost[selected]
        and enemyOnTile(round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) and attackDistance <= 1024 then
          for i = 1, #enemies do
            if enemies[i][3] == round((mX - 32 + x) / 64) * 64 and enemies[i][4] == round((mY - 32 + y) / 64) * 64 then
              target = i
            end
          end
          newLaser(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64, target, 4)
          chars[selected][5] = chars[selected][5] - specialCost[selected]
        end
        move = 1
      end
    end
  end
end

function love.keypressed(key)
  if key == "return" and enemyTurn == false then
  chars[1][5] = 0
  chars[2][5] = 0
  chars[3][5] = 0
  chars[4][5] = 0
end
  if key == "tab" then
    mode = 1
    selected = selected + 1
    while dead[selected] == 1 or selected > 4 do
      if dead[selected] == 1 then
        selected = selected + 1
      end
      if selected > 4 then
        selected = selected - 4
      end
    end
    x = chars[selected][1] - round(w / 2)
    y = chars[selected][2] - round(h / 2)
  elseif key == "1" then
    if mode == 1 or mode == 3 then
      mode = 2
    else
      mode = 1
    end
  elseif key == "2" then
    if mode == 1 or mode == 2 then
      mode = 3
      if selected == 1 then
        if chars[selected][5] >= specialCost[selected] then
          for rowsDown = 0, #map - 1 do
            for tilesAcross = 0, #map[1] - 1 do
              if mapRevealed[rowsDown + 1][tilesAcross + 1] == 0
              and math.sqrt((rowsDown * 64 - chars[selected][2]) * (rowsDown * 64 - chars[selected][2]) + (tilesAcross * 64 - chars[selected][1]) * (tilesAcross * 64 - chars[selected][1])) < 512 then
                mapRevealed[rowsDown + 1][tilesAcross + 1] = 1
              end
            end
          end
          chars[selected][5] = chars[selected][5] - specialCost[selected]
        end
        mode = 1
      elseif selected == 4 then
        if chars[selected][5] >= specialCost[selected] then
          healed = 0
          for i = 1, 4 do
            closeness = math.sqrt((chars[i][3] - chars[selected][3]) * (chars[i][3] - chars[selected][3]) + (chars[i][4] - chars[selected][4]) * (chars[i][4] - chars[selected][4]))
            if closeness <= 96 then
              if i == 2 then
                if chars[i][6] < 200 then
                  healed = healed + 1
                  chars[i][6] = chars[i][6] + 50
                end
                if chars[i][6] > 200 then
                  chars[i][6] = 200
                end
              else
                if chars[i][6] < 100 then
                  healed = healed + 1
                  chars[i][6] = chars[i][6] + 50
                end
                if chars[i][6] > 100 then
                  chars[i][6] = 100
                end
              end
            end
          end
          if healed > 0 then
            chars[selected][5] = chars[selected][5] - specialCost[selected]
          end
        end
        mode = 1
      end
    else
      mode = 1
    end
  end
end

function love.draw()
  love.graphics.setColor(255, 255, 255)
  for rowsDown = 1, #map do
    for tilesAcross = 1, #map[1] do
      if mapRevealed[rowsDown][tilesAcross] == 1 then
        if enemyTurn == true then love.graphics.setColor(255, 55, 55) end
        love.graphics.draw(tileset, tiles[map[rowsDown][tilesAcross]], (tilesAcross - 1) * 64 - x, (rowsDown - 1) * 64 - y - 64)
      end
    end
    for i = 1, 4 do
      if enemyTurn == true then love.graphics.setColor(255, 55, 55) end
      if chars[i][2] > (rowsDown * 64) - 128 and chars[i][2] <= (rowsDown * 64) - 64 and dead[i] ~= 1 then
        if i == 1 then
          love.graphics.draw(scout, chars[i][1] - x, chars[i][2] - y - 64)
        elseif i == 2 then
          love.graphics.draw(tank, chars[i][1] - x - 16, chars[i][2] - y - 96)
        elseif i == 3 then
          love.graphics.draw(sniper, chars[i][1] - x, chars[i][2] - y - 64)
        else
          love.graphics.draw(healer, chars[i][1] - x, chars[i][2] - y - 64)
        end
        love.graphics.setLineWidth(4)
        love.graphics.setColor(255, 0, 0)
        if i == 2 then
          love.graphics.line(chars[i][1] - x + 2, chars[i][2] - y - images[i]:getHeight() / 2 - 4, chars[i][1] - x + (chars[i][6] / 200) * 62, chars[i][2] - y - images[i]:getHeight() / 2 - 4)
        else
          love.graphics.line(chars[i][1] - x + 2, chars[i][2] - y - images[i]:getHeight() / 2 - 4, chars[i][1] - x + (chars[i][6] / 100) * 62, chars[i][2] - y - images[i]:getHeight() / 2 - 4)
        end
        love.graphics.setColor(0, 255, 255)
        if chars[i][5] > 0 then
          love.graphics.line(chars[i][1] - x + 2, chars[i][2] - y - images[i]:getHeight() / 2 + 4, chars[i][1] - x + (chars[i][5] / 10) * 62, chars[i][2] - y - images[i]:getHeight() / 2 + 4)
        end
        love.graphics.setLineWidth(math.sin(dtTotal) * 5)
        love.graphics.setColor(255, 255, 255)
      end
    end
    for i = 1, #enemies do
      if enemyTurn == true then love.graphics.setColor(255, 55, 55) end
      if enemies[i][2] > (rowsDown * 64) - 128 and enemies[i][2] <= (rowsDown * 64) - 64 then
        if mapRevealed[round(enemies[i][2] / 64) + 1][round(enemies[i][1] / 64) + 1] == 1 then
          love.graphics.draw(stormtrooper, enemies[i][1] - x, enemies[i][2] - y - 64)
          love.graphics.setLineWidth(4)
          love.graphics.setColor(255, 0, 0)
          love.graphics.line(enemies[i][1] - x + 2, enemies[i][2] - y - 64, enemies[i][1] - x + (enemies[i][6] / 100) * 62, enemies[i][2] - y - 64)
          love.graphics.setLineWidth(math.sin(dtTotal) * 5)
          love.graphics.setColor(255, 255, 255)
        end
      end
    end
  end

  if #lasers > 0 then
    if enemyTurn == true then love.graphics.setColor(255, 55, 55) end
    if lasers[1][6] == 1 or lasers[1][6] == 2 then
      love.graphics.draw(laser, lasers[1][1] - x + 32, lasers[1][2] - y - 32, math.atan2(lasers[1][4] - lasers[1][2], lasers[1][3] - lasers[1][1]))
    elseif lasers[1][6] == 3 then
      love.graphics.draw(rock, lasers[1][1] - x + 32, lasers[1][2] - y - 32, math.atan2(lasers[1][4] - lasers[1][2], lasers[1][3] - lasers[1][1]))
    elseif lasers[1][6] == 4 then
      love.graphics.draw(bluelaser, lasers[1][1] - x + 32, lasers[1][2] - y - 32, math.atan2(lasers[1][4] - lasers[1][2], lasers[1][3] - lasers[1][1]))
    end
  end

  if mode == 1 then
    if moveValid(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true
    and noOverlap(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true
    and enoughActions(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true then
      love.graphics.setColor(0, 255, 255, 125)
    else
      love.graphics.setColor(255, 0, 0, 125)
    end
    love.graphics.rectangle("fill", round((mX - 32 + x) / 64) * 64 - x, round((mY - 32 + y) / 64) * 64 - y, 64, 64)
    love.graphics.line(round(chars[selected][1]) - x + 32, round(chars[selected][2]) - y + 32, round((mX - 32 + x) / 64) * 64 - x + 32, round((mY - 32 + y) / 64) * 64 - y + 32)
  elseif mode == 2 then
    attackDistance = math.sqrt((round((mX - 32 + x) / 64) * 64 - round(chars[selected][1])) * (round((mX - 32 + x) / 64) * 64 - round(chars[selected][1])) + (round((mY - 32 + y) / 64) * 64 - round(chars[selected][2])) * (round((mY - 32 + y) / 64) * 64 - round(chars[selected][2])))
    if selected == 1 or selected ==3 then
      if moveValid(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true and chars[selected][5] >= 2
      and enemyOnTile(round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) and attackDistance <= 512 then
        love.graphics.setColor(0, 255, 255, 125)
      else
        love.graphics.setColor(255, 0, 0, 125)
      end
    elseif selected == 2 or selected == 4 then
      if moveValid(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true and chars[selected][5] >= 2
      and enemyOnTile(round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) and attackDistance <= 96 then
        love.graphics.setColor(0, 255, 255, 125)
      else
        love.graphics.setColor(255, 0, 0, 125)
      end
    end
    love.graphics.rectangle("fill", round((mX - 32 + x) / 64) * 64 - x, round((mY - 32 + y) / 64) * 64 - y, 64, 64)
  elseif mode == 3 then
    attackDistance = math.sqrt((round((mX - 32 + x) / 64) * 64 - round(chars[selected][1])) * (round((mX - 32 + x) / 64) * 64 - round(chars[selected][1])) + (round((mY - 32 + y) / 64) * 64 - round(chars[selected][2])) * (round((mY - 32 + y) / 64) * 64 - round(chars[selected][2])))
    if selected == 2 then
      if moveValid(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true and chars[selected][5] >= specialCost[selected]
      and enemyOnTile(round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) and attackDistance <= 512 then
        love.graphics.setColor(0, 255, 255, 125)
      else
        love.graphics.setColor(255, 0, 0, 125)
      end
    end
    if selected == 3 then
      if moveValid(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true and chars[selected][5] >= specialCost[selected]
      and enemyOnTile(round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) and attackDistance <= 1024 then
        love.graphics.setColor(0, 255, 255, 125)
      else
        love.graphics.setColor(255, 0, 0, 125)
      end
    end
    love.graphics.rectangle("fill", round((mX - 32 + x) / 64) * 64 - x, round((mY - 32 + y) / 64) * 64 - y, 64, 64)
  end
  if enemyTurn == true then
    love.graphics.setColor(255, 0, 0, 200)
    love.graphics.setFont(fontBig)
    love.graphics.print("Enemy Activity", w / 2 - 400, h / 2 - 48)
  end
  if selected == 1 then
    love.graphics.setColor(255, 255, 255, 200)
    love.graphics.setFont(font)
    love.graphics.print("Main attack: Blaster\nRanged attack that does medium damage\n\nSpecial Attack: Scout\n(Type: instant)\nReveals tiles in a large radius around itself", 0, 0)
  elseif selected == 2 then
    love.graphics.setColor(255, 255, 255, 200)
    love.graphics.setFont(font)
    love.graphics.print("Main attack: Smash\nMelee attack that deals high damage\n\nSpecial Attack: Slingshot\n(Type: Targeted)\nShoot a rock that does high damage to foes", 0, 0)
  elseif selected == 3 then
    love.graphics.setColor(255, 255, 255, 200)
    love.graphics.setFont(font)
    love.graphics.print("Main attack: Blaster\nRanged attack that does medium damage\n\nSpecial Attack: Sniper Rifle\n(Type: Targeted)\ninstantly kills an enemy", 0, 0)
  elseif selected == 4 then
    love.graphics.setColor(255, 255, 255, 200)
    love.graphics.setFont(font)
    love.graphics.print("Main attack: Slash\nMelee attack that deals high damage\n\nSpecial Attack: Heal\n(Type: instant)\nHeal all allies within a one-tile radius", 0, 0)
    end
end
