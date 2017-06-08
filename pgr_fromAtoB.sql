CREATE OR REPLACE function pgr_fromAtoB(tbl varchar,tolerance float,startx float, starty float,endx float,endy float)   
returns  geometry as  
$body$  
declare  
    v_startLine geometry;-- start point's nearest line  
    v_endLine geometry;-- end point's nearest line  
      
    v_startTarget integer;-- the end point of the line that nearest start point  
    v_endSource integer;-- the start point of the line that nearest end point 
  
    v_statpoint geometry;-- the point of nearest start point at v_startLine 
    v_endpoint geometry;-- the point of nearest end point at v_endLine  
      
    v_res geometry;-- shortest path geometry result 
  
    v_perStart float;--v_statpoint at v_res percentage
    v_perEnd float;--v_endpoint  at v_res percentage  
  
    v_shPath geometry;-- result
    tempnode float;	
begin     
    -- Software Version:
    -- pgrouting version:2.1.0 
    -- postgis 2.3.2
    -- postgresql 9.6.3

    -- Algorithm Version:1.0.0
    -- Author:itas109
    -- http://blog.csdn.net/itas109
    -- https://github.com/itas109

    -- set topology null
    -- UPDATE ||tbl|| SET source = NULL,target = NULL;	
    -- create topology
    -- select pgr_createTopology('||tbl||','||tolerance||',source:='source',id:='gid',target:='target',the_geom:='data');
    -- set length
    -- UPDATE line_guide SET length = ST_Length(data);

    -- ************************************************** 
    -- find nearest start point  
    execute 'select data,target  from ' ||tbl||
			' where 
			ST_DWithin(data,ST_Geometryfromtext(''point('||	startx ||' ' || starty||')''),15) 
			order by ST_Distance(data,ST_GeometryFromText(''point('|| startx ||' '|| starty ||')''))  limit 1' 
			into v_startLine ,v_startTarget;  
      
    -- find nearest end point 
    execute 'select data,source  from ' ||tbl||
			' where ST_DWithin(data,ST_Geometryfromtext(''point('|| endx || ' ' || endy ||')''),15) 
			order by ST_Distance(data,ST_GeometryFromText(''point('|| endx ||' ' || endy ||')''))  limit 1' 
			into v_endLine,v_endSource;  
  
    -- if no shortest path,return null   
    if (v_startLine is null) or (v_endLine is null) then  
        return null;  
    end if ;  
  
    select  ST_ClosestPoint(v_startLine, ST_Geometryfromtext('point('|| startx ||' ' || starty ||')')) into v_statpoint;  
    select  ST_ClosestPoint(v_endLine, ST_GeometryFromText('point('|| endx ||' ' || endy ||')')) into v_endpoint;  
  
      
    -- get dijkstra path
    execute 'SELECT st_linemerge(st_union(b.data)) ' || 
    'FROM pgr_kdijkstraPath(  
    ''SELECT gid as id, source, target, length as cost FROM ' || tbl ||''','  
    ||v_startTarget || ', ' ||'array['||v_endSource||'] , false, false  
    ) a, '  
    || tbl || ' b  
    WHERE a.id3=b.gid  
    GROUP by id1  
    ORDER by id1' into v_res ;  

    -- if  v_startTarget = v_endSource, v_res equal null is OK
    if(v_res is null) and (v_startTarget != v_endSource) then  
        return null;  
    end if;

    -- if v_res is MULTILINESTRING,convert to linestring
    if(GeometryType(v_res) = 'MULTILINESTRING') then
    	SELECT ST_LineMerge(ST_SnapToGrid(v_res,0.0001)) into v_res;
    end if;

    -- if v_res still is MULTILINESTRING,represent that v_res has cross line
    if(GeometryType(v_res) = 'MULTILINESTRING') then
    	return null;
    end if;
      
    -- v_res,v_startLine,v_endLine merge 
    select  st_linemerge(ST_Union(array[v_res,v_startLine,v_endLine])) into v_res;  

    -- if v_res is MULTILINESTRING,convert to linestring
    if(GeometryType(v_res) = 'MULTILINESTRING') then
        SELECT ST_LineMerge(ST_SnapToGrid(v_res,0.0001)) into v_res;
    end if;

    -- if v_res still is MULTILINESTRING,represent that v_res has cross line
    if(GeometryType(v_res) = 'MULTILINESTRING') then
    	return null;
    end if;
     
    select  ST_LineLocatePoint(v_res, v_statpoint) into v_perStart;  
    select  ST_LineLocatePoint(v_res, v_endpoint) into v_perEnd;  
	
    if(v_perStart > v_perEnd) then  
        tempnode =  v_perStart;
	      v_perStart = v_perEnd;
	      v_perEnd = tempnode;
    end if;
	
    -- sub v_res
    SELECT ST_Line_SubString(v_res,v_perStart, v_perEnd) into v_shPath;  
       
    return v_shPath;   
      
end;  
$body$  
LANGUAGE plpgsql VOLATILE STRICT 