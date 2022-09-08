-- Copyright (c) 2022 Branko Majic
-- Provided under MIT license. See LICENSE for details.


local main = require("scripts.main")


local handlers = {}


--- Updates button visibility when players changes a held item.
--
-- @param event EventData Event data as passed-in by the game engine.
--
function handlers.on_player_cursor_stack_changed(event)
    local player = game.players[event.player_index]
    main.update_button_visibility(player)
end


--- Initialises mod data for newly joined players.
--
-- @param event EventData Event data as passed-in by the game engine.
--
function handlers.on_player_joined_game(event)
    local player = game.players[event.player_index]

    main.initialise_player_data(player)
end


--- Cleans-up data for removed players.
--
-- @param event EventData Event data as passed-in by the game engine.
--
function handlers.on_player_removed(event)
    local player = game.players[event.player_index]

    main.destroy_player_data(player)
end


--- Initialises mod data when mod is first added to a savegame.
--
function handlers.on_init()
    main.initialise_data()
end


return handlers
