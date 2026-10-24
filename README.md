# Kyrat Coordinate Generator
A general-purpose, dependency-free random coordinate generator for simple planar polygons. The repository includes Python and Lua implementations using uniform bounding-box rejection sampling. Neither implementation embeds a map boundary or loads a default file. **You must provide the polygon on each standalone invocation or prepare and reuse it programmatically.**
## Files
- [kyrat_coordinate_generator_v20261024T033421Z.py](kyrat_coordinate_generator_v20261024T033421Z.py) — Python command-line and importable generator (standard library only).
- [kyrat_random_coordinate_event_v20261024T033421Z.lua](kyrat_random_coordinate_event_v20261024T033421Z.lua) — Callable Lua generator with a prepared-polygon interface.
- [south_kyrat_border_points_v20261024T033421Z.tsv](south_kyrat_border_points_v20261024T033421Z.tsv) — Example southern Kyrat polygon; 141 vertices, two tab-separated columns (`x`, `y`) with no required header.
- [LICENSE](LICENSE) — CC0 1.0 Universal.
## Python: terminal output
Provide an arbitrary polygon as JSON, TSV, or a Python coordinate series. Exactly one `x,y` pair is printed by default; `--count N` prints N pairs.
```sh
python kyrat_coordinate_generator_v20261024T033421Z.py --coords '[[0,0],[10,0],[10,10],[0,10]]'
python kyrat_coordinate_generator_v20261024T033421Z.py --tsv south_kyrat_border_points_v20261024T033421Z.tsv
python kyrat_coordinate_generator_v20261024T033421Z.py --tsv south_kyrat_border_points_v20261024T033421Z.tsv --count 10 --seed 42
```
For pipelines, use `--stdin-tsv` or `--stdin-json`; `--tsv-text` accepts TSV content directly. TSV rows contain exactly two tab-separated numeric values, optionally preceded by an `x<TAB>y` header.
As a Python library:
```python
from kyrat_coordinate_generator_v20261024T033421Z import prepare_polygon
area=prepare_polygon([(0,0),(10,0),(10,10),(0,10)])
x,y=area.sample()
```
An optional `--validate` checks self-intersections. Inputs must represent valid simple polygons with nonzero area; invalid geometry may yield incorrect sampling if self-intersection checks are skipped.
## Lua: callable event
Load the Lua file in a standard Lua host, then provide nested or flat coordinate series:
```lua
dofile("kyrat_random_coordinate_event_v20261024T033421Z.lua")
local x,y=KyratRandomCoordinateEvent({{0,0},{10,0},{10,10},{0,10}})
```
Reuse the prepared polygon when generating repeatedly:
```lua
local polygon=KyratPreparePolygon({{0,0},{10,0},{10,10},{0,10}})
local x1,y1=KyratRandomCoordinateEvent(polygon)
local x2,y2=KyratRandomCoordinateEvent(polygon)
KyratRandomCoordinateEvent(polygon,function(x,y) print(x,y) end)
```
Lua also accepts the text of a TSV polygon with `KyratPreparePolygon(tsv_text)` or `KyratRandomCoordinateEvent(tsv_text)`, and exposes `KyratParsePolygonTSV(tsv_text)`. No file is read automatically. Callers are responsible for supplying text or coordinate values.
Functions return coordinates on success and `nil,error_message` for invalid arguments or failed sampling. The Lua implementation uses the host's `math.random` state.
## Sampling method
Both versions compute the bounding rectangle once when preparing a polygon. They draw uniform candidate points in that rectangle and reject candidates outside the input polygon. Accepted coordinates are uniform in the **original polygon's planar area**, not its bounding box. There is no convex hull, triangulation, cached dataset, or hardcoded southern Kyrat geometry.
## Far Cry 4 status
This code is **not an installed or verified Far Cry 4 modification**. A native Dunia/Domino loading mechanism and in-game action binding have not been implemented. The example southern Kyrat TSV uses historical map-image coordinates, **not validated Far Cry 4 world coordinates**.
