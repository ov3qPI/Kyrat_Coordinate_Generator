import argparse,json,math,random,sys
from pathlib import Path
SCRIPT_NAME="kyrat_coordinate_generator_v20261024T033421Z"
SCRIPT_VERSION="v20261024T033421Z"
def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
def segments_intersect(a,b,c,d):
    p,q,r,s=cross(a,b,c),cross(a,b,d),cross(c,d,a),cross(c,d,b)
    def on(u,v,w):return min(u[0],v[0])<=w[0]<=max(u[0],v[0]) and min(u[1],v[1])<=w[1]<=max(u[1],v[1])
    return (p*q<0 and r*s<0) or (p==0 and on(a,b,c)) or (q==0 and on(a,b,d)) or (r==0 and on(c,d,a)) or (s==0 and on(c,d,b))
def validate_simple(points):
    n=len(points)
    for i in range(n):
        for j in range(i+1,n):
            if j==i+1 or (i==0 and j==n-1):continue
            if segments_intersect(points[i],points[(i+1)%n],points[j],points[(j+1)%n]):raise ValueError(f'polygon self-intersects at edges {i+1} and {j+1}')
def normalize_points(values):
    if isinstance(values,(str,bytes)):raise ValueError('coordinates must be numeric pairs or a flat numeric series')
    try:items=list(values)
    except TypeError as error:raise ValueError('coordinates must be a sequence') from error
    if not items:raise ValueError('polygon is empty')
    if isinstance(items[0],(list,tuple)):
        if any(not isinstance(pair,(list,tuple)) or len(pair)!=2 for pair in items):raise ValueError('each vertex must contain exactly two coordinates')
        pairs=items
    else:
        if len(items)%2:raise ValueError('flat coordinates require an even number of values')
        pairs=zip(items[::2],items[1::2])
    try:points=tuple((float(x),float(y)) for x,y in pairs)
    except (TypeError,ValueError) as error:raise ValueError('coordinates must be numeric') from error
    if any(not math.isfinite(x) or not math.isfinite(y) for x,y in points):raise ValueError('coordinates must be finite')
    if len(points)>1 and points[0]==points[-1]:points=points[:-1]
    if len(points)<3:raise ValueError('polygon needs at least three vertices')
    if len(set(points))!=len(points):raise ValueError('polygon contains duplicate vertices')
    return points
def parse_tsv(text):
    points=[]
    for number,line in enumerate(text.lstrip('\ufeff').splitlines(),1):
        if not line.strip():continue
        parts=line.split('\t')
        if not points and len(parts)==2 and [p.strip().lower() for p in parts]==['x','y']:continue
        if len(parts)!=2:raise ValueError(f'TSV line {number}: expected exactly two tab-separated fields')
        points.append([part.strip() for part in parts])
    return normalize_points(points)
class PreparedPolygon:
    __slots__=('points','bounds','area','max_attempts')
    def __init__(self,coordinates,validate=False):
        points=normalize_points(coordinates)
        if validate:validate_simple(points)
        minx=min(p[0] for p in points);miny=min(p[1] for p in points)
        maxx=max(p[0] for p in points);maxy=max(p[1] for p in points)
        twice=sum(x*points[(i+1)%len(points)][1]-points[(i+1)%len(points)][0]*y for i,(x,y) in enumerate(points))
        area=abs(twice)/2;rectangle=(maxx-minx)*(maxy-miny)
        if not math.isfinite(area) or not math.isfinite(rectangle) or area<=0 or rectangle<=0:raise ValueError('polygon must have finite positive area and bounding bounds')
        self.points=points;self.bounds=(minx,miny,maxx,maxy);self.area=area
        self.max_attempts=max(256,min(1000000,math.ceil(20*rectangle/area)))
    def contains(self,x,y):
        inside=False;ax,ay=self.points[-1]
        for bx,by in self.points:
            if (bx-ax)*(y-ay)==(by-ay)*(x-ax) and min(ax,bx)<=x<=max(ax,bx) and min(ay,by)<=y<=max(ay,by):return False
            if (ay>y)!=(by>y) and x<ax+(bx-ax)*(y-ay)/(by-ay):inside=not inside
            ax,ay=bx,by
        return inside
    def sample(self,rng=None):
        rng=random if rng is None else rng
        minx,miny,maxx,maxy=self.bounds
        for _ in range(self.max_attempts):
            x=rng.uniform(minx,maxx);y=rng.uniform(miny,maxy)
            if self.contains(x,y):return x,y
        raise RuntimeError(f'no point accepted after {self.max_attempts} attempts')
def prepare_polygon(coordinates,validate=False):return PreparedPolygon(coordinates,validate)
def sample_coordinate(coordinates,rng=None):return (coordinates if isinstance(coordinates,PreparedPolygon) else PreparedPolygon(coordinates)).sample(rng)
def main(argv=None):
    parser=argparse.ArgumentParser(description='Print random coordinates uniformly sampled within an explicitly supplied polygon')
    source=parser.add_mutually_exclusive_group(required=True)
    source.add_argument('--tsv',type=Path,metavar='PATH',help='read x TAB y rows from the specified TSV')
    source.add_argument('--tsv-text',metavar='TEXT',help='parse a supplied TSV string')
    source.add_argument('--coords',metavar='JSON',help='JSON pairs or flat numeric coordinate series')
    source.add_argument('--stdin-tsv',action='store_true',help='read TSV polygon rows from stdin')
    source.add_argument('--stdin-json',action='store_true',help='read JSON coordinates from stdin')
    parser.add_argument('--count',type=int,default=1)
    parser.add_argument('--seed',type=int)
    parser.add_argument('--validate',action='store_true',help='verify that polygon edges do not intersect')
    args=parser.parse_args(argv)
    if args.count<1:parser.error('--count must be positive')
    try:
        if args.tsv is not None:points=parse_tsv(args.tsv.read_text(encoding='utf-8-sig'))
        elif args.tsv_text is not None:points=parse_tsv(args.tsv_text)
        elif args.stdin_tsv:points=parse_tsv(sys.stdin.read())
        else:points=normalize_points(json.loads(args.coords if args.coords is not None else sys.stdin.read()))
        area=prepare_polygon(points,args.validate);rng=random.Random(args.seed)
        for _ in range(args.count):
            x,y=area.sample(rng)
            print(f'{x:.6f},{y:.6f}')
    except (OSError,TypeError,ValueError,RuntimeError) as error:
        print(f'{SCRIPT_NAME}: {error}',file=sys.stderr)
        return 1
    return 0
if __name__=='__main__':raise SystemExit(main())
