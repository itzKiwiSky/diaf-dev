love.filesystem.load("src/Components/Initialization/Run.lua")()
love.filesystem.load("src/Components/Initialization/ErrorHandler.lua")()

--AssetHandler = require("src.Components.Helpers.AssetManager")()

VERSION = {
    ENGINE = "0.0.1",
    FORMATS = "0.0.1",
    meta = {
        commitID = "",
        branch = "",
    }
}

function love.initialize(args)
    fontcache = require 'src.Components.Modules.System.FontCache'
    versionChecker = require 'src.Components.Modules.API.CheckVersion'
    Presence = require 'src.Components.Modules.API.Presence'
    GameColors = require 'src.Components.Modules.Utils.GameColors'
    LanguageController = require 'src.Components.Modules.System.LanguageManager'
    connectGJ = require 'src.Components.Modules.API.InitializeGJ'
    connectDiscordRPC = require 'src.Components.Modules.API.InitializeDiscord'


    fontcache.init()

    lollipop.currentSave.game = {
        user = {
            settings = {
                video = {

                },
                audio = {
                    master = 75,
                    music = 75,
                    sfx = 50,
                },
                misc = {
                    language = "English",
                    discordrpc = false,
                    gamejolt = {
                        username = "",
                        usertoken = ""
                    },
                }
            }
        }
    }

    lollipop.initializeSlot("game")

    love.audio.setVolume(0.01 * lollipop.currentSave.game.user.settings.audio.master)
    languageService = LanguageController(lollipop.currentSave.game.user.settings.misc.language)

    registers = {
        user = {
        },
        system = {
        }
    }


    local gitStuff = require 'src.Components.Initialization.GitStuff'
    --connectGJ()
    
    if lollipop.currentSave.game.user.settings.misc.discordrpc then
        connectDiscordRPC()
    end

    if not love.filesystem.isFused() then
        gitStuff.getAll()

        if love.filesystem.getInfo(".commitid") then
            local title = love.window.getTitle()
            love.window.setTitle(title .. " | " .. love.filesystem.read(".nxid"))
        end
    end

    local states = love.filesystem.getDirectoryItems("src/States")
    for s = 1, #states, 1 do
        require("src.States." .. states[s]:gsub(".lua", ""))
    end

    if not love.system.getOS() == "Android" or not love.system.getOS() == "iOS" then
        joysticks = love.joystick.getJoysticks()
    end

    local substates = love.filesystem.getDirectoryItems("src/SubStates")
    for s = 1, #substates, 1 do
        require("src.SubStates." .. substates[s]:gsub(".lua", ""))
    end

    love.filesystem.createDirectory("editor")
    love.filesystem.createDirectory("editor/levels")
    love.filesystem.createDirectory("editor/edited")

    gamestate.registerEvents()
    gamestate.switch(PlayState)
end

function love.update(elapsed)
    if lollipop.currentSave.game.user.settings.misc.discordrpc then
        discordrpc.runCallbacks()
    end
    if gamejolt.isLoggedIn then
        registers.system.gameTime = registers.system.gameTime * elapsed
        if math.floor(registers.system.gameTime) >= 20 then
            gamejolt.pingSession(true)
            registers.system.gameTime = 0
        end
    end
end

function love.quit()
    if gamejolt.isLoggedIn then
        gamejolt.closeSession()
    end
    if lollipop.currentSave.game.user.settings.misc.discordrpc then
        discordrpc.shutdown()
    end
end

function discordrpc.ready(userId, username, discriminator, avatar)
    io.printf(string.format("{bgBlue}{brightBlue}{bold}[Discord]{reset}{brightBlue} : Client connected (%s, %s, %s){reset}\n", userId, username, discriminator))
end

function discordrpc.disconnected(errorCode, message)
    io.printf(string.format("{bgBlue}{brightBlue}{bold}[Discord]{reset}{brightBlue} : Client disconnected (%d, %s){reset}\n", errorCode, message))
end

function discordrpc.errored(errorCode, message)
    io.printf(string.format("{bgBlue}{brightBlue}{bold}[Discord]{reset}{bgRed}{brightWhite}[Error]{reset}{brightWhite} : (%d, %s){reset}\n", errorCode, message))
end