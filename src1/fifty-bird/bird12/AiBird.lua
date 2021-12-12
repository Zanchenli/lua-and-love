AiBird = Class{}

local GRAVITY = 10
local v0 = -2
local GAP_HEIGHT=110

function AiBird:init()
    self.bird = Bird()
end

function AiBird:update(dt, pair)
    if self.bird.y-3*v0*v0/(2*GRAVITY) > pair.y+PIPE_HEIGHT then
        if self.bird.y+self.bird.height+15 > pair.y+PIPE_HEIGHT+GAP_HEIGHT then
         love.keypressed('space')
        end
    end
    self.bird:update(dt)
end

function AiBird:render()
    self.bird:render()
end