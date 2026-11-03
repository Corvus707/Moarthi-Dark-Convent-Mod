local faction_key = "wh2_main_def_cult_of_pleasure"

local panel_name = "corvus_morathi_court"
local panel_layout = "ui/campaign ui/corvus_morathi_court"
local button_holder_name = "corvus_morathi_court_button_holder"
local button_holder_layout = "ui/campaign ui/corvus_morathi_court_button"
local button_name = "button_corvus_morathi_court"
local button_icon = "ui/skins/default/icon_gift_of_slaanesh.png"
local button_tooltip = "Morathi's Court||Open Morathi's Court."
local escape_key_name = "corvus_morathi_court_escape"

-- Top-level UI (HUD, other panels) hidden while the court is open, restored on close
local hidden_components = {}

local function get_resource_bar()
    return find_uicomponent(core:get_ui_root(), "hud_campaign", "resources_bar_holder", "resources_bar")
end

local function get_panel()
    return find_uicomponent(core:get_ui_root(), panel_name)
end

local function get_button()
    local resource_bar = get_resource_bar()
    return resource_bar and find_uicomponent(resource_bar, button_holder_name, button_name)
end

local function is_panel_open()
    local panel = get_panel()
    return panel and panel:Visible()
end

local function set_button_selected(selected)
    local button = get_button()
    if button then
        button:SetState(selected and "selected" or "active")
    end
end

local function hide_other_ui()
    local root = core:get_ui_root()
    for i = 0, root:ChildCount() - 1 do
        local child = UIComponent(root:Find(i))
        local id = child:Id()
        -- Skip tooltips so the one under the cursor when the court opened doesn't come back stale
        if id ~= panel_name and child:Visible() and not string.find(string.lower(id), "tooltip") then
            child:SetVisible(false)
            table.insert(hidden_components, child)
        end
    end
end

local function restore_other_ui()
    for _, child in ipairs(hidden_components) do
        child:SetVisible(true)
    end
    hidden_components = {}
end

local function close_panel()
    local panel = get_panel()
    if panel then
        panel:SetVisible(false)
    end
    restore_other_ui()
    set_button_selected(false)
    cm:release_escape_key_with_callback(escape_key_name)
end

local function open_panel()
    local panel = get_panel()
    if not panel then
        out("Creating "..panel_name)
        panel = UIComponent(core:get_ui_root():CreateComponent(panel_name, panel_layout))
    end
    hide_other_ui()
    panel:SetVisible(true)
    set_button_selected(true)
    cm:steal_escape_key_with_callback(escape_key_name, close_panel)
end

local function get_or_create_button()
    local resource_bar = get_resource_bar()
    if not resource_bar then
        out("Could not find resource bar")
        return
    end
    if find_uicomponent(resource_bar, button_holder_name) then
        return
    end

    out("Creating "..button_holder_name)
    local holder = UIComponent(resource_bar:CreateComponent(button_holder_name, button_holder_layout))
    holder:SetVisible(true)
    local button = find_uicomponent(holder, button_name)
    button:SetImagePath(button_icon, 0)
    button:SetTooltipText(button_tooltip, true)
    resource_bar:Layout()
end

local function button_check_callback()
    if cm:get_local_faction_name(true) ~= faction_key then
        return
    end
    local ok, err = pcall(get_or_create_button)
    if not ok then
        out("Error in corvus_morathi_court button_check_callback: "..tostring(err))
    end
end

cm:add_first_tick_callback(function ()
    core:progress_on_loading_screen_dismissed(function ()
        cm:real_callback(button_check_callback, 500, "corvus_morathi_add_court_button")
    end)

    core:add_listener(
        "corvus_morathi_court_button_check",
        "FactionTurnStart",
        function (context)
            return context:faction():name() == cm:get_local_faction_name(true)
        end,
        button_check_callback,
        true)

    core:add_listener(
        "corvus_morathi_court_button_clicked",
        "ComponentLClickUp",
        function (context)
            return context.string == button_name
        end,
        function ()
            if is_panel_open() then
                close_panel()
            else
                open_panel()
            end
        end,
        true)

    core:add_listener(
        "corvus_morathi_court_close_clicked",
        "ComponentLClickUp",
        function (context)
            return context.string == "button_close" and is_panel_open() and uicomponent_descended_from(UIComponent(context.component), panel_name)
        end,
        close_panel,
        true)

    core:add_listener(
        "corvus_morathi_court_other_panel_opened",
        "PanelOpenedCampaign",
        function (context)
            return context.string ~= panel_name and is_panel_open()
        end,
        function (context)
            out("Closing "..panel_name.." because "..context.string.." opened")
            close_panel()
        end,
        true)
end)
