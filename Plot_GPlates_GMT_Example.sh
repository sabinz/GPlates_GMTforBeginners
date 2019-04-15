#!/bin/bash

gmt gmtset PS_COLOR_MODEL=RGB PS_MEDIA=A2 MAP_FRAME_TYPE=plain FORMAT_GEO_MAP=ddd:mm:ssF FONT_ANNOT_PRIMARY=14p MAP_FRAME_PEN=thin FONT_LABEL=16p,Helvetica,black PROJ_LENGTH_UNIT=cm MAP_GRID_PEN_PRIMARY=0.1p,220/220/220

# Example GPlates-GMT plotting script
# ---- Author: Sabin Zahirovic
# ---- Date: 14 January 2019 (last updated)

# ---- This script creates time-series JPEGs of the age-grid, coastline,
# ---- closed polygon outlines and velocity vectors for the purposes of 
# ---- creating figures or animations. The current plate model used is the 
# ---- modified Caltech plate polygon dataset. 
# ---- 
# ---- This script was created to work with GMT version 5 or above
# ---- If you find that GMT reports errors, it may be because you are using an older version
# ---- and may need to upgrade. The flags may produce such errors on old GMT versions,
# ---- and can be changed to flags as a last resort if you cannot upgrade to a new version.
# ----

# ---- IMPORTANT: Note on Velocities
#       Velocity vectors exported from GPlates (see screenshot for required options) - Velocity vectors scaled by 0.1 and sampled every 1 points in GPlates export option 
#       Column 1 = Lon
#       Column 2 = Lat
#       Column 3 = Azimuth (degrees east of North) of velocity vector
#       Column 4 = SCALED Magnitude of vector (cm per year)
#       The GMT PSXY application can plot such vectors using the -SV command. Be very careful to not use the lowercase "v"
#       as this would plot the incorrect velocity vector directions. Consult the PSXY manual page for more info. 
#
# ---- 

# ---- IMPORTANT: 
#      This draft version of the script is mixing GMT4 and GMT5 syntax, but should work with warnings. 

# ---- Initiates basic parameters that do not depend on the $age variable 

# Projection
frame=90/180/-45/20
width=15
proj=M135/$width # Mercator projection 

age_cpt=age.cpt

# Set absolute or relative path to the "main" directory where GPlates output is generated 
root=GPlates_Geometries 

# ---- Set recontime loop

age=0

  while (( $age <= 160 ))
      do

	# Output filenames
	timestep=$( echo " 160 - $age" | bc )
	echo "Age is " $age " Ma"
	echo "Frame is " $timestep
	timestamp=$(printf "%04d" $timestep)

	echo "Timestamp is " $timestamp

	# ---- Input parameters dependant on the $age variable

	# Input grid file
	grdfile=Agegrid/EarthByte_AREPS_Muller_etal_2016_AgeGrid-${age}.nc

	# Input coastline directory generated using GPlates "Export Animation" tool
	csfilexy=${root}/Coastlines/reconstructed_${age}.00Ma.xy
	subduction_left=${root}/Topologies/topology_subduction_boundaries_sL_${age}.00Ma.xy
	subduction_right=${root}/Topologies/topology_subduction_boundaries_sR_${age}.00Ma.xy
	subduction=${root}/Topologies/topology_network_subduction_boundaries_${age}.00Ma.xy

	# Input polygon and velocities directories with relevant date-stamps (see above)
	input_polygons=${root}/Topologies/topology_platepolygons_${age}.00Ma.xy
	input_velocity=${root}/Velocities/velocity_${age}.00Ma.xy

	# Output filenames
	outfile1=GPlates_reconstructions_${timestamp}.ps

	# Plots simple basemap with Mollweide projection
	gmt psbasemap -R$frame -J$proj -Ba30f15 -Y5c -P -K > $outfile1

	# Plots alternative basemap time-dependent raster (in this case, seafloor age-grid)
	# gmt grdimage -R$frame -J$proj -Y5c $grdfile -Ba30wNsE -C$age_cpt -K -V -P > $outfile1

	# Plots reconstructed present-day coastlines 
	gmt psxy -R$frame -J$proj -Gnavajowhite4 -Bf30WNse -K -O $csfilexy -V >> $outfile1

	# Plots plate topology outlines
	gmt psxy -R$frame -J$proj -W1.5p $input_polygons -K -O -N -V >> $outfile1

	# Plot subduction zones and their symbology 
	gmt psxy -R$frame -J$proj -W1.5p,magenta -K -O ${subduction} -V >> $outfile1
	gmt psxy -R$frame -J$proj -W1.5p,magenta -Sf7p/1.5plt -K -O ${subduction_left} -V >> $outfile1
	gmt psxy -R$frame -J$proj -W1.5p,magenta -Sf7p/1.5prt -K -O ${subduction_right} -V >> $outfile1

	# Plots velocity vectors
	gmt psxy -R$frame -J$proj -W0.3p $input_velocity -SV0.2c+e+g -G0 -K -O -V >> $outfile1

	# Plot age timestamp 
	echo "14 -1.2 18 0 1 5 $age Ma" | gmt pstext -R0/10/0/1 -Jx1 -N -K -O >> $outfile1

	# Plot colour bar
	gmt psscale -D6.5/9/13/0.4h -C$age_cpt -B20:"Age of Oceanic Crust [Myr]": -Y-10c -O >> $outfile1

	# Converts the PS file
	gmt ps2raster $outfile1 -A -E300 -Tj -P


age=$(($age + 1))
done
