#!/usr/bin/lua

local ansiPrefix = string.char(27).."["
local goto00 = ansiPrefix.."0;0H"


function add(k,v,tt)
	if v==nil then return end
	tt[k]=v
end	



function proces()

	local f = assert (io.popen ("/sbin/iwlist scan"))
	local r={}
	local tt={}
	local hist={}

	for l in f:lines () do
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
		--	cellNum,n,cellAddr=string.match(l,"(%d+)(............)(.................)")
		end
	r[#r+1] = tt
	table.remove(r,1)

	function bar(q)
		local ret=""
		for i=0,q,1 do
			ret=ret.."|"
		end
		for i=0,70-q,1 do
			ret=ret.."-"
		end
		return ret
	end

	function col(s,n)
		return string.sub(s.."                              ",0,n)
	end

	table.sort(r,function(a,b) return a.quality>b.quality end)

	print(goto00)

	for i,c in pairs(r) do
		if c.quality==nil then else
			hist[#hist+1] = c
			print(col(i,3)..col(c.cellnum,3)..col(c.channel,3)..col(c.essid,18)..col(c.address,18)..col(c.quality,3)..bar(tonumber(c.quality)))
		end
	end
	print(#hist)
	
end

for i=0,100,1 do
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
