if not shell then
	return error("Not running from a shell!")
end

if not http then
	return printError("HTTP is not enabled!")
end

local workingDir = shell.getRunningProgram()

local function resolveFile(file)
	return fs.combine(workingDir, file)
end

local requireCache = {}

local function require(file)
	local path = resolveFile(file)

	if requireCache[path] then
		return requireCache[path]
	else
		local env = {
			shell = shell,
			require = require,
			resolveFile = resolveFile
		}

		setmetatable(env, { __index = _G })

		local chunk, err = loadfile(file, env)
		
		if chunk == nil then
			return error(err or "N/A", 0)
		end

		requireCache[path] = chunk()
		return requireCache[path]
	end
end


local addressInUse = "kre3w0i79j"

local krist = require("src/krist.lua")
local sheets = require("src/sheets.lua")

local app = sheets.Application()
local screen = app.screen

local sidebarRelativeWidth = 0.32
local sidebarWidth = math.floor(screen.width * sidebarRelativeWidth + 0.5)
local infoContainer = nil

-- Sidebar creation
local sidebar = screen + sheets.Container(0, 0, sidebarWidth, screen.height)
sidebar.style:setField("colour", sheets.colour.lightBlue)

local function setGKWStyle(comp)
	comp.style:setField("colour", sheets.colour.cyan)
	comp.style:setField("colour.pressed", sheets.colour.lightBlue)
	comp.style:setField("textColour", sheets.colour.black)
end

local sidebarBtnWidth = sidebar.width - 2

local sidebarButtons = {
	overview = sidebar + sheets.Button(1, 1, sidebarBtnWidth, 1, "Overview"),
	transactions = sidebar + sheets.Button(1, 3, sidebarBtnWidth, 1, "Transactions"),
	economicon = sidebar + sheets.Button(1, 5, sidebarBtnWidth, 1, "Economicon"),
	exit = sidebar + sheets.Button(1, sidebar.height - 3, sidebarBtnWidth, 1, "Exit")	
}

function sidebarButtons.exit:onClick(button)
	if button == 1 then
		app:stop()
	end
end

local sidebarLabel = sidebar + sheets.Text(0, sidebar.height - 1, sidebar.width, 1, "by Lignum ")
sidebarLabel.style:setField("colour", sheets.colour.lightBlue)
sidebarLabel.style:setField("textColour", sheets.colour.blue)
sidebarLabel.style:setField("horizontal-alignment", sheets.alignment.centre)

for _,v in pairs(sidebarButtons) do
	setGKWStyle(v)
end

local function createInfoContainer()
	return sheets.ScrollContainer(sidebarWidth, 0, screen.width - sidebarWidth, screen.height)
end

local function createOverviewPanel()
	local overviewPanel = createInfoContainer()
	local addrText = "Your Address: " .. addressInUse
	local addressText = overviewPanel + sheets.Text(1, 1, #addrText, 1, addrText)
	local copyAddressBtn = overviewPanel + sheets.Button(overviewPanel.width - 9, 1, 8, 1, "Copy")
	setGKWStyle(copyAddressBtn)
	local balanceText = overviewPanel + sheets.Text(1, 3, overviewPanel.width - 1, 1, "Balance: " .. krist.getBalance(addressInUse) .. " KST")
	return overviewPanel
end

local function setInfoContainer(container)
	screen:removeChild(infoContainer)
	infoContainer = screen + container
end

setInfoContainer(createOverviewPanel())

app:run()