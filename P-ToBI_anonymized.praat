# P-ToBI transcriber anonymous for peer-review

# many comments have been erased, if you want to recreate or understand the code, I'd wait for the commented version of it ;)

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You can find the terms of the GNU General Public License here
# http://www.gnu.org/licenses/gpl-3.0.en.html


#####	form	##########
form P-ToBI transcriber
	comment ALERT! The script will write the segmentation in your TextGrids,
	comment maybe you want to make a copy of them, before running this. 
	sentence Folder /Users/xxx/data/
	word stressed_syllable_mark T
	optionmenu nucleus_method 1
		option manual
		option automatic
	comment In which tier is your syllable per syllable sgmentation and stress mark?
	integer segmentation_tier 3
	boolean create_new_tiers_for_the_ToBI_transcription 1
	comment In what position do you want the transcription?
	integer Tier_Tones 5
	boolean Do_you_have_a_Break_Indices_tier 1
	integer Tier_BI 4
	real threshold_(St) 1.5
	#real threshold_upstep_(St) 6.0
	comment Which kind of transcription do you want:
	boolean Surface_labelling 1
	boolean deep_labelling 1
	comment Do you want to pause the script to include corrections?
	boolean Correction 0
	boolean Create_picture 0
 	integer Begin_with_file_number 1
 	integer overwrite_TextGrid 1
 	  integer humanToBI 1

 	 	boolean Make_a_txt_report_on_labels 1
 	 	 	 boolean verbose 1

endform


##############		Fixed VARIABLES	######################
nucleusMark$ = "0"
range$ = "60-600"
from = begin_with_file_number
bI= do_you_have_a_Break_Indices_tier
c = 1
d = 1
f = 0
g= 1
fallingCounter = 0
risingCounter = 0
stressedstotalesfile=0

echo 'nucleus_method$'
pause 

if deep_labelling =1 and surface_labelling =0
	pause Deep labelling comes from surface, surface labels will be applied and then removed.
endif

f0_max = extractNumber (range$, "-")
f0_max$ = "'f0_max'"
f0_min$ = "'range$'" - "'f0_max$'"
f0_min$= "'f0_min$'" - "-"
f0_min = 'f0_min$'

numberOfLetras = 15
thresholdnegative = threshold - (2*threshold)
ultimastressed = 0
deepLabel$ = "* no"
deepLabel$ = " * aguda"
finalLabeldeep$ = "\% "

##############	BUCLE GENERAL 	######################
# Crea la lista de objetos desde el string
myFileList= Create Strings as file list: "list", folder$ + "/" + "*"
numberOfFiles = Get number of strings

for stri to numberOfFiles
	filename$ = Get string: stri
	if (right$(filename$, 4) <> ".wav") and (right$(filename$, 4) <> ".WAV")
 		Remove string: stri
 		stri= stri-1
 		numberOfFiles= numberOfFiles-1
 	endif
endfor

numberOfFiles = Get number of strings
if numberOfFiles = 0 
	exitScript: "There are no .wav or .WAV files in folder" + folder$
endif

nucleusData = Create Table with column names: "nucleus", 0, "file nucleus last difInt nucleusRange range lastRange "


if make_a_txt_report_on_labels = 1
	myTable = Create Table with column names: "table", 0, "file NPA humanNPA BT humanBT dur difprepre difpremaxton diftonStartEnd diftonStartMid diftonMidEnd diftonpos difpospos"
	agreementNPA = 0
	agreementBT= 0
	mySlopes = Create Table with column names: "mySlopes", 0, "file humanNPA dur difprepre difpremaxton diftonStartEnd diftonStartMid diftonMidEnd"
	myRising = Create Table with column names: "myRising", 0, "file humanNPA NPA diftonStartEnd diftonpos difpospos dur difprepre difpremaxton diftonStartMid diftonMidEnd"
endif
	allTable = Create Table with column names: "allTable", 0, "file interval humanNPA NPA intensity stringInt range stringRange dur stringDur durPre"

