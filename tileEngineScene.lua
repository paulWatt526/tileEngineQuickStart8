local Composer = require( "composer" )
local TileEngine = require "plugin.wattageTileEngine"

local scene = Composer.newScene()

-- -----------------------------------------------------------------------------------
-- This table represents a simple environment.  Replace this with
-- the model needed for your application.
-- -----------------------------------------------------------------------------------
local ENVIRONMENT = {
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,1,1,0,0,0,1,1,0,0,0,1},
    {1,0,0,0,1,1,0,0,0,1,1,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,1,1,0,0,0,1,1,0,0,0,1},
    {1,0,0,0,1,1,0,0,0,1,1,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}

local CAMERA_SPEED      = 4 / 1000          -- Camera speed, 4 tiles per second
local MOVING_LIGHT_SPEED= 4 / 1000          -- Moving light speed, 4 tiles per second
local ENTITY_SPEED      = 4 / 1000          -- Speed of the entity, 4 tiles per second
local ROW_COUNT         = #ENVIRONMENT      -- Row count of the environment
local COLUMN_COUNT      = #ENVIRONMENT[1]   -- Column count of the environment
local WALL_LAYER_COUNT  = 4                 -- The number of extruded wall layers
local SCALING_DELTA     = 0.04              -- The scaling delta between wall layers

local tileEngine                            -- Reference to the tile engine
local lightingModel                         -- Reference to the lighting model
local tileEngineViewControl                 -- Reference to the UI view control
local lastTime                              -- Used to track how much time passes between frames
local cameraDirection                       -- Tracks the direction of the camera
local topLightId                            -- Will track the ID of the top light
local bottomLightId                         -- Will track the ID of the bottom light
local leftLightId                           -- Will track the ID of the left light
local rightLightId                          -- Will track the ID of the right light
local movingLightId                         -- Will track the ID of the moving light
local movingLightDirection                  -- Tracks the direction of the moving light
local movingLightXPos                       -- Tracks the continous position of the moving light
local entityId                              -- Will track the ID of the entity
local entityDirection                       -- Tracks the direction of the moving entity
local entityLayer                           -- Reference to the entity layer
local playerTokenId                         -- Will track the ID of the player token.

-- -----------------------------------------------------------------------------------
-- This will load in the example sprite sheet.  Replace this with the sprite
-- sheet needed for your application.
-- -----------------------------------------------------------------------------------
local spriteSheetInfo = require "tiles"
local spriteSheet = graphics.newImageSheet("tiles.png", spriteSheetInfo:getSheet())

-- -----------------------------------------------------------------------------------
-- A sprite resolver is required by the engine.  Its function is to create a
-- SpriteInfo object for the supplied key.  This function will utilize the
-- example sprite sheet.
-- -----------------------------------------------------------------------------------
local spriteResolver = {}
spriteResolver.resolveForKey = function(key)
    local frameIndex = spriteSheetInfo:getFrameIndex(key)
    local frame = spriteSheetInfo.sheet.frames[frameIndex]
    local displayObject = display.newImageRect(spriteSheet, frameIndex, frame.width, frame.height)
    return TileEngine.SpriteInfo.new({
        imageRect = displayObject,
        width = frame.width,
        height = frame.height
    })
end

local stateMachine = {}
stateMachine.init = function()
    -- Set initial state
    stateMachine.curState = 0

    -- Set the initial position and direction of the moving light
    movingLightDirection = "right"
    movingLightXPos = 1.5

    -- Set up for state 0
    movingLightId = lightingModel.addLight({
        row=8,
        column=math.floor(movingLightXPos + 0.5),
        r=1,g=1,b=0.7,intensity=0.75,radius=9
    })
    lightingModel.setUseTransitioners(true)
    lightingModel.setAmbientLight(1,1,1,0.15)
end
stateMachine.update = function(deltaTime)
    local xDelta = MOVING_LIGHT_SPEED * deltaTime
    if movingLightDirection == "right" then
        movingLightXPos = movingLightXPos + xDelta
        if movingLightXPos > 13.5 then
            movingLightDirection = "left"
            movingLightXPos = 13.5 - (movingLightXPos - 13.5)
        end
    else
        movingLightXPos = movingLightXPos - xDelta
        if movingLightXPos < 1.5 then
            movingLightDirection = "right"
            movingLightXPos = 1.5 + (1.5 - movingLightXPos)
        end
    end
    if movingLightId ~= nil then
        lightingModel.updateLight({
            lightId = movingLightId,
            newRow = 8,
            newColumn = math.floor(movingLightXPos + 0.5)
        })
    end
