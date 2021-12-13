Powerup = Class{}

paletteColors = {
    -- blue
    [1] = {
        ['r'] = 99/255,
        ['g'] = 155/255,
        ['b'] = 255/255
    },
    -- green
    [2] = {
        ['r'] = 106/255,
        ['g'] = 190/255,
        ['b'] = 47/255
    },
    -- red
    [3] = {
        ['r'] = 217/255,
        ['g'] = 87/255,
        ['b'] = 99/255
    },
    -- purple
    [4] = {
        ['r'] = 215/255,
        ['g'] = 123/255,
        ['b'] = 186/255
    },
    -- gold
    [5] = {
        ['r'] = 251/255,
        ['g'] = 242/255,
        ['b'] = 54/255
    }
}


function Powerup:init(skin)
    self.width = 16
    self.height = 16

    -- set it to fall slowly
    self.dy = 15
    self.dx = 0

    self.x = math.random(0, VIRTUAL_WIDTH -16)
    self.y = math.random(0, VIRTUAL_HEIGHT / 2 -8)
    
    self.skin = skin

    self.color = 5

    -- particle system belonging to the powerup, emitted on hit
    self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 64)

    -- various behavior-determining functions for the particle system
    -- https://love2d.org/wiki/ParticleSystem

    -- lasts between 0.5-1 seconds seconds
    self.psystem:setParticleLifetime(0.5, 1)

    -- give it an acceleration of anywhere between X1,Y1 and X2,Y2 (0, 0) and (80, 80) here
    -- gives generally downward 
    self.psystem:setLinearAcceleration(-15, 0, 15, -80)

    -- spread of particles; normal looks more natural than uniform
    self.psystem:setEmissionArea('normal', 10, 10)
end

function Powerup:collides(target)
     -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end  

function Powerup:hit()
    -- set the particle system to interpolate between two colors; in this case, we give
    -- it our self.color but with varying alpha; brighter for higher tiers, fading to 0
    -- over the particle's lifetime (the second color)
    self.psystem:setColors(
        paletteColors[self.color].r,
        paletteColors[self.color].g,
        paletteColors[self.color].b,
        55 * (self.skin + 1),
        paletteColors[self.color].r,
        paletteColors[self.color].g,
        paletteColors[self.color].b,
        0
    )
    self.psystem:emit(64)

    -- sound on hit
    gSounds['brick-hit-2']:stop()
    gSounds['brick-hit-2']:play()

    self.dy = 0

end

function Powerup:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    self.psystem:update(dt)

end

function Powerup:render()
    -- gTexture is our global texture for all blocks
    -- gBallFrames is a table of quads mapping to each individual ball skin in the texture
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.skin],
        self.x, self.y)
end


-- renders particles
function Powerup:renderParticles()
    love.graphics.draw(self.psystem, self.x + 8, self.y + 8)
end