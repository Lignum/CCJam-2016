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

local addressInUse = ""

local krist = require("src/krist.lua")
local sheets = require("src/sheets.lua")

local app = sheets.Application()
local screen = app.screen

local introContainer = screen + sheets.Container(0, 0, screen.width, screen.height)
introContainer.style:setField("colour", sheets.colour.lightBlue)

local inputDataBox = introContainer + sheets.Container(2, math.floor(introContainer.height / 2) - 3, introContainer.width - 4, 6)
inputDataBox.style:setField("colour", sheets.colour.cyan)

local startTxt = "Start \16"
local startButton = inputDataBox + sheets.Button(inputDataBox.width - #startTxt - 3, inputDataBox.height - 2, #startTxt + 2, 1, startTxt)
startButton.style:setField("colour", sheets.colour.grey)
startButton.style:setField("colour.pressed", sheets.colour.grey)

local privatekeyTxt = "Password: "
local privatekeyText = inputDataBox + sheets.Text(1, 1, #privatekeyTxt, 1, privatekeyTxt)
privatekeyText.style:setField("colour", sheets.colour.cyan)
privatekeyText.style:setField("textColour", sheets.colour.black)
local privatekeyBox = inputDataBox + sheets.TextInput(privatekeyText.width + 1, 1, inputDataBox.width - privatekeyText.width - 2, 1)
privatekeyBox.style:setField("mask", "*")

local addressText = inputDataBox + sheets.Text(1, 3, inputDataBox.width - 1, 1, "=> ...")
addressText.style:setField("colour", sheets.colour.cyan)

function privatekeyBox:onUnFocus()
	local address = krist.makeAddress(privatekeyBox.text)

	if #privatekeyBox.text > 0 and address then
		addressText:setText("=> " .. address)
		addressText.style:setField("textColour", sheets.colour.black)

		startButton.style:setField("colour", sheets.colour.green)
		startButton.style:setField("colour.pressed", sheets.colour.lime)

		startButton.validAddress = true
	else
		addressText:setText("=> N/A")
		addressText.style:setField("textColour", sheets.colour.red)

		startButton.style:setField("colour", sheets.colour.grey)
		startButton.style:setField("colour.pressed", sheets.colour.grey)

		startButton.validAddress = false
	end
end

local privatekey = ""

local walletContainer = screen + sheets.Container(screen.width, 0, screen.width, screen.height)

local sidebarRelativeWidth = 0.32
local sidebarWidth = math.floor(screen.width * sidebarRelativeWidth + 0.5)
local infoContainer = nil

-- Sidebar creation
local sidebar = walletContainer + sheets.Container(0, 0, sidebarWidth, screen.height)
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

	--makeTransferButton.style:setField("colour", sheets.colour.green)
	--makeTransferButton.style:setField("colour.pressed", sheets.colour.lime)

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

	local makeTransferButtonText = "Transfer \16"
	local makeTransferButton = makeTransferPanel + sheets.Button(makeTransferPanel.width - 3 - #makeTransferButtonText, makeTransferPanel.height - 2, #makeTransferButtonText + 2, 1, makeTransferButtonText)

	local stateText = makeTransferPanel + sheets.Text(1, 7, makeTransferPanel.width - 3 - makeTransferButton.width, 1, "Idle")
	stateText.style:setField("colour", sheets.colour.lightGrey)
	stateText.style:setField("textColour", sheets.colour.grey)

	local function confirmTransferButtonState()
		local valid = true

		if tonumber(amtField.text) == nil then
			valid = false
			amtField.style:setField("colour", sheets.colour.red)
		else
			amtField.style:setField("colour", sheets.colour.grey)
		end

		if #toField.text ~= 10 then
			valid = false
			toField.style:setField("colour", sheets.colour.red)
		else
			toField.style:setField("colour", sheets.colour.grey)
		end

		--makeTransferButton.style:setField("colour", valid and sheets.colour.green or sheets.colour.grey)
		--makeTransferButton.style:setField("colour.pressed", valid and sheets.colour.lime or sheets.colour.grey)
		return valid
	end

	function makeTransferButton:onClick(btn)
		--[[if btn == 1 and confirmTransferButtonState() then
			local amount = tonumber(amtField.text)
			local toAddr = toField.text

			if krist.performTX(privatekey, toAddr, amount) == nil then
				stateText:setText("Failed")
				stateText.style:setField("colour", sheets.colour.red)
			else
				stateText:setText("Transaction complete")
				stateText.style:setField("colour", sheets.colour.lime)
			end
		end]]
	end

	confirmTransferButtonState()

	function amtField:onUnFocus()
		return confirmTransferButtonState()
	end

	function toField:onUnFocus()
		return confirmTransferButtonState()
	end

	return transactionPanel
end

local function makeActiveSidebarButton(btn)
	for _,v in pairs(sidebarButtons) do
		v.style:setField("textColour", sheets.colour.black)
	end

	btn.style:setField("textColour", sheets.colour.white)
end

local function setInfoContainer(container, callback)
	screen:removeChild(infoContainer)
	infoContainer = walletContainer + container

	if callback then
		return callback()
	end
end

function sidebarButtons.overview:onClick(btn)
	if btn == 1 then
		makeActiveSidebarButton(sidebarButtons.overview)
		return setInfoContainer(createOverviewPanel())
	end
end

function sidebarButtons.transactions:onClick(btn)
	if btn == 1 then
		makeActiveSidebarButton(sidebarButtons.transactions)
		return setInfoContainer(createTransactionPanel())
	end
end

function startButton:onClick(btn)
	if btn == 1 and startButton.validAddress then
		local addr, pkey = krist.login(privatekeyBox.text)
		addressInUse = addr
		privatekey = pkey

		if addr == nil then
			startButton.style:setField("colour", sheets.colour.red)
			return
		end

		introContainer:animateX(-screen.width)
		walletContainer:animateX(0)

		setInfoContainer(createOverviewPanel())
	end
end

makeActiveSidebarButton(sidebarButtons.overview)

app:run()