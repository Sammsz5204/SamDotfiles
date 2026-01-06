-- MINI BATTLE ROYALE - LOVE2D (MELHORADO)







--------------------------------
-- Basicamente Resizable UI and game
--------------------------------

ui = {
    w = 0,
    h = 0,
    targetW = 0,
    targetH = 0
}


function love.resize(w, h)
    ui.w  = w
    ui.h = h

    ui.targetW = w
    ui.targetH = h
end


MAP_WIDTH  = 5000
MAP_HEIGHT = 5000

--------------------------------
-- PLAYER
--------------------------------
player = {
    x = MAP_WIDTH/2,
    y = MAP_HEIGHT/2,
    speed = 250,
    radius = 15,

    life = 100,
    maxLife = 100,

    materials = 100,
    maxMaterials = 999,
    medkits = 3,

    buildCooldown = 0,
    buildRotation = 0,
    mode = "gun",
    
    damageFlash = 0,
    kills = 0
}

--------------------------------
-- CAMERA
--------------------------------
camera = {
    x = 0, y = 0,
    width = 1280, height = 720
}

--------------------------------
-- TABLES
--------------------------------
walls = {}
bullets = {}
enemyBullets = {}
enemies = {}
particles = {}

--------------------------------
-- GAME STATE
--------------------------------
gameState = "playing" -- "playing" | "won" | "lost"
gameTimer = 0

--------------------------------
-- WEAPONS
--------------------------------
weapons = {
    { name="Pistol",  cooldown=0.4, speed=600, damage=20, spread=0,   pellets=1, color={1,1,0} },
    { name="Rifle",   cooldown=0.15,speed=800, damage=10, spread=0,   pellets=1, color={0,1,1} },
    { name="Shotgun", cooldown=0.8, speed=500, damage=8,  spread=0.5, pellets=6, color={1,0.5,0} }
}
currentWeapon = 1
shootTimer = 0

--------------------------------
-- SAFE ZONE
--------------------------------
safeZone = {
    x = MAP_WIDTH/2,
    y = MAP_HEIGHT/2,
    radius = MAP_WIDTH/2,
    targetRadius = 300,
    shrinkSpeed = 8,
    damage = 15
}

--------------------------------
-- LOAD
--------------------------------
function love.load()
    love.window.setTitle("Mini Battle Royale")
    math.randomseed(os.time())

    ui.w = love.graphics.getWidth()
    ui.h = love.graphics.getHeight()
    ui.targetW = ui.w
    ui.targetH = ui.h

    camera.width  = ui.w
    camera.height = ui.h

    for i=1,40 do spawnBot() end
end


--------------------------------
-- UPDATE
--------------------------------
function love.update(dt)

    ui.w = ui.w + (ui.targetW - ui.w) * math.min(1, dt * 10)
    ui.h = ui.h + (ui.targetH - ui.h) * math.min(1, dt * 10)


    if gameState ~= "playing" then
        if love.keyboard.isDown("r") then
            resetGame()
        end
        return
    end

    gameTimer = gameTimer + dt
    shootTimer = math.max(0, shootTimer - dt)
    player.buildCooldown = math.max(0, player.buildCooldown - dt)
    player.damageFlash = math.max(0, player.damageFlash - dt * 3)

    updatePlayer(dt)
    updateStorm(dt)

    updateBullets(bullets, dt, enemies, true)
    updateBullets(enemyBullets, dt, {player}, false)

    for i=#enemies,1,-1 do
        updateBot(enemies[i], dt)
        if enemies[i].life <= 0 then
            createParticles(enemies[i].x, enemies[i].y, 10, {1,0,0})
            player.kills = player.kills + 1
            table.remove(enemies, i)
        end
    end

    updateParticles(dt)

    camera.x = clamp(player.x - ui.w/2, 0, MAP_WIDTH  - ui.w)
    camera.y = clamp(player.y - ui.h/2,0, MAP_HEIGHT - ui.h)

    -- Condições de vitória/derrota
    if player.life <= 0 then
        gameState = "lost"
    elseif #enemies == 0 then
        gameState = "won"
    end
