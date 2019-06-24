;  This extension adds GIS (Geographic Information Systems) support to NetLogo
extensions [ gis ]

;  Setting global variables
globals [ amz-rainforest legal-logs illegal-logs regrowth total-cost
  ilog-sum il-tick tick-count scope-patches scope-radius saved-sum
  saved years-passed SE-annual multiplier llog-plot ilog-plot r-plot arrests#]

;  Loggers represent entities engaged in illegal deforestation regardless of purpose
;  Rangers represent the collective conservation effort
breed [ loggers logger ]
breed [ rangers ranger ]



to setup-forest

  clear-all

  ;  Loading the vector GIS data for the Amazon Rainforest
  ;  Please make sure to save the GIS folder "amapoly_ivb"
  ;  in the directory of SavingAmazon.nlogo or else modify
  ;  the path below.
  set-current-directory "./"
  set amz-rainforest gis:load-dataset "./amapoly_ivb/amapoly_ivb.shp"

  ;  Setting the world envelope
  gis:set-world-envelope (gis:envelope-of amz-rainforest)

  ;  Drawing forest outline
  gis:set-drawing-color [255 255 254]
  gis:draw amz-rainforest 1

  ;  Set forest patches green in accordance with set forest density
  ask (patches gis:intersecting amz-rainforest) [set pcolor [0 0 1]]
  let d count patches with [pcolor = [0 0 1]]
  set multiplier floor (d / 550)
  ask n-of (Rainforest-density * multiplier) (patches gis:intersecting amz-rainforest)
      [set pcolor one-of [53 54 55]] ; 4 shades of green

  ;  'multiplier' set above contains the conversion rate between MHa and # of green patches
  set regrowth ((Annual-tree-cover-gain / 1000) * multiplier)
  set legal-logs (Legal-logging-base * multiplier)
  set illegal-logs (Illegal-logging-base * multiplier)

  ;  Initializing other global variables
  set SE-annual Spending-effectiveness
  set ilog-sum 0
  set TCgain-stdDev 2
  set LL-stdDev 0
  set IL-stdDev 0.1
  set SE-stdDev 0.1
  set Years 0
  set Cover 0
  set total-cost 0
  set tick-count 0
  set llog-plot 0
  set ilog-plot 0
  set r-plot 0
  set years-passed 0
  set Annual-Spending 0
  set arrests# 0

  ;  Preliminary setup for Loggers vs Rangers
  if (Loggers-vs-Rangers?)
  [

    set-default-shape loggers "person"
    set-default-shape rangers "person"

    ;  Refer to function for description
    update-YearlyParams

    ;  Creating loggers and rangers in game space
    cast-loggers Loggers#
    cast-rangers Rangers#
    ask loggers with [pcolor = white]
    [
      set color grey
      set arrests# arrests# + 1
    ]
  ]

  reset-ticks
end


to go

  ;  Stops if target tree cover density is set and reached
  if Cover > 0
  [ if ( (count patches with [pcolor = 53 or pcolor = 54 or pcolor = 55]) / multiplier ) <= Cover [ stop]]

  ;  Stops if # green patches is less that sum of legal and illegal logs to be cut
  if (count patches with [pcolor = 53 or pcolor = 54 or pcolor = 55]) < (illegal-logs + legal-logs)
    [ stop ]

  ;  With Loggers-vs-Rangers off, ticks is the same as the # of years passed
  ;  When on, then (ticks+1)/Average-Operation-Time = # of years passed
  ifelse Loggers-vs-Rangers?
  [
    ;  Stops if target year is set and reached
    if Years > 0
    [ if ticks / Average-Operation-Time >= Years [ stop]]

    ;  Refer to function for description
    generate-players

    ;  Performing logging operations on the forest and updating variables
    ;  after each year.
    ;  Refer to functions for descriptions
    if (((ticks + 1) mod Average-Operation-Time) = 0)
    [
      set years-passed years-passed + 1

      logging legal-logs ilog-sum
      update-params
      update-YearlyParams

      generate-players
      natural-growth

      set ilog-sum 0
      set tick-count 0

    ]

  ]

  ;  No turtles exist in this mode (i.e. when Rangers-vs-Loggers? is off)
  ;  Game space is inactive
  [
    if Years > 0
     [ if ticks >= Years [ stop]]

    set years-passed years-passed + 1
    logging legal-logs illegal-logs
    natural-growth
    update-params
  ]

  tick

end

;  Creates loggers in game space
to cast-loggers [lf]
   ask n-of lf patches with [pcolor = black]
      [
        sprout-loggers 1 [set color red set size 5]
      ]
end

;  Creates rangers in game space
;  Coordinated effort prevents ranger scope overlap
;  This results in a greater ranger search space and
;  hence more logger arrests#.
to cast-rangers [rf]
   if Conservation-efforts?
  [
    ask n-of rf patches with [pcolor = black]
      [
        sprout-rangers 1 [set color blue set size 5]
        ifelse Coordinated-effort?
        [ ask min-n-of scope-patches patches with [pcolor = black] [distance myself] [set pcolor white] ]
        [ ask patches in-radius scope-radius with [pcolor = black] [set pcolor white] ]
      ]
  ]
end

;  Updates variables for annual tree loss and saves
;  Kills loggers and rangers for the previous year
;  Resets game space and creates new ones for upcoming year
;  Sets loggers within rangers' range to grey
to generate-players
  update-TickParams
  ask loggers [die]
  ask rangers [die]
  ask patches with [pcolor = white] [set pcolor black]
  cast-loggers Loggers#
  cast-rangers Rangers#
  ask loggers with [pcolor = white]
  [
    set color grey
    set arrests# arrests# + 1
  ]
end

;  Updates variables for annual tree loss and saves
to update-TickParams
  if count loggers >= 1 [
    ask loggers with [pcolor = black] [set ilog-sum ilog-sum + il-tick]
    ask loggers with [pcolor = white] [set saved-sum saved-sum + il-tick]
  ]
end

;  Setting ranger scope and logging amount per operation
;  Ranger scope depends on whether coordinated effort is selected
to update-YearlyParams
  if Loggers# > 0
  [ set il-tick ((illegal-logs / Loggers#) / Average-Operation-Time) ]

  if Rangers# > 0
  [
    let bp count patches with [pcolor = black]
    ifelse Coordinated-effort?
    [ set scope-patches ((bp * (SE-annual / 100)) / Rangers#) ]
    [ set scope-radius sqrt(((bp * (SE-annual / 100)) / Rangers#) / pi) ]
  ]
end

;  Tree regrowth rate, annual legal and illegal # of logs, as well as
;  spending effetiveness are all drawn from random distributions with
;  standard deviations set by the user. This allows the user to simulate
;  uncertainty if need be.
to update-params

    ;  Computing total cost of conservation efforts and corresponding number of trees saved
    if (Conservation-efforts?)
    [
      set total-cost (total-cost + Annual-Spending)
      if not Loggers-vs-Rangers?
       [set saved-sum saved-sum + saved]
    ]

    set regrowth (random-normal (regrowth) (TCgain-stdDev))
    if regrowth < 0
    [ set regrowth 0 ]

    set legal-logs (random-normal (legal-logs * LL-coefficient-annual) (LL-stdDev * multiplier))
    if legal-logs < 0
    [ set legal-logs 0 ]

    set illegal-logs (random-normal (illegal-logs * IL-coefficient-annual) (IL-stdDev * multiplier))
    if illegal-logs < 0
    [ set illegal-logs 0 ]

    set SE-annual (random-normal (Spending-effectiveness) (SE-stdDev))
    if SE-annual < 0
    [ set SE-annual 0 ]
end

;  Performs logging activites for both legal and illegal operations
;  simply by assigning patches wihtin the forest different colors.
to logging [ll il]
  if any? patches with [pcolor = 53 or pcolor = 54 or pcolor = 55] [

   if ll >= 1 [
    ask n-of ll patches with [pcolor = 53 or pcolor = 54 or pcolor = 55] [ set pcolor [0 0 1] ]
    set llog-plot ll
   ]

   if il >= 1 [
    if (Conservation-efforts? and not Loggers-vs-Rangers?)
    [
      set saved ((SE-annual / 100) * il )
      set il (il - saved)
    ]

    ask n-of il patches with [pcolor = 53 or pcolor = 54 or pcolor = 55] [
        set pcolor [55 0 5]
    set ilog-plot il
    ]
  ]
 ]
end

;  Brings about natural forest growth
to natural-growth
  set r-plot regrowth
  ask n-of regrowth (patches gis:intersecting amz-rainforest)
    [set pcolor one-of [53 54 55]]
end
@#$#@#$#@
GRAPHICS-WINDOW
462
16
924
479
-1
-1
3.414
1
10
1
1
1
0
1
1
1
-66
66
-66
66
1
1
1
ticks
30.0

BUTTON
5
10
108
43
Setup Forest
setup-forest
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
7
383
185
416
Spending-effectiveness
Spending-effectiveness
0.1
100
18.0
0.1
1
%
HORIZONTAL

SLIDER
9
182
202
215
Legal-logging-base
Legal-logging-base
0
10
0.45
0.01
1
MHa
HORIZONTAL

SLIDER
251
181
447
214
Illegal-logging-base
Illegal-logging-base
0
10
1.1
0.01
1
MHa
HORIZONTAL

SLIDER
8
220
236
253
LL-coefficient-annual
LL-coefficient-annual
0
2
1.01
0.01
1
Multiplier
HORIZONTAL

SLIDER
251
218
447
251
IL-coefficient-annual
IL-coefficient-annual
0
2
1.01
0.01
1
Multiplier
HORIZONTAL

SLIDER
252
14
418
47
Rainforest-density
Rainforest-density
20
550
550.0
0.1
1
MHa
HORIZONTAL

SLIDER
251
67
420
100
Annual-tree-cover-gain
Annual-tree-cover-gain
0
1000
58.0
1
1
KHa
HORIZONTAL

MONITOR
1158
19
1307
64
Percentage of illegal logging
(illegal-logs / (legal-logs + illegal-logs)) * 100
2
1
11

PLOT
941
77
1307
307
Tree Loss and Regrowth
Ticks
KHa
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Legal" 1.0 0 -8431303 true "" "plot (llog-plot / multiplier) * 1000"
"Ilegal" 1.0 0 -7171555 true "" "plot (ilog-plot / multiplier) * 1000"
"Regrowth" 1.0 0 -15040220 true "" "plot (r-plot / multiplier) * 1000"

SWITCH
942
327
1310
360
Loggers-vs-Rangers?
Loggers-vs-Rangers?
1
1
-1000

BUTTON
6
60
96
93
Go
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

INPUTBOX
161
38
211
98
Years
0.0
1
0
Number

MONITOR
941
19
1045
64
Tree Density (MHa)
count (patches with [pcolor = 53 or pcolor = 54 or pcolor = 55]) / multiplier
3
1
11

INPUTBOX
9
260
81
320
LL-stdDev
0.0
1
0
Number

INPUTBOX
251
258
321
318
IL-stdDev
0.1
1
0
Number

INPUTBOX
251
103
331
163
TCgain-stdDev
2.0
1
0
Number

SWITCH
8
341
445
374
Conservation-efforts?
Conservation-efforts?
0
1
-1000

INPUTBOX
161
104
211
164
Cover
0.0
1
0
Number

INPUTBOX
9
425
74
485
SE-stdDev
0.1
1
0
Number

INPUTBOX
237
377
334
437
Annual-Spending
0.0
1
0
Number

MONITOR
237
442
333
487
Total Cost
total-cost
5
1
11

TEXTBOX
106
70
165
101
Optionally, until
11
0.0
1

TEXTBOX
144
138
164
156
or
11
0.0
1

SLIDER
943
447
1126
480
Average-Operation-Time
Average-Operation-Time
1
30
7.0
1
1
 Days
HORIZONTAL

SWITCH
1155
375
1300
408
Coordinated-effort?
Coordinated-effort?
1
1
-1000

MONITOR
81
440
185
485
Saved Trees (MHa)
saved-sum / multiplier
3
1
11

MONITOR
1065
19
1140
64
Years Passed
years-passed
0
1
11

SLIDER
943
373
1126
406
Loggers#
Loggers#
1
1000
77.0
1
1
NIL
HORIZONTAL

SLIDER
943
410
1126
443
Rangers#
Rangers#
1
1000
8.0
1
1
NIL
HORIZONTAL

MONITOR
1158
436
1221
481
Arrests#
arrests#
17
1
11

@#$#@#$#@
“The forest is a peculiar organism of unlimited kindness and benevolence that makes no demands for its sustenance and extends generously the products of its life activity; it affords protection to all beings, offering shade even to the axe-man who destroys it.”
-Gautama Buddha

## WHAT IS IT?

This model simulates deforestation of the Amazon rainforest brought about by logging activities, both legal and illegal, and explores the effects and costs of conservation efforts.

## HOW IT WORKS

The world in this model is split into 2 spaces.

First, the Amazon rainforest itself which is drawn using the GIS extension and vector data specific to this forest [1]. The forest is filled with green patches to represent trees with a density specified by the user. This density as well as logging amounts are specfied in MHa (millions of hectares). The forest density is capped at 550 MHa [2] and logging (deforestation) slider ranges are wide enough to include realistic values [3][4]. With Logger-vs-Rangers? off, this space is the only one where changes can be seen. The effects of logging are merely brought about by simple color changes in patches, with diffferent colors assigned to deforested patches to differentiate between legal and illegal activities. This allows one to see the overall effects more clearly in a completely deforested barren land. Initial values for legal and illegal logging amount can be set along with their growth/decline annual coefficients. The latter can be changed at anytime. One may also wish to set standard deviations to simulate uncertainty using samples drawn from normal distributions with means updated to values from the previous year. Ticks represent years, and any variable change in the interface takes effect immediately. The same uncertainty mechanism can be applied to conservation efforts which could be switched on or off at any time. Spending effectiveness determines the percentage of the volume of illegal logging that was prevented. It can be set to reflect a particular conservations strategy in mind or you may use [5] as a guide. Annual spending can be used to specify the yearly cost of all consercation efforts. If user wishes to modify the spending effectiveness while the model is running and has set a value for total cost per annum, it is recommended that they press GO to stop simulation, modify effectiveness and subsequently the annual spending to reflect the newly set effectiveness, then press GO again to resume. The total cost of conservation is also reported.


Second, the game space which is the area engulfing the forest. This space is only used when Loggers-vs-Rangers? is switched on. In this mode, ticks no longer represent years. Instead, the ticks simply loop through the average # of days for logging operations in a year. The number of years passed is displayed by the corresponding monitor. At the end of each year, any relevant interface variable changes take effect. These include # of rangers, # of loggers, average annual logging operation time in days, conservation efforts and spending effectiveness, coordinated conservation efforts, legal and illegal coefficients for annual growth/decline, and the applicable and respective standard deviations.
During a game, conservation efforts are simulated by attributing a scope a to each ranger. This scope is computed in one of 2 ways.

For an uncoordinated effort in conservation (perhaps coordination here can be thought of as one between countries or organizations or other entities), the ranger scope is a circle and overlap of ranger scopes with other scopes and with the forest is possible and more frequent the higher the spending effectiveness (i.e. the larger the ranger scope). Overlaps reduce the total area of the scopes. The radius of which is computed in the following way:

* Count the total # of patches in game space
* Count the # of conservation patches corresponding to Spending-Effectiveness %
* Divide this space into the # of rangers
* Consider each space a circle and compute corresponding radius

For coordinated efforts, only the last step is different and this leads to no overlap in ranger scopes:

* Assign the closest non-assigned patches to each ranger to make a full scope

Annual tree losses and saves post conservation efforts in a game space are computed as follows:

* With the number of days in average annual per logger operation time as ticks, generate # of rangers and # of loggers specified and at each tick accumulate the per logger logs for loggers not in any scope (i.e. not arrested), and those for loggers that are generated in a ranger scope (i.e. arrested).
* At the end of each year, perform logging operations corresponding to sum of successful illegal logging computed from the number of loggers not arrested.

Note: Logging and deforestation are interchangeable in the description of this model. Deforestation can have a number of causes such as mining, paper, overpopulation, logging, agriculture expansion and livestock ranching [6]. I have used the term logging to denote the removal of trees, whatever the cause maybe as all such causes end up in the removal of trees and furthermore may be either legal or illegal. In the game space, loggers are agents that bring about illegal deforestation and rangers are entities that engage in conservation efforts.


## HOW TO USE IT

**Important**: Make sure that the folder "amapoly_ivb" is in the same directory as "SavingAmazon.nlogo".

Quick start:

1. Adjust slider and switch parameters, or use default settings.
2. Press SETUP FOREST.
3. Enter new values for input parameter, or use default settings.
4. Press GO to begin simulation.
5. Look at monitors to see current remaining forest density, percentage of illegal to total logs, saved trees and total current conservation costs.
6. Look at plots to view current logging and regrowth volumes.


Parameters:
RAINFOREST-DENSITY: Initial forest density (MHa)
ANNUAL-TREE-COVER-GAIN: Annual forest regrowth rate (MHa)
TCGAIN-STDDEV: Tree cover gain standard deviation
LEGAL-LOGGING-BASE: Initial volume of legal logging
LL-COEFFICIENT-ANNUAL: Coefficient multiplied by previous year legal logging volume and represents logging growth or decline
LL-STDDEV: Legal logging standard deviation (MHa) for normal distribution sampling
ILLEGAL-LOGGING-BASE: Initial volume of illegal logging
IL-COEFFICIENT-ANNUAL: Coefficient multiplied by previous year illegal logging volume and represents logging growth or decline
IL-STDDEV: Illegal logging standard deviation (MHa) for normal distribution sampling
CONSERVATION-EFFORTS?: Turn conservation efforts on or off
SPENDING-EFFECTIVENESS: With Loggers-vs-Rangers? off, this is the percentage of the volume of illegal logging that was prevented annually. With Loggers-vs-Rangers? on, the effect is determined by the interplay between loggers and rangers as explained in the previous section.
SE-STDDEV: Spending effectiveness standard deviation (%)
ANNUAL-SPENDING: Annual conservation cost
LOGGERS-VS-RANGERS?: 'On' to use the agent based game space to simulate deforestation. 'Off' to stick to basic model.
LOGGERS#: Number of loggers
RANGERS#: Number of rangers
AVERAGE-OPERATION-TIME: Average number of days per logger operation
COORDINATED-EFFORT?: If 'On' prevents ranger scope overlap, and 'Off' allows for overlap which makes rangers slightly less effective in cases where overlap occurs since total area under rangers' control is decreased.

Monitors:
Tree Density (MHa): Current tree denisty in Millions of Hectares
Percentage of Illegal Logging: Proportion of illegally logged volume to total logged volume
Saved Trees (MHa): Millions of Hectares in saved tress due to conservation efforts
Total Cost: Total accumulated annual conservation costs
Years Passed: Displays the # years passed
Arrests#: Current total number of loggers arrested by rangers

Plot:
Displays the legal logging, illegal logging, and regrowth volume values over time.

Notes:

Concerning parameters for which you wish to change, make sure to set all switch and slider parameters before clicking on SETUP FOREST and all input parameters after SETUP FOREST and before GO.

In order to have rangers in the game mode, conservation efforts must be switched on.

In order for rangers to have a visible scope, spending effectiveness must be set to a high enough value. This also depends on the number of rangers, since the greater the number of rangers the smaller the scope per ranger if the spending effectiveness is kept constant.


## THINGS TO NOTICE

Conservation efforts is simple arithmetic with Logger-vs-Ranger? switched off, and agent based with it on.

With coordinated effort in conservation, more often than not more trees are saved.

## THINGS TO TRY

Try running the model in all modes:

* Basic Mode (Logger-vs-Rangers? set to 'Off')
	* Conservation-efforts? - Off
	* Conservation-efforts? - On
* Game Mode (Logger-vs-Rangers? set to 'On')
	* Conservation-efforts? - Off (i.e. only loggers)
	* Conservation-efforts? - On
		* Coordinated-efforts? - Off
		* Coordinated-efforts? - On

You may also try to change parameters while the model is running, for example spending effectiveness modification while using game mode will visibly change the range of rangers' scopes for the next year.

## EXTENDING THE MODEL

Conservation efforts in this model only address illegal deforestation activities. A possible and logical extension, perhaps in the form of a mode or option for the user, would be to simulate their effects on legal deforestation as is the case with environmental movements.

It might also be useful to split the game space into nine polygons representing the nine nations that have a foothold in the Amazon Rainforest with polygon sizes corresponding to the nation shares of the forest. This will allow a better visualization of the efforts of different nations towards conservation in game mode.

As mentioned earlier, deforestation can be due to a number of causes and one may want to model the causes and effects of conservation activities pertaining to those causes separately.

One other thing that can be useful is simulating the effect of climate change on the forest over the number years that the model runs.

Finally, the total cost is simply sum of annual spending over the number of years the model runs. This can be extended if a study is found that explains the relationship between annual spending and spending effectiveness so that a user may set/modify the desired spending effectiveness while the model computes the required annual and thus total spending to bring about set level of effectiveness.

## NETLOGO FEATURES

Uses GIS extension following the example at [7].

## RELATED MODELS

I am not aware of any related models as of date of creation.

## CREDITS AND REFERENCES

[1] http://worldmap.harvard.edu/data/geonode:amapoly_ivb
[2] https://en.wikipedia.org/wiki/Amazon_rainforest
[3] https://rainforests.mongabay.com/amazon/deforestation_calculations.html
[4] https://www.globalforestwatch.org
[5] https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5091886/
[6] https://futurism.media/deforestation-causes-effects-and-solutions
[7] http://ccl.northwestern.edu/2019/combination.pdf

## Model Metadata

This model was created as part of the Agent Based Modeling course at Data ScienceTech Institute taught by Dr. Georgiy Bobashev.
Creator: Ali Sheikhi
Email: ali.sheikhi@edu.dsti.institute
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
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
