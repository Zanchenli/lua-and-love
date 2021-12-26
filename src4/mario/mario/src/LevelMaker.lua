--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- predetermine the position of the key and the locked block
    local keyPosition = math.random(width)
    local lockedBlockPosition = math.random(width)

    local numEmptyColumn = 0


    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- check and spawn the key
        if x == keyPosition then
            tileID = TILE_ID_GROUND

            local keyHeight = 5

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            local key = GameObject {
                texture = 'keys_and_locks',
                x = (x - 1) * TILE_SIZE,
                y = (keyHeight - 1) * TILE_SIZE,
                width = 16,
                height = 16,
                frame = math.random(#KEYS),
                collidable = true,
                consumable = true,
                solid = false,

                -- gem has its own function to add to the player's score
                onConsume = function(player, object)
                    gSounds['pickup']:play()
                    player.key = player.key + 1
                end
            }
            table.insert(objects, key)
            goto continue

        -- check to spawn the locked block
        elseif x == lockedBlockPosition then
            tileID = TILE_ID_GROUND

            local lockedBlockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'keys_and_locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (lockedBlockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(LOCKEDBRICK[1], LOCKEDBRICK[#LOCKEDBRICK]),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(player, obj)

                            -- spawn a gem if we haven't already hit the block
                            if  player.key >= 1 then
                                obj.hit = true
                                obj.solid = false
                                player.key = 0
                                gSounds['powerup-reveal']:play()

                                local pole = GameObject {
                                    texture = 'poles',
                                    x = (width - 1) * TILE_SIZE,
                                    y = (lockedBlockHeight - 1) * TILE_SIZE,
                                    width = 16,
                                    height = 64,
                                    frame = math.random(#POLES),
                                    collidable = true,
                                    consumable = false,
                                    solid = true,

                                    onCollide = function(player, obj)
                                        local flag = GameObject {
                                            texture = 'flags',
                                            x = (width - 1) * TILE_SIZE + 8,
                                            y = (lockedBlockHeight - 1) * TILE_SIZE,
                                            width = 16,
                                            height = 16,
                                            frame = FLAGS[math.random(#FLAGS)],
                                            collidable = false,
                                            consumable = false,
                                            solid = false,

                                        }
                                        table.insert(objects, flag)

                                        gSounds['pickup']:play()

                                        Timer.tween(1, {
                                            [flag] = {y = 5 * TILE_SIZE} 
                                        })
                                        :finish(function()
                                            gStateMachine:change('play', {levelWidth = player.map.width, score = player.score})
                                        end)

                                    end
                                }

                                table.insert(objects, pole) 


                            end
                        end
                    }
            )
            goto continue

        end

        -- chance to just be emptiness
        -- numEmptyColumn makes sure that we don't generate too large gap to jump across
        if math.random(7) == 1 and x ~= 1 and x~= width and numEmptyColumn < 2 then
            numEmptyColumn = numEmptyColumn + 1
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND
            numEmptyColumn = 0
            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 and x ~= width then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    numEmptyColumn = -1
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- chance to spawn a block
            if math.random(10) == 1 and x ~= width and blockHeight ~= 2 then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(player, obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
        end
        ::continue::
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end