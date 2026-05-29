local TableUtil = {}

function TableUtil.DeepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, childValue in pairs(value) do
		copy[TableUtil.DeepCopy(key)] = TableUtil.DeepCopy(childValue)
	end

	return copy
end

function TableUtil.Reconcile(defaultData, loadedData)
	local reconciled = TableUtil.DeepCopy(defaultData)
	if type(loadedData) ~= "table" then
		return reconciled
	end

	for key, loadedValue in pairs(loadedData) do
		if type(loadedValue) == "table" and type(reconciled[key]) == "table" then
			reconciled[key] = TableUtil.Reconcile(reconciled[key], loadedValue)
		elseif reconciled[key] ~= nil then
			reconciled[key] = loadedValue
		end
	end

	return reconciled
end

return TableUtil
