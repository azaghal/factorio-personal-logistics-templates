-- Copyright (c) 2023 Branko Majic
-- Provided under MIT license. See LICENSE for details.


local utils = require("scripts.utils")


local template = {}


--- Checks if passed-in list of blueprint entities constitutes a valid personal logistics template that can be imported.
--
-- @param entities {BlueprintEntity} List of blueprint entities to check.
--
-- @return bool true if passed-in entities constitute valid personal logistics template, false otherwise.
--
function template.is_valid_template(entities)

    -- List must contain at least one entity.
    if table_size(entities) == 0 then
        return false
    end

    for _, entity in pairs(entities) do
        -- Only constant combinators are allowed in the list.
        if entity.name ~= "constant-combinator" then
            return false
        end

        -- Control behaviour must contain two filters exactly (if any are set).
        if entity.control_behavior and entity.control_behavior.filters and table_size(entity.control_behavior.filters) ~= 2 then
            return false
        end

        -- Check the content of each individual combinator.
        if entity.control_behavior and entity.control_behavior.filters then
            local minimum_filter, maximum_filter = entity.control_behavior.filters[1], entity.control_behavior.filters[2]

            -- Swap the minimum/maximum filters around based on the position in combinator.
            if minimum_filter.index > maximum_filter.index then
                minimum_filter, maximum_filter = maximum_filter, minimum_filter
            end

            -- Filters must occupy correct positions.
            if minimum_filter.index ~= 1 or maximum_filter.index ~= 11 then
                return false
            end

            -- Signal type for both filters must be correct.
            if minimum_filter.signal.type ~= "item" or maximum_filter.signal.type ~= "item" then
                return false
            end

            -- Signal names of both filters must match.
            if minimum_filter.signal.name ~= maximum_filter.signal.name then
                return false
            end

        end

    end

    return true
end


--- Converts personal logistics configuration into list of (blueprint entity) constant combinators.
--
-- Each slot of personal logistics configuration is represented by a single constant combinator in the resulting list.
--
-- Minimum and maximum quantities are kept in the first slot of first and second row (respectively). Filter icons are
-- used to represent the requested item.
--
-- Since combinators use _signed_ 32-bit integers, and personal logistics slots use _unsigned_ 32-bit integers,
-- overflowing values are stored as negative values, with -1 corresponding to 2147483648, and -2147483648 corresponding
-- to 4294967296.
--
-- @param entity LuaEntity Entity for which to generate the list of blueprint entities.
--
-- @return {BlueprintEntity} List of blueprint entities (constant combinators) representing the configuration.
--
function template.personal_logistics_configuration_to_constant_combinators(entity)

    -- Determine function to invoke for reading logistic slot information.
    local _, get_logistic_slot = utils.get_logistic_slot_functions(entity)

    -- Set-up a list of empty combinators that will represent the configuration.
    local combinators = {}

    for i = 1, entity.request_slot_count == 0 and 1 or entity.request_slot_count do

        -- Calculate combinator position in the blueprint. Lay them out in rows, each row with up to 10 slots.
        local x = (i - 1) % 10 + 1
        local y = math.ceil(i/10)

        table.insert(
            combinators,
            {
                entity_number = i,
                name = "constant-combinator",
                position = {x = x, y = y},
                control_behavior = {filters = {}}
            }
        )
    end

    -- Populate combinators with slot requests.
    for slot_index = 1, entity.request_slot_count do

        local slot = get_logistic_slot(slot_index)

        if slot.name then
            local combinator = combinators[slot_index]

            -- Minimum quantities are kept in the first slot of the first row.
            local filter_min = {
                index = 1,
                -- Combinator signals use signed 32-bit integers, whereas slot requests are unsigned 32-bit
                -- integers. Store overflows as negative values.
                count = slot.min > 2147483647 and - slot.min + 2147483647 or slot.min,
                signal = {
                    name = slot.name,
                    type = "item"
                }
            }
            table.insert(combinator.control_behavior.filters, filter_min)

            -- Maximum quantities are kept in the first slot of the second row.
            local filter_max = {
                index = 11,
                -- Combinator signals use signed 32-bit integers, whereas slot requests are unsigned 32-bit
                -- integers. Store overflows as negative values.
                count = slot.max > 2147483647 and - slot.max + 2147483647 or slot.max,
                signal = {
                    name = slot.name,
                    type = "item"
                }
            }
            table.insert(combinator.control_behavior.filters, filter_max)
        end
    end

    return combinators
end


