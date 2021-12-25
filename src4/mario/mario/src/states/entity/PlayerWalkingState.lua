--[[
    GD50
    Super Mario Bros. Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerWalkingState = Class{__includes = BaseState}

function PlayerWalkingState:init(player)
    self.player = player
    self.animation = Animation {
        frames = {10, 11},
        interval = 0.1
    }
    self.player.currentAnimation = self.animation
end

function PlayerWalkingState:update(dt)
    self.player.currentAnimation:update(dt)

    -- idle if we're not pressing anything at all
    if not love.keyboard.isDown('left') and not love.keyboard.isDown('right') then
        self.player:changeState('idle')
    else
        local tileBottomLeft = self.player.map:pointToTile(self.player.x + 1, self.player.y + self.player.height)
        local tileBottomRight = self.player.map:pointToTile(self.player.x + self.player.width - 1, self.player.y + self.player.height)

        -- temporarily shift player down a pixel to test for game objects beneath(看看脚下有没有箱子)
        self.player.y = self.player.y + 1

        local collidedObjects = self.player:checkObjectCollisions()

        self.player.y = self.player.y - 1

        -- check to see whether there are any tiles beneath us
        -- 如果下面没有箱子 而且 左下和右下地块都为空（出界） 而且 左下、右下地块为不可碰撞类型（空气地块）
        if #collidedObjects == 0 and (tileBottomLeft and tileBottomRight) and (not tileBottomLeft:collidable() and not tileBottomRight:collidable()) then
            self.player.dy = 0
            self.player:changeState('falling')
        elseif love.keyboard.isDown('left') then
            self.player.x = self.player.x - PLAYER_WALK_SPEED * dt
            self.player.direction = 'left'
            -- 检查左边是否遇到新的障碍，如果遇到，拉回玩家
            self.player:checkLeftCollisions(dt)
        elseif love.keyboard.isDown('right') then
            self.player.x = self.player.x + PLAYER_WALK_SPEED * dt
            self.player.direction = 'right'
            self.player:checkRightCollisions(dt)
        end
    end

    -- check if we've collided with any entities and die if so
    for k, entity in pairs(self.player.level.entities) do
        if entity:collides(self.player) then
            gSounds['death']:play()
            gStateMachine:change('start')
        end
    end

    if love.keyboard.wasPressed('space') then
        self.player:changeState('jump')
    end
end