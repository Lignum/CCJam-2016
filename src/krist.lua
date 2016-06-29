local Krist = {}
local JSON = require("src/json.lua")

function Krist.getNode(https)
	if https then
		return "https://krist.ceriat.net"
	else
		return "http://krist.ceriat.net"
	end
end

function Krist.getBalance(addr)
	local req = http.get(Krist.getNode() .. "/addresses/" .. addr)
	local res = req.readAll()

	local address = JSON.decode(res)
	local balance = address.address.balance

	req.close()

	return balance
end

return Krist