--- Converts list of (blueprint entity) constant combinators into personal logistics configuration.
--
-- Function assumes that the passed-in list of constant combinators has been validated (see template.is_valid_template).
--
-- @param combinators {BlueprintEntity} List of constant combinators representing personal logistics configuration.
--
-- @return {uint = LogisticParameters} Mapping between personal logistic slot indices and slot configuration.
--
function template.constant_combinators_to_personal_logistics_configuration(combinators)
    local slots = {}

    -- Sort the passed-in combinators by coordinates. This should help get a somewhat sane ordering even if player has
    -- been messing with the constant combinator layout. Slots are read from top to bottom and from left to right.
    local sort_by_coordinate = function(elem1, elem2)
        if elem1.position.y < elem2.position.y then
            return true
        elseif elem1.position.y == elem2.position.y and elem1.position.x < elem2.position.x then
            return true
        end

        return false
    end
    table.sort(combinators, sort_by_coordinate)

    -- Each combinator corresponds to a single slot in personal logistics requests.
    for slot_index, combinator in pairs(combinators) do
        if combinator.control_behavior and combinator.control_behavior.filters then

            local minimum_filter, maximum_filter =
                combinator.control_behavior.filters[1], combinator.control_behavior.filters[2]

            local slot = {
                name = minimum_filter.signal.name,
                min = minimum_filter.count < 0 and - minimum_filter.count + 2147483647 or minimum_filter.count,
                max = maximum_filter.count < 0 and - maximum_filter.count + 2147483647 or maximum_filter.count
            }

            -- Ensure that minimum is not greater than maximum (to avoid game crashes when setting the slot configuration).
            if slot.min > slot.max then
                slot.min, slot.max = slot.max, slot.min
            end

            slots[slot_index] = slot

        end
    end

    return slots
end


--- Retrieves information about auto-trash requests in entity's personal logistics requests.
--
-- Function can be used even in situations where no auto-trash requests are defined - this way it is easy to determine
-- where to start adding new ones.
--
-- Returned information covers:
--
--   - Index of slot where the auto-trash requests begin at (always beginning of the row).
--   - First available slot index that can be used for appending new auto-trash requests.
--   - List of empty slot indices corresponding to gaps in auto-trash slot layout.
--   - Mapping between slot indices and request parameters.
--   - Mapping between requested item names and request parameters.
--
-- @param entity LuaEntity Entity for which to fetch the information.
--
-- @return { from = int, append = int, gaps = { int }, slots = { int = LogisticParameters }, items = { string = LogisticParameters  } }
--
function template.get_auto_trash_info(entity)

    -- Set-up structure for storing information.
    local auto_trash_info = {
        from = nil,
        append = nil,
        gaps = {},
        slots = {},
        items = {}
    }

    -- Bail-out early if not a single request is set. Leave the first two rows blank.
    if entity.request_slot_count == 0 then

        -- Leave two blank rows, no requests are set whatsoever.
        auto_trash_info.from = 21
        auto_trash_info.append = 21

        return auto_trash_info

    end

    -- Determine getter function for logistic slot information.
    local _, get_logistic_slot = utils.get_logistic_slot_functions(entity)

    -- Keep track of previous and current row type.
    local row_type, previous_row_type

    -- Assume that there are no auto-trash requests set. Leave a gap of two blank rows after the final request.
    auto_trash_info.from = entity.request_slot_count - entity.request_slot_count % 10 + 31

    -- Iterate personal logistics requests back-to-front.
    for slot_index = entity.request_slot_count, 1, -1 do

        -- Fetch the slot and determine its type.
        local slot = get_logistic_slot(slot_index)
        local slot_type =
            slot.name == nil and "blank" or
            slot.min == 0 and slot.max == 0 and "trash" or
            "regular"

        -- Drop out of the loop the moment we hit the first regular request.
        if slot_type == "regular" then
            break
        end

        -- Row type is based on most significant slot type in the row (regular > trash > blank). Row type can never be
        -- regular at this point because we bail-out from the loop the moment we hit a regular request.
        row_type =
            (row_type == "trash" or slot_type == "trash") and "trash" or
            slot_type

        -- Detect when a whole row has been read.
        if slot_index % 10 == 1 then

            -- Auto-trash requests are always separated by at least one blank row from regular requests. Every time a
            -- blank row has bin hit, the auto-trash starting point is updated. Previous row is checked in order to try
            -- to leave two blank rows in-between regular and auto-trash requests (if possible).
            if row_type == "blank" and previous_row_type == "blank" then
                auto_trash_info.from = slot_index + 20
            elseif row_type == "blank" then
                auto_trash_info.from = slot_index + 10
            end

            -- Reset row types for next iteration.
            previous_row_type = row_type
            row_type = nil
        end

    end

    -- Figure out slot index where new auto-trash requests can be added at.
    auto_trash_info.append =
        auto_trash_info.from > entity.request_slot_count and auto_trash_info.from or
        entity.request_slot_count + 1

    -- Now that we know where the auto-trash requests begin, extract information for all of them.
    for slot_index = auto_trash_info.from, entity.request_slot_count do

        local slot = get_logistic_slot(slot_index)

        if slot.name then
            auto_trash_info.slots[slot_index] = slot
            auto_trash_info.items[slot.name] = slot
        else
            table.insert(auto_trash_info.gaps, slot_index)
        end

    end

    return auto_trash_info
end


return template