end
stateMachine.nextState = function()
    stateMachine.curState = stateMachine.curState + 1
    if stateMachine.curState > 5 then
        stateMachine.curState = 0
    end

    if stateMachine.curState == 0 then
        movingLightId = lightingModel.addLight({
            row=8,
            column=math.floor(movingLightXPos + 0.5),
            r=1,g=1,b=0.7,intensity=0.75,radius=9
        })
        lightingModel.setUseTransitioners(true)
        lightingModel.setAmbientLight(1,1,1,0.15)
    end

    if stateMachine.curState == 1 then
        lightingModel.removeLight(movingLightId)
        movingLightId = nil
        topLightId = lightingModel.addLight({
            row=5,column=8,r=1,g=1,b=0.7,intensity=0.75,radius=9
        })
        lightingModel.setUseTransitioners(false)
    end

    if stateMachine.curState == 2 then
        lightingModel.removeLight(topLightId)
        topLightId = nil
        rightLightId = lightingModel.addLight({
            row=8,column=11,r=0,g=0,b=1,intensity=0.75,radius=9
        })
    end

    if stateMachine.curState == 3 then
        lightingModel.removeLight(rightLightId)
        rightLightId = nil
        bottomLightId = lightingModel.addLight({
            row=11,column=8,r=0,g=1,b=0,intensity=0.75,radius=9
        })
    end

    if stateMachine.curState == 4 then
        lightingModel.removeLight(bottomLightId)
        bottomLightId = nil
        leftLightId = lightingModel.addLight({
            row=8,column=5,r=1,g=0,b=0,intensity=0.75,radius=9
        })
    end

    if stateMachine.curState == 5 then
        lightingModel.removeLight(leftLightId)
        leftLightId = nil
        lightingModel.setAmbientLight(1,1,1,0.75)
    end
end

-- -----------------------------------------------------------------------------------
-- An event handler for screen taps.
-- -----------------------------------------------------------------------------------
local function tapListener()
    stateMachine.nextState()
end

-- -----------------------------------------------------------------------------------
-- A simple helper function to add floor tiles to a layer.
-- -----------------------------------------------------------------------------------
local function addFloorToLayer(layer)
    for row=1,ROW_COUNT do
        for col=1,COLUMN_COUNT do
            local value = ENVIRONMENT[row][col]
            if value == 0 then
                layer.updateTile(
                    row,
                    col,
                    TileEngine.Tile.new({
                        resourceKey="tiles_0"
                    })
                )
            elseif value == 1 then
                layer.updateTile(
                    row,
                    col,
                    TileEngine.Tile.new({
                        resourceKey="tiles_1"
                    })
                )
            end
        end
    end
end

-- -----------------------------------------------------------------------------------
-- A simple helper function to add walls to a layer.
-- -----------------------------------------------------------------------------------
local function addWallsToLayer(layer)
    for row=1,ROW_COUNT do
        for col=1,COLUMN_COUNT do
            local value = ENVIRONMENT[row][col]
            if value == 1 then
                layer.updateTile(
                    row,
                    col,
                    TileEngine.Tile.new({
                        resourceKey="tiles_1"
                    }))
            end
        end
    end
end

-- -----------------------------------------------------------------------------------
-- This is a callback required by the lighting model to determine whether a tile
-- is transparent.  In this implementation, the cells with a value of zero are
-- transparent.  The engine may ask about the transparency of tiles that are outside
-- the boundaries of our environment, so the implementation must handle these cases.
-- That is why nil is checked for in this example callback.
-- -----------------------------------------------------------------------------------
local function isTileTransparent(column, row)
    local rowTable = ENVIRONMENT[row]
    if rowTable == nil then
        return true
    end
    local value = rowTable[column]
    return value == nil or value == 0
end

-- -----------------------------------------------------------------------------------
-- This is a callback required by the lighting model to determine whether a tile
-- should be affected by ambient light.  This simple implementation always returns
-- true which indicates that all tiles are affected by ambient lighting.  If an
-- environment had a section which should not be affected by ambient lighting, this
-- callback can be used to indicate that.  For example, the environment my be
-- an outdoor environment where the ambient lighting is the sun.  A few tiles in this
-- environment may represent the inside of a cabin, and these tiles would need to
-- not be affected by ambient lighting.
-- -----------------------------------------------------------------------------------
local function allTilesAffectedByAmbient(column, row)
    return true
