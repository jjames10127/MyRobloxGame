local TimeUtil = {}

function TimeUtil.Now()
	return os.time()
end

function TimeUtil.SecondsUntil(timestamp)
	return math.max(0, timestamp - TimeUtil.Now())
end

function TimeUtil.HasExpired(timestamp)
	return TimeUtil.Now() >= timestamp
end

return TimeUtil
