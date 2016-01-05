#!/usr/bin/lua

os.execute("reset")

local ansiPrefix = string.char(27).."["
local goto00 = ansiPrefix.."0;0H"
local hist={}
local stat={}


function add(k,v,tt)
	if v==nil then return end
	tt[k]=v
end	

function injectString(s,c)
	local ret = s
	local min=tonumber(stat[c.address.."min"])
	local max=tonumber(stat[c.address.."max"])
	local sum=tonumber(stat[c.address.."sum"])
	local count=tonumber(stat[c.address.."count"])
	local avg=math.floor(sum/count)
	if count == 0 then avg=0 end
	ret=ret:sub(0,avg).."a"..ret:sub(avg+2)
	ret=ret:sub(0,min).."m"..ret:sub(min+2)
	ret=ret:sub(0,max).."X"..ret:sub(max+2)
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
	if stat[c.address.."max"]
		then if stat[c.address.."max"]<c.quality then stat[c.address.."max"] = c.quality end
		else stat[c.address.."max"]=c.quality
	end

	if stat[c.address.."min"]
		then if stat[c.address.."min"]>c.quality then stat[c.address.."min"] = c.quality end
		else stat[c.address.."min"]=c.quality
	end

	if stat[c.address.."count"]
		then stat[c.address.."count"]=stat[c.address.."count"]+1
		else stat[c.address.."count"]=0
	end

	if stat[c.address.."sum"]
		then stat[c.address.."sum"]=stat[c.address.."sum"]+c.quality
		else stat[c.address.."sum"]=0
	end
end

function proces()

	local proc = assert (io.popen ("/sbin/iwlist scan 2>/dev/null"))
	local r={}
	local tt={}

	for l in proc:lines () do
		--print (l)
		cellnum,address = string.match(l,"Cell (%d+)............(.*)")
		if cellnum then
			r[#r+1] = tt
			tt={}
			add("cellnum",cellnum,tt)
			add("address",address,tt)
		end
		add("essid",string.match(l,"ESSID:.(.*)."),tt)
		add("channel",string.match(l,"Channel:(%d+)"),tt)
		add("quality",string.match(l,"Quality=(%d+).*"),tt)
		--cellNum,n,cellAddr=string.match(l,"(%d+)(............)(.................)")
		end
	r[#r+1] = tt
	table.remove(r,1)

	-- table.sort(r,function(a,b) return a.quality>b.quality end)
	table.sort(r,function(a,b) return a.essid>b.essid end)

	print(goto00)

	for i,c in pairs(r) do
		if c.quality==nil then else
			hist[#hist+1] = c
			gatherStat(c)
			print(col(i,3)..col(c.cellnum,3)..col(c.channel,3)..col(c.essid,18)..col(c.address,18)..col(c.quality,3)..bar(c))
		end
	end
	--print(#hist)
end

for i=0,1000,1 do
	proces()
end

--pc("31mxpa")
--pc("32mxpa")
--pc("33mxpa")
--pc("34mxpa")
--pc("6n")
--
--pc("10A")
--pc("33mxpa")