end

--------------------------------
-- PLAYER
--------------------------------
function updatePlayer(dt)
    local ox, oy = player.x, player.y
    local moved = false

    if love.keyboard.isDown("w") then player.y = player.y - player.speed * dt; moved = true end
    if love.keyboard.isDown("s") then player.y = player.y + player.speed * dt; moved = true end
    if love.keyboard.isDown("a") then player.x = player.x - player.speed * dt; moved = true end
    if love.keyboard.isDown("d") then player.x = player.x + player.speed * dt; moved = true end

    -- Colisão com limites do mapa
    player.x = clamp(player.x, player.radius, MAP_WIDTH - player.radius)
    player.y = clamp(player.y, player.radius, MAP_HEIGHT - player.radius)

    -- Colisão com paredes
    for _,w in ipairs(walls) do
        if circleRect(player.x, player.y, player.radius, w) then
            player.x, player.y = ox, oy
            break
        end
    end

    if player.mode == "gun" then
        if love.mouse.isDown(1) and shootTimer <= 0 then
            shoot()
        end
    end
end

--------------------------------
-- BUILD
--------------------------------
function getBuildPreview()
    local mx, my = love.mouse.getPosition()
    local wx, wy = mx + camera.x, my + camera.y
    local a = math.atan2(wy - player.y, wx - player.x)

    local w, h = 20, 80
    if player.buildRotation == 1 then
        w, h = 80, 20
    end

    local bx = player.x + math.cos(a)*60 - w/2
    local by = player.y + math.sin(a)*60 - h/2

    return {
        x = bx,
        y = by,
        w = w,
        h = h
    }
end

function canBuild(bx, by, bw, bh)
    -- Verifica se está muito perto de outras paredes
    for _,w in ipairs(walls) do
        if rectsOverlap(bx, by, bw, bh, w.x, w.y, w.w, w.h) then
            return false
        end
    end
    return true
end

function buildWall(x,y,w,h)
    table.insert(walls, {
        x=x, y=y, w=w, h=h,
        life=150,
        maxLife=150
    })
end

--------------------------------
-- BOTS
--------------------------------
function spawnBot()
    local attempts = 0
    local bx, by
    
    repeat
        bx = math.random(100, MAP_WIDTH-100)
        by = math.random(100, MAP_HEIGHT-100)
        attempts = attempts + 1
    until attempts > 20 or distance(bx, by, player.x, player.y) > 200

    table.insert(enemies,{
        x = bx,
        y = by,
        size = 20,
        speed = 100,
        life = 80,
        maxLife = 80,
        shootTimer = math.random(0.5, 1.5),
        buildTimer = math.random(2, 4),
        moveTimer = 0,
        strafeDir = math.random() > 0.5 and 1 or -1
    })
end

