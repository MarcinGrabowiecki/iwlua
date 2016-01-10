#!/usr/bin/env lua
os.execute("reset")
local ansiPrefix = string.char(27).."["
--local goto00 = ansiPrefix.."0;0H"
local goto00 = ansiPrefix.."H"
local color={["reset"] = ansiPrefix.."0m",["red"] = ansiPrefix.."31m",["green"] = ansiPrefix.."32m",["yellow"]=ansiPrefix.."33m",["xblue"]=ansiPrefix.."35m",["blue"]=ansiPrefix.."34m",["yblue"]=ansiPrefix.."36m"}
local bg={["reset"] = ansiPrefix.."0m",["red"] = ansiPrefix.."41m",["green"] = ansiPrefix.."42m",["yellow"]=ansiPrefix.."43m",["blue"]=ansiPrefix.."44m"}
local clearLine = ansiPrefix.."2K"
local space="%s"
local allCells={}
local scanNum=0

function add(k,v,tt)
	if v==nil then return end
	tt[k]=v
end	

function bar(c)
	local e="|"
	local n = "."
	local v = tonumber(c.quality)
	local ret=e:rep(v)..n:rep(70-v)..bg.reset
	--ret=string.rep("1234567890",10);ret=ret:sub(v)
	local zm=ret:sub(0,c.minQuality)
	local ma=ret:sub(c.minQuality+2,c.avgQuality+1)
	local ax=ret:sub(c.avgQuality+3,c.maxQuality+2)
	local xe=ret:sub(c.maxQuality+4)
	return color.reset..zm..color.yblue.."<"..ma.."+"..ax..">"..color.reset..xe
end

function col(s,n)
	local sp=" "
	return string.sub(s..sp:rep(20),0,n)
end

function ifNilVal(e,v)
	if e then return e end
	return v
end

function addWithStats(c,sn)
	if c.address==nil then else
		local qu=tonumber(c.quality)
		if allCells[c.address] == nil
		then
			c.firstScan=sn
			c.scanCount=1
			c.sumQuality=qu
			c.avgQuality=qu
			c.minQuality=qu
			c.maxQuality=qu
			c.new=true
		else
			if c.quality==nil then exit(0) end
			c.scanCount=1+allCells[c.address].scanCount
			c.sumQuality=c.quality+allCells[c.address].sumQuality
			c.avgQuality=math.floor(c.sumQuality/c.scanCount)
			if allCells[c.address].maxQuality < qu then c.maxQuality=qu else c.maxQuality=allCells[c.address].maxQuality end
			if allCells[c.address].minQuality > qu then c.minQuality=qu else c.minQuality=allCells[c.address].minQuality end
			c.new=false
		end
		allCells[c.address]=c
	end
end

function proces()
	scanNum=scanNum+1
	local proc = assert (io.popen ("`which iwlist` scan 2>/dev/null"))
	local tt={}
	for l in proc:lines () do
		cellnum,address = string.match(l,space:rep(10).."Cell (%d+)............(.*)")
		if cellnum then
			addWithStats(tt,scanNum)
			tt={}
			add("cellnum",cellnum,tt)
			add("address",address,tt)
			add("scanNum",scanNum,tt)
		end
		add("essid",string.match(l,space:rep(20).."ESSID:.(.*)."),tt)
		add("channel",string.match(l,space:rep(20).."Channel:(%d+)"),tt)
		add("quality",string.match(l,space:rep(20).."Quality=(%d+).*"),tt)
		end
		addWithStats(tt,scanNum)
	print(goto00)

	toSort={}
	for a,c in pairs(allCells) do
		table.insert(toSort,c)
	end	
	table.sort(toSort,function(a,b) return a.quality>b.quality end)

	for i,c in pairs(toSort) do
		local row=(col(i,3)..col(c.cellnum,3)..col(c.channel,3)..col(c.essid,18)..col(c.address,18)..col(c.quality,3)..bar(c))
		if c.new then row=color.green..row..color.reset end
		if c.scanNum==scanNum then else row=color.red..row..color.reset end
		print(row,scanNum,c.scanNum)
	end
end

for i=0,1000,1 do
	proces()
	os.execute("sleep 1")
end