#bucle archivos
for ifile from 'from' to numberOfFiles

	stressedstotalesfile= 0

	select Strings list
	soundFile$ = Get string: ifile
	base$ = soundFile$ - ".wav"
	base$ = base$ - ".WAV"
	writeInfoLine: "Working on file " + string$(ifile) + ": "+ base$

	#reads sound
	if fileReadable(folder$ +"/" + soundFile$)
		mySound = Read from file: folder$ +"/" + soundFile$
	else
		exitScript: "No file in " + folder$ + " called " + soundFile$ + "."
	endif

	#reads grid
	if fileReadable(folder$ + "/" +base$ + ".TextGrid")
		myText = Read from file: folder$ + "/" +base$ + ".TextGrid"
	else 
		exitScript: "There are no TextGrids matching your sound " + base$ + ". Check for spaces in filename"
	endif

	#########	Check textgrid for assess ########

	numberOfIntervals = Get number of intervals: segmentation_tier
	soundBegins = Get end point: segmentation_tier, 1
	soundEnds = Get start point: segmentation_tier, numberOfIntervals
	nPoints = Get number of points: humanToBI
	labelHumanNPA$ = Get label of point: humanToBI, nPoints-1
	labelHumanBT$ = Get label of point: humanToBI, nPoints
	
	selectObject: myTable
	Append row
	Set string value: ifile, "file", base$
	Set string value: ifile, "humanNPA", labelHumanNPA$
	Set string value: ifile, "humanBT", labelHumanBT$

	
	#clean soundwav
	selectObject: mySound 
	filteredSound = Filter (stop Hann band): 2000, 5000, 100
	Rename: base$

	firstPitch = To Pitch: 0.001, f0_min, f0_max

	f0medial = do ("Get mean...", 0, 0, "Hertz")
	@printData("fileMean: " + fixed$(f0medial,0)+"Hz")
	
	#cuantiles teoría de Hirst (2011) analysis by synthesis of speach melody
	q25 = Get quantile: soundBegins, soundEnds, 0.25, "Hertz"
	q75 = Get quantile: soundBegins, soundEnds, 0.75, "Hertz"
	

	if q25 != undefined
		minpitch = q25 * 0.75
	else
		minpitch = f0_min

	endif
	
	if q75 != undefined
		maxpitch = q75 * 2.5
		#set to 2.5 for expressive speech because portuguese range goes over the octave, else 1.5
	else
		maxpitch= f0_max
	endif

	selectObject: filteredSound 
	myPitch = To Pitch: 0.001, minpitch, maxpitch
	Kill octave jumps
	removeObject: firstPitch

	gama = maxpitch - minpitch

	terciogama = gama/3
	tercio1 = minpitch + terciogama
	tercio2 = minpitch + (2*terciogama)
	tercio3 = minpitch + (3*terciogama)
	@printData("Low range less than: "+ fixed$(tercio2,0) +"Hz. Mid range from: "+ fixed$(tercio1,0) + " Hz. High range more than"+ fixed$(tercio2,0)+ "Hz.")
	
	Interpolate
	myPitchTier= Down to PitchTier
	selectObject: mySound
	intensity = To Intensity: 100, 0, "yes"
	intTable = Create Table with column names: "intTable", 0, "interval intensity stringInt range stringRange dur stringDur durPre"






	selectObject: myText
	numberOfIntervals = Get number of intervals: segmentation_tier
	i = 1

	


	#####################
	if  create_new_tiers_for_the_ToBI_transcription = 1
		Insert point tier... 'tier_Tones' "Tones"
	endif
	if  deep_labelling = 1
		tier_deep = tier_Tones + 1
		Insert point tier... 'tier_deep' "Tones II"
	endif

	#bucle silabas
	if bI =1
		numberOfIPs = Count points where: tier_BI, "is equal to", "4"
		myPointProcess = Get points: tier_BI, "is equal to", "4"
		endIntervalIP =1
	else
		numberOfIPs = 1
		selectObject: "TextGrid " + base$ 
		endOfSound= Get end time
		lastInt = Get number of intervals: segmentation_tier
		lastBoundary = Get end point: segmentation_tier, lastInt
		myPointProcess = Create empty PointProcess: base$, 0, endOfSound
		Add point: lastBoundary
		endIntervalIP = 1
	endif
	
	
	startIntervalIP = 0
	iIP=1
	numberOfsyllablesIP = 0

	for iIP from 1 to numberOfIPs
		stressedstotalesfrase = 0

		stressedInventory = Create Table with column names: "stressedInventory", 0, "n nInterval isNucleus"


		selectObject: myPointProcess
		timeOf4Boundary = Get time from index: iIP
		select TextGrid 'base$'
		endIntervalIP = Get interval at time: segmentation_tier, timeOf4Boundary
		endIntervalIP =endIntervalIP-1
		actualInterval=0

		i=1
		for i to endIntervalIP-startIntervalIP

			actualInterval = startIntervalIP + i
			numberOfsyllablesIP =numberOfsyllablesIP 

			if actualInterval < numberOfIntervals

				numberdesdeelfinal = endIntervalIP - actualInterval
				select TextGrid 'base$'

				labeli$ = Get label of interval: segmentation_tier, actualInterval

				# Hago un array que guarda los caracteres en variables diferentes
				for letra from 1 to numberOfLetras
					labeltext$[letra] = mid$ ("'labeli$'", letra)
				endfor

				if labeltext$[1] = stressed_syllable_mark$
					ultimastressed = actualInterval
					delayedPeak= 0

					stressedstotalesfrase = stressedstotalesfrase + 1
					stressedstotalesfile = stressedstotalesfile + 1 
					
					selectObject: stressedInventory
					Append row
					Set numeric value: stressedstotalesfrase, "n", stressedstotalesfrase
					Set numeric value: stressedstotalesfrase, "nInterval", actualInterval

					######

					if nucleus_method$ = "manual"
						if index(labeli$, nucleusMark$) != 0
							Set string value: stressedstotalesfrase, "isNucleus", "yes"
						else
							Set string value: stressedstotalesfrase, "isNucleus", "no"
						endif
					else
							Set string value: stressedstotalesfrase, "isNucleus", "no"
					endif

					######

					if ultimastressed < 1
						exitScript: "No stress marks found"
					endif
					@printData: ""
					@printData: "Analysing stress syl in interval:" + fixed$(ultimastressed, 0)


					
					selectObject: myText
					startingpointstressed = Get start point... 'segmentation_tier' 'actualInterval'
					endingpointstressed = Get end point... 'segmentation_tier' 'actualInterval'
					durstressed = endingpointstressed - startingpointstressed
					middlestressed = startingpointstressed + (durstressed/2)

					numberOfIntervalPrestressed = actualInterval - (1)
					startingpointprestressed = Get start point... 'segmentation_tier' 'numberOfIntervalPrestressed'
					endingpointprestressed = Get end point... 'segmentation_tier' 'numberOfIntervalPrestressed'
					durprestressed = endingpointprestressed - startingpointprestressed
					middleprestressed = startingpointprestressed + (durprestressed/2)
					numberOfIntervalPosstressed = actualInterval + 1
					startingpointposstressed = Get start point... 'segmentation_tier' 'numberOfIntervalPosstressed'
					endingpointposstressed = Get end point... 'segmentation_tier' 'numberOfIntervalPosstressed'
					durposstressed = endingpointposstressed - startingpointposstressed
					middleposstressed = startingpointposstressed + (durposstressed/2)

					###
					# VARIABLES FOR FINDING THE NUCLEUS
					###

					selectObject: intensity
					meanInt = Get mean: startingpointstressed, endingpointposstressed, "energy"
					if meanInt= undefined
						meanInt = 0
					endif
					
					selectObject: intTable
					Append row

					#nRows = Get number of rows
					#while stressedstotalesfile > nRows
					#	nRows = Get number of rows
					#endwhile

					Set numeric value: stressedstotalesfile, "interval", actualInterval
					Set numeric value: stressedstotalesfile, "intensity", meanInt
					stringInt$ = string$(meanInt)
					Set string value: stressedstotalesfile, "stringInt", stringInt$

					#stringInt range stringRange dur stringDur durPre
					select PitchTier 'base$'
					rangeStressed = Get standard deviation (curve): startingpointstressed, endingpointstressed

					selectObject: intTable
					Set numeric value: stressedstotalesfile, "range", rangeStressed
					stringRange$ = string$(rangeStressed)
					Set string value: stressedstotalesfile, "stringRange", stringRange$



					selectObject: allTable
					Append row
					nRows = Get number of rows

					Set string value: nRows, "file", base$

					Set numeric value: nRows, "interval", actualInterval
					Set numeric value: nRows, "intensity", meanInt
					stringInt$ = string$(meanInt)
					Set string value: nRows, "stringInt", stringInt$
					Set numeric value: nRows, "range", rangeStressed
					stringRange$ = string$(rangeStressed)
					Set string value: nRows, "stringRange", stringRange$
					Set string value: nRows, "humanNPA", labelHumanNPA$



					#############

					select PitchTier 'base$'
					f01pre = Get value at time... 'startingpointprestressed'
					f02pre = Get value at time... 'middleprestressed'
					f03pre = Get value at time... 'endingpointprestressed'
					if numberOfIntervalPrestressed = 1
						f02pre = Get value at time... 'startingpointstressed'
						f01pre = Get value at time... 'startingpointstressed'
						f03pre = Get value at time... 'startingpointstressed'
					endif
					@printData: "Mid pre-stressed value: " + fixed$(middleprestressed,0)

					f01ton = Get value at time... 'startingpointstressed'
					f02ton = Get value at time... 'middlestressed'
					f03ton = Get value at time... 'endingpointstressed'
					f01pos = Get value at time... 'startingpointposstressed'
					f02pos = Get value at time... 'middleposstressed'
					f03pos = Get value at time... 'endingpointposstressed'
					

					@printData: "Stressed mid, central and final values " + fixed$(f01ton,0)+" "+ fixed$(f02ton,0)+" "+ fixed$(f03ton,0)
					@printData: "Poststressed mid, central and final values " + fixed$(f01pos,0)+" "+ fixed$(f02pos,0)+" "+ fixed$(f03pos,0)

					select Pitch 'base$'
					f0tonmax = Get maximum: startingpointstressed, endingpointstressed, "Hertz", "Parabolic"
					if f0tonmax=undefined
						@undefined: f0tonmax, endingpointstressed
						f0tonmax = value
					endif
					f0tonmin = Get minimum: startingpointstressed, endingpointstressed, "Hertz", "Parabolic"
					if f0tonmin=undefined
						@undefined: f0tonmin, endingpointstressed
						f0tonmin = value
					endif

					f0targetpos = Get maximum: startingpointposstressed, endingpointposstressed, "Hertz", "Parabolic"
					timeOfPeakPos = Get time of maximum: startingpointposstressed, endingpointposstressed, "Hertz", "Parabolic"
					if f0targetpos= undefined
						@undefined: f0targetpos, endingpointposstressed
						f0targetpos = value
						timeOfPeakPos = time
						if f0targetpos = undefined
							f0targetpos = minpitch
						endif
					endif


					#####	DIFERENCIA EN ST ENTRE DOS FRECUENCIAS	###############

					difpreton = (12 / log10 (2)) * log10 ('f02ton' / 'f02pre')
					diftonpos = (12 / log10 (2)) * log10 ('f02pos' / 'f02ton')
					difton2pos3 = (12 / log10 (2)) * log10 ('f03pos' / 'f02ton')
					difpremaxton = (12 / log10 (2)) * log10 ('f0tonmax' / 'f02pre')
					diftonStartEnd = (12 / log10 (2)) * log10 ('f03ton' / 'f01ton')
					diftontargetpos = (12 / log10 (2)) * log10 ('f0targetpos' / 'f0tonmin')
					diftonmintonmax = (12 / log10 (2)) * log10 ('f0tonmax' / 'f0tonmin')
					
					@printData: "Prenuclear analysis: Differences between pre/str " + fixed$(difpreton,0) + " str/post "+ fixed$(diftonpos,0)

					################	FORMULAS	####################

					#########	PRENUCLEAR PITCH ACCENTS ########################
					labelTone$= "prenuclear"
					deepLabel$= "prenuclear"
					@printData: ""
					@printData: "Prenuclear formulae"
					###############	MONOTONALS ##################
					if abs (diftonStartEnd) < 'threshold' and f02ton < tercio1
						labelTone$ = "L*"
						deepLabel$ = "L*"
					@printData: "L*"
					endif

					if abs (diftonStartEnd) < 'threshold' and f02ton >= tercio1
						labelTone$ = "H*"
						deepLabel$ = "H*"
					@printData: "H*"
					endif

					# MONOTONAL tones for no falling from a previous high/rising tone
					select TextGrid 'base$'
					numeropuntosahora = Get number of points: 'tier_Tones'
					if numeropuntosahora >=2
						labelstressedprevious$ = Get label of point: tier_Tones, numeropuntosahora-1
						tpuntoprevious = Get time of point: tier_Tones, numeropuntosahora-1
							select PitchTier 'base$'
							f0_puntoprevious = Get value at time: tpuntoprevious
							select TextGrid 'base$'
							intervalptoprevious = Get interval at time: segmentation_tier, tpuntoprevious
							iniciointervalprevious = Get start point: segmentation_tier, intervalptoprevious
							finintervalprevious = Get end point: segmentation_tier, intervalptoprevious
							select Pitch 'base$'
							f0maxstressedprevious = Get maximum: iniciointervalprevious, finintervalprevious, "Hertz", "Parabolic"
							if f0maxstressedprevious = undefined
								@undefined: f0maxstressedprevious, finintervalprevious
										f0maxstressedprevious = value
							endif
							difconlaprevious = (12 / log10 (2)) * log10 (f0maxstressedprevious / f0_puntoprevious)
							@printData: "Diff from last str. syl peak: " + string$(difconlaprevious)

						if ('difconlaprevious' > 'thresholdnegative') and ((labelstressedprevious$ = "H*") or (labelstressedprevious$ = "L*+H") or (labelstressedprevious$ = "(L*)+H") or (labelstressedprevious$ = "L+H*") or (labelstressedprevious$ = "(L+H*)+H")or (labelstressedprevious$ = "L+(H*+H)") or (labelstressedprevious$ = "L*+(H+H)") or (labelstressedprevious$ = "(L*+H)+H)") or (labelstressedprevious$ = "(L+H*)+L)"))
							delayedPeak= 0
							pitchaccent$ = "H*"
							labelTone$ = "H*"
							deepLabel$ = "H*"
							stressedH= 1
							@printData: "H*, lack declination from previous point"

						else
							pitchaccent$ = "L*"
							labelTone$ = "L*"
							deepLabel$ = "L*"
							stressedH= 0
							@printData: "L*, has been declination from previous point"

						endif
					endif

					#si puedes mira el pto previous y pon si el plateu es alto o bajo dependiendo del tono previous
					select TextGrid 'base$'
					numeropuntosahora = Get number of points: 'tier_Tones'
					if abs (difpreton) < threshold and abs (diftonpos) < 'threshold' and (numeropuntosahora >= 1) and (diftonStartEnd > thresholdnegative)
						delayedPeak= 0
						labelstressedprevious$ = Get label of point: tier_Tones, numeropuntosahora
						if (labelstressedprevious$ = "H*") or (labelstressedprevious$ = "L*+H") or (labelstressedprevious$ = "(L*+)H") or (labelstressedprevious$ = "L+H*") or (labelstressedprevious$ = "(L+H*)+H")or (labelstressedprevious$ = "L+(H*+H)") or (labelstressedprevious$ = "L*+(H+H)")or (labelstressedprevious$ = "(L*+H)+H)")
							#ves a buscar el valor de del punto previous y si del punto previous al punto de ahora no pasa el threshold negativo etiquetalo como H*
							select TextGrid 'base$'
							tpuntoprevious = Get time of point: tier_Tones, numeropuntosahora
							select PitchTier 'base$'
							f0_puntoprevious = Get value at time: tpuntoprevious
							difconlaprevious = (12 / log10 (2)) * log10 ('f02ton' / 'f0_puntoprevious')
							if difconlaprevious > 'thresholdnegative'
								labelTone$ = "H*"
								deepLabel$ = "H*"
								@printData: "H*, no movement from previous H target"

							endif
						endif
					endif

					##############################
					# BITONAL PRENUCLEAR PITCH ACCENTS
					##############################


					if difpreton > 'threshold'
						labelTone$ = "(L+)H*"
						deepLabel$ = "H*"
						@printData: "(L+)H*: rising from pre to str"

					endif

					# L+H* L*+H <H* rising stressed syllable, optionally with delayed peaks
					if (diftonStartEnd > threshold)
						labelTone$ = "L+H*"
						deepLabel$= "(L+)H*"
						@printData: "L+H*: rising str syl"

						#L*+H: begins very low and peak at the end of stressed
						if f0tonmin < tercio1 and f03ton > f02ton
							labelTone$ = "L+H*"
							deepLabel$ = "L*+H"
							@printData: "L+H*: str begins low and peak at the end of str"

						endif
						# <H* with peak in the poststressed 
						if f02pos >= f01pos
							labelTone$ = "L+H*+H"
							deepLabel$ = "<H*"
							delayedPeak= 1
							timeOfDelayedPeak = timeOfPeakPos
							@printData: "<H*: poststr continues rising"

						endif
					endif

						
					# H+L*: goes over threshold in the stressed syllable
					if diftonStartEnd < 'thresholdnegative'
						labelTone$ = "H+L*"
						deepLabel$= "H+L*"
						delayedPeak= 0
						@printData: "H+L*: falling str syl"

						#but if the start of the stressed syllable is rising, then it's a H*+L
						if f02ton> f01ton
							labelTone$ = "H*+L"
							deepLabel$= "H*+L"
							@printData: "H*+L: falling str syl+ start of str syl is rising"

						endif


					endif


					########################################################
					if (diftonmintonmax > 'threshold') and (diftonStartEnd < 0) and (abs (diftontargetpos) < 'threshold')
						delayedPeak= 0
						labelTone$ = "H+L*"
						deepLabel$ = "H+L*"
							select TextGrid 'base$'
							numeropuntosahora = Get number of points: 'tier_Tones'
							if numeropuntosahora >=1
								labelstressedprevious$ = Get label of point: tier_Tones, numeropuntosahora
								if labelstressedprevious$ ="L*+H" or labelstressedprevious$ ="H+(L*+H)"
									tpuntoprevious = Get time of point: tier_Tones, numeropuntosahora
									intervalultimotono = Get interval at time: segmentation_tier, tpuntoprevious
									intervaltarget = intervalultimotono + 1
									inicio_target = Get start point: segmentation_tier, intervalultimotono
									fin_target = Get end point: segmentation_tier, intervalultimotono+1
									select Pitch 'base$'
									f0_targetprevious = Get maximum: inicio_target, fin_target, "Hertz", "Parabolic"
									if f0_targetprevious=undefined
										@undefined: f0_targetprevious, fin_target
										f0_targetprevious = value
									endif

									#select PitchTier 'base$'
									#f0_targetprevious = Get value at time: fin_target
									difconlaprevious = (12 / log10 (2)) * log10 ('f02pre' / 'f0_targetprevious')
									printline difconlaprevious 'difconlaprevious'
									if difconlaprevious < thresholdnegative
										labelTone$ = "H+L*/L*"
										deepLabel$ = "L*"
										printline fórmula prenúcleo 'labeli$' "H+L*/L*"
									endif
								endif
							endif
					endif

					##############################
					# (phonetically) TRITONAL PRENUCLEAR PITCH ACCENTS
					##############################
					if difpreton < 'thresholdnegative' and diftontargetpos >= 'threshold'
						delayedPeak= 0
						if abs (difpreton) >= abs (diftontargetpos)
							labelTone$ = "H+(L*+H)"
							deepLabel$= "H*+L"
						else
							labelTone$ = "(H+L*)+H"
							deepLabel$= "H+L*+H"
						endif

							select TextGrid 'base$'
							numeropuntosahora = Get number of points: 'tier_Tones'
							if numeropuntosahora >=1
								labelstressedprevious$ = Get label of point: tier_Tones, numeropuntosahora
								if (labelstressedprevious$ = "L*+H") or (labelstressedprevious$ ="L+(H*+H)") or (labelstressedprevious$ ="(L+H*)+H")
									tpuntoprevious = Get time of point: tier_Tones, numeropuntosahora
									intervalultimotono = Get interval at time: segmentation_tier, tpuntoprevious
									intervaltarget = intervalultimotono + 1
									inicio_target = Get start point: segmentation_tier, intervalultimotono
									fin_target = Get end point: segmentation_tier, intervalultimotono+1
									select Pitch 'base$'
									f0_targetprevious = Get maximum: inicio_target, fin_target, "Hertz", "Parabolic"
									if f0_targetprevious = undefined
										@undefined: f0_targetprevious, fin_target
										f0_targetprevious = value
									endif
									#select PitchTier 'base$'
									#f0_targetprevious = Get value at time: fin_target
									difconlaprevious = (12 / log10 (2)) * log10 ('f0tonmin' / 'f0_targetprevious')
									printline difconlaprevious 'difconlaprevious'
									if difconlaprevious < thresholdnegative
										deepLabel$ = "L*+H"
									endif
								endif
							endif
					printline fórmula prenúcleo 'labeli$' H+L*+H
					endif


					# H*  (phonetically L+H*+L ) rising stressed syllable
					if difpreton >= 'threshold' and diftonpos < 'thresholdnegative'
						delayedPeak= 0
						labelTone$ = "L+H*+L"
						
						if abs (difpreton) >= abs (diftonpos)
							labelTone$ = "L+(H*+L)"
							deepLabel$= "(L+)H*"
						else
							labelTone$ = "(L+H*)+L"
							deepLabel$= "H*+L"
						endif
					printline fórmula prenúcleo 'labeli$' L+H*+L
					endif


					select TextGrid 'base$'
					if delayedPeak = 0 
						Insert point... 'tier_Tones' 'middlestressed' 'labelTone$'
						if deep_labelling = 1
							Insert point... 'tier_deep' 'middlestressed' 'deepLabel$'
						endif
					else
						Insert point... 'tier_Tones' 'timeOfDelayedPeak' 'labelTone$'
						if deep_labelling = 1
							Insert point... 'tier_deep' 'timeOfDelayedPeak' 'deepLabel$'
						endif

					##############
				endif
			endif


		endfor




		
	@printData: "--"
	@printData: "NUCLEAR CONFIGURATION"

		if ultimastressed < 1
			pause There are not stressed syllables
		endif


		###
		# decide where is the nucleus
		##
		selectObject: intTable
		
		int1 = Get value: stressedstotalesfile, "intensity"
		if stressedstotalesfile > 2
			int2 = Get value: 2, "intensity"
		else
			int2= 0
		endif


		intFirst= int1
		intLast = Get value: stressedstotalesfile, "intensity"
		difInt = intLast-intFirst 
		if difInt< -5
			early = 1
			selectObject: intTable
			nOfRows = Get number of rows
			for row to nOfRows
				value= Get value: row, "intensity"
				if value = undefined
					Set numeric value: row, "intensity", 0
				endif
			endfor
			
			max = Get maximum: "intensity"
			if max = undefined
				max = 0
			endif
			strMax$ = string$(max)
			row = Search column: "stringInt", strMax$
		else 
			early= 0
			row = stressedstotalesfile
		endif

		### nucleus by range
		maxR = Get maximum: "range"
		if maxR = undefined
				maxR = 0
		endif
			strMaxR$ = string$(maxR)
		rowR = Search column: "stringRange", strMaxR$

		if rowR = stressedstotalesfile
			early = 0
		else
			early=1
		endif





		selectObject: nucleusData
		Append row
		Set string value: ifile, "file", base$
		Set numeric value: ifile, "nucleus", row
		Set numeric value: ifile, "difInt", difInt
		#by range
		Set numeric value: ifile, "nucleusRange", rowR
		Set numeric value: ifile, "range", maxR


		if row = stressedstotalesfile
			Set string value: ifile, "last", "yes"
		else
			Set string value: ifile, "last", "no"
		endif


		if rowR = stressedstotalesfile
			Set string value: ifile, "lastRange", "yes"
		else
			Set string value: ifile, "lastRange", "no"
		endif

		
		selectObject: stressedInventory
		nucl= Search column: "isNucleus", "yes"


		if nucl <> 0
			ultimastressed= Get value: nucl, "nInterval"
			early = 1
		else 
			nucl = stressedstotalesfile
			early= 0
		endif


		select TextGrid 'base$'
		startingpointlastton = Get start point: segmentation_tier, ultimastressed
		endingpointlastton = Get end point: segmentation_tier, ultimastressed
		ultimasilaba = endIntervalIP
		endingpointlastsyl = Get end point: segmentation_tier, ultimasilaba
		durlastton = endingpointlastton - startingpointlastton

		stressType = ultimasilaba - ultimastressed

		
		pretonlastton = ultimastressed - 1
		startingpointprelastton = Get start point: segmentation_tier, pretonlastton
		endingpointprelastton = Get end point: segmentation_tier, pretonlastton
		durprelastton = endingpointprelastton - startingpointprelastton
		middleprelastton = startingpointprelastton + (durprelastton/2)


		if stressType =0
			@printData: "Oxytone"

			select TextGrid 'base$'
			endingpointlastton = startingpointlastton+ durlastton/2
			durlastton = endingpointlastton-startingpointlastton
			middlelastton = startingpointlastton + (durlastton/2)
			parteslastton=  durlastton/6
			t4lastton = parteslastton*2
			t5lastton = parteslastton*4

			startingpointposlastton = endingpointlastton
			endingpointposlastton = Get end point: segmentation_tier, ultimastressed
			durposlastton = endingpointposlastton - startingpointposlastton
			middleposlastton = startingpointposlastton + (durposlastton/2)
			parteslastpos=  durposlastton/6
			t4lastpos = parteslastpos*2
			t5lastpos = parteslastpos*4
		else
			@printData: "Non-oxytone"

			select TextGrid 'base$'
			middlelastton = startingpointlastton + (durlastton/2)
			parteslastton=  durlastton/6
			t4lastton = parteslastton*2
			t5lastton = parteslastton*4

			postonlastton = ultimastressed + 1
			startingpointposlastton = Get start point... 'segmentation_tier' 'postonlastton'
			endingpointposlastton = Get end point... 'segmentation_tier' 'postonlastton'
			durposlastton = endingpointposlastton - startingpointposlastton
			middleposlastton = startingpointposlastton + (durposlastton/2)
			parteslastpos=  durposlastton/6
			t4lastpos = parteslastpos*2
			t5lastpos = parteslastpos*4	
		endif

		# compute F0 differences
		select PitchTier 'base$'


		if numberOfIntervalPrestressed = 1
			startingpointlastton= startingpointlastton+0.05
			middleprelastton = startingpointlastton
		elsif numberOfIntervalPrestressed = 2
			startingpointprelastton = startingpointprelastton+0.05
		endif

		


		f01pre = Get value at time: startingpointprelastton
		f02pre = Get value at time... 'middleprelastton'
		f03pre = Get value at time: endingpointprelastton
		f01ton = Get value at time... 'startingpointlastton'
		f02ton = Get value at time... 'middlelastton'
		f03ton = Get value at time... 'endingpointlastton'
		f04ton = Get value at time... 't4lastton'
		f05ton = Get value at time... 't5lastton'
		
		@printData: "Last str syl: start" + fixed$(f01ton, 0) + "Hz. Mid: "+ fixed$(f02ton, 0) + "Hz. End: " +fixed$(f03ton, 0)
		@printData: "Last str syl: near start" + fixed$(f04ton, 0) + "Hz. Near end: "+ fixed$(f05ton, 0)


		
		f0fin = Get value at time... 'endingpointlastsyl'-0.05
		f01pos = Get value at time... 'startingpointposlastton'
		f02pos = Get value at time... 'middleposlastton'
		f03pos = Get value at time... 'endingpointposlastton'
		f04pos = Get value at time... 't4lastpos'
		f05pos = Get value at time... 't5lastpos'

		#elige valor más alto...
		f0maxultimastressed = max (f01ton, f02ton,f03ton,f04ton,f05ton)

		selectObject: myPitch
		f0maxton = Get maximum: startingpointlastton, endingpointlastton, "Hertz", "Parabolic"
		whereMax= Get time of maximum: startingpointlastton, endingpointlastton, "Hertz", "Parabolic"
		if f0maxton= undefined
			@undefined: f0maxton, endingpointlastton
			f0maxton = value
			whereMax = time
		endif
			@printData: "Last pres syl:" + fixed$(f02pre, 0) + "Last post: "+ fixed$(f02pos, 0)

		##### 	calculos semitonos ultima stressed #######
		difpreton = (12 / log10 (2)) * log10 ('f02ton' / 'f02pre')
		diftonpos = (12 / log10 (2)) * log10 ('f02pos' / 'f02ton')	
		difpospos = (12 / log10 (2)) * log10 ('f03pos' / 'f01pos')
		diftonMidEnd = (12 / log10 (2)) * log10 ('f03ton' / 'f02ton')
		diftonStartMid = (12 / log10 (2)) * log10 ('f02ton' / 'f01ton')
		diftonMidStartMid = (12 / log10 (2)) * log10 ('f02ton' / 'f04ton')

		diftonStartEnd = (12 / log10 (2)) * log10 ('f03ton' / 'f01ton')
		difprepre = (12 / log10 (2)) * log10 ('f03pre' / 'f01pre')
		diftonfin = (12 / log10 (2)) * log10 ('f0fin' / 'f02ton')
		difpremaxton = (12 / log10 (2)) * log10 ('f0maxton' / 'f02pre')
		diftonmaxton = (12 / log10 (2)) * log10 ('f0maxton' / 'f01ton')
		difposfin= (12 / log10 (2)) * log10 ('f0fin' / 'f02pos')

		@printData: "Differences"
		@printData: "Dif pre/pre: " + string$(difprepre) 
		@printData: "Dif pre/str: " + string$(difpreton) + "st. Dif str/pos: " + string$(diftonpos) +" st."
		@printData: "Dif within stressed syl" 
		@printData: "Start-End: "+ string$(diftonStartEnd)+ "st. Start-Mid " + fixed$(diftonStartMid,0) +"st. Mid-End: " + string$(diftonMidEnd)+"st."

		


		########### 
		# RULES FOR NUCLEAR PITCH ACCENTS
		###########

		@printData: ""
		@printData: "Last stressed syl formulae"

		pitchaccent$ = ""
		labelTone$ = "nuclearSurface "
		deepLabel$ = "nuclearDeep"

		#CALCULO DEL TONO EN VEZ DE POR TERCIOS POR DECLINACION
		select TextGrid 'base$'
		numeropuntosahora = nucl-1
		printline numeropuntosahora 'numeropuntosahora'
		labelstressedprevious$ = ""
		if numeropuntosahora >=1
			tpuntoprevious = Get time of point: tier_Tones, numeropuntosahora
			labelstressedprevious$ = Get label of point: tier_Tones, numeropuntosahora
				select PitchTier 'base$'
				f0_puntoprevious = Get value at time: tpuntoprevious
				select TextGrid 'base$'
				intervalptoprevious = Get interval at time: segmentation_tier, tpuntoprevious
				iniciointervalprevious = Get start point: segmentation_tier, intervalptoprevious
				fintargetprevious = startingpointprelastton
				select Pitch 'base$'
				f0maxtargetprevious = Get maximum: iniciointervalprevious, fintargetprevious, "Hertz", "Parabolic"
				if f0maxtargetprevious = undefined
					@undefined: f0maxtargetprevious, fintargetprevious
							f0maxtargetprevious = value
				endif
				difconlaprevious = (12 / log10 (2)) * log10 (f01pre / f0maxtargetprevious)
				@printData: "Movement since last target " + fixed$(difconlaprevious, 2) + " St"

				if difconlaprevious < thresholdnegative
					pitchaccent$ = "L*"
					labelTone$ = "L*"
					deepLabel$ = "L*"
					stressedH =0
				elif difconlaprevious>=threshold
					pitchaccent$ = "H*"
					labelTone$ = "H*"
					deepLabel$ = "H*"
					stressedH =1
				else
					if f02ton >= tercio2
						pitchaccent$ = "H*"
						labelTone$ = "H*"
						deepLabel$ = "H*"
						stressedH =1
					endif
					if f02ton < tercio2
						pitchaccent$ = "L*"
						labelTone$ = "L*"
						deepLabel$ = "L*"
						stressedH =0
					endif
				endif

		else
			difconlaprevious = (12 / log10 (2)) * log10 ('f02ton' / 'f02pre')
			if ( 'difconlaprevious' < 'thresholdnegative')
				pitchaccent$ = "L*"
				labelTone$ = "L*"
				deepLabel$ = "L*"
				stressedH =0
			elif difconlaprevious >= threshold
				pitchaccent$ = "H*"
				labelTone$ = "H*"
				deepLabel$ = "H*"
				stressedH =1
			else
				if f02ton >= tercio2
					pitchaccent$ = "H*"
					labelTone$ = "H*"
					deepLabel$ = "H*"
					stressedH =1
				endif
				if f02ton < tercio2
					pitchaccent$ = "L*"
					labelTone$ = "L*"
					deepLabel$ = "L*"
					stressedH =0
				endif
			endif
		endif
		@printData: "Level stressed syllable: " + pitchaccent$
		if pitchaccent$ = "L*"
			stressedH=0

		else 
			stressedH=1
		endif


		# movement since last stressed dont goes beyond
		if abs (difpreton) < 2.5
			if pitchaccent$ = "L*"
				labelTone$ = "L*"
				deepLabel$ = "L*"
				stressedH = 0
				@printData: "L*"
			elsif pitchaccent$ = "H*"
				labelTone$ = "H*"
				deepLabel$ = "H*"
				stressedH = 1
				@printData: "H*"
			endif
		endif

		# H*+L for esdrujulas creo que ya no hace falta porque cambie el alineamiento
		#if stressType =2 and pitchaccent$="H*" and difpreton > 0 and difpospos < 3
		#	labelTone$ = "H*+L"
		#	deepLabel$ = "H*+L"
		#	stressedH = 0

		#endif

		#if early= 1 and diftonpos> threshold
		#	labelTone$ = "L*+H"
		#	deepLabel$ = "L*+H"
		#	stressedH = 1
			# 45 and 54
		#endif

		if diftonStartMid< thresholdnegative and diftonMidEnd >= threshold
			labelTone$ = "L*+H"
			deepLabel$ = "L*+H"
			stressedH = 1
		endif

		if difpreton >= threshold
			labelTone$ = "(L+)H*"
			deepLabel$ = "H*"
			stressedH = 1
			@printData: "Rise from pre to str: (L+)H*"
		endif

		# L+H* L*+H rising stressed syllable, 
		if (diftonStartEnd >= threshold) or (diftonStartMid >= threshold)
			labelTone$ = "L+H*"
			deepLabel$= "(L+)H*"
			stressedH = 1
			@printData: "Rising str" + fixed$(diftonmintonmax,2) + " st between ton min and max"
			#L*+H: begins very low and peak at the end of stressed
			if f0tonmin < tercio1 and f03ton > f02ton
				labelTone$ = "L+H*"
				deepLabel$ = "L*+H"
				@printData: "Rising str, begins low"
			endif
			if f02ton > f03ton and diftonmintonmax>=2.5
				labelTone$ = "H*"
				deepLabel$ = "H*"
				@printData: "Peak at mid point str: H*"
			endif
		endif

					
		# H+L*: goes over threshold in the stressed syllable
		if diftonStartEnd < 'thresholdnegative'
			stressedH = 0
			labelTone$ = "H+L*"
			deepLabel$= "H+L*"
			@printData: "Falling stress syl"

			if diftonStartMid> 0
				labelTone$ = "H*+L"
				deepLabel$ = "H*+L"
				@printData: "start mid does not fall H*+L" 

			endif			
			
			#if durlastton> 0.20 and difprepre >= -2
			#	labelTone$ = "H*+L"
			#	deepLabel$ = "H*+L"
			#	@printData: "Too long for a H+L* -> H*+L. Dur: " + fixed$(durlastton,2)
			#	@printData: "Difprepre: "+ fixed$(difprepre,2)
			#elif durlastton > 0.16 and difprepre > 0
			#	labelTone$ = "H*+L"
			#	deepLabel$ = "H*+L"
			#	@printData: "Too long for a H+L* -> H*+L (confidence 80%)"
			#endif

			# thresholds from mean t Student variables chosen by discrimant analysis expected succes 70% 
			if  (durlastton > 0.17 or diftonStartEnd > -2.7) and difprepre < -1.7
				labelTone$ = "H+L*"
				deepLabel$ = "L*"
				@printData: "Discriminant analysis rule,expected succes 90%: H+L*> L*"
				stressedH=0
			endif

			#if difpremaxton < -2.53
			#	labelTone$ = "H+L*"
			#	deepLabel$ = "H+L*"
			#	@printData: "Fall greater than 2.5 only H+L*"
			#endif




			if stressType= 0 and diftonStartEnd > -5 and diftonMidEnd < threshold
				labelTone$ = "L*"
				deepLabel$ = "L*"
				@printData: "oxytone: Falling stress: H+L*> L* (L%)"

			endif
		endif
	
		###
		# Nuclear tritonal (phonetically)
		###

		# H+L*+H (nucleus)

		if stressType=2 and difpreton < thresholdnegative and difpospos > threshold
			labelTone$ = "H+L*+H"
			deepLabel$ = "L*+H"
			stressedH=1
			@printData: "prepreoxy special alignment of L*+H"
		endif

		if difpreton < thresholdnegative and diftonpos > threshold
			labelTone$ = "H+L*+H"
			deepLabel$ = "H+L*"
			@printData: "pre/str rising, str/post falling: H+L*+H"
			stressedH=0
			
			# diferiantiates from L* Bt: possibly H+L*LH%
			#if durlastton < 0.16
			#	deepLabel$ = "H+L*"
			#	stressedH=0	
			#endif


			if  durlastton>= 0.18 and difprepre < -2.25
				# el primer internto era L pero VOY A VERR SI MEJORO RESULTADO CHANGE
				deepLabel$ = "L*"
				deepLabel$ = "H+L*"

				@printData: "Discriminant analysis rule,expected succes 90%: H+L*> L*"
				stressedH=0

				if numeropuntosahora= 0 and difprepre < -6 
				deepLabel$ = "H+L*"
				@printData: "First accent in sentence and falling greater than 6st, keep high target"
				endif
			endif


			##tiene que salir solo si es L*+H HL%
			if diftonMidEnd > threshold and difposfin < thresholdnegative
				stressedH=1
				deepLabel$ = "L*+H"
				@printData: "Rising within the stressed L*+H and falling BT"
				stressedH=1
			endif
		endif



		### NO TOCAR PARA LOS VOCATIVOS
		# H* H*+L or H+L* (phonetically L+H*+L)
		if stressType=2 and difpreton >=threshold and difpospos < thresholdnegative
			labelTone$ = "L+H*+L"
			deepLabel$ = "H*+L"
			@printData: "prepreoxy special aligment of H*+L"
		endif

		if ((difpreton >= threshold) or (diftonStartMid>=threshold)) and ((diftonpos < thresholdnegative) or (diftonMidEnd< thresholdnegative))
			labelTone$ = "L+H*+L"
			deepLabel$ = "L+H*+L"
			stressedH = 0
			# goes down in the first half of the stressed

			if diftonStartMid >threshold
				labelTone$ = "L+H*+L"
				deepLabel$= "H*+L"
				stressedH= 1
			endif

			if diftonStartMid < thresholdnegative
				labelTone$ = "L+H*+L"
				deepLabel$= "H+L*"
				@printData: "The first half of the str syl is falling over threshold: H+L*"
				
				if durlastton> 0.20 and difprepre >= -2
					labelTone$ = "H*+L"
					deepLabel$ = "H*+L"
					@printData: "Too long for a H+L* -> H*+L. Dur: " + fixed$(durlastton,2)
					@printData: "Difprepre: "+ fixed$(difprepre,2)
				elif durlastton > 0.16 and difprepre > 0
					labelTone$ = "H*+L"
					deepLabel$ = "H*+L"
					@printData: "Too long for a H+L* -> H*+L (confidence 80%)"
				endif
			endif


			# apply only in calling contours
			selectObject: myText
			numberOfPoints = Get number of points: tier_Tones
			if numberOfPoints<=1 and ((difpremaxton > threshold) or (f0maxultimastressed=f02ton) or (f0maxultimastressed=f04ton) or (f0maxultimastressed=f05ton))
				labelTone$ = "L+H*+L"
				deepLabel$= "H*"
				stressedH = 1
				@printData: "The F0 peak is far from edges: H*"

				#obvious statement H*+L !H%
				if difpremaxton< 3 and diftonMidStartMid < threshold
					deepLabel$= "H*+L"
					@printData: "early peak: H*+L"
				endif
			endif

			if stressType =0 and difpreton < 3
				labelTone$ = "!H*"
				deepLabel$= "L*"
				@printData: "Oxytone, peak too low for a real target: L+H*+L"
			endif

			if diftonMidEnd > threshold and difposfin < thresholdnegative
				stressedH=1
				labelTone$ = "L*+H"
				deepLabel$ = "L*+H"
				@printData: "Rising within the stressed L*+H and falling BT"
				stressedH=1
			endif
		endif


		######## escribe etiqueta de la última tónica ##########
		select TextGrid 'base$'
		numberOfPoints = Get number of points: tier_Tones
		if numberOfPoints < 1
			exitScript: "No stressed syl anal."
		endif

		#each new IP adds a boundary tone that is not counted in the nucl but it is a point
		# so we add the a point for each IP and we substract the current IP because we have not put the BT yet
		Remove point: tier_Tones, nucl + iIP -1
		Insert point... 'tier_Tones' 'middlelastton' 'labelTone$'
		if deep_labelling = 1
			Remove point: tier_deep, nucl + iIP -1
			Insert point... 'tier_deep' 'middlelastton' 'deepLabel$'
		endif

		if early = 1
		#if its early and more than 1 ip, comething should change here
			numberOfPointsProf = Get number of points: tier_deep
			while numberOfPointsProf> nucl
				Remove point: tier_deep, numberOfPointsProf
				numberOfPointsProf = Get number of points: tier_deep
			endwhile
		endif

		if make_a_txt_report_on_labels = 1
			selectObject: myTable
			Set string value: ifile, "NPA", deepLabel$
			Set string value: ifile, "humanNPA", labelHumanNPA$
			Set string value: ifile, "file", base$
			Set numeric value: ifile, "dur", durlastton
			Set numeric value: ifile, "difprepre", difprepre
			Set numeric value: ifile, "difpremaxton", difpremaxton
			Set numeric value: ifile, "diftonStartEnd", diftonStartEnd
			Set numeric value: ifile, "diftonStartMid", diftonStartMid
			Set numeric value: ifile, "diftonMidEnd", diftonMidEnd
			Set numeric value: ifile, "difpospos", difpospos
			Set numeric value: ifile, "diftonpos", diftonpos


			if (labelHumanNPA$ = deepLabel$) or (labelHumanNPA$ = "H*" and deepLabel$ = "(L+)H*") or (labelHumanNPA$ = "(L+)H*" and deepLabel$ = "H*") or (labelHumanNPA$ = "(L*)" and deepLabel$ = "L*") or (labelHumanNPA$ = "H+L*?" and deepLabel$ = "H+L*") or (labelHumanNPA$ = "(H)+L*" and deepLabel$ = "L*")or (labelHumanNPA$ = "L*+H?" and deepLabel$ = "L*+H")
				agreementNPA =agreementNPA+1
			endif
		endif

		if labelHumanNPA$ = "H+L*" or labelHumanNPA$ = "H*+L" or labelHumanNPA$ = "L*"
			#mySlopes = Create Table with column names: "table", 0, "file NPA humanNPA diftonton slope"
			fallingCounter =fallingCounter+1
			selectObject: mySlopes
			Append row
			#Set string value: fallingCounter, "NPA", deepLabel$
			Set string value: fallingCounter, "file", base$
			Set string value: fallingCounter, "humanNPA", labelHumanNPA$
			Set numeric value: fallingCounter, "dur", durlastton
			Set numeric value: fallingCounter, "difprepre", difprepre
			Set numeric value: fallingCounter, "difpremaxton", difpremaxton
			Set numeric value: fallingCounter, "diftonStartEnd", diftonStartEnd
			Set numeric value: fallingCounter, "diftonStartMid", diftonStartMid
			Set numeric value: fallingCounter, "diftonMidEnd", diftonMidEnd

		endif



		if labelHumanNPA$ = "L+H*" or labelHumanNPA$ = "L*+H" or labelHumanNPA$ = "H*"
			#mySlopes = Create Table with column names: "table", 0, "file NPA humanNPA diftonton slope"
			risingCounter =risingCounter+1
			selectObject: myRising
			Append row
			#Set string value: fallingCounter, "NPA", deepLabel$
			Set string value: risingCounter, "file", base$
			Set string value: risingCounter, "humanNPA", labelHumanNPA$
			Set numeric value: risingCounter, "dur", durlastton
			Set numeric value: risingCounter, "difprepre", difprepre
			Set numeric value: risingCounter, "difpremaxton", difpremaxton
			Set numeric value: risingCounter, "diftonStartEnd", diftonStartEnd
			Set numeric value: risingCounter, "diftonStartMid", diftonStartMid
			Set numeric value: risingCounter, "diftonMidEnd", diftonMidEnd
			Set numeric value: risingCounter, "diftonpos", diftonpos
			Set numeric value: risingCounter, "difpospos", difpospos


		endif

		#selectObject: nucleusData
		#if deepLabel$ = "L*"
		#Set string value: ifile, "lastRange", "L"
		#early = 0
		#endif

		#######################			TONOS JUNTURA			#######################

		ultimasilaba = endIntervalIP
		#dice si es aguda
		if stressType = 0
			@printData: "Stress type oxytone, applying oxytone formulae"
			select TextGrid 'base$'
			endpointtail = endingpointlastsyl
			startingpointtail = startingpointlastton
			durtail = endpointtail - startingpointtail
			partes = durtail/12
			t0tail = startingpointtail
			t3tail = startingpointtail + (3*partes)
			t4tail = startingpointtail + (4*partes)
			t6tail = startingpointtail + (6*partes)
			t8tail = startingpointtail + (8*partes)
			t9tail = startingpointtail + (9*partes)
			t12tail = startingpointtail + (12*partes)

			select PitchTier 'base$'
			f00tail = Get value at time... 't0tail'
			f03tail = Get value at time... 't3tail'
			f04tail = Get value at time... 't4tail'
			f06tail = Get value at time... 't6tail'
			f08tail = Get value at time... 't8tail'
			f09tail = Get value at time... 't9tail'
			f012tail = Get value at time... 't12tail'-0.05


			select TextGrid 'base$'
			pointultimastressed = Get number of points... 'tier_Tones'


			select Pitch 'base$'
			f0maxprimeramitaddetail = Get maximum: f03tail, f06tail, "Hertz", "Parabolic"
			if f0maxprimeramitaddetail = undefined
				f0maxprimeramitaddetail = f06tail
			endif

			f0minprimeramitaddetail = Get minimum: f03tail, f06tail, "Hertz", "Parabolic"
			if f0minprimeramitaddetail = undefined
				f0minprimeramitaddetail = f06tail
			endif

		
			# i consider f03tail as the mid point of stressed
			diftonfin = (12 / log10 (2)) * log10 ('f012tail' / 'f03tail')
			diftonCasifin = (12 / log10 (2)) * log10 ('f04tail' / 'f03tail')
			diftonmidtail = (12 / log10 (2)) * log10 ('f06tail' / 'f03tail')
			dif06 = (12 / log10 (2)) * log10 ('f012tail' / 'f03tail')
			dif03 = (12 / log10 (2)) * log10 ('f06tail' / 'f03tail')
			dif36 = (12 / log10 (2)) * log10 ('f012tail' / 'f06tail')
			
			#para el mid
			dif6max = (12 / log10 (2)) * log10 ('f012tail' / 'f0maxultimastressed')
			dif6min3 = (12 / log10 (2)) * log10 ('f012tail' / 'f0minprimeramitaddetail')

			#sólo para el tritonal
			dif02 = (12 / log10 (2)) * log10 ('f08tail' / 'f06tail')
			dif34 = (12 / log10 (2)) * log10 ('f09tail' / 'f06tail')
			dif23 = (12 / log10 (2)) * log10 ('f06tail' / 'f08tail')
			dif46 = (12 / log10 (2)) * log10 ('f012tail' / 'f09tail')
			dif24 = (12 / log10 (2)) * log10 ('f09tail' / 'f08tail')


			finalLabel$= "final-agudo"
			finalLabeldeep$="final-agudo"

			# this is to match value in rest of syllables
			f04tail= f09tail

		####	if not oxytone	###################
		else
			@printData: ""
			@printData: "Non-oxytone toneme: labelling Boundary Tones"

			select TextGrid 'base$'
			endpointtail = endingpointlastsyl
			startpointtail = endingpointlastton
			durtail = endpointtail - startpointtail
			partespos = durtail/6
			t0tail = startpointtail
			t2tail = startpointtail+ (2*partespos)
			t3tail = startpointtail+ (3*partespos)
			t4tail = startpointtail+ (4*partespos)
			t6tail = startpointtail+ (6*partespos)

			select PitchTier 'base$'
			f00tail = Get value at time... 't0tail'
			f02tail = Get value at time... 't2tail'
			f03tail = Get value at time... 't3tail'
			f04tail = Get value at time... 't4tail'
			f06tail = Get value at time: t6tail
			select Pitch 'base$'
			f0maxprimeramitaddetail = Get maximum: f00tail, f03tail, "Hertz", "Parabolic"
			if f0maxprimeramitaddetail = undefined
				f0maxprimeramitaddetail = f03tail
			endif

			f0minprimeramitaddetail = Get minimum: f00tail, f03tail, "Hertz", "Parabolic"
			if f0minprimeramitaddetail = undefined
				f0minprimeramitaddetail = f03tail
			endif

			# diffeences computation

			# f02ton es centro stressed
			diftonfin = (12 / log10 (2)) * log10 ('f06tail' / 'f02ton')
			diftonCasifin = (12 / log10 (2)) * log10 ('f04tail' / 'f02ton')
			diftonmidtail = (12 / log10 (2)) * log10 ('f03tail' / 'f02ton')

			dif06 = (12 / log10 (2)) * log10 ('f06tail' / 'f00tail')
			dif03 = (12 / log10 (2)) * log10 ('f03tail' / 'f00tail')
			dif36 = (12 / log10 (2)) * log10 ('f06tail' / 'f03tail')
			#sólo para el tritonal
			dif02 = (12 / log10 (2)) * log10 ('f02tail' / 'f00tail')
			dif34 = (12 / log10 (2)) * log10 ('f04tail' / 'f03tail')
			dif23 = (12 / log10 (2)) * log10 ('f03tail' / 'f02tail')
			dif24 = (12 / log10 (2)) * log10 ('f04tail' / 'f02tail')

			dif46 = (12 / log10 (2)) * log10 ('f06tail' / 'f04tail')
			#para el mid
			dif6max = (12 / log10 (2)) * log10 ('f06tail' / 'f0maxultimastressed')
			dif0max3 = (12 / log10 (2)) * log10 ('f0maxprimeramitaddetail' / 'f00tail')
			dif0min3 = (12 / log10 (2)) * log10 ('f0minprimeramitaddetail' / 'f00tail')
			dif6min3 = (12 / log10 (2)) * log10 ('f06tail' / 'f0minprimeramitaddetail')

			@printData: "Dif between mid-str and end tail: " + fixed$(diftonfin,2) +" st." + "Diff peak str-end tail: " + fixed$(dif6max,0)
			@printData: "Dif between start-end tail: " + fixed$(dif06,2) +" st."
			@printData: "Dif between start-mid tail: " + fixed$(dif03,2) +" st."
			@printData: "Dif between mid-end tail: " + fixed$(dif36,2) +" st."
			
			finalLabel$= "L\% "
			finalLabeldeep$="L\% "
		endif
			

		##########
		#	BOUNDARIES: monotonal
		##########

		##
		# after a low target only H and L possible
		##

		if (stressedH = 0) and ((abs(dif06) <'threshold') or (diftonfin<thresholdnegative))
			finalLabel$ = "L\% "
			finalLabeldeep$ = "L\% "
			@printData: " After L: nothing or falling"
			if f04tail > tercio1
				finalLabel$ = "!H\% "
				finalLabeldeep$ = "!H\% "
			endif

			if nucl>0
				select TextGrid 'base$'
				labelstressedprevious$ = Get label of point: tier_Tones, nucl
			
			
				if labelstressedprevious$ = "H+L*+H"
					finalLabel$ = "HL\% "
					finalLabeldeep$ = "HL\% "
					@printData: " After H+L*+H:  falling: HL%"

					if abs(dif06)< threshold
						finalLabel$ = "LH\% "
						finalLabeldeep$ = "LH\% "
						@printData: "After H+L*+H nothing > H+L* LH% (probably a tail without pitch fricative)"
					endif

				endif
			endif
		endif
		
		if stressedH = 0 and (dif06 >= threshold or dif36 >= threshold)
			finalLabel$ = "LH\% "
			finalLabeldeep$ = "LH\% "
			@printData: "Rising poststr: LH%"
		endif


		##
		# after a HIGH target
		##

		if stressedH = 1 and (diftonfin >= thresholdnegative)
			finalLabel$ = "H\% "
			finalLabeldeep$ = "H\% "
			@printData: "After H. From str to end does not fall beyond threshold"
			# i think that the fillowing formula should be high
			if diftonfin  < 0
				finalLabel$ = "!H\% "
				finalLabeldeep$ = "!H\% "
				@printData: "Does not rise either"
			endif
		elif stressedH = 1 and (diftonfin < thresholdnegative)
			finalLabel$ = "L\% "
			finalLabeldeep$ = "L\% "
			@printData: "After H. There is a fall"
			if diftonfin >= -3.1
				finalLabel$= "!H\% "
				finalLabeldeep$ = "!H\% "
				@printData: "Falls for less than 3 st."
			endif
			
			selectObject: myText
			labelstressedprevious$ = Get label of point: tier_deep, nucl
			if labelstressedprevious$ = "L*+H"
				finalLabel$= "HL\% "
				finalLabeldeep$ = "HL\% "
				@printData: "Falling BT with "+ labelstressedprevious$ +" L% --> HL%" 
			endif
	

		endif

		if stressedH= 1 and stressType=2 and (diftonfin < -1)
				finalLabel$= "H!H\% "
				finalLabeldeep$ = "HL\% "
				@printData: "prepreoxy."
		endif

		
		######### BITONALES

		# bitonales después de L

		# subida en la 1posstressed y bajada en la segunda
		# en la postónica hay una subida (la diferencia es positiva), del inicio al máximo de la tail pasa el threshold. Y el final pasa el threshold negativo.
		#debería calcularla con el maximo de la tail y no el máximo de la tónica, así funcionaría también en los H+L* 
		if stressedH = 0 and dif03 >= threshold and dif36 < thresholdnegative
			finalLabel$ = "HL\% "
			finalLabeldeep$ = "HL\% "
			@printData: "After L. Rise and fall"

			if dif03 < 3 and diftonCasifin > -3
				finalLabel$ = "H!H\% "
				finalLabeldeep$ = "!H\% "
			endif
		endif


		# ultima tónica baja primera pos sube menos del threshold o baja más del threshold y la segunda sube
		#alternativa a usart diftonmidtail es usar dif 03 
		if stressedH = 0 and (dif03 < threshold) and dif36 >= threshold
			finalLabel$ = "LH\% "
			finalLabeldeep$ = "LH\% "
			@printData: "After L. Nothing and rise"

			if f04tail < tercio2
				finalLabel$ = "L!H\% "
			endif
		endif

		

		##
		# bitonales after a high target
		##
		if stressedH = 1 and (diftonmidtail < thresholdnegative) and (dif36 > threshold)
			@printData: "After H. A fall and rise"
			finalLabel$ = "LH\% "
			finalLabeldeep$ = "LH\% "
			if f06tail < tercio2 or dif36 < 3
				finalLabel$ = "L!H\% "
				finalLabeldeep$ = "LH\% "
			endif
			
		endif

		if stressedH = 1 and (dif02 > threshold and dif24 < thresholdnegative)
			finalLabel$ = "HL\% "
			finalLabeldeep$ = "HL\% "
		endif
		
		
		# dif03  and not diftonmid makes it work better in calling contours
		if stressedH = 1 and (dif03 > thresholdnegative and dif36 < threshold)
			finalLabel$ = "HL\% "
			finalLabeldeep$ = "HL\% "

			@printData: "After H. nothing and fall"
		
				selectObject: myText
				labelstressedprevious$ = Get label of point: tier_deep, nucl
				if labelstressedprevious$ = "H*+L"
						finalLabel$ = "L\% "
						finalLabeldeep$ = "L\% "
						@printData: "After H. nothing and fall, H included in stressed"
				endif
		

			if dif03 >= threshold
				finalLabel$ = "\!dHL\% "
				if diftonCasifin>-3
					finalLabel$ = "\!dH!H\% "
					finalLabeldeep$ = "L\%"
				endif
			endif


			if (f04tail > tercio1) or diftonCasifin>-3
				finalLabel$ = "H!H\% "
				finalLabeldeep$ = "!H\% "
					selectObject: myText
					labelstressedprevious$ = Get label of point: tier_deep, nucl
					if labelstressedprevious$ = "L*+H"
						finalLabel$ = "H!H\% "
						finalLabeldeep$ = "HL\% "
					endif
			
			endif

			
		endif

		##########	#######	escribe la etiqueta
		@correctFallingNPAforLHboundary()


		select TextGrid 'base$'
		Insert point... 'tier_Tones' 'endpointtail' 'finalLabel$'
		
		if deep_labelling = 1
			Insert point... 'tier_deep' 'endpointtail' 'finalLabeldeep$'
		endif
			
			if make_a_txt_report_on_labels = 1
					selectObject: myTable
					Set string value: ifile, "BT", finalLabeldeep$
					if labelHumanBT$ = finalLabeldeep$ or (labelHumanBT$ = "LH\% ?" and finalLabeldeep$ = "LH\% ")
							agreementBT =agreementBT+1
					endif
			endif
		endif
		# guardo para la proxima vez que pase que el inicio de la IP tiene que ser el final de la que acaba de pasar
		startIntervalIP = endIntervalIP
		removeObject: stressedInventory
	endfor 
	#acaba el bucle para las IP


	################# borra el etiquetaje fonético en caso de que no se quiera

	if surface_labelling = 0
		select textGrid 'base$'
		numberOfTiers = Get number of tiers
		itier = 1
		repeat
			tiername$ = Get tier name... itier
			itier = itier + 1
		until tiername$ = name$ or itier > numberOfTiers
		if tiername$ = "Tones"
            tier_ToBIfonetico = itier
		endif
		Remove tier: itier
	endif
	if deep_labelling = 0
		select textGrid 'base$'
		numberOfTiers = Get number of tiers
		itier = 1
		repeat
			tiername$ = Get tier name... itier
			itier = itier + 1
		until tiername$ = name$ or itier > numberOfTiers
		if tiername$ = "Tones II"
            tier_deep = itier
		endif
		Remove tier: itier
	endif

