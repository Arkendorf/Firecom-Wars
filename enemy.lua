playersSpotted = {}

function newEnemy(x, y)
  table.insert(enemies, {x, y, x, y, 10, 100})
  table.insert(enemyMove, {0, 0, 0})
  table.insert(playersSpotted, {0, 0, 0, 0})
end

function spotPlayers(i)
  distanceToPlayers = {}
  for char = 1, 4 do
    distanceToPlayers[char] = {char, math.sqrt((chars[char][3] - enemies[i][1]) * (chars[char][3] - enemies[i][1]) + (chars[char][4] - enemies[i][2]) * (chars[char][4] - enemies[i][2]))}
    if distanceToPlayers[char][2] < 512 and dead[i] ~= 1 then
      playersSpotted[i][char] = 1
    end
  end
end

function getEnemyMoves(i)
  validMoves = {}
  if playersSpotted[i][1] == 0 and playersSpotted[i][2] == 0 and playersSpotted[i][3] == 0 and playersSpotted[i][4] == 0  then
    return
  end
  table.sort(distanceToPlayers, function(a, b) return a[2] < b[2] end)
  for rowsDown = 0, #map - 1 do
    for tilesAcross = 0, #map[1] - 1 do
      moveDistance = math.sqrt((tilesAcross * 64 - enemies[i][1]) * (tilesAcross * 64 - enemies[i][1]) + (rowsDown * 64 - enemies[i][2]) * (rowsDown * 64 - enemies[i][2]))
      if moveValid(enemies[i][1], enemies[i][2], tilesAcross * 64, rowsDown * 64) == true and noOverlap(enemies[i][1], enemies[i][2], tilesAcross * 64, rowsDown * 64) == true
      and round(moveDistance / 64) <= 10 then
        table.insert(validMoves, {tilesAcross * 64, rowsDown * 64, round(moveDistance / 64)})
      end
    end
  end
end

function chooseEnemyMove(i)
  enemies[i][5] = 10
  if #validMoves < 1 then
    return
  end
  tilesToMove = round((distanceToPlayers[1][2] - 256) / 64)
    if tilesToMove > 0 or moveValid(enemies[i][3], enemies[i][4], chars[distanceToPlayers[1][1]][3], chars[distanceToPlayers[1][1]][4]) == false then
    table.sort(validMoves, function(a, b) return a[3] < b[3] end)
    for range = tilesToMove, 10 do
      for move = 1, #validMoves do
        distanceToPlayer = math.sqrt((chars[distanceToPlayers[1][1]][3] - validMoves[move][1]) * (chars[distanceToPlayers[1][1]][3] - validMoves[move][1]) + (chars[distanceToPlayers[1][1]][4] - validMoves[move][2]) * (chars[distanceToPlayers[1][1]][4] - validMoves[move][2]))
        if validMoves[move][3] == range and distanceToPlayer < distanceToPlayers[1][2] and moveValid(validMoves[move][1], validMoves[move][2], chars[distanceToPlayers[1][1]][3], chars[distanceToPlayers[1][1]][4]) then
          enemies[i][5] = enemies[i][5] - validMoves[move][3]
          enemies[i][3] = validMoves[move][1]
          enemies[i][4] = validMoves[move][2]
          enemyMove[i][3] = validMoves[move][3] * 16
          enemyMove[i][1] = (validMoves[move][1] - enemies[i][1]) / enemyMove[i][3]
          enemyMove[i][2] = (validMoves[move][2] - enemies[i][2]) / enemyMove[i][3]
          return
        end
      end
    end
    for range = tilesToMove, 0, -1 do
      for move = 1, #validMoves do
        if validMoves[move][3] == range and distanceToPlayer < distanceToPlayers[1][2] and moveValid(validMoves[move][1], validMoves[move][2], chars[distanceToPlayers[1][1]][3], chars[distanceToPlayers[1][1]][4]) then
          enemies[i][5] = enemies[i][5] - validMoves[move][3]
          enemies[i][3] = validMoves[move][1]
          enemies[i][4] = validMoves[move][2]
          enemyMove[i][3] = validMoves[move][3] * 16
          enemyMove[i][1] = (validMoves[move][1] - enemies[i][1]) / enemyMove[i][3]
          enemyMove[i][2] = (validMoves[move][2] - enemies[i][2]) / enemyMove[i][3]
          return
        end
      end
    end
  end
end

function enemyAttack(i)
  if moveValid(enemies[i][3], enemies[i][4], chars[distanceToPlayers[1][1]][3], chars[distanceToPlayers[1][1]][4]) and enemies[i][5] > 0 then
    for attacks = enemies[i][5], 2, -2 do
      newLaser(enemies[i][3], enemies[i][4], chars[distanceToPlayers[1][1]][3], chars[distanceToPlayers[1][1]][4], distanceToPlayers[1][1])
    end
  elseif enemies[i][5] > 4 then
    for char = 1, 4 do
      if playersSpotted[i][char] == 1 then
        for enemy = 1, #enemies do
          playersSpotted[enemy][char] = 1
        end
      end
    end
  end
end
