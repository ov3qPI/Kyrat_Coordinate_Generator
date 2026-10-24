KyratRandomCoordinateEventName="kyrat_random_coordinate_event_v20261024T033421Z"
KyratRandomCoordinateEventVersion="v20261024T033421Z"
local prepared_tag={}
local function parse_tsv(text)
  local values={}
  local row=0
  text=text:gsub("^\239\187\191","")
  for line in (text.."\n"):gmatch("([^\r\n]*)\r?\n") do
    if line:match("%S") then
      row=row+1
      local a,b=line:match("^([^\t]+)\t([^\t]+)$")
      if not a then return nil,"TSV row "..row..": expected two tab-separated fields" end
      if not (row==1 and a:match("^%s*[xX]%s*$") and b:match("^%s*[yY]%s*$")) then
        local x,y=tonumber(a),tonumber(b)
        if not x or not y then return nil,"TSV row "..row..": nonnumeric coordinate" end
        values[#values+1]=x;values[#values+1]=y
      end
    end
  end
  return values
end
function KyratParsePolygonTSV(text)
  if type(text)~="string" then return nil,"TSV input must be text" end
  return parse_tsv(text)
end
local function prepare(vertices)
  if type(vertices)=="table" and getmetatable(vertices)==prepared_tag then return vertices end
  if type(vertices)=="string" then
    local parsed,err=parse_tsv(vertices)
    if not parsed then return nil,err end
    vertices=parsed
  end
  if type(vertices)~="table" then return nil,"polygon coordinates are required" end
  local points={}
  if type(vertices[1])=="table" then
    for i=1,#vertices do
      local pair=vertices[i]
      if type(pair)~="table" or #pair~=2 then return nil,"each vertex must contain two coordinates" end
      points[#points+1]=pair[1];points[#points+1]=pair[2]
    end
  else
    for i=1,#vertices do points[i]=vertices[i] end
  end
  if #points%2~=0 or #points<6 then return nil,"at least three coordinate pairs are required" end
  for i=1,#points do
    local value=points[i]
    if type(value)~="number" or value~=value or value==math.huge or value==-math.huge then return nil,"coordinates must be finite numbers" end
  end
  if points[1]==points[#points-1] and points[2]==points[#points] then points[#points]=nil;points[#points]=nil end
  if #points<6 then return nil,"at least three distinct vertices are required" end
  local minx,miny,maxx,maxy=math.huge,math.huge,-math.huge,-math.huge
  local twice=0
  for i=1,#points,2 do
    local x,y=points[i],points[i+1]
    local j=i+2
    if j>#points then j=1 end
    if x<minx then minx=x end
    if x>maxx then maxx=x end
    if y<miny then miny=y end
    if y>maxy then maxy=y end
    twice=twice+x*points[j+1]-points[j]*y
  end
  local area=math.abs(twice)/2
  local rectangle=(maxx-minx)*(maxy-miny)
  if area<=0 or rectangle<=0 or area==math.huge or rectangle==math.huge then return nil,"polygon area and bounds must be finite and positive" end
  local attempts=math.max(256,math.min(1000000,math.ceil(20*rectangle/area)))
  return setmetatable({points=points,minx=minx,miny=miny,maxx=maxx,maxy=maxy,max_attempts=attempts},prepared_tag)
end
function KyratPreparePolygon(coordinates)return prepare(coordinates) end
local function contains(points,x,y)
  local inside=false
  local j=#points-1
  for i=1,#points,2 do
    local ax,ay,bx,by=points[j],points[j+1],points[i],points[i+1]
    if (bx-ax)*(y-ay)==(by-ay)*(x-ax) and x>=math.min(ax,bx) and x<=math.max(ax,bx) and y>=math.min(ay,by) and y<=math.max(ay,by) then return false end
    if (ay>y)~=(by>y) and x<ax+(bx-ax)*(y-ay)/(by-ay) then inside=not inside end
    j=i
  end
  return inside
end
function KyratRandomCoordinateEvent(coordinates,callback)
  if callback~=nil and type(callback)~="function" then return nil,"callback must be a function" end
  local area,err=prepare(coordinates)
  if not area then return nil,err end
  for attempt=1,area.max_attempts do
    local x=area.minx+math.random()*(area.maxx-area.minx)
    local y=area.miny+math.random()*(area.maxy-area.miny)
    if contains(area.points,x,y) then
      if callback then callback(x,y) end
      return x,y
    end
  end
  return nil,"sampling attempts exhausted"
end
