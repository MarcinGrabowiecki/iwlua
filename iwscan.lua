#!/usr/bin/lua
local f = assert (io.popen ("/sbin/iwlist scan"))
local r={}
local tt={}
local hist={}

function add(k,v)
	if v==nil then return end
	tt[k]=v
end	

function pc(s)
	print(string.char(27).."["..s)
end

for l in f:lines () do
	--print (l)
	cellnum,address = string.match(l,"Cell (%d+)............(.*)")
	if cellnum then
		r[#r+1] = tt
		tt={}
		add("cellnum",cellnum)
	end
	add("essid",string.match(l,"ESSID:.(.*)."))
	add("channel",string.match(l,"Channel:(.*)"))
	add("quality",string.match(l,"Quality=(%d+).*"))

	--	cellNum,n,cellAddr=string.match(l,"(%d+)(............)(.................)")
	--	n,channel=string.match(l,"(Channel:)(%d+)")
	end
r[#r+1] = tt
table.remove(r,1)

function bar(q)
	local ret=""
	for i=0,q,1 do
		ret=ret.."#"
	end
	for i=0,70-q,1 do
		ret=ret.."_"
	end
	return ret
end

function col(s,n)
	return string.sub(s.."                              ",0,n)
end

table.sort(r,function(a,b) return a.quality>b.quality end)

for i,c in pairs(r) do
	if c.quality==nil then else
		hist[#hist+1] = c
		print(col(i,3)..col(c.cellnum,3)..col(c.channel,3)..col(c.essid,18)..col(c.quality,3)..bar(tonumber(c.quality)))
	end
end

print(#hist)

--pc("31mxpa")
--pc("32mxpa")
--pc("33mxpa")
--pc("34mxpa")
--pc("6n")
--
--pc("10A")
--pc("33mxpa")
