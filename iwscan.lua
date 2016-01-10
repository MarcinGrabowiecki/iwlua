#!/usr/bin/env lua
os.execute("reset")
local ansiPrefix = string.char(27).."["
--local goto00 = ansiPrefix.."0;0H"
local goto00 = ansiPrefix.."H"
local color={["reset"] = ansiPrefix.."0m",["red"] = ansiPrefix.."31m",["green"] = ansiPrefix.."32m",["yellow"]=ansiPrefix.."33m",["blue"]=ansiPrefix.."34m"}
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
	return {["min"]=statNum(c,"min"),["max"]=statNum(c,"max"),["avg"]=math.floor(statNum(c,"sum")/(statNum(c,"count")))}
end

function bar(c)
	local e=":"
	local n = "-"
	local v = tonumber(c.quality)
	local ret=""
	ret=ret..e:rep(v)
	ret=ret..n:rep(70-v)
	--ret=string.rep("1234567890",10);ret=ret:sub(v)
	local st=stats(c)
	local zm=ret:sub(0,st.min)
	local ma=ret:sub(st.min+2,st.avg+1)
	local ax=ret:sub(st.avg+3,st.max+2)
	local xe=ret:sub(st.max+4)
	return color.reset..zm..color.blue.."<"..ma.."+"..ax..">"..color.reset..xe
end

function col(s,n)
	local sp=" "
	return string.sub(s..sp:rep(20),0,n)
end

function gatherStat(c)
	local new = false
	if stat[c.address.."max"] then else
		stat[c.address.."max"]=c.quality
		stat[c.address.."min"]=c.quality
		stat[c.address.."count"]=0,0001
		stat[c.address.."sum"]=0
		new = true
	end
	if stat[c.address.."max"]<c.quality then stat[c.address.."max"] = c.quality end
	if stat[c.address.."min"]>c.quality then stat[c.address.."min"] = c.quality end
	stat[c.address.."count"]=stat[c.address.."count"]+1
	stat[c.address.."sum"]=stat[c.address.."sum"]+c.quality
	stat["scanned"][c.address]=c
	return new
end

function remove(t,key)
	local toremove = 0
	for i,j in pairs(t) do
		toremove=toremove+1
		if j==key then
			table.remove(t,toremove)
			return
		end
	end
	
end

function proces()
	local proc = assert (io.popen ("`which iwlist` scan 2>/dev/null"))
	local r={}
	local tt={}
	for l in proc:lines () do
		--print (l)
		cellnum,address = string.match(l,space:rep(10).."Cell (%d+)............(.*)")
		if cellnum then
			r[#r+1] = tt
			tt={}
			add("cellnum",cellnum,tt)
			add("address",address,tt)
		end
		add("essid",string.match(l,space:rep(20).."ESSID:.(.*)."),tt)
		add("channel",string.match(l,space:rep(20).."Channel:(%d+)"),tt)
		add("quality",string.match(l,space:rep(20).."Quality=(%d+).*"),tt)
		end
	r[#r+1] = tt
	table.remove(r,1)
	table.sort(r,function(a,b) return stats(a).avg>stats(b).avg end)
	--table.sort(r,function(a,b) return a.quality>b.quality end)
	--table.sort(r,function(a,b) return a.essid>b.essid end)
	
	local removed={}
	for i,j in pairs(stat["scanned"]) do
		removed[#removed+1] = i
	end

	print(goto00)
	for i,c in pairs(r) do
		if c.quality==nil then else
			local new=gatherStat(c)
			local row=(col(i,3)..col(c.cellnum,3)..col(c.channel,3)..col(c.essid,18)..col(c.address,18)..col(c.quality,3)..bar(c))
			if new then row=color.green..row..color.reset end
			print(row)
			stat[c.address.."row"]=row
			remove(removed,c.address)
		end
	end

	for i,j in pairs(removed) do
		print(color.red..stat[j.."row"]..color.reset)
	end

	-- for i,j in pairs(stat.scanned) do
	-- 	print(clearLine..i,colorRed..j.essid..colorReset)
	-- end
end

for i=0,1000,1 do
	proces()
	os.execute("sleep 1")
end