##############	GUARDAR	#####################
	if correction = 1
		selectObject: mySound, myText
		View & Edit
			
		editor: "TextGrid "+ base$
			Pitch settings: minpitch, maxpitch, "Hertz", "autocorrelation", "automatic"
			pause Make changes and press Continue
		endeditor


	endif
	select TextGrid 'base$'

	#if stressed_syllable_mark$ = markstressedcompleja$
	#	do ("Replace interval text...", segmentation_tier, i, numberOfIntervals, "ˈ", "\'1 ", "Literals")
	#endif
if overwrite_TextGrid = 1
	Save as text file: folder$ + "/"+ base$ + ".TextGrid"
endif

##############	pictures	#####################
	if create_picture = 1
		picture_width = 7
		
		selectObject: mySound
		To Spectrogram... 0.005 5000 0.002 20 Gaussian
		Times
		Font size: 12
		Line width: 1
		Black

	    Viewport: 0, picture_width, 0, 2
		select Sound 'base$'
		Draw... 0 0 0 0 no curve
		Viewport: 0, picture_width, 1, 4
		select Spectrogram 'base$'
		Paint... 0 0 0 0 100 yes 50 6 0 no

		
		Line width... 10
		White
		Viewport: 0, picture_width, 1, 4
		select Pitch 'base$'
		Smooth: 15
		Draw: 0, 0, minpitch-50, maxpitch+50, "no"

		Line width... 6
		Black
		Draw: 0, 0, minpitch-50, maxpitch+50, "no"

		Line width... 1

			minpitch$ = fixed$ (minpitch-50, 0)
			maxpitch$= fixed$ (maxpitch+50, 0)
			minpitch_rounded = number (minpitch$)
			maxpitch_rounded = number (maxpitch$)
			maxpitch_rounded = maxpitch_rounded/10
			minpitch_rounded = minpitch_rounded/10
			maxpitch_rounded$ = fixed$(maxpitch_rounded, 0)
			maxpitch_rounded = number (maxpitch_rounded$)
			minpitch_rounded$ = fixed$(minpitch_rounded, 0)
			minpitch_rounded = number (minpitch_rounded$)
			minpitch_rounded = minpitch_rounded * 10
			maxpitch_rounded = maxpitch_rounded * 10
			One mark left... minpitch_rounded yes no no
			One mark left... maxpitch_rounded yes no no


		wideRange = gama+100
		if wideRange >= 500
			interval_entre_marks = 150
		elsif wideRange >= 300
			interval_entre_marks = 100
		elsif wideRange < 300
			interval_entre_marks = 50
		endif

		numero_de_marksf0 = (wideRange/interval_entre_marks)+ 1

		minpitch= minpitch-50
		maxpitch= maxpitch+50
		if minpitch >= 250
			mark = 250
		elsif minpitch >= 200
			mark = 200
		elsif minpitch >= 150
			mark = 150
		elsif minpitch >= 100
			mark = 100
		elsif minpitch >= 50
			mark = 50
		elsif minpitch < 50
			mark = 0
		endif

		for i to numero_de_marksf0
			mark = mark + interval_entre_marks
			mark$ = "'mark'"
			if mark <= maxpitch
				do ("One mark left...", 'mark', "yes", "yes", "no", "'mark$'")
			endif
		endfor


		Draw inner box
		Draw... 0 0 'minpitch' 'maxpitch' no

			label_of_the_frequency_axis$ = "F0 (Hz)"
		Text left... yes 'label_of_the_frequency_axis$'
		label_of_the_time_axis$ = "t (s)"

		Text top... no 'label_of_the_time_axis$'


		Marks top every... 1 0.1 no yes no
		Marks top every... 1 0.5 yes yes no




		select TextGrid 'base$'
		numberOfTiers = Get number of tiers


		boxtextgrid = (4 + 0.5 * 'numberOfTiers') - 0.02 * 'numberOfTiers'


		# Ventana rosa para los texgrid
		Viewport: 0, picture_width, 1, boxtextgrid


		# Dibuja el TextGrid
		select TextGrid 'base$'
		Draw... 0 0 yes yes no

		# Crea ventana para línea exterior
		Viewport: 0, picture_width, 0, boxtextgrid
		# Dibuja la línea exterior
		Black
		Draw inner box

  		if macintosh = 1
  			Save as PDF file: folder$ +"/"+ base$ + ".pdf"
		endif

		if windows = 1
			Save as 300-dpi PNG file: folder$ + "/" + base$ + ".png"
		endif
		Erase all

	endif