end

-- -----------------------------------------------------------------------------------
-- This will be called every frame.  It is responsible for setting the camera
-- positiong, updating the lighting model, rendering the tiles, and reseting
-- the dirty tiles on the lighting model.
-- -----------------------------------------------------------------------------------
local function onFrame(event)
    local camera = tileEngineViewControl.getCamera()
    local lightingModel = tileEngine.getActiveModule().lightingModel
    local lineOfSightModel = tileEngine.getActiveModule().losModel

    if lastTime ~= 0 then
        -- Determine the amount of time that has passed since the last frame and
        -- record the current time in the lastTime variable to be used in the next
        -- frame.
        local curTime = event.time
        local deltaTime = curTime - lastTime
        lastTime = curTime

        -- Update the position of the camera
        local curXPos = camera.getX()
        local xDelta = CAMERA_SPEED * deltaTime
        if cameraDirection == "right" then
            curXPos = curXPos + xDelta
            if curXPos > 13.5 then
                cameraDirection = "left"
                curXPos = 13.5 - (curXPos - 13.5)
            end
        else
            curXPos = curXPos - xDelta
            if curXPos < 1.5 then
                cameraDirection = "right"
                curXPos = 1.5 + (1.5 - curXPos)
            end
        end
        camera.setLocation(curXPos, camera.getY())

        -- Set the entity position
        entityLayer.setEntityTilePosition(playerTokenId, camera.getY(), curXPos)

        -- Update the position of the entity
        local entityRow, entityCol = entityLayer.getEntityTilePosition(entityId)
        local yDelta = ENTITY_SPEED * deltaTime
        if entityDirection == "down" then
            entityRow = entityRow + yDelta
            if entityRow > 12.5 then
                entityDirection = "up"
                entityRow = 12.5 - (entityRow - 12.5)
            end
        else
            entityRow = entityRow - yDelta
            if entityRow < 2.5 then
                entityDirection = "down"
                entityRow = 2.5 + (2.5 - entityRow)
            end
        end
        entityLayer.setEntityTilePosition(entityId, entityRow, entityCol)

        -- Update the state machine
        stateMachine.update(deltaTime)

        -- Update the lighting model passing the amount of time that has passed since
        -- the last frame.
        lightingModel.update(deltaTime)

        -- Update the line of sight model passing the row and column for the current
        -- point of view nad the amount of time that has passed
        -- since the last frame.
        lineOfSightModel.update(8, math.floor(curXPos + 0.5), deltaTime)
    else
        -- This is the first call to onFrame, so lastTime needs to be initialized.
        lastTime = event.time

        -- This is the initial position of the camera
        camera.setLocation(1.5, 7.5)

        -- Set the initial position of the entity
        entityLayer.centerEntityOnTile(entityId, 3, 8)

        -- Set the initial position of the player token
        entityLayer.centerEntityOnTile(playerTokenId, 8, 2)

        -- Since a time delta cannot be calculated on the first frame, 1 is passed
        -- in here as a placeholder.
        lightingModel.update(1)

        -- Set the initial position of the player to match the
        -- position of the camera.  Pass in a time delta of 1 since this is
        -- the first frame.
        lineOfSightModel.update(8, 3, 1)
    end

    -- Render the tiles visible to the passed in camera.
    tileEngine.render(camera)

    -- The lighting model tracks changes, then acts on all accumulated changes in
    -- the lightingModel.update() function.  This call resets the change tracking
    -- and must be called after lightingModel.update().
    lightingModel.resetDirtyFlags()

    -- The line of sight model also tracks changes to the player position.
    -- It is necessary to reset the change tracking to provide a clean
    -- slate for the next frame.
    lineOfSightModel.resetDirtyFlags()
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )
    local sceneGroup = self.view

    -- Create a group to act as the parent group for all tile engine DisplayObjects.
    local tileEngineLayer = display.newGroup()

    -- Create an instance of TileEngine.
    tileEngine = TileEngine.Engine.new({
        parentGroup=tileEngineLayer,
        tileSize=32,
        spriteResolver=spriteResolver,
        compensateLightingForViewingPosition=true,
        hideOutOfSightElements=true
    })

    -- The tile engine needs at least one Module.  It can support more than
    -- one, but this template sets up only one which should meet most use cases.
    -- A module is composed of a LightingModel and a number of Layers
    -- (TileLayer or EntityLayer).  An instance of the lighting model is created
    -- first since it is needed to instantiate the Module.
    lightingModel = TileEngine.LightingModel.new({
        isTransparent = isTileTransparent,
        isTileAffectedByAmbient = allTilesAffectedByAmbient,
        useTransitioners = false,
        compensateLightingForViewingPosition = true
    })

    -- An instance of LineOfSightModel is created for the module to
    -- track which tiles are visible.
    local lineOfSightModel = TileEngine.LineOfSightModel.new({
        radius = 20,
        isTransparent = isTileTransparent
    })
    lineOfSightModel.setTransitionTime(225)

    -- Instantiate the module.
    local module = TileEngine.Module.new({
        name="moduleMain",
        rows=ROW_COUNT,
        columns=COLUMN_COUNT,
        lightingModel=lightingModel,
        losModel=lineOfSightModel
    })

    -- Next, layers will be added to the Module...

    -- Create a TileLayer for the floor.
    local floorLayer = TileEngine.TileLayer.new({
        rows = ROW_COUNT,
        columns = COLUMN_COUNT
    })

    -- Use the helper function to populate the layer.
    addFloorToLayer(floorLayer)

    -- It is necessary to reset dirty tile tracking after the layer has been
    -- fully initialized.  Not doing so will result in unnecessary processing
    -- when the scene is first rendered which may result in an unnecessary
    -- delay (especially for larger scenes).
    floorLayer.resetDirtyTileCollection()

    -- Add the layer to the module at index 1 (indexes start at 1, not 0).  Set
    -- the scaling delta to zero.
    module.insertLayerAtIndex(floorLayer, 1, 0)

    entityLayer = TileEngine.EntityLayer.new({
        tileSize = 32,
        spriteResolver = spriteResolver
    })
    module.insertLayerAtIndex(entityLayer, 2, 0)
    entityId = entityLayer.addEntity("tiles_2")
    playerTokenId = entityLayer.addEntity("tiles_3")

    -- Create extruded wall layers
    for i=1,WALL_LAYER_COUNT do
        local wallLayer = TileEngine.TileLayer.new({
            rows = ROW_COUNT,
            columns = COLUMN_COUNT
        })
        addWallsToLayer(wallLayer)
        wallLayer.resetDirtyTileCollection()
        module.insertLayerAtIndex(wallLayer, i + 2, SCALING_DELTA)
    end

    -- Add the module to the engine.
    tileEngine.addModule({module = module})

    -- Set the module as the active module.
    tileEngine.setActiveModule({
        moduleName = "moduleMain"
    })

    -- To render the tiles to the screen, create a ViewControl.  This example
    -- creates a ViewControl to fill the entire screen, but one may be created
    -- to fill only a portion of the screen if needed.
    tileEngineViewControl = TileEngine.ViewControl.new({
        parentGroup = sceneGroup,
        centerX = display.contentCenterX,
        centerY = display.contentCenterY,
        pixelWidth = display.actualContentWidth,
        pixelHeight = display.actualContentHeight,
        tileEngineInstance = tileEngine
    })

    stateMachine.init()
end


-- show()
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)

        -- Set the lastTime variable to 0.  This will indicate to the onFrame event handler
        -- that it is the first frame.
        lastTime = 0

        -- Initialize the camera direction to "right"
        cameraDirection = "right"

        -- Initialize the entity direction to "down"
        entityDirection = "down"

        -- Register the onFrame event handler to be called before each frame.
        Runtime:addEventListener( "enterFrame", onFrame )

        -- Register an event listener to handle screen taps.
        Runtime:addEventListener( "tap", tapListener )
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
    end
end


-- hide()
function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)

        -- Remove the onFrame event handler.
        Runtime:removeEventListener( "enterFrame", onFrame )

        -- Remove the event listener for taps
        Runtime:removeEventListener( "tap", tapListener)
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
    end
end


-- destroy()
function scene:destroy( event )

    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view

    -- Destroy the tile engine instance to release all of the resources it is using
    tileEngine.destroy()
    tileEngine = nil

    -- Destroy the ViewControl to release all of the resources it is using
    tileEngineViewControl.destroy()
    tileEngineViewControl = nil

    -- Set the reference to the lighting model to nil.
    lightingModel = nil
end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene