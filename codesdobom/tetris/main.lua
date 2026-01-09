-- TETRIS - LOVE2D
-- feito do zero, simples e limpo

local gridW, gridH = 10, 20
local blockSize = 30
local offsetX, offsetY = 100, 50

local grid = {}
local current, nextPiece
local timer = 0
local speed = 0.5
local gameOver = false
local score = 0

local shapes = {
    I = {
        {{1,1,1,1}},
        {{1},{1},{1},{1}}
    },
    O = {
        {{1,1},{1,1}}
    },
    T = {
        {{0,1,0},{1,1,1}},
        {{1,0},{1,1},{1,0}},
        {{1,1,1},{0,1,0}},
        {{0,1},{1,1},{0,1}}
    },
    L = {
        {{1,0},{1,0},{1,1}},
        {{1,1,1},{1,0,0}},
        {{1,1},{0,1},{0,1}},
        {{0,0,1},{1,1,1}}
    },
    J = {
        {{0,1},{0,1},{1,1}},
        {{1,0,0},{1,1,1}},
        {{1,1},{1,0},{1,0}},
        {{1,1,1},{0,0,1}}
    },
    S = {
        {{0,1,1},{1,1,0}},
        {{1,0},{1,1},{0,1}}
    },
    Z = {
        {{1,1,0},{0,1,1}},
        {{0,1},{1,1},{1,0}}
    }
}

local colors = {
    {0,1,1},{1,1,0},{0.6,0,1},
    {1,0.5,0},{0,0,1},{0,1,0},{1,0,0}
}

function newPiece()
    local keys = {}
    for k in pairs(shapes) do table.insert(keys, k) end
    local shape = shapes[keys[love.math.random(#keys)]]
    return {
        shape = shape,
        rot = 1,
        x = math.floor(gridW/2)-1,
        y = 0,
        color = colors[love.math.random(#colors)]
    }
end

function reset()
    grid = {}
    for y=1,gridH do
        grid[y] = {}
        for x=1,gridW do grid[y][x] = nil end
    end
    current = newPiece()
    nextPiece = newPiece()
    gameOver = false
    score = 0
end

function collision(px, py, rot)
    local shape = current.shape[rot]
    for y=1,#shape do
        for x=1,#shape[y] do
            if shape[y][x] == 1 then
                local gx = px + x
                local gy = py + y
                if gx < 1 or gx > gridW or gy > gridH or
                   (gy >= 1 and grid[gy][gx]) then
                    return true
                end
            end
        end
    end
    return false
end

function lockPiece()
    local shape = current.shape[current.rot]
    for y=1,#shape do
        for x=1,#shape[y] do
            if shape[y][x] == 1 then
                grid[current.y+y][current.x+x] = current.color
            end
        end
    end
end

function clearLines()
    for y=gridH,1,-1 do
        local full = true
        for x=1,gridW do
            if not grid[y][x] then full = false break end
        end
        if full then
            table.remove(grid, y)
            local newLine = {}
            for x=1,gridW do newLine[x] = nil end
            table.insert(grid, 1, newLine)
            score = score + 100
            y = y + 1
        end
    end
end

function love.load()
    love.window.setTitle("Tetris - Love2D")
    reset()
end

function love.update(dt)
    if gameOver then return end
    timer = timer + dt
    if timer >= speed then
        timer = 0
        if not collision(current.x, current.y+1, current.rot) then
            current.y = current.y + 1
        else
            lockPiece()
            clearLines()
            current = nextPiece
            nextPiece = newPiece()
            if collision(current.x, current.y, current.rot) then
                gameOver = true
            end
        end
    end
end

function love.keypressed(key)
    if gameOver and key == "r" then reset() end
    if gameOver then return end

    if key == "left" and not collision(current.x-1, current.y, current.rot) then
        current.x = current.x - 1
    elseif key == "right" and not collision(current.x+1, current.y, current.rot) then
        current.x = current.x + 1
    elseif key == "down" and not collision(current.x, current.y+1, current.rot) then
        current.y = current.y + 1
    elseif key == "up" then
        local nextRot = current.rot % #current.shape + 1
        if not collision(current.x, current.y, nextRot) then
            current.rot = nextRot
        end
    elseif key == "space" then
        while not collision(current.x, current.y+1, current.rot) do
            current.y = current.y + 1
        end
    end
end

function drawBlock(x, y, color)
    love.graphics.setColor(color)
    love.graphics.rectangle(
        "fill",
        offsetX + (x-1)*blockSize,
        offsetY + (y-1)*blockSize,
        blockSize-1, blockSize-1
    )
end

function love.draw()
    love.graphics.setColor(1,1,1)
    love.graphics.print("Score: "..score, 10, 10)

    -- grid
    for y=1,gridH do
        for x=1,gridW do
            if grid[y][x] then
                drawBlock(x,y,grid[y][x])
            end
        end
    end

    -- current piece
    local shape = current.shape[current.rot]
    for y=1,#shape do
        for x=1,#shape[y] do
            if shape[y][x] == 1 then
                drawBlock(current.x+x, current.y+y, current.color)
            end
        end
    end

    if gameOver then
        love.graphics.setColor(1,0,0)
        love.graphics.print("GAME OVER\nPressione R", 120, 300)
    end
end