##############	LIMPIAR		#####################
	select all
	minus Strings list
	minus Table table
	minus Table intTable
	minus Table mySlopes
	minus Table myRising
	minus Table nucleus
	minus Table allTable


	Remove

	if make_a_txt_report_on_labels=1 
		agrNPA = (agreementNPA/numberOfFiles)*100
		agrBT = (agreementBT/numberOfFiles)*100

		writeInfoLine: string$(agreementNPA)+ " NPA labels match: " + fixed$(agrNPA,2) + "%"
		appendInfoLine: string$(agreementBT) + " BT labels match: " + fixed$(agrBT,2) + "%"
	endif

#############	FINAL BUCLE GENERAL	#############
# bucle archivos
endfor


if make_a_txt_report_on_labels=1 
	selectObject: myTable
	Sort rows: "humanNPA"
	Save as semicolon-separated file: folder$ + "/"+ "labelList" + ".txt"

	selectObject: mySlopes
	Sort rows: "humanNPA"
	Save as text file: folder$ + "/"+ "dataOfNPA" + ".Table"

	selectObject: myRising
	Sort rows: "humanNPA"
	Save as text file: folder$ + "/"+ "dataOfrisingNPA" + ".Table"
endif
# Limpieza final
select all
minus Strings list
	minus Table table
	minus Table intTable
	minus Table mySlopes
	minus Table myRising
	minus Table nucleus
	minus Table allTable
