# postgis_navigation

This project is used to navigation with postgis and pgrouting in postgresql.
You can create a function with this in  postgresql.

# Usage

## Step 1.
Install postgis and pgrouting extension

## Step 2.
add pgr_fromatob function to your database

## Step 3.
SQL Usage:
```
SELECT ST_AsGeoJson(pgr_fromatob) AS geojson FROM pgr_fromAtoB('line_guide', 0.0001,'102.73590087890626', '36.13787471840729', '103.06686401367188','36.13787471840729');
```

# History
----------------------------------------------------
* Version:1.0.0

* First Version

----------------------------------------------------
# Contacting

Email:itas109@qq.com
QQ Group:129518033

## Links

* [itas109 Blog](http://blog.cadn.net/itas109)

