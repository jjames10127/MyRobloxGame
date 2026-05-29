local NumberUtil = {}

function NumberUtil.Clamp(value, minValue, maxValue)
	return math.clamp(value, minValue, maxValue)
end

function NumberUtil.Round(value, decimals)
	local places = decimals or 0
	local multiplier = 10 ^ places
	return math.floor(value * multiplier + 0.5) / multiplier
end

return NumberUtil
