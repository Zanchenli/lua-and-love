AiBird = Class{}

local GRAVITY = 10
local v0 = -2
local GAP_HEIGHT=110

function AiBird:init()
    self.bird = Bird()
end

function AiBird:update(dt, pair)
    -- bird's uplimit - jump's height > bottom of the top pipe (y=0 is the top,not the bottom of the screen)
    if self.bird.y-3*v0*v0/(2*GRAVITY) > pair.y+PIPE_HEIGHT then
        -- bird's top position + bird height + bottom detection box grace distance > top of the bottom pipe)
        if self.bird.y+self.bird.height+15 > pair.y+PIPE_HEIGHT+GAP_HEIGHT then
         love.keypressed('space')
        end
    end
    self.bird:update(dt)
end

function AiBird:render()
    self.bird:render()
end