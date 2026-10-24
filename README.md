# Kyrat Coordinate Generator
Random coordinate generation within southern Kyrat from Far Cry 4, using a 141-vertex planar map boundary.
## Lua: callable coordinate event
The new [kyrat_random_coordinate_event_v20261024T022552Z.lua](kyrat_random_coordinate_event_v20261024T022552Z.lua) contains a dependency-free Lua function intended as a starting point for an eventual Far Cry 4 gameplay event. It embeds the southern Kyrat boundary and samples uniformly inside its planar area with rejection sampling.
Load the file in a Lua environment before calling the function:
```lua
dofile("kyrat_random_coordinate_event_v20261024T022552Z.lua")
local x,y=KyratRandomCoordinateEvent()
print(x,y)
```
Pass an optional callback to handle the generated pair:
```lua
KyratRandomCoordinateEvent(function(x,y)
  print(x,y)
end)
```
The function returns `x,y` on success or `nil,error_message` on failure. It excludes polygon boundary points, makes at most 512 sampling attempts, and uses the host Lua runtime's `math.random` state. It does not seed that generator itself. Its global version identifier is `KyratRandomCoordinateEventVersion`.
**Integration status:** This is portable Lua logic, not an installed or verified Far Cry 4 mod. The `dofile` example demonstrates a standard Lua host, not a confirmed Dunia/Domino loading mechanism. No Far Cry 4 engine hook, event binding, spawn action, waypoint API, or packaging has been implemented or tested.
**Coordinate system:** Outputs are the original map-image coordinates (approximately X=180–557 and Y=273–712). They are **not** verified in-game Dunia world coordinates. Using the points to place entities in the game will require a validated map-to-world transformation.
## Python: original plotting generator
The original [southern_kyrat_coordinate_generator.py](southern_kyrat_coordinate_generator.py) remains available. It generates and plots a random coordinate inside southern Kyrat, using NumPy, Matplotlib, and Shapely.
Install its dependencies:
```sh
python -m pip install numpy matplotlib shapely
```
Run it with:
```sh
python southern_kyrat_coordinate_generator.py
```
The original [south_kyrat_border_points.csv](south_kyrat_border_points.csv) records the polygon boundary used by both implementations. The Lua script embeds those same vertices, while the original Python script also embeds its own copy.
