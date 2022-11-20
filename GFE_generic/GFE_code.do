******************************************************************************************************
* Generic code for the Grouped Fixed-Effects Estimator (GFE)                                         *
* Bonhomme and Manresa, "Grouped Patterns of Heterogeneity in Panel Data", to appear in Econometrica *
******************************************************************************************************

* Stata version 11.2

* The code computes the optimal grouping for individuals in a generic unbalanced panel dataset into G different groups.
* The calculation of the Grouped Fixed Effects (GFE) estimator is done by means of an executable FORTRAN file.

* Throughout the program XXX denotes inputs to be filled by the researcher.
* The user needs to do the following tasks before running this program:
*  - Save the input dataset in the folder "GFE_generic" in stata format.
*  - Make sure that the panel contains the same number of periods for all units, possibly with missing information (if unbalanced).
*  - Fill in appropiately the XXX in the "USER INPUTS" part of this program. Specifically:
* 	-- Enter the path to the folder "GFE_generic" (line 56).
*       -- Fill in the name of the dataset in "UPLOAD DATA" (line 61).
*	-- Specify the individual/unit identifier as ID (line 64).
*	-- Specify the time identifier as TIME (line 65).
*	-- Label the outcome (dependent variable) as "OUTCOME" (line 74).
*	-- Label the list of covariates (independent variables) as "COVARIATES" (line 78).

* Once this is done, the program is ready to be run in Stata.

* When the program runs, an executable file appears in order to calculate the GFE estimator. 
* At this point, the researcher is asked to specify:
*  - The number of groups G
*  - The number of covariates (0 or greater). The number of covariates must match the dimension of "COVARIATES".
*  - The type of algorithm: "0" for algorithm 1 in the paper (iterative), and "1" for algorithm 2 (variable neighborhood search)
*  - The parameters of the algorithm: 
*          -- For algorithm 1: only the number of starting values (ex: 1000).
*          -- For algorithm 2: the number of starting values, the number of neighbors, and the maximum number of iterations (ex: 10,10,10).
*  - The type of standard errors (1 if bootstrapped), together with the computation algorithm (ex: 5,10,5 for Algorithm 2, with 100 replications).


* The executable file generates the "outputobj.txt" file, which contains:
*  - The value of the objective function attained at each iteration in the algorithm (Nsim in the paper).
*  - The estimate of the slope parameters (theta in the paper).
* Inspection of this file provides an idea of the numerical stability of the solution. 

* Finally, the optimal grouping per unit is added to the input dataset as an additional variable named "assignment". 
* The resulting dataset, containing all existing variables as well as the new "assignment" variable is saved as a new dataset named "DATA_GFE.dta".
* "DATA_GFE.dta" is contained in "GFE_generic".
* Bootstrapped standard errors (optional) can be found in "standard_errors_bootstrap"

* The code contains two optional parts:
*  - The algorithm may be estimated in deviations to the mean, so as to remove time-invariant fixed-effects (line 80).
*  - A selection criterion may be applied to remove units that have less than a prespecified number of time periods (line 112).

* Final word: PLEASE USE! ANY COMMENTS OR SUGGESTIONS ARE WELCOME! - emanresa@mit.edu, sbonhomme@uchicago.edu 

clear 
set more off

*****************
* USER INPUTS   *
*****************

* ENTER PATH HERE
/* cd XXX */

*cd GFE_generic

* UPLOAD DATA
use df, clear

* IDENTIFIERS (UNIT & PERIOD)
gen ID = individual
gen TIME = time

* PANEL DATA SETUP
tsset ID TIME
sort ID TIME
save DATA_inter, replace

* OUTCOME (TO BE FILLED IN)
* Example: "unab OUTCOME: Y"
unab OUTCOME: Y

* LIST OF COVARIATES (TO BE FILLED IN)
* Example: "unab COVARIATES: X1 X2"
unab COVARIATES: X1 X2

* We construct deviation to the mean (optional)
/*
foreach vv of varlist `OUTCOME'{
bys ID (TIME): egen inter=mean(`vv')
replace `vv'=`vv'-inter
drop inter
}
foreach vv of varlist `COVARIATES'{
bys ID (TIME): egen inter=mean(`vv')
replace `vv'=`vv'-inter
drop inter
}
*/

********************
* AUTOMATIC CODE   *
********************

* Define non-missing indicators, as well as a global missing indicator
gen nomis_tot=1
foreach vv of varlist `OUTCOME'{
gen nomis_`vv' = (`vv'~=.)
replace nomis_tot=nomis_tot*nomis_`vv'
}
foreach vv of varlist `COVARIATES'{
gen nomis_`vv' = (`vv'~=.)
replace nomis_tot=nomis_tot*nomis_`vv'
}

* Compute the number of non-missing observations, by ID
bys ID (TIME): egen sumnomis=sum(nomis_tot)

* Keep only if number of non-missing observations>=THRESH (optional)
/*
scalar THRESH = XXX
keep if sumnomis>THRESH
*/

* Recompute the total non-missing indicator
drop sumnomis 
bys ID (TIME): egen sumnomis=sum(nomis_tot)

* Create a file with the unit identifiers
preserve
gen uno = 1
collapse (count) uno, by(ID)
drop uno
save ID_list.dta, replace
restore

* We use the convention that, when OUTCOME or any of the COVARIATES is missing, 
*  then all of them are set to zero
keep ID TIME nomis_tot sumnomis `OUTCOME' `COVARIATES'
foreach vv of varlist `OUTCOME'{
replace `vv'=0 if nomis_tot==0 
}
foreach vv of varlist `COVARIATES'{
replace `vv'=0 if nomis_tot==0 
}

* Store N and T_max (ie, the maximum number of periods per individual)
preserve 
qui su ID, det
qui count if ID==r(min)
scalar Tmax=r(N)
count
scalar NTmax=r(N)
scalar N=NTmax/Tmax
gen var1 = N
gen var2 = Tmax
collapse var1 var2
outsheet using InputNT.txt, nonames replace
restore

* We print in txt file the pattern of missing data 5
preserve 
keep ID TIME nomis_tot
sort ID TIME
reshape wide nomis_tot, i(ID) j(TIME) 
drop ID
outsheet using Ti_unbalanced.txt, nonames replace
restore

sort ID TIME
keep `OUTCOME' `COVARIATES'
order `OUTCOME' `COVARIATES'
outsheet using data.txt, nonames replace

* We call the fortran executable in order to compute the GFE assignment
*shell cd Y:\Bonhomme_Manresa_codes_replicationFiles_Bonhomme\Bonhomme_Manresa_codes\Application\GFE_generic
shell Bootstrap_version.exe

* We incorporate the group assignement into the original data
clear
insheet using assignment.txt
rename v1 assignment
merge 1:1 _n using ID_list.dta
drop _merge

merge 1:m ID using DATA_inter.dta
drop _merge ID TIME

************
* OUTPUT   *
************

* Save data in DATA_GFE
save DATA_GFE.dta, replace


************
* CLEAN UP *
************

* We delete all auxiliary files created as input for the GFE.exe program
shell del data.txt InputNT.txt Ti_unbalanced.txt assignment.txt ID_list.dta


* We rename bootstrap output files: "replications.txt" contains the estimation of the replications and "standard_errors_bootstrap.txt" contains the standard errors.
shell ren assignment_bootstrap.txt replications.txt
shell ren outputobj_bootstrap.txt standard_errors_bootstrap.txt
