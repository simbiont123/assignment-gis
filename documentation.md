# Dokumentácia projektu

**Opis aplikácie**: `Aplikácia pre vyhľadávanie múzeí a galérií v Moskve a blízkom okolí`

**Zdroj dát**: `open street maps`

**Použité technológie**: `ruby, ruby on rails, jquery, leaflet, postgis`

### Opis domény

Úlohou aplikácie je zobrazovanie múzeí a galérií v jednom z veľkých miest, ako je Moskva a jej blízke okolie. Aplikácia umožňuje zobrazovanie múzeí a galérii spolu s dodatočnými informáciami získanými zo zdroja dát [OpenStreetMap](https://www.openstreetmap.org/). Opis jednotlivých scenárov sa nachádza nižšie v dokumentácií.

### Frontend 

Frontedová časť aplikácie zobrazuje statickú HTML stránku `home.html.erb`, ktorá rendruje mapu z [Mapboxu](https://www.mapbox.com/) a grafické prvky sú do nej pridávané pomocou [Leaflet.js](http://leafletjs.com/).

Javascript pre frontend sa nachádza v `custom.js` a je volaný z uvedenej `home.html.erb`. Úlohou tohto kódu je len transformovať požiadavky používateľa na API volania a odpovede z backendu zobrazovať na mape v podobe bodov, čiar alebo polygónov.

Pre lepší vzhľad mapy som využil Mapbox Studio, ktoré dovoľuje takmer ľuboveľne upravovať vzhľad mapy. Zameral som na zvýraznenie budov, ktoré sú bodom záujmu (múzeá a galérie) a odfiltroval som rušivé prvky, ktoré pre projekt nie sú potrebné ako lesy, vodné plochy, a pod. 

### Backend 

Backendová časť aplikácie je napísaná v jazyku Ruby sa využitia aplikačného rámca Ruby on Rails. Táto časť je zodpovedná za všetky dopyty a úpravu dát z geo databázy.

### Opis scenárov + príklady dopytov
#### Scenár 1 - Zobrazenie múzeí a galérií v požadovanom rozsahu
Zobrazenie všetkých múzeí a galérii od zvoleného bodu, ktoré sa nachádzajú do maximálnej požadovanej vzdialenosti (taktiež zvolená). Farebná škála ukazuje vzdialenosť od zvoleného bodu. Čím tmavšia, tým je múzeum, alebo galéria ďalej od miesta určenia.

Dopyt pozostáva zo získania všetkých galérií a múzeí spolu s ich vzdialenosťou, ktoré sú vo zvolenom rozsahu. Každé múzeum alebo galéria je zobrazená ako bod, ktorý obsahuje dodatočné informácie, ako sú meno, spomínaná vzdialenosť, vybavenie, alebo či je to obchod so suvenírmi.

použité postgis funkcie : `ST_DWithin, ST_Distance`

SQL:
```sql
SELECT name, amenity, shop,  
ST_Distance(ST_SetSRID(ST_MakePoint('#{params[:lon]}', '#{params[:lat]}'),4326)::geography, way::geography) AS distance, ST_AsGeoJSON(way) AS geometry
  FROM museums_points
  WHERE ST_DWithin(ST_SetSRID(ST_MakePoint('#{params[:lon]}', '#{params[:lat]}'),4326)::geography, way::geography, '#{params[:range]}')
  ORDER BY distance ASC
```
**API** : `GET /museums/all_range?lat=55.80205284218845&lon=37.59933471679688&range=100000`
##### Príklad odpovede
JSON:
```json
[  
   {  
      "title":"Музей \"Храм Покрова в Филях\"",
      "distance":"947.28",
      "type":"Feature",
      "geometry":{  
         "type":"Point",
         "coordinates":[  
            37.5102343,
            55.7506982
         ]
      },
      "properties":{  
         "title":"Музей \"Храм Покрова в Филях\"",
         "description":"Amenity: not available | \nShop:  not available | Distance to point: 47.28 m",
         "marker-color":"#00cc00",
         "marker-size":"large",
         "marker-symbol":"museum"
      }
   }
]
```
#### Scenár 2 - Zobrazenie parkovísk v požadovanom rozsahu od múzeí a galérií v požadovanom rozsahu 
Zobrazenie všetkých múzeí a galérií od zvoleného bodu, ktoré sa nachádzajú do maximálnej požadovanej vzdialenosti (taktiež zvolená) a k nim všetky parkoviská, ktoré sú taktiež v požadovanej vzdialenosti (opäť zvolená).Farebná škála ukazuje vzdialenosť od najbližšieho parkoviska. Čím tmavšia, tým je múzeum, alebo galéria ďalej od miesta určenia.

Dopyt pozostáva v prvom kroku zo získania všetkých galérií a múzeí spolu s ich vzdialenosťou, ktoré sú vo zvolenom rozsahu. Tento výsledok je pridružený k parkoviskám, ktoré tiež spĺňajú rozsahové kritérium. Každé múzeum alebo galéria je zobrazená ako bod, ktorý obsahuje dodatočné informácie, ako sú meno, vzdialenosť od zvoleného bodu, alebo najkratšia vzdialenosť k parkovisku, vybevenie, alebo či je to obchod so suvenírmi. Každé parkovisko je zobrazené ako polygón a obsahuje rovnako aj informácie ako sú meno, alebo vzdialenosť od najbližšieho múzea.

použité postgis funkcie : `ST_DWithin, ST_Distance`

SQL:
```sql
WITH m AS (SELECT m.*, ST_Distance(ST_SetSRID(ST_MakePoint('#{params[:lon]}', '#{params[:lat]}'),4326)::geography, way::geography) AS distance2
    FROM museums_points m
    WHERE ST_DWithin(ST_SetSRID(ST_MakePoint('#{params[:lon]}', '#{params[:lat]}'),4326)::geography, way::geography, '#{params[:range]}'))
    SELECT m.name,m.distance2,ST_AsGeoJSON(p.way) AS geometry,ST_AsGeoJSON(m.way) AS geometry2,ST_Distance(m.way::geography, p.way::geography) AS distance FROM m
    CROSS JOIN museums_parking p 
    WHERE ST_DWithin(m.way::geography, p.way::geography, '#{params[:range2]}')
    ORDER BY distance ASC
```
**API** : `GET /museums/all?lat=55.8159439039053&lon=37.61581420898438&range=100000&range2=1000`
##### Príklad odpovede
JSON:
```json
[  
   {  
      "title":"Музей техники Apple",
      "distance":"147.56",
      "type":"Feature",
      "geometry":{  
         "type":"Polygon",
         "coordinates":[  
            [  
               [  
                  37.5909681,
                  55.8047694
               ],
               [  
                  37.5909807,
                  55.8047395
               ],
               [  
                  37.5910126,
                  55.8047146
               ]
               "comment: ... (skratene kvoli setreniu miesta v tejto dokumentacii)"
            ]
         ]
      },
      "properties":{  
         "title":"Музей техники Apple",
         "description":"Amenity: not available | \nShop:  not available | Distance to closest museum: 147.56 m",
         "marker-color":"#00FF00"
      }
   }
]
```
#### Scenár 3 - Zobrazenie múzeí a galérií v zadanom polygóne
Zobrazenie všetkých múzeí a galérii, ktoré sa nachádzajú vo zvolenom polygóne (zvolené 4 body).

Dopyt pozostáva zo získania všetkých galérií a múzeí spolu s ich rozlohou, ktoré sú vo zvolenom polygóne. Každé múzeum alebo galéria je zobrazená ako polygón, ktorý obsahuje dodatočné informácie, ako sú meno, spomínaná rozloha v metroch štvorcových, vybevenie, alebo či je to obchod so suvenírmi.

použité postgis funkcie : `ST_Area, ST_Contains`

SQL:
```sql
SELECT name,amenity,shop, ST_Area(way::geography)*POWER(0.3048,2) AS distance, ST_AsGeoJSON(way) AS geometry
    FROM museums
    WHERE ST_Contains(ST_SetSRID(ST_MakePolygon(ST_GeomFromText('LINESTRING(#{params[:lon1]} #{params[:lat1]},#{params[:lon2]} #{params[:lat2]},#{params[:lon3]} #{params[:lat3]},#{params[:lon4]} #{params[:lat4]},#{params[:lon1]} #{params[:lat1]})')),4326)::geometry, way::geometry)
    ORDER BY distance ASC
```
**API** : `GET /museums/polygon?lat1=55.78120695355271&lon1=37.70095825195313&lat2=55.694615940831945&lon2=37.60208129882813&lat3=55.7309766355099&lon3=37.49084472656251&lat4=55.80591196770664&lon4=37.58285522460938`
##### Príklad odpovede
JSON:
```json
[  
   {  
      "title":"Дом Бурганова",
      "distance":"3.45",
      "type":"Feature",
      "geometry":{  
         "type":"Polygon",
         "coordinates":[  
            [  
               [  
                  37.5971759,
                  55.7465148
               ],
               [  
                  37.5972547,
                  55.7465141
               ],
               [  
                  37.5972862,
                  55.7465138
               ],
               [  
                  37.5972845,
                  55.7465609
               ],
               "comment: ... (skratene kvoli setreniu miesta v tejto dokumentacii)"
            ]
         ]
      },
      "properties":{  
         "title":"Дом Бурганова",
         "description":"Amenity: not available | \nShop:  not available | Area: 3.45 m^2",
         "color":"#ffffff"
      }
   }
]
```

#### Scenár 4 - Zobrazenie múzeí a galérií v zadanej línii spolu s ich chodníkmi
Zobrazenie všetkých múzeí a galérii, ktoré sa nachádzajú vo zvolenej línii (zvolené 2 body). K nim je pridaná informácia s ich okolitými chodníkmi (prístupovými cestami).

Dopyt pozostáva zo získania všetkých galérií a múzeí spolu s ich rozlohou, ktoré sú vo zvolenej línii. Tento výsledok je pridružený ku chodníkom , ktoré sa nachádzajú v blizkosti výsledných múzeií (resp. prelínajú rozlohu múzea) alebo galérií. Každé múzeum alebo galéria je zobrazená ako polygón, ktorý obsahuje dodatočné informácie, ako sú meno, spomínaná rozloha v metroch štvorcových, vybevenie, alebo či je to obchod so suvenírmi.

použité postgis funkcie : `ST_Intersects`

SQL:
```sql
WITH m AS (SELECT name,amenity,shop,way AS way2, ST_AsGeoJSON(way) AS geometry
    FROM museums
    WHERE ST_Intersects(ST_SetSRID(ST_MakeLine(ST_MakePoint('#{params[:lon]}', '#{params[:lat]}'), ST_MakePoint('#{params[:lon1]}', '#{params[:lat1]}')),4326)::geometry, way::geometry))
    SELECT m.*, ST_AsGeoJSON(l.way) AS geometry2
    FROM m
    CROSS JOIN lines_footway l 
    WHERE ST_Intersects(m.way2::geometry, l.way::geometry)
```
**API** : `GET /museums/line?lat=55.74436160832188&lon=37.61229515075684&lat1=55.74767090272232&lon1=37.60418415069581`
##### Príklad odpovede
JSON:
```json
[  
   {  
      "title":"Музей изобразительных искусств им. Пушкина",
      "type":"Feature",
      "geometry":{  
         "type":"Polygon",
         "coordinates":[  
            [  
               [  
                  37.6042776,
                  55.7471899
               ],
               [  
                  37.6044521,
                  55.747129
               ],
               [  
                  37.6044689,
                  55.7471442
               ],
               [  
                  37.6048145,
                  55.7470236
               ],
               [  
                  37.6047936,
                  55.7470046
               ],
               "comment: ... (skratene kvoli setreniu miesta v tejto dokumentacii)"
         ]
      },
      "properties":{  
         "title":"Музей изобразительных искусств им. Пушкина",
         "description":"Amenity: not available | \nShop:  not available"
      }
   }
]
```
### Informácie o dátach v databáze, indexy 

Vo svojom projekte som pracoval s dátami z ```open street maps```, konkrétne som si vybral mesto Moskva nakoľko sa tu nachádza najviac múzeií a galérii v rozsahu, ktorý bolo možné získať z ```open street maps```. Na tejto ploche sa nachádzalo viac ako 300 múzeií a galérií.

Pri vytváraní indexov som sledoval ako vytvorené indexy pomohli dopytu, čo sa týka či už časového hľadiska zo strany používateľa alebo pomocou príkazu ```EXPLAIN SELECT ...```

Pri väčšine dopytov som si vytvoril views, najmä pre sprehľadnenie a následnú jednoduchú prácu s nimi.

```sql
CREATE materialized view museums AS
  SELECT * FROM planet_osm_polygon
  WHERE name IS NOT NULL AND (tourism = 'museum' OR tourism = 'gallery')
CREATE materialized view museums_points AS
  SELECT * FROM planet_osm_point
  WHERE name IS NOT NULL AND (tourism = 'museum' OR tourism = 'gallery')
CREATE materialized view museums_parking AS
  SELECT * FROM planet_osm_polygon
  WHERE building = 'parking'
CREATE materialized view lines_footway AS
  SELECT * FROM planet_osm_line l
  WHERE highway = 'footway'
```

Indexy boli vytvorené nad stĺpcami, ktoré sa používajú pri väčšine dopytov :
- stĺpec building na základe ktorého vyhľadávame parkoviská
- stĺpec tourism na základe ktorého vyhľadávame múzeá a galérie
- stĺpec highway na základe ktorého vyhľadávame chodníky

```sql
CREATE INDEX index_tourism_planet_osm_point ON planet_osm_point(tourism);

CREATE INDEX index_building_planet_osm_polygon ON planet_osm_polygon(building);
CREATE INDEX index_tourism_planet_osm_polygon ON planet_osm_polygon(tourism);

CREATE INDEX index_highway_planet_osm_line ON planet_osm_line(highway);
```

Vytvoril som si aj geo indexy nad stĺpcom obsahujúcim súradnice, čo značne urýchlilo dopyty.

```sql
create index index_gist_way_planet_osm_point on planet_osm_point using gist(geography(way));
create index index_gist_way_planet_osm_line on planet_osm_line using gist(geography(way));
create index index_gist_way_planet_osm_polygon on planet_osm_polygon using gist(geography(way));
```

### Screenshot z aplikácie

Znázornenie aktuálnej polohy sa určuje pomocou kliknutia do mapy a zobrazenia markera (modrej značky). Ak používateľ nemá zvolenú polohu na mape, aplikácia ho upozorní.  

Nasledujúci screenshot z aplikácie zobrazuje scenár č.1 - Zobrazenie múzeí a galérií v požadovanom rozsahu.
Pri kliknutí na tlačidlo All, je potrebné zadať potrebný rozsah vľavo v input boxe č.1 (rozsah od zvoleného bodu). Potom aplikácia upozorní používateľa aby si zvolil bod na mape.
![alt text](./screens/screen1.bmp "scenar1")

Nasledujúci screenshot z aplikácie zobrazuje scenár č.2 - Zobrazenie parkovísk v požadovanom rozsahu od múzeí a galérií v požadovanom rozsahu. Pri kliknutí na tlačidlo Museums, je potrebné zadať potrebný rozsah vľavo v input boxe č.1 (rozsah od zvoleného bodu) a č.2 (rozsah múzea od parkoviska). Potom aplikácia upozorní používateľa aby si zvolil bod na mape.
![alt text](./screens/screen2.bmp "scenar2")

Nasledujúci screenshot z aplikácie zobrazuje scenár č.3 - Zobrazenie múzeí a galérií v zadanom polygóne. Pri kliknutí na tlačidlo Polygon aplikácia upozorní používateľa aby si zvolil štyri body na mape (polygón).
![alt text](./screens/screen3.bmp "scenar3")

Nasledujúci screenshot z aplikácie zobrazuje scenár č.4 -Zobrazenie múzeí a galérií v zadanej línii spolu s ich chodníkmi. Pri kliknutí na tlačidlo Line aplikácia upozorní používateľa aby si zvolil dva body na mape (línia).
![alt text](./screens/screen4.bmp "scenar4")


