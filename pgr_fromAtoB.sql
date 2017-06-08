CREATE OR REPLACE function pgr_fromAtoB(tbl varchar,startx float, starty float,endx float,endy float)   
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

		v_perStartLine geometry;--v_statpoint at v_res percentage Line
    v_perEndLine geometry;--v_endpoint  at v_res percentage Line
  
    v_shPath geometry;-- result
    tempnode float;	
begin     
    -- Software Version:
    -- pgrouting version:2.4.1 
    -- postgis 2.3.2
    -- postgresql 9.6.3

    -- Algorithm Version:1.1.0
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
    -- find nearest start line and start target id in topology
    execute 'select data,target  from ' ||tbl||	' 
      where 
			ST_DWithin(data,ST_Geometryfromtext(''point('||	startx ||' ' || starty||')''),15) 
			order by ST_Distance(data,ST_GeometryFromText(''point('|| startx ||' '|| starty ||')''))  limit 1' 
			into v_startLine ,v_startTarget;  
      
    -- find nearest end line and end source id in topology 
    execute 'select data,source  from ' ||tbl||	' 
			where
			ST_DWithin(data,ST_Geometryfromtext(''point('|| endx || ' ' || endy ||')''),15) 
			order by ST_Distance(data,ST_GeometryFromText(''point('|| endx ||' ' || endy ||')''))  limit 1' 
			into v_endLine,v_endSource;  
  
    -- if no shortest path,return null   
    if (v_startLine is null) or (v_endLine is null) then  
        return null;  
    end if ;  
  
		-- start point nearest point at start line
    select  ST_ClosestPoint(v_startLine, ST_Geometryfromtext('point('|| startx ||' ' || starty ||')')) into v_statpoint;  
		-- end point nearest point at end line
    select  ST_ClosestPoint(v_endLine, ST_GeometryFromText('point('|| endx ||' ' || endy ||')')) into v_endpoint;  

    -- sub v_startLine to v_perStartLine
	  select  ST_LineLocatePoint(v_startLine, v_statpoint) into v_perStart;  
    select ST_Line_SubString(v_startLine,v_perStart, 1) into v_perStartLine;

		-- sub v_endLine to v_perEndLine
    select  ST_LineLocatePoint(v_endLine, v_endpoint) into v_perEnd;  
    select ST_Line_SubString(v_endLine,0, v_perEnd) into v_perEndLine;  
  
		--  if v_startLine equal v_endLine,and v_perStart > v_perEnd, represent path is opposite
    if (v_startLine = v_endLine) and (v_perStart > v_perEnd) then  
        return null;  
    end if ;  

    -- if v_startLine equal v_endLine,and path is directed. sub line to result,and return
    if(v_startLine = v_endLine) and (v_perStart < v_perEnd) then  
        select ST_Line_SubString(v_startLine,v_perStart, v_perEnd) into v_shPath; 
				return v_shPath;
    end if;
      
    -- get dijkstra path
		-- pgr_dijkstra(text sql, integer source, integer target,boolean directed, boolean has_rcost);
		-- we set directed true.
    execute 'SELECT st_linemerge(st_union(b.data)) ' || 
    'FROM pgr_dijkstra(  
    ''SELECT gid as id, source, target, length as cost FROM ' || tbl ||''','  
    ||v_startTarget || ', '||v_endSource||' , true, false  
    ) a, 
		' || tbl || ' b  
    WHERE a.id2=b.gid  
    GROUP by id1  
    ORDER by id1' into v_res ;  

    -- if  v_startTarget = v_endSource, v_res equal null is OK
    if(v_res is null) and (v_startTarget != v_endSource) then  
        return null;  
    end if;
     
    -- v_res,v_startLine,v_endLine merge 
    -- we allow the result is mutilinestring
    select  st_linemerge(ST_Union(array[v_res,v_perStartLine,v_perEndLine])) into v_shPath; 
       
    return v_shPath;   
      
end;  
$body$  
LANGUAGE plpgsql VOLATILE STRICT 