function updateBot(e, dt)
    local dx, dy = player.x - e.x, player.y - e.y
    local d = math.sqrt(dx*dx + dy*dy)
    local ox, oy = e.x, e.y

    if d > 0 and d < 500 then
        -- Movimento mais inteligente
        local moveX, moveY = dx/d, dy/d
        
        -- Strafe ocasionalmente
        e.moveTimer = e.moveTimer + dt
        if e.moveTimer > 2 then
            e.strafeDir = -e.strafeDir
            e.moveTimer = 0
        end
        
        if d < 200 then
            -- Muito perto: recua com strafe
            moveX = -moveX + moveY * e.strafeDir * 0.5
            moveY = -moveY - dx/d * e.strafeDir * 0.5
        elseif d > 350 then
            -- Muito longe: avança
            moveX = moveX
            moveY = moveY
        else
            -- Distância ideal: strafe
            moveX = moveY * e.strafeDir
            moveY = -dx/d * e.strafeDir
        end
        
        local len = math.sqrt(moveX*moveX + moveY*moveY)
        if len > 0 then
            e.x = e.x + (moveX/len) * e.speed * dt
            e.y = e.y + (moveY/len) * e.speed * dt
        end
        
        -- Colisão com paredes
        for _,w in ipairs(walls) do
            if circleRect(e.x, e.y, e.size/2, w) then
                e.x, e.y = ox, oy
                break
            end
        end
        
        -- Colisão com limites
        e.x = clamp(e.x, e.size, MAP_WIDTH - e.size)
        e.y = clamp(e.y, e.size, MAP_HEIGHT - e.size)
    end

    -- Construir apenas se tiver linha de visão
    e.buildTimer = e.buildTimer - dt
    if e.buildTimer <= 0 and d < 250 and hasLineOfSight(e.x, e.y, player.x, player.y) then
        local angle = math.atan2(dy, dx)
        local bx = e.x + math.cos(angle) * 30 - 10
        local by = e.y + math.sin(angle) * 30 - 30
        if canBuild(bx, by, 20, 60) then
            buildWall(bx, by, 20, 60)
        end
        e.buildTimer = math.random(3, 5)
    end

    -- Atirar com mais precisão
    e.shootTimer = e.shootTimer - dt
    if e.shootTimer <= 0 and d < 400 then
        local a = math.atan2(dy, dx) + (math.random()-0.5)*0.2
        table.insert(enemyBullets,{
            x=e.x, y=e.y,
            dx=math.cos(a)*450,
            dy=math.sin(a)*450,
            damage=12
        })
        e.shootTimer = math.random(1.2, 1.8)
    end
end

function hasLineOfSight(x1, y1, x2, y2)
    for _,w in ipairs(walls) do
        if lineRectIntersect(x1, y1, x2, y2, w) then
            return false
        end
    end
    return true
end

--------------------------------
-- STORM
--------------------------------
function updateStorm(dt)
    safeZone.radius = math.max(
        safeZone.targetRadius,
        safeZone.radius - safeZone.shrinkSpeed * dt
    )

    local d = distance(player.x, player.y, safeZone.x, safeZone.y)
    if d > safeZone.radius then
        player.life = player.life - safeZone.damage * dt
        player.damageFlash = 0.5
    end

    -- Dano aos bots na tempestade
    for _,e in ipairs(enemies) do
        local ed = distance(e.x, e.y, safeZone.x, safeZone.y)
        if ed > safeZone.radius then
            e.life = e.life - safeZone.damage * dt
        end
    end

    player.life = math.max(0, player.life)
end

--------------------------------
-- SHOOT
--------------------------------
function shoot()
    local w = weapons[currentWeapon]
    shootTimer = w.cooldown

    local mx,my = love.mouse.getPosition()
    local wx,wy = mx + camera.x, my + camera.y
    local a = math.atan2(wy - player.y, wx - player.x)

    for i=1,w.pellets do
        local ang = a + (math.random()-0.5)*w.spread
        table.insert(bullets,{
            x=player.x, y=player.y,
            dx=math.cos(ang)*w.speed,
            dy=math.sin(ang)*w.speed,
            damage=w.damage,
            color=w.color
        })
    end
    
    createParticles(player.x + math.cos(a)*20, player.y + math.sin(a)*20, 3, w.color)
end

