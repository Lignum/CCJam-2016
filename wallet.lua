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
	overviewPanel.type = "overview"

	local infoHeight = math.floor(overviewPanel.height * 0.25 + 0.5)
	local infoBox = overviewPanel + sheets.Container(1, 1, overviewPanel.width - 2, infoHeight)
	infoBox.style:setField("colour", sheets.colour.lightGrey)

	local addrText = "Your Address: "
	local addressText = infoBox + sheets.Text(1, 1, #addrText, 1, addrText)
	addressText.style:setField("colour", sheets.colour.lightGrey)
	addressText.style:setField("textColour", sheets.colour.black)

	local usedAddressText = infoBox + sheets.Text(#addrText + 1, 1, #addressInUse, 1, addressInUse)
	usedAddressText.style:setField("colour", sheets.colour.lightGrey)
	usedAddressText.style:setField("textColour", sheets.colour.white)

	local balText = "Balance: "
	local balanceText = infoBox + sheets.Text(1, 3, infoBox.width - 1, 1, balText)
	balanceText.style:setField("colour", sheets.colour.lightGrey)
	balanceText.style:setField("textColour", sheets.colour.black)

	local usedBalText = tostring((krist.getBalance(addressInUse) or "N/A") .. " KST")
	local usedBalanceText = infoBox + sheets.Text(#balText + 1, 3, #usedBalText, 1, usedBalText)
	usedBalanceText.style:setField("colour", sheets.colour.lightGrey)
	usedBalanceText.style:setField("textColour", sheets.colour.white)

	return overviewPanel
end

local function createTransactionPanel()
	local transactionPanel = createInfoContainer()
	transactionPanel.type = "transaction"

	local makeTransferPanel = transactionPanel + sheets.Container(1, 1, transactionPanel.width - 2, 9)
	makeTransferPanel.style:setField("colour", sheets.colour.lightGrey)

	local makeTransText = "Make transfer:"
	local makeTransferText = makeTransferPanel + sheets.Text(1, 1, #makeTransText, 1, makeTransText)
	makeTransferText.style:setField("colour", sheets.colour.lightGrey)
	makeTransferText.style:setField("textColour", sheets.colour.black)

	local toTxt = "Recipient: "
	local toText = makeTransferPanel + sheets.Text(1, 3, #toTxt, 1, toTxt)
	toText.style:setField("colour", sheets.colour.lightGrey)
	toText.style:setField("textColour", sheets.colour.black)
	local toField = makeTransferPanel + sheets.TextInput(#toTxt + 1, 3, makeTransferPanel.width - #toTxt - 2, 1)
	toField.style:setField("colour", sheets.colour.grey)
	toField.style:setField("textColour", sheets.colour.lightGrey)
	toField.style:setField("textColour.focussed", sheets.colour.white)

	local amtTxt = "Amount: "
	local amtText = makeTransferPanel + sheets.Text(1, 5, #amtTxt, 1, amtTxt)
	amtText.style:setField("colour", sheets.colour.lightGrey)
	amtText.style:setField("textColour", sheets.colour.black)
	local amtField = makeTransferPanel + sheets.TextInput(#amtTxt + 1, 5, makeTransferPanel.width - #amtTxt - 2, 1)
	amtField.style:setField("colour", sheets.colour.grey)
	amtField.style:setField("textColour", sheets.colour.lightGrey)
	amtField.style:setField("textColour.focussed", sheets.colour.white)

	function amtField:onUnFocus()
		if tonumber(amtField.text) == nil then
			amtField.style:setField("colour", sheets.colour.red)
		else
			amtField.style:setField("colour", sheets.colour.grey)
		end
	end

	local makeTransferButtonText = "Transfer \16"
	local makeTransferButton = makeTransferPanel + sheets.Button(makeTransferPanel.width - #makeTransferButtonText - 3, 7, #makeTransferButtonText + 2, 1, makeTransferButtonText)
	makeTransferButton.style:setField("colour", sheets.colour.green)
	makeTransferButton.style:setField("colour.pressed", sheets.colour.lime)

	return transactionPanel
end

local function setInfoContainer(container, callback)
	screen:removeChild(infoContainer)
	infoContainer = screen + container

	if callback then
		return callback()
	end
end

function sidebarButtons.overview:onClick(btn)
	if btn == 1 then
		return setInfoContainer(createOverviewPanel())
	end
end

function sidebarButtons.transactions:onClick(btn)
	if btn == 1 then
		return setInfoContainer(createTransactionPanel())
	end
end

setInfoContainer(createOverviewPanel())

app:run()