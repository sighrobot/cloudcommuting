; Citi Bike simulator v3
; by Abe Rubenstein

; 1.831 is max distance radius for alternate stations

extensions [ table ]
breed [ bikes bike ]
bikes-own [
  target
  speed
  target-valid?
  time-waiting
]

breed [ stations station ]
stations-own [
  station-id      ; item 0
  $station-name   ; item 1
  available-bikes ; item 8
  available-docks ; item 2
  total-docks     ; item 3
  latitude        ; item 4
  longitude       ; item 5
  status-key      ; item 7
  master-launch-rate
  launch-table
]

globals [
  $data
  file-end?
  lat-values
  lon-values
  nearby-station-radius
]

to setup
  clear-all
  file-close-all
  set lat-values [40.68034242 40.771522 0.09117958]     ; min max range
  set lon-values [-74.01713445 -73.95004798 0.06708647] ; min max range
  set-default-shape stations "target"
  set nearby-station-radius 1.831 ; about 0.4 mi (8 min walk)
  
  file-open "citibike_stations.txt"
  let fl file-read-line
  print "Loading station data..."
  while [ not file-at-end? ] [
      set $data []
      read-station-data
      if item 7 $data = 1 [ ; only load stations with status key == 1
        create-ordered-stations 1 [
          set station-id item 0 $data
          set $station-name item 1 $data
          set available-bikes item 8 $data
          set available-docks item 2 $data
          set total-docks item 3 $data
          set latitude item 4 $data
          set longitude item 5 $data
          set status-key item 7 $data
          let x max-pxcor - (item 1 lon-values - longitude) / item 2 lon-values  * (max-pxcor - min-pxcor)
          let y max-pycor - (item 1 lat-values - latitude) / item 2 lat-values * (max-pycor - min-pycor)
          setxy x y
        ]
      ]
  ]
  print "Station data loaded."
  
  file-close
  
  print "Loading master launch rates..."
  file-open "launch_rates.txt"
  set fl file-read-line
  while [ not file-at-end? ] [
    set $data []
    read-station-data
    ask stations with [station-id = item 0 $data] [
      if self != nobody [ set master-launch-rate item 2 $data / 100.0 ]
    ]
  ]
  file-close
  print "Master launch rates loaded."

  print "Loading launch rate data..."
  ask stations [ 
    let error-msg word "Error on station id " station-id
    carefully [
      file-open (word "endstationdata/" station-id ".csv")
      set fl file-read-line
    ] [ print error-msg stop ]
    
    set launch-table []
    while [ not file-at-end? ] [
      set $data []
      read-station-data
      repeat (item 1 $data) [
        set launch-table lput item 0 $data launch-table
      ]
    ]
  ]
  print "Launch rate data loaded."                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  
  file-close-all
  reset-ticks
  
end

to go
  
  ask bikes [
    
    let target-open? false

    
    
    ask target [ 
      if available-docks > 0 [ set target-open? true ]
    ]
    ; arrived at target
    ifelse distance target < 1 [
        
      ifelse target-open? [
        ask target [
          set available-docks available-docks - 1
          set available-bikes available-bikes + 1
        ]
        move-to target
        die
      ]
      ; else wait or leave
      [ 
        ifelse time-waiting < 100 [ set time-waiting time-waiting + 1 ]
        [
          set time-waiting 0
          set target one-of other stations in-radius nearby-station-radius
          face target
          fd speed
        ]
        
      ]
        
       
    ]
    ; not yet at target, move forward
    [ fd speed  ]   
    
    
    ifelse show-bikes? [set color 1 ] [ set color black ] 
  ]

  ask stations [
    
    if available-bikes > 0 [
      if random-float 1 < master-launch-rate [
        hatch-bikes 1 [
          set target nobody
          while [ target = nobody ] [
            set target one-of stations with [ station-id = one-of launch-table ]
          ]
          if target != nobody [
            if target = myself [
              setxy random-xcor random-ycor
            ]
            face target
            set speed 0.4
            set time-waiting 0
            set color black
            set label ""
          ]
        ]
        set available-docks available-docks + 1
        set available-bikes available-bikes - 1
      ]
    ]
    ifelse show-counts?
    [ set label (word (available-bikes) " B / " (available-docks) " D") ]
    [ set label "" ]
    set color green
    
    let capacity available-docks + available-bikes
    if available-docks > (capacity * 0.95) [ set color blue ]
    if available-bikes > (capacity * 0.95) [ set color red ]
  ]
  
  tick
end

; String parsing code by Jim Lyons of netlogo-users Yahoo! Group
; http://netlogo-users.18673.x6.nabble.com/Reading-in-an-Excel-CSV-file-to-Netlogo-td4870465.html
to read-station-data
  if not file-at-end? [
   let $csv file-read-line  ; test string 
   set $csv word $csv ","  ; add comma for loop termination 
   ;$data []  ; list of values 
   while [not empty? $csv] 
   [ let $x position "," $csv
     let $item substring $csv 0 $x  ; extract item 
     carefully [set $item read-from-string $item][] ; convert if number 
     set $data lput $item $data  ; append to list 
     set $csv substring $csv ($x + 1) length $csv  ; remove item and comma 
   ]
  ]
end 
@#$#@#$#@
GRAPHICS-WINDOW
271
10
911
709
16
17
19.1
1
10
1
1
1
0
0
0
1
-16
16
-17
17
1
1
1
ticks
30.0

BUTTON
40
22
125
55
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
124
22
209
55
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
50
111
186
144
show-counts?
show-counts?
1
1
-1000

TEXTBOX
20
234
202
271
Green: Balanced
18
64.0
1

TEXTBOX
21
288
250
327
Red: unbalanced full
18
15.0
1

TEXTBOX
20
339
170
383
Blue: unbalanced empty
18
104.0
1

SWITCH
53
71
187
104
show-bikes?
show-bikes?
0
1
-1000

MONITOR
19
167
115
212
# bikes active
count bikes
1
1
11

PLOT
8
411
261
561
plot 1
time
bikes
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count bikes"

@#$#@#$#@
## Citi Bike simulator v2.0

Created by Abe Rubenstein, T.K. Broderick, and Aaron Arntz
Cloudcommuting: Rethinking Urban Mobility-on-Demand Systems
Instructor: Dimitris Papanikolaou
Interactive Telecommunications Program
New York University
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