--------------------------------
-- BULLETS
--------------------------------
function updateBullets(list, dt, targets, isPlayer)
    for i=#list,1,-1 do
        local b = list[i]
        b.x = b.x + b.dx * dt
        b.y = b.y + b.dy * dt

        -- Remove balas fora do mapa
        if b.x < 0 or b.x > MAP_WIDTH or b.y < 0 or b.y > MAP_HEIGHT then
            table.remove(list, i)
            goto continue
        end

        -- Colisão com paredes
        for j=#walls,1,-1 do
            local w = walls[j]
            if b.x>w.x and b.x<w.x+w.w and b.y>w.y and b.y<w.y+w.h then
                w.life = w.life - b.damage
                if w.life <= 0 then
                    createParticles(w.x + w.w/2, w.y + w.h/2, 8, {0.6,0.4,0.2})
                    if isPlayer and math.random() > 0.5 then
                        player.materials = math.min(player.maxMaterials, player.materials + 10)
                    end
                    table.remove(walls, j)
                end
                createParticles(b.x, b.y, 3, {0.8,0.8,0.8})
                table.remove(list,i)
                goto continue
            end
        end

        -- Colisão com alvos
        for j=#targets,1,-1 do
            local t = targets[j]
            local r = t.radius or t.size/2
            if distance(b.x,b.y,t.x,t.y) < r then
                t.life = t.life - b.damage
                if not isPlayer then
                    player.damageFlash = 1
                end
                createParticles(b.x, b.y, 5, {1,0,0})
                table.remove(list,i)
                break
            end
        end
        ::continue::
    end
end

--------------------------------
-- PARTICLES
--------------------------------
function createParticles(x, y, count, color)
    for i=1,count do
        table.insert(particles, {
            x = x,
            y = y,
            vx = (math.random()-0.5)*200,
            vy = (math.random()-0.5)*200,
            life = 0.5,
            color = color
        })
    end
end

function updateParticles(dt)
    for i=#particles,1,-1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 400 * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        end
    end
end

--------------------------------
-- DRAW
--------------------------------
function love.draw()
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    -- Mapa
    love.graphics.setColor(0.25,0.6,0.25)
    love.graphics.rectangle("fill",0,0,MAP_WIDTH,MAP_HEIGHT)

    -- Grid
    love.graphics.setColor(0.2,0.5,0.2,0.3)
    for x=0,MAP_WIDTH,100 do
        love.graphics.line(x, 0, x, MAP_HEIGHT)
    end
    for y=0,MAP_HEIGHT,100 do
        love.graphics.line(0, y, MAP_WIDTH, y)
    end

    -- Safe zone
    love.graphics.setColor(0,0.5,1,0.15)
    love.graphics.circle("fill", safeZone.x, safeZone.y, safeZone.radius)
    love.graphics.setColor(0,0.3,1,0.6)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", safeZone.x, safeZone.y, safeZone.radius)
    love.graphics.setLineWidth(1)

    -- Build preview
    if player.mode=="build" and player.materials>=10 then
        local p = getBuildPreview()
        local canPlace = canBuild(p.x, p.y, p.w, p.h)
        love.graphics.setColor(canPlace and 0.5 or 1, canPlace and 1 or 0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", p.x, p.y, p.w, p.h)
        love.graphics.setColor(1,1,1,0.8)
        love.graphics.rectangle("line", p.x, p.y, p.w, p.h)
    end

    -- Walls
    for _,w in ipairs(walls) do
        local health = w.life / w.maxLife
        love.graphics.setColor(0.6,0.4,0.2)
        love.graphics.rectangle("fill", w.x, w.y, w.w, w.h)
        love.graphics.setColor(0.3,0.2,0.1)
        love.graphics.rectangle("line", w.x, w.y, w.w, w.h)
        
        -- Barra de vida da parede
        if health < 1 then
            love.graphics.setColor(1,0,0)
            love.graphics.rectangle("fill", w.x, w.y-5, w.w * health, 3)
        end
    end

    -- Player
    if player.damageFlash > 0 then
        love.graphics.setColor(1, 0.3, 0.3)
    else
        love.graphics.setColor(0.2,0.5,0.8)
    end
    love.graphics.circle("fill", player.x, player.y, player.radius)
    love.graphics.setColor(0.1,0.3,0.5)
    love.graphics.circle("line", player.x, player.y, player.radius)
    
    -- Direção do player
    local mx, my = love.mouse.getPosition()
    local wx, wy = mx + camera.x, my + camera.y
    local a = math.atan2(wy - player.y, wx - player.x)
    love.graphics.setColor(1,1,1)
    love.graphics.line(player.x, player.y, 
        player.x + math.cos(a)*player.radius, 
        player.y + math.sin(a)*player.radius)

    -- Enemies
    for _,e in ipairs(enemies) do
        love.graphics.setColor(0.8,0.2,0.2)
        love.graphics.rectangle("fill", e.x-e.size/2, e.y-e.size/2, e.size, e.size)
        love.graphics.setColor(0.5,0.1,0.1)
        love.graphics.rectangle("line", e.x-e.size/2, e.y-e.size/2, e.size, e.size)
        
        -- Barra de vida
        love.graphics.setColor(0,0,0)
        love.graphics.rectangle("fill", e.x-e.size/2, e.y-e.size/2-8, e.size, 4)
        love.graphics.setColor(0,1,0)
        love.graphics.rectangle("fill", e.x-e.size/2, e.y-e.size/2-8, e.size * (e.life/e.maxLife), 4)
    end

    -- Bullets
    for _,b in ipairs(bullets) do
        love.graphics.setColor(b.color or {1,1,0})
        love.graphics.circle("fill", b.x, b.y, 3)
    end

    for _,b in ipairs(enemyBullets) do
        love.graphics.setColor(1,0.3,0.3)
        love.graphics.circle("fill", b.x, b.y, 3)
    end

    -- Particles
    for _,p in ipairs(particles) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.life)
        love.graphics.circle("fill", p.x, p.y, 2)
    end

    love.graphics.pop()
    drawUI()
    
    if gameState ~= "playing" then
        drawGameOver()
    end
