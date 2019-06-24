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