Remove

procedure ponetiqueta ()
	select TextGrid 'base$'
		Remove point... 'tier_Tones' 'pointfinal'
		Remove point... 'tier_Tones' 'pointultimastressed'

		Insert point... 'tier_Tones' 't3tail' 'labelTone$'
		Insert point... 'tier_Tones' 'endpointtail' 'finalLabel$'

	if deep_labelling =1
		Remove point... 'tier_deep' 'pointfinal'
		Remove point... 'tier_deep' 'pointultimastressed'
		Insert point... 'tier_deep' 't3tail' 'deepLabel$'
		Insert point... 'tier_deep' 'endpointtail' 'finalLabeldeep$'
	endif
endproc

procedure undefined: value, time
total_duration= Get total duration
timeprimitivo = time
	while value = undefined and time <total_duration
		time= time+0.001
		value = Get value at time: time, "Hertz", "Linear"
	endwhile

	if value = undefined
		time = timeprimitivo
		while value = undefined and time > 0
			time= time-0.001
			value = Get value at time: time, "Hertz", "Linear"
		endwhile
	endif
endproc



procedure printData: data$
	if verbose = 1
		appendInfoLine: data$
	endif
endproc



procedure correctFallingNPAforLHboundary()

## need to recover and correct previous NPA:
# LH% only combines with H+L* and L*
	if finalLabeldeep$ = "LH\% "
		select TextGrid 'base$'
		#numeropuntosahora= Get number of points: tier_Tones
		labelstressedprevious$ = Get label of point: tier_Tones, nucl
		
		if labelstressedprevious$ = "H*+L"
			Set point text: tier_Tones, nucl, "H+L*"
		endif	
		
		if deep_labelling = 1
			labelstressedpreviousprof$ = Get label of point: tier_deep, nucl
			if labelstressedpreviousprof$ = "H*+L"
					Set point text: tier_deep, nucl, "H+L*"
					deepLabel$ = "H+L*"

					if make_a_txt_report_on_labels = 1
					selectObject: myTable
					Set string value: ifile, "NPA", deepLabel$
						if labelHumanNPA$ = deepLabel$
							agreementNPA =agreementNPA+1
						endif
					endif
			endif
		endif
	endif

	if finalLabeldeep$ = "!H\% "
		select TextGrid 'base$'
		labelstressedprevious$ = Get label of point: tier_Tones, nucl
		
		if labelstressedprevious$ = "L*+H" or labelstressedprevious$ = "L+H*"
			Set point text: tier_Tones, nucl, "H*"
		endif

		if labelstressedprevious$ = "H+L*"
			finalLabeldeep$ = "L\% "

		endif
		
		if deep_labelling = 1
			labelstressedpreviousprof$ = Get label of point: tier_deep, nucl
			if labelstressedpreviousprof$ = "L*+H" or labelstressedprevious$ = "L+H*"
					Set point text: tier_deep, nucl, "H*"
					deepLabel$ = "H*"

					if make_a_txt_report_on_labels = 1
					selectObject: myTable
					Set string value: ifile, "NPA", deepLabel$
						if labelHumanNPA$ = deepLabel$
							agreementNPA =agreementNPA+1
						endif
					endif
			endif
		endif
	endif


endproc