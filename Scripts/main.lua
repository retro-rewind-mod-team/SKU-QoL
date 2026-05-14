-- ============================================================
--  Retro Rewind - SKU QoL
--  Version: 1.0
--
--  Automatically uses the last picked-up cassette's SKU
--  wherever you need to enter it — no typing required.
--
--  HOW IT WORKS:
--  When the player picks up a cassette, its SKU is stored.
--
--  COMPUTER: When the player sits down at the computer and
--  opens the Black Market tab, the search runs automatically
--  by calling the Committed delegate directly.
--
--  POSTER: When the player opens the SKU editor on any
--  PosterFrame actor, the stored SKU is committed immediately
--  via "SKU Command Button Committed", bypassing manual input.
--
--  Both paths are always active — the mod reacts to whichever
--  action the player takes after picking up a cassette.
--
--  USAGE:
--  1. Pick up a cassette
--  2a. Sit at the computer  → Black Market search fires
--  2b. Open a poster's SKU  → SKU is applied automatically
-- ============================================================

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    Debug        = false,  -- true = log hook registrations and detailed errors
    HookDelayMs  = 3000,
}

-- ============================================================
-- INTERNAL STATE
-- ============================================================
local lastSKU              = nil
local playerAtComputer     = false
local registeredHooks      = {}
local pickupHookRegistered = false

-- ============================================================
-- INTERNAL CONSTANTS - do not modify
-- ============================================================

local P = "[SKU-QoL] "

local PRODUCT_STRUCTURE_KEY = "Product Structure"
local BASE_STRUCTURE_KEY    = "BaseStructure_2_FBB12C464AE570CAFD12ED8506160683"
local BOX_DATA_KEY          = "BoxData_25_B5A798DA4F509BDCCF4B189171C1DA10"
local SKU_KEY               = "SKU_26_C5F25F4E49D05A4DEC2DEEAE5AEE5876"

-- The Committed delegate on UI_ScreenComputer_Widget_C that
-- triggers the Black Market search with a given SKU integer
local COMMITTED_DELEGATE = "BndEvt__UI_ScreenComputer_Widget_UI_Computer_Command_SKU_K2Node_ComponentBoundEvent_1_Committed__DelegateSignature"

-- ============================================================
-- HELPERS
-- ============================================================

local function log(msg)
    print(P .. msg .. "\n")
end

local function debug(msg)
    if Config.Debug then
        log(msg)
    end
end

local function safe(label, fn, ...)
    local results = {pcall(fn, ...)}
    if not results[1] then
        log(label .. " FAILED: " .. tostring(results[2]))
        return nil
    end
    return table.unpack(results, 2)
end

local function registerHookOptional(path, callback)
    if registeredHooks[path] then return end
    registeredHooks[path] = true

    local ok, err = pcall(function() RegisterHook(path, callback) end)
    if ok then
        debug("Hook active: " .. path)
    else
        log("Hook error: " .. path .. " / " .. tostring(err))
    end
end

-- ============================================================
-- CORE: Trigger the Black Market search for a given SKU.
-- Only fires if the player is actively using the computer.
-- Calls the Committed delegate directly on the screen widget,
-- which is the same path the search button takes internally.
-- ============================================================
local function searchSKUInComputer(sku)
    if not playerAtComputer then return end

    local screens = FindAllOf("UI_ScreenComputer_Widget_C")
    if not screens or #screens == 0 then return end

    for _, screen in ipairs(screens) do
        safe("Computer search SKU " .. tostring(sku), function()
            screen[COMMITTED_DELEGATE](sku)
            log("Search triggered for SKU: " .. tostring(sku))
        end)
    end
end

-- ============================================================
-- HOOKS
-- ============================================================

ExecuteWithDelay(Config.HookDelayMs, function()

    -- Hook: Toggle Machine on ComputerScreen_C
    -- Fires twice: true = player entering, false = player leaving.
    -- We use false to reset the playerAtComputer flag.
    registerHookOptional(
        "/Game/VideoStore/asset/prop/Computer/ComputerScreen.ComputerScreen_C:Toggle Machine",
        function(self, enableParam)
            safe("Toggle Machine", function()
                if enableParam:get() == false then
                    playerAtComputer = false
                    debug("Player left computer")
                end
            end)
        end
    )

    -- Hook: End of Enter Machine Animation on ComputerScreen_C
    -- Fires when the camera animation finishes and the player
    -- is fully seated at the computer. This is the correct moment
    -- to trigger the search.
    registerHookOptional(
        "/Game/VideoStore/asset/prop/Computer/ComputerScreen.ComputerScreen_C:End of Enter Machine Animation",
        function(self)
            playerAtComputer = true
            debug("Player entered computer")
            if lastSKU then
                searchSKUInComputer(lastSKU)
            end
        end
    )

    -- Hook: Create SKU Interface on PosterFrame_C
    -- Fires when the player opens the SKU input on any poster type
    -- (wall, standing, small). Immediately commits the stored SKU
    -- via "SKU Command Button Committed", the same function the
    -- in-game confirm button calls — no manual typing needed.
    registerHookOptional(
        "/Game/VideoStore/asset/prop/PosterFrame/PosterFrame.PosterFrame_C:Create SKU Interface",
        function(self)
            if not lastSKU then return end
            safe("Poster SKU commit " .. tostring(lastSKU), function()
                local poster = self:get()
                poster["SKU Command Button Committed"](lastSKU)
                log("Poster SKU set: " .. tostring(lastSKU))
            end)
        end
    )

    -- Reset on save reload: clear both flags to prevent stale state
    registerHookOptional(
        "/Game/VideoStore/asset/outside/WeatherSystem.WeatherSystem_C:ReceiveBeginPlay",
        function()
            playerAtComputer = false
            lastSKU          = nil
            debug("Save reloaded - state reset")
        end
    )

    -- Reset computer flag at end of day
    registerHookOptional(
        "/Game/VideoStore/core/gamemode/Core_Gamemode.Core_Gamemode_C:End of the day",
        function()
            playerAtComputer = false
            debug("Day ended - computer flag reset")
        end
    )

    log("Hooks registered")
end)

-- ============================================================
-- Hook: PickUp on Cartridge_Base_C
-- Uses NotifyOnNewObject because UE4SS only resolves the UFunction
-- after the first cassette instance is created. Early spawns during
-- level load can still fail with Func: 0x0 (Blueprint not yet
-- compiled), so we track success and silently retry on each new
-- cassette until registration succeeds.
-- ============================================================
NotifyOnNewObject(
    "/Game/VideoStore/asset/prop/vhs/Cartridge_Base.Cartridge_Base_C",
    function()
        if pickupHookRegistered then return end
        ExecuteWithDelay(100, function()
            if pickupHookRegistered then return end
            local ok = pcall(function()
                RegisterHook(
                    "/Game/VideoStore/asset/prop/vhs/Cartridge_Base.Cartridge_Base_C:PickUp",
                    function(self)
                        safe("PickUp SKU read", function()
                            local cart = self:get()
                            if not cart or not cart:IsValid() then return end
                            local box  = cart[PRODUCT_STRUCTURE_KEY][BASE_STRUCTURE_KEY][BOX_DATA_KEY]
                            lastSKU    = box[SKU_KEY]
                            log("SKU stored: " .. tostring(lastSKU))
                            searchSKUInComputer(lastSKU)
                        end)
                    end
                )
            end)
            if ok then
                pickupHookRegistered = true
                debug("PickUp hook active")
            end
        end)
    end
)

-- ============================================================
log("SKU QoL loaded.")
log("Pick up a cassette, then sit at the computer or open a poster's SKU.")
