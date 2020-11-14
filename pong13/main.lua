Class = require 'class'
push = require 'push'

require 'Ball'
require 'Paddle'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200
MOMENTUM = 1.1

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.window.setTitle('Pong')

    math.randomseed(os.time())

    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 24)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    love.graphics.setFont(smallFont)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = true
    })

    player1Score = 0
    player2Score = 0

    servingPlayer = math.random(2) == 1 and 1 or 2

    player1 = Paddle(5, 20, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH-10, VIRTUAL_HEIGHT-30, 5, 20)
    ball = Ball(VIRTUAL_WIDTH/2-2, VIRTUAL_HEIGHT/2-2, 5, 5)

    needAI1 = false
    needAI2 = false
    gameState = 'start'
end

function love.resize(w, h)
    push:resize(w,h)
end

function love.update(dt)
    if gameState == 'start' then
        player1.x = 5
        player1.y = 20
        player2.x = VIRTUAL_WIDTH-10
        player2.y = VIRTUAL_HEIGHT-30

    elseif gameState == 'serve' then
        if servingPlayer == 1 then
            ball.dx = 100
        else
            ball.dx = -100
        end

    elseif gameState == 'play' then

        if ball.x <= 0 then
            player2Score = player2Score + 1
            servingPlayer = 1
            
            sounds['score']:play()

            ball:reset()
            
            if player2Score >= 10 then
                gameState ='victory'
                winningPlayer = 2
            else
                gameState = 'serve'
            end
        end

        if ball.x >= VIRTUAL_WIDTH-4 then
            player1Score = player1Score + 1
            servingPlayer = 2

            sounds['score']:play()

            ball:reset()
            
            if player1Score >= 10 then
                gameState ='victory'
                winningPlayer = 1
            else
                gameState = 'serve'
            end
        end

        if ball:collides(player1) then
            ball.dx = -ball.dx * MOMENTUM
            ball.x = player1.x + 5

            sounds['paddle_hit']:play()

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10,150)
            end
        end

        if ball:collides(player2) then
            ball.dx = -ball.dx * MOMENTUM
            ball.x = player2.x - 5

            sounds['paddle_hit']:play()

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10,150)
            end
        end

        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy

            sounds['wall_hit']:play()
        end

        if ball.y >= VIRTUAL_HEIGHT-4 then
            ball.y = VIRTUAL_HEIGHT-4
            ball.dy = -ball.dy

            sounds['wall_hit']:play()
        end

        if needAI1 == false then
            if love.keyboard.isDown('w') then
                player1.dy = -PADDLE_SPEED
            elseif love.keyboard.isDown('s') then
                player1.dy = PADDLE_SPEED
            else
                player1.dy = 0
            end
        elseif needAI1 == true then
            if ball.x < VIRTUAL_WIDTH/2 then
                if player1.y > (ball.y + ball.height/2) then
                    player1.dy = -PADDLE_SPEED
                elseif (player1.y + player1.height/2) < (ball.y + ball.height/2) then
                    player1.dy = PADDLE_SPEED
                else
                    player1.dy = 0
                end
            end
        end

        if needAI2 == false then
            if love.keyboard.isDown('i') then
                player2.dy = -PADDLE_SPEED
            elseif love.keyboard.isDown('k') then
                player2.dy = PADDLE_SPEED
            else
                player2.dy = 0
            end
        elseif needAI2 == true then
            if ball.x > VIRTUAL_WIDTH/2 then
                if player2.y > (ball.y + ball.height/2) then
                    player2.dy = -PADDLE_SPEED
                elseif (player2.y + player2.height/2) < (ball.y + ball.height/2) then
                    player2.dy = PADDLE_SPEED
                else
                    player2.dy = 0
                end
            end
        end

        if gameState == 'play' then
            ball:update(dt)
        end

        player1:update(dt)
        player2:update(dt)
    end
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif gameState == 'start' then
        if key == '1' then
            gameState = 'pvp'
            needAI1 = false
            needAI2 = false
        elseif key == '2' then
            gameState = 'pvcpu'
            needAI1 = false
            needAI2 = true
        elseif key == '3' then
            gameState = 'cpuvcpu'
            needAI1 = true
            needAI2 = true
        end
    elseif key == 'backspace' then
        if gameState == 'pvp' or gameState == 'pvcpu' or gameState == 'cpuvcpu' then
            gameState = 'start'
        end
    elseif key == 'enter' or key == 'return' then
        if gameState == 'pvp' or gameState == 'pvcpu' or gameState == 'cpuvcpu' then
            gameState = 'serve'
        elseif gameState == 'victory' then
            gameState = 'start'
            player1Score = 0
            player2Score = 0
        elseif gameState == 'serve' then
            gameState = 'play'
        end
    end
end

function love.draw()
    push:apply('start')
    love.graphics.clear(40/255, 45/255, 52/255, 255/255)
    
    love.graphics.setFont(smallFont)

    if gameState == 'start' then
        love.graphics.setFont(largeFont)
        love.graphics.printf("Welcome to Pong!", 0, 5, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf("Enter 1 for the P vs P, 2 for the P vs CPU, or 3 for CPU vs CPU", 0, 32, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'pvp' then
        love.graphics.printf("You have chosen: Player vs Player", 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Enter to Continue or Backspace to Return to Menu", 0, 32, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'pvcpu' then
        love.graphics.printf("You have chosen: Player vs CPU", 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Enter to Continue or Backspace to Return to Menu", 0, 32, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'cpuvcpu' then
        love.graphics.printf("You have chosen: CPU vs CPU", 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Enter to Continue or Backspace to Return to Menu", 0, 32, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.printf("Player " ..  tostring(servingPlayer) .. "'s turn!", 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Enter to Serve", 0, 32, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'victory' then
        love.graphics.setFont(largeFont)
        love.graphics.printf("Player " ..  tostring(winningPlayer) .. " wins!", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf("Press Enter to Return to Menu", 0, 42, VIRTUAL_WIDTH, 'center')
    end

    love.graphics.setFont(scoreFont)
    love.graphics.print(player1Score, VIRTUAL_WIDTH/2-50, VIRTUAL_HEIGHT/3)
    love.graphics.print(player2Score, VIRTUAL_WIDTH/2+30, VIRTUAL_HEIGHT/3)

    player1:render()
    player2:render()

    ball:render()

    displayFPS()

    push:apply('end')
end

function displayFPS()
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.setFont(smallFont)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 40, 20)
    love.graphics.setColor(1, 1, 1, 1)
end