#!/usr/bin/env lua

os.execute("reset")

local ansiPrefix = string.char(27).."["
--local goto00 = ansiPrefix.."0;0H"
local goto00 = ansiPrefix.."H"
local colorRed = ansiPrefix.."31m"
local colorReset = ansiPrefix.."0m"
local colorWhite = ansiPrefix.."37m"
local clearLine = ansiPrefix.."2K"
local stat={}
local space="%s"
stat["scanned"]={}

function add(k,v,tt)
	if v==nil then return end
	tt[k]=v
end	

function statNum(c,t)
	local r=tonumber(stat[c.address..t])
	if r==nil then return 0 else return r end
end

function stats(c)
	t={}
	t["min"]=statNum(c,"min")
	t["max"]=statNum(c,"max")
	t["avg"]=math.floor(statNum(c,"sum")/(statNum(c,"count")+0.01))
	return t
end

function injectString(s,c)
	local ret = s
	ret=ret:sub(0,stats(c).avg).."+"..ret:sub(stats(c).avg+2)
	ret=ret:sub(0,stats(c).min).."<"..ret:sub(stats(c).min+2)
	ret=ret:sub(0,stats(c).max)..">"..ret:sub(stats(c).max+2)
	return ret
end

function bar(c)
	local e="|"
	local n = "-"
	local v = tonumber(c.quality)
	local ret=""
	ret=ret..e:rep(v)
	ret=ret..n:rep(70-v)
	return injectString(ret,c)
end

function col(s,n)
	return string.sub(s.."                    ",0,n)
end

function gatherStat(c)
	if stat[c.address.."max"] then else
		stat[c.address.."max"]=c.quality
		stat[c.address.."min"]=c.quality
		stat[c.address.."count"]=0
		stat[c.address.."sum"]=0
	end
		if stat[c.address.."max"]<c.quality then stat[c.address.."max"] = c.quality end
		if stat[c.address.."min"]>c.quality then stat[c.address.."min"] = c.quality end
		stat[c.address.."count"]=stat[c.address.."count"]+1
		stat[c.address.."sum"]=stat[c.address.."sum"]+c.quality
		stat["scanned"][c.address]=c
end

function proces()

	local proc = assert (io.popen ("/sbin/iwlist scan 2>/dev/null"))
	local r={}
	local tt={}

	for l in proc:lines () do
		--print (l)
		cellnum,address = string.match(l,"%s%s%s%s%s%s%s%sCell (%d+)............(.*)")
		if cellnum then
			r[#r+1] = tt
			tt={}
			add("cellnum",cellnum,tt)
			add("address",address,tt)
		end
		add("essid",string.match(l,"%s%s%sESSID:.(.*)."),tt)
		add("channel",string.match(l,"%s%s%s%Channel:(%d+)"),tt)
		add("quality",string.match(l,"%s%s%sQuality=(%d+).*"),tt)
		end
	r[#r+1] = tt
	table.remove(r,1)
	table.sort(r,function(a,b) return stats(a).avg>stats(b).avg end)
	--table.sort(r,function(a,b) return a.quality>b.quality end)
	--table.sort(r,function(a,b) return a.essid>b.essid end)
	print(goto00)

	for i,c in pairs(r) do
		if c.quality==nil then else
			gatherStat(c)
			print(col(i,3)..col(c.cellnum,3)..col(c.channel,3)..col(c.essid,18)..col(c.address,18)..col(c.quality,3)..bar(c))
		end
	end
	-- for i,j in pairs(stat.scanned) do
	-- 	print(clearLine..i,colorRed..j.essid..colorReset)
	-- end
end

for i=0,1000,1 do
	proces()
end

