# postgis_navigation

This project is used to navigation with postgis and pgrouting in postgresql.
You can create a function with this in  postgresql.

This time,it can complete one-way navigation.

# Software Version

|  software  | version 
| ---------- | -------------  
| postgresql | 9.6.3  
| postgis    | 2.3.2   
| pgrouting  | 2.4.1        

# Usage

## Step 1.
Install postgis and pgrouting extension

## Step 2.
add pgr_fromatob function to your database

## Step 3.
SQL Usage:
```
SELECT ST_AsGeoJson(pgr_fromatob) AS geojson FROM pgr_fromAtoB('line_guide','102.73590087890626', '36.13787471840729', '103.06686401367188','36.13787471840729');
```

## Step 4.
* result:
![image](https://github.com/itas109/postgis_navigation/raw/master/navigation_0.png)

# History
----------------------------------------------------
* Version:1.0.0

* First Version

----------------------------------------------------
* Version:1.1.0

* reconstruction code
* allow mutilinestring as result,so the path is more accurate
* change function pgr_kdijkstraPath to function pgr_dijkstra
* set pgr_dijkstra only for directed
* fixed un-directed problem
* fixed on path sub problem 

----------------------------------------------------
# Contacting

* Email:itas109@qq.com
* QQ Group:129518033

## Links

* [itas109 Blog](http://blog.csdn.net/itas109)

## Reference
* http://blog.csdn.net/longshengguoji/article/details/46793111
