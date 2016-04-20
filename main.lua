function generateMap(size) -- temporary till we have a handcrafted one
  map = {}
  mapRevealed = {}
  for rowsDown = 1, size do
    map[rowsDown] = {}
    mapRevealed[rowsDown] = {}
    for tilesAcross = 1, size do
      map[rowsDown][tilesAcross] = 1
      mapRevealed[rowsDown][tilesAcross] = 0
    end
  end
end

function love.load()

  require("enemy")

  love.window.setFullscreen(true)

  tiles = {}
  tileset = love.graphics.newImage("tileset.png")
  for rowsDown = 0, (tileset:getHeight() / 64) - 1 do
    for tilesAcross = 0, (tileset:getWidth() / 64) - 1 do
      tiles[rowsDown * (tileset:getWidth() / 64) + tilesAcross + 1] = love.graphics.newQuad(tilesAcross * 64, rowsDown * 64, 64, 64, tileset:getDimensions())
    end
  end

  scout = love.graphics.newImage("scout.png")
  scout1 = love.graphics.newQuad(64, 0, 64, 96, scout:getDimensions())

  dtTotal = 0

  w = love.graphics.getWidth ()
  h = love.graphics.getHeight ()

  generateMap(50)
  map[3][3] = 2 -- TO TEST WALLS!
  tileType = {0, 1}
  x = 0
  xV = 0
  y = 0
  yV = 0
  dX = 0
  dY = 0
  selected = 1 -- 1 is scout
  chars = {{0, 0, 0, 0, 10}, {0, 64, 0, 64, 10}, {64, 0, 64, 0, 10}, {64, 64, 64, 64, 10}}
  charMove = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}}
  enemies = {{256, 256, 256, 256, 10}}
  enemyMove = {{0, 0, 0}}
  orderE = {}
end

function round(n, deci) deci = 10^(deci or 0) return math.floor(n*deci+.5)/deci end

function noOverlap(x1, y1, x2, y2)
  for i = 1, 4 do
    if x2 == round(chars[i][1]) and y2 == round(chars[i][2]) then
      return false
    end
  end
  for i = 1, #enemies do
    if x2 == round(enemies[i][1]) and y2 == round(enemies[i][2]) then
      return false
    end
  end
  distance = math.sqrt((y2 - y1) * (y2 - y1) + (x2 - x1) * (x2 - x1))
  return true
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
          if x2 >= x1 and tilesAcross * 64 >= x1 then
          elseif x2 <= x1 and tilesAcross * 64 <= x1 then
          else
            return true
          end
          if y2 >= y1 and rowsDown * 64 >= y1 then
          elseif y2 <= y1 and rowsDown * 64 <= y1 then
          else
            return true
          end
          return false
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
  end

  for i = 1, #enemies do
    moveEnemy(i)
  end

  if chars[1][5] == 0 and chars[2][5] == 0 and chars[3][5] == 0 and chars[4][5] == 0 then
    chars[1][5] = 10
    chars[2][5] = 10
    chars[3][5] = 10
    chars[4][5] = 10
    for i = 1, #enemies do
      spotPlayers(i)
      getEnemyMoves(i)
      chooseEnemyMove(i)
    end
  end

  love.graphics.setLineWidth(math.sin(dtTotal) * 5)


  if love.keyboard.isDown("escape") then
    love.event.quit()
  end
end

function love.mousepressed(mX, mY, button)
  if chars[selected][3] - chars[selected][1] < 1 and chars[selected][4] - chars[selected][2] < 0.5 then
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
  end
end

function love.keypressed(key)
  if key == "tab" then
    selected = selected + 1
    if selected == 5 then
      selected = 1
    end
    x = chars[selected][1] - round(w / 2)
    y = chars[selected][2] - round(h / 2)
  end
end

function love.draw()
  love.graphics.setColor(255, 255, 255)
  for rowsDown = 1, #map do
    for tilesAcross = 1, #map[1] do
      if mapRevealed[rowsDown][tilesAcross] == 1 then
        love.graphics.draw(tileset, tiles[map[rowsDown][tilesAcross]], (tilesAcross - 1) * 64 - x, (rowsDown - 1) * 64 - y)
      end
    end
  end

  orderC = {{scout, scout1, chars[1][1] - x, chars[1][2] - y - 32}, {scout, scout1, chars[2][1] - x, chars[2][2] - y - 32}, {scout, scout1, chars[3][1] - x, chars[3][2] - y - 32}, {scout, scout1, chars[4][1] - x, chars[4][2] - y - 32}}
  table.sort(orderC, function(a, b) return a[4] < b[4] end)

  for i = 1, #enemies do
    table.insert(orderE, {scout, scout1, enemies[i][1] - x, enemies[i][2] - y - 32})
  end
  table.sort(orderE, function(a, b) return a[4] < b[4] end)

  for i = 1, 4 do  -- Players
    love.graphics.draw(orderC[i][1], orderC[i][2], orderC[i][3], orderC[i][4])
  end

  for i = 1, #orderE do -- Enemies
    if mapRevealed[round((orderE[i][4] + y + 32) / 64)][round((orderE[i][3] + x) / 64)] == 1 then
      love.graphics.draw(orderE[i][1], orderE[i][2], orderE[i][3], orderE[i][4])
    end
  end

  if moveValid(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true
  and noOverlap(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true
  and enoughActions(round(chars[selected][1]), round(chars[selected][2]), round((mX - 32 + x) / 64) * 64, round((mY - 32 + y) / 64) * 64) == true then
    love.graphics.setColor(0, 255, 255, 125)
  else
    love.graphics.setColor(255, 0, 0, 125)
  end

  love.graphics.rectangle("fill", round((mX - 32 + x) / 64) * 64 - x, round((mY - 32 + y) / 64) * 64 - y, 64, 64)
  love.graphics.line(round(chars[selected][1]) - x + 32, round(chars[selected][2]) - y + 32, round((mX - 32 + x) / 64) * 64 - x + 32, round((mY - 32 + y) / 64) * 64 - y + 32)
end
