--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = {}
    table.insert(self.balls, params.ball)
    -- self.ball = params.ball
    self.level = params.level

    self.recoverPoints = 5000
    
    self.sizeTransformScore = 2000

    -- flags for keeping track of powerup status
    -- flag_powerped for rendering of the powerup
    -- flag_powerup_hit keeping track of if the powerup has been eaten
    self.powerupPoints = 100
    self.flag_poweruped = false
    self.flag_powerup_hit = false

    self.numKeys = 0

    -- give ball random starting velocity
    -- self.ball.dx = math.random(-200, 200)
    -- self.ball.dy = math.random(-50, -60)
    for k, ball in pairs(self.balls) do 
        ball.dx = math.random(-200,200)
        ball.dy = math.random(-50,-60)
    end
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    for k, ball in pairs(self.balls) do
        ball:update(dt)
    end

    -- update powerup after it is spawned
    if self.flag_poweruped == true or self.flag_powerup_hit == true then
        self.powerup:update(dt)
    end

    if self.flag_poweruped == true and self.powerup:collides(self.paddle) then
        self.powerup:hit()
        self.powerupPoints = 100000
        self.flag_poweruped = false
        self.flag_powerup_hit = true

        -- adding a key if the powerup is a key
        if self.powerup.skin == 10 then
            self.numKeys = self.numKeys + 1
        end

        -- adding a new ball upon eating the powerup
        b = Ball(5)
        b.x = self.powerup.x + 4
        b.y = self.powerup.y + 4
        b.dx = math.random(-200, 200)
        b.dy = math.random(-50,-60)
        table.insert(self.balls, b)

    end

    for k, ball in pairs(self.balls) do
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        for m, ball in pairs(self.balls) do
            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                -- check if the ball collides with the locked brick
                if brick.color == 6 and brick.tier == 3 then
                    if self.numKeys >= 1 then
                        self.numKeys = self.numKeys - 1 
                        self.score = self.score + (brick.tier * 200 + brick.color * 25)

                        -- trigger the brick's hit function, which removes it from play
                        brick:hit()

                        -- if we have enough points, recover a point of health
                        if self.score > self.recoverPoints then
                            -- can't go above 3 health
                            self.health = math.min(3, self.health + 1)

                            -- multiply recover points by 2
                            self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                            -- play recover sound effect
                            gSounds['recover']:play()
                        end

                        -- if we have enough points, transform to a bigger paddle
                        if self.score > self.sizeTransformScore then
                            self.sizeTransformScore = math.min(100000, self.sizeTransformScore * 2)
                            self.paddle:sizeTransform(1)

                            gSounds['recover']:play()

                        end
                        -- if we have enough scores, spawn a powerup at random locations and start falling down
                        if self.flag_poweruped == false and self.score > self.powerupPoints then
                            self.flag_poweruped = true
                            self.flag_powerup_hit = false
                            self.powerup = Powerup(math.random(1,2) == 1 and 2 or 10)
                        end

                        -- go to our victory screen if there are no more bricks left
                        if self:checkVictory() then
                            gSounds['victory']:play()

                            gStateMachine:change('victory', {
                                level = self.level,
                                paddle = self.paddle,
                                health = self.health,
                                score = self.score,
                                highScores = self.highScores,
                                ball = self.balls[1],
                                recoverPoints = self.recoverPoints
                            })
                        end
                    
                    end
                    --
                    -- collision code for bricks
                    --
                    -- we check to see if the opposite side of our velocity is outside of the brick;
                    -- if it is, we trigger a collision on that side. else we're within the X + width of
                    -- the brick and should check to see if the top or bottom edge is outside of the brick,
                    -- colliding on the top or bottom accordingly 
                    --

                    -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                    if ball.x + 2 < brick.x and ball.dx > 0 then
                        
                        -- flip x velocity and reset position outside of brick
                        ball.dx = -ball.dx
                        ball.x = brick.x - 8
                    
                    -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                    elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                        
                        -- flip x velocity and reset position outside of brick
                        ball.dx = -ball.dx
                        ball.x = brick.x + 32
                    
                    -- top edge if no X collisions, always check
                    elseif ball.y < brick.y then
                        
                        -- flip y velocity and reset position outside of brick
                        ball.dy = -ball.dy
                        ball.y = brick.y - 8
                    
                    -- bottom edge if no X collisions or top collision, last possibility
                    else
                        
                        -- flip y velocity and reset position outside of brick
                        ball.dy = -ball.dy
                        ball.y = brick.y + 16
                    end

                    -- slightly scale the y velocity to speed up the game, capping at +- 150
                    if math.abs(ball.dy) < 150 then
                        ball.dy = ball.dy * 1.02
                    end

                    -- only allow colliding with one brick, for corners
                    break

                else
                    -- add to score
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)

                    -- trigger the brick's hit function, which removes it from play
                    brick:hit()

                    -- if we have enough points, recover a point of health
                    if self.score > self.recoverPoints then
                        -- can't go above 3 health
                        self.health = math.min(3, self.health + 1)

                        -- multiply recover points by 2
                        self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                        -- play recover sound effect
                        gSounds['recover']:play()
                    end

                    -- if we have enough points, transform to a bigger paddle
                    if self.score > self.sizeTransformScore then
                        self.sizeTransformScore = math.min(100000, self.sizeTransformScore * 2)
                        self.paddle:sizeTransform(1)

                        gSounds['recover']:play()

                    end
                    -- if we have enough scores, spawn a powerup at random locations and start falling down
                    if self.flag_poweruped == false and self.score > self.powerupPoints then
                        self.flag_poweruped = true
                        self.flag_powerup_hit = false
                        self.powerup = Powerup(math.random(1,2) == 1 and 2 or 10)
                    end

                    -- go to our victory screen if there are no more bricks left
                    if self:checkVictory() then
                        gSounds['victory']:play()

                        gStateMachine:change('victory', {
                            level = self.level,
                            paddle = self.paddle,
                            health = self.health,
                            score = self.score,
                            highScores = self.highScores,
                            ball = self.balls[1],
                            recoverPoints = self.recoverPoints
                        })
                    end

                    --
                    -- collision code for bricks
                    --
                    -- we check to see if the opposite side of our velocity is outside of the brick;
                    -- if it is, we trigger a collision on that side. else we're within the X + width of
                    -- the brick and should check to see if the top or bottom edge is outside of the brick,
                    -- colliding on the top or bottom accordingly 
                    --

                    -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                    if ball.x + 2 < brick.x and ball.dx > 0 then
                        
                        -- flip x velocity and reset position outside of brick
                        ball.dx = -ball.dx
                        ball.x = brick.x - 8
                    
                    -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                    elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                        
                        -- flip x velocity and reset position outside of brick
                        ball.dx = -ball.dx
                        ball.x = brick.x + 32
                    
                    -- top edge if no X collisions, always check
                    elseif ball.y < brick.y then
                        
                        -- flip y velocity and reset position outside of brick
                        ball.dy = -ball.dy
                        ball.y = brick.y - 8
                    
                    -- bottom edge if no X collisions or top collision, last possibility
                    else
                        
                        -- flip y velocity and reset position outside of brick
                        ball.dy = -ball.dy
                        ball.y = brick.y + 16
                    end

                    -- slightly scale the y velocity to speed up the game, capping at +- 150
                    if math.abs(ball.dy) < 150 then
                        ball.dy = ball.dy * 1.02
                    end

                    -- only allow colliding with one brick, for corners
                    break
                end
            end
        end
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    for k, ball in pairs(self.balls) do
        if ball.y >= VIRTUAL_HEIGHT then
            self.health = self.health - 1
            self.paddle:sizeTransform(-1)
            gSounds['hurt']:play()

            if self.health == 0 then
                gStateMachine:change('game-over', {
                    score = self.score,
                    highScores = self.highScores
                })
            else
                gStateMachine:change('serve', {
                    paddle = self.paddle,
                    bricks = self.bricks,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    level = self.level,
                    recoverPoints = self.recoverPoints,
                    powerupPoints = self.powerupPoints
                })
            end
        end
    end

    -- if powerup falls below bounds, remove it
    if self.flag_poweruped == true and self.powerup.y >= VIRTUAL_HEIGHT then
        self.powerup = nil
        self.flag_poweruped = not self.flag_poweruped
        self.powerupPoints = self.powerupPoints * 2
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    if self.flag_powerup_hit == true then
        self.powerup:renderParticles()
        -- self.flag_powerup_hit = false
    end

    self.paddle:render()
    for k, ball in pairs(self.balls) do
        ball:render()
    end
    if self.flag_poweruped == true then
        self.powerup:render()                   
    end

    renderScore(self.score)
    renderHealth(self.health)
    renderKeys(self.numKeys)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end