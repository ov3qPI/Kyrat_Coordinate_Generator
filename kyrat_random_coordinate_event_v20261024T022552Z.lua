KyratRandomCoordinateEventVersion="kyrat_random_coordinate_event_v20261024T022552Z"
local coordinates={
  211,423,203,440,194,437,188,441,188,448,190,454,199,456,202,459,
  204,461,200,459,201,468,197,478,199,484,191,494,188,500,191,510,
  190,517,185,523,182,531,180,535,180,541,183,543,184,550,187,557,
  193,558,194,561,192,568,193,575,195,582,190,593,193,601,197,606,
  205,608,211,607,216,608,223,608,223,617,226,619,227,613,229,609,
  243,616,245,610,254,600,263,595,263,601,264,604,268,604,270,608,
  273,609,279,607,288,604,292,608,293,614,300,617,311,621,320,619,
  340,642,347,657,337,663,326,671,325,684,320,693,325,708,335,706,
  340,694,347,683,359,691,366,698,384,706,405,709,418,712,444,704,
  456,686,465,687,473,705,487,700,486,666,500,641,489,618,501,604,
  522,583,532,551,557,535,556,516,552,480,557,453,556,434,547,417,
  536,413,544,401,540,396,532,395,523,391,513,390,509,385,505,375,
  507,367,508,357,506,349,509,340,498,340,479,341,480,332,480,321,
  472,318,468,323,456,319,449,313,441,310,452,304,452,295,442,300,
  436,295,432,295,430,302,424,301,401,308,376,300,367,292,365,284,
  359,278,343,273,336,282,322,276,321,284,312,298,312,325,323,338,
  320,361,324,383,321,407,305,421,291,397,272,382,259,378,247,390,
  225,406,213,411,202,413,206,419,212,419
}
local minx,miny,maxx,maxy=math.huge,math.huge,-math.huge,-math.huge
for i=1,#coordinates,2 do
  local x,y=coordinates[i],coordinates[i+1]
  if x<minx then minx=x end
  if x>maxx then maxx=x end
  if y<miny then miny=y end
  if y>maxy then maxy=y end
end
local function contains(x,y)
  local inside=false
  local j=#coordinates-1
  for i=1,#coordinates,2 do
    local xi,yi,xj,yj=coordinates[i],coordinates[i+1],coordinates[j],coordinates[j+1]
    local dx,dy=xj-xi,yj-yi
    if dx*(y-yi)==dy*(x-xi) and x>=math.min(xi,xj) and x<=math.max(xi,xj) and y>=math.min(yi,yj) and y<=math.max(yi,yj) then return false end
    if (yi>y)~=(yj>y) and x<xi+dx*(y-yi)/dy then inside=not inside end
    j=i
  end
  return inside
end
function KyratRandomCoordinateEvent(callback)
  if callback~=nil and type(callback)~="function" then return nil,"callback must be a function" end
  for attempt=1,512 do
    local x=minx+math.random()*(maxx-minx)
    local y=miny+math.random()*(maxy-miny)
    if contains(x,y) then
      if callback then callback(x,y) end
      return x,y
    end
  end
  return nil,"sampling attempts exhausted"
end