end

--------------------------------
-- UI
--------------------------------
function drawUI()
    local lifePercent = math.max(0, math.min(1, player.life / player.maxLife))

    -- Barra de vida
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill", 18,18,204,24)
    love.graphics.setColor(0.3,0,0)
    love.graphics.rectangle("fill", 20,20,200,20)
    love.graphics.setColor(1-lifePercent,lifePercent,0)
    love.graphics.rectangle("fill", 20,20,200*lifePercent,20)
    love.graphics.setColor(1,1,1)
    love.graphics.print(string.format("HP: %d/%d", math.floor(player.life), player.maxLife), 25, 23)

    -- Info
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill", 18, 48, 200, 100)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Mode: "..player.mode:upper(), 25, 55)
    love.graphics.print("Materials: "..player.materials, 25, 75)
    love.graphics.print("Medkits: "..player.medkits.." (E)", 25, 95)
    love.graphics.print("Kills: "..player.kills, 25, 115)
    love.graphics.print("Enemies: "..#enemies, 25, 135)

    -- Controles
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill", ui.w-218, 18, 200, 80)
    love.graphics.setColor(1,1,1)
    love.graphics.print("TAB: Trocar modo", ui.w-213, 25)
    love.graphics.print("Q: Construir", ui.w-213, 45)
    love.graphics.print("R: Rotacionar", ui.w-213, 65)
    love.graphics.print("1,2,3: Armas", ui.w-213, 85)

    -- Armas
    for i,w in ipairs(weapons) do
        local selected = (i == currentWeapon)
        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill", 248+i*85, 548, 76, 46)
        
        if selected then
            love.graphics.setColor(1,1,0)
        else
            love.graphics.setColor(0.5,0.5,0.5)
        end
        love.graphics.rectangle("line", 250+i*85, 550, 72, 42)
        love.graphics.print(w.name, 255+i*85, 560)
        love.graphics.print(i, 255+i*85, 575)
    end

    -- Safe zone timer
    local shrinkPercent = (safeZone.radius - safeZone.targetRadius) / (MAP_WIDTH/2 - safeZone.targetRadius)
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill", ui.w/2-102, ui.h-42, 204, 24)
    love.graphics.setColor(0.5,0,0.5)
    love.graphics.rectangle("fill", ui.w/2-100, ui.h-40, 200, 20)
    love.graphics.setColor(0.8,0,0.8)
    love.graphics.rectangle("fill", ui.w/2-100, ui.h-40, 200*shrinkPercent, 20)
    love.graphics.setColor(1,1,1)
    love.graphics.print("ZONA SEGURA", ui.w/2-45, ui.h-37)
end

function drawGameOver()
    love.graphics.setColor(0,0,0,0.8)
    love.graphics.rectangle("fill", 0, 0, ui.w, ui.h)
    
    love.graphics.setColor(1,1,1)
    love.graphics.printf(
        gameState == "won" and "VITÓRIA!" or "DERROTA!",
        0, ui.h/2 - 60, ui.w, "center"
    )
    
    love.graphics.printf(
        string.format("Kills: %d\nTempo: %.1fs", player.kills, gameTimer),
        0, ui.h/2, ui.w, "center"
    )
    
    love.graphics.printf(
        "Pressione R para reiniciar",
        0, ui.h/2 + 60, ui.w, "center"
    )
end

--------------------------------
-- INPUT
--------------------------------
function love.keypressed(k)
    if gameState ~= "playing" then return end

    if k=="tab" then
        player.mode = (player.mode=="gun") and "build" or "gun"
    end

    if k=="r" then
        player.buildRotation = 1 - player.buildRotation
    end

    if k=="q" and player.mode=="build" and player.buildCooldown<=0 and player.materials>=10 then
        local p = getBuildPreview()
        if canBuild(p.x, p.y, p.w, p.h) then
            buildWall(p.x,p.y,p.w,p.h)
            player.materials = player.materials - 10
            player.buildCooldown = 0.25
        end
    end

    if k=="e" and player.medkits>0 then
        player.life = math.min(player.maxLife, player.life+50)
        player.medkits = player.medkits - 1
    end

    if k=="1" then currentWeapon=1 end
    if k=="2" then currentWeapon=2 end
    if k=="3" then currentWeapon=3 end
end

--------------------------------
-- RESET
--------------------------------
function resetGame()
    player.x = MAP_WIDTH/2
    player.y = MAP_HEIGHT/2
    player.life = player.maxLife
    player.materials = 100
    player.medkits = 3
    player.kills = 0
    
    walls = {}
    bullets = {}
    enemyBullets = {}
    enemies = {}
    particles = {}
    
    safeZone.radius = MAP_WIDTH/2
    gameState = "playing"
    gameTimer = 0
    
    for i=1,5 do spawnBot() end
end

--------------------------------
-- UTILS
--------------------------------
function distance(x1,y1,x2,y2)
    return math.sqrt((x2-x1)^2+(y2-y1)^2)
end

function clamp(v,a,b)
    return math.max(a, math.min(b,v))
end

function circleRect(cx,cy,r,w)
    local x = clamp(cx, w.x, w.x+w.w)
    local y = clamp(cy, w.y, w.y+w.h)
    return (cx-x)^2 + (cy-y)^2 < r*r
end

function rectsOverlap(x1,y1,w1,h1,x2,y2,w2,h2)
    return x1 < x2+w2 and x2 < x1+w1 and y1 < y2+h2 and y2 < y1+h1
end

function lineRectIntersect(x1,y1,x2,y2,rect)
    -- Algoritmo simplificado de interseção linha-retângulo
    local left = rect.x
    local right = rect.x + rect.w
    local top = rect.y
    local bottom = rect.y + rect.h
    
    -- Verifica se algum ponto está dentro
    if (x1 >= left and x1 <= right and y1 >= top and y1 <= bottom) or
       (x2 >= left and x2 <= right and y2 >= top and y2 <= bottom) then
        return true
    end
    
    return false
end