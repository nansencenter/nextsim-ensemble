# Todo
1. DONE. add a script-block to resubmit crashed job. Waiting all jobs are finished before moving to enkf. 
2. DONE: stop daily output of .bin and .dat, only output the final. output_per_day=0 in nextsim.cfg
3. DONE. increate time step in nextsim.cfg in the latest nextsim version. from 200 to 400
4. DONE. investigate prior.nc size puzzle. duplication of outputing statevectors is fixed
5. Adjust ECMWF data air drag coefficient.
6. Run more periods to reducing results dependence on the initial dates.
7. DONE. merge branch to enkf_interface or others. merged develop branch
8. discard: add damage to Moorings.nc
9. Tune factors (R, K, inflation, localisation radii) in enkf
10. implement Ali's changes
11. change step 5 to online data transfer with save/read on at the end/beginning of simulations.
12. retrieve subdomain charged by each processor by index, to apply the correct perturbation




# Enkf - c
## compile  
  make clean;make; cp ./bin/* example_filter/; cd example_filter/; make clean; 
  keywords in code related to spread： UPDATE_DOANALYSISSPREAD， &fields[i - bufindex], "write analysis spread" 
## Reference_grid prepared for using enkf-c code
  grid size: 528*522
  longitude: -180 to 180
  latitude: N 40.137 to 90 

## Tune factors (refer to Todo 9)
1. R-factor: Incresing R-factor decreases the impact of observation. Ensemble spread/sqrt(R-factor)
2. K-factor: Incresing K-factor increases the impact of ensemble spread. background check. 2.7.3. 
   Modifies observation error so that the increment for this observation would not exceed KFACTOR * <ensemble spread> (all in observation space) after assimilating this observation only.
3. Inflation: The ensemble anomalies (A=E-x.1') for any model state element will be inflated to avoid collapses. 
    (x_a - x\bar)*inflation + x\bar
    capping of inflation: inflation = 1+inflation*( std_f/std_a-1)
4. Localization radius: it defines the impact area size of observation. Increasing it increases the number of local observations

# knowledges
divergence of the Kalman filter: if the ensemble collapses, the Kalman gain tends to zero and the assimilation system behaves as one – expensive – free run.

# 6-9
Due to structure change in nextsim, the wind perturbation interface needs to be adjusted accordingly. THe main issue is the change of wind input mesh size. 
In the latest version, the procedure is 
  1. read in the raw wind field
  2. truncate or interpolate into a subdomain
  3. split the sbudomain with mutiple processors
  4. create perturbations of the raw wind field domain by the root processor 
  5. save perturbations to file for backup and read in again by the root processor.
  6. broadcast perturbations to all processors by the root processor.
   The error occurs at step 6 while the underlying reason is due to step2. (I guess step2 was after step 6 in the previous version)
ToDO: 1. change step 5 to online data transfer with save/read on at the end/beginning of simulations.
      2. retrieve subdomain charged by each processor by index, to apply the correct perturbation

# 2-9
In externaldata.cpp The size of matrix of wind velocity is M_full*N_full=1803600, but after iterator>273600, either u or v components of the velocity becomes zeros, very large, which implies only the first 273600 values are useful.

# 31-8 
compiled nextsim program crashed in wind perturbation part. Try to location the error in code

*** Error in `/cluster/work/jobs/736388/bin/nextsim.exec': corrupted double-linked list: 0x00000000048ae7b0 ***
*** Error in `/cluster/work/jobs/736388/bin/nextsim.exec': malloc(): memory corruption: 0x000000000224f400 ***
The errors are actived at by code in externaldata.cpp:
boost::mpi::broadcast(M_comm, & M_dataset->variables[ii].loaded_data[jj][0], MN_full, 0);

# 28-8
writing work about experiment plan, literature reivew, etc 


# 27-8
fixed errors in loading compilers. Merged enkf branch with develop branch again.
new errors in submitting jobs. root files are copied to job path. It needs to solve now.

# 24-8
Encountered failed cases are all due to hitting the wall time after a long stuck time. In those cases, output information in nextsim.log file stoped at 96%. The reason is unknown. 
to save computational time, we willonly output prior.nc   
mooring is turned off, and only be turned.on when utput fonal result.
Thus, in nextsim.cfg, output_per_day=0 & use_moorings=false

# 21-8 
task lost on Fram that nohup *.sh is not in the job list, thus it cannot be terminated. While the job is running.
Task Crashs more freuqenctly in the later periods. For example, in the ensemble size test, 3/4 tasks are failed in the fourth period.


# 17-8
The cost of running a neXtSIM instance is reduced to 25 mins due to using binary format IO (60->40) in wind perturbation and using 32 cpus instead of 16 cpus in the debug mode (40 mins-> 25mins).

# 12-8
data in SIDNEPx buoy project is included in IABP. Thus, IABP dataset is used as an observation source to valid the simulation.

# 10-8
To reduce computational time <1 hour, changes are made in nextsim.cfg, such as step=900, dynamics-type=bmeb, dynamic->substeps=120
use_sidfex_drifters=true



# 8-8 
create a script to generate runs for optimizing EnKF parameters using enumeration method


# 17-7
 lost records in 2 weeks
 finished test 1 (assimilate sit), and test2 (assimilate sic and sit)
 save results from test 2 in .docx document.
 increase time step in nextsim.cfg from 200 to 400 and change output_per_day=0

Investigate the possible mutual interuption in sic and sit assimilation
prior/mem***.nc + obs. -> prior/mem***.analysis.nc
# Todo
 - redo test2 using 7 day forecasts instead of 6 day
 

# 3-7
create read_cs2smos.c from read_smos.c
needs to change:  allreaders.c/h, reader_smos.c, add reader_cs2smos.c to Makefile,
     obs.prm(product, reader)

ice concentration >1 seems not an error (maximum of analysis is about 1.2~1.4 in ensemble members). 
nextim/finiteelement.cpp 
- update() has a correction script limits concentration <=1
   M_conc[cpt] = std::min(1.,std::max(M_conc[cpt],0.));
- initIce() has several ice source options, e.g. a command in topazAmsr2Ice() below
  M_conc[i] = std::min(1., M_init_conc[i]);

a comment says "after the advection the concentration can be higher than 1, meaning that ridging should have occured" in finiteelement.cpp

# 2-7
 if a data file is listed in the observation data parameter file, then observations from  this  file  are  assimilated.
add ice concentration to enk-c
-  obstypes.prm
-  obs.prm
- add concentration in reader_smos.c, refer to reader_cars.c
- model.prm

# 30-6
7.5 km resolution. 
what is the scaled cohesion value
("dynamics.C_lab", po::value<double>()->default_value( 6.8465e+6 ), "Pa")   // Cohesion value at the lab scale (10^6 Pa is the order of magnitude determined by Schulson).
# 27-6
- Test 1 is done. Ne20_T4_D7.
- set 4 cores in rum.fram.sh is not done.

# 26-6
- Correct time domain size in prior.nc from 2 to 1. It fixes the bug of all-zeros sit in .nc.analysis 
  Remove duplicate stateVectorAppendNetcdf , which is called inside of updateStateVector() located in exportStateVector()ahead.
  No need to change in enkf-c/common/utils.c, line 861: start[0] = 0; //dimlen[0] - 1;

- change output directories structure: OUTPUTPATH-> time -> members. Thus, all middle results are solved
- write a script to find crashed nextsim instants and resubmit before doing enkf
- TODO
  - matlab to batch process analysis results 
  - remove .dat .bin outputs, check with Tim to see if it is already done.

# 25-6
- several failures of incomplete output of prior.nc. It needs to investigate why variables are not saved to prior.nc when duration >1 with wind pertubation. The issue maybe related to the following warning in nextsim.log
Reading nextsim.cfg...
[INFO] : -----------------------Simulation started on 2020-Jun-25 03:19:28
[INFO] : TIMESTEP= 200
[INFO] : DURATION= 604800
pseudo-random forcing is active for ensemble generation
 Using FFTW for Fourier transform
 Feel the power of the Fastest Fourier Transform in the West!
--------------------------------------------------------------------å------
A process has executed an operation involving a call to the
"fork()" system call to create a child process.  Open MPI is currently
operating in a condition that could result in memory corruption or
other system errors; your job may hang, crash, or produce silent
data corruption.  The use of fork() (or system() or other calls that
create child processes) is strongly discouraged.

The process that invoked fork was:

  Local host:          [[2549,0],0] (PID 159425)

If you are *absolutely sure* that your application will successfully
and correctly survive a call to fork(), you may disable this warning
by setting the mpi_warn_on_fork MCA parameter to 0.
--------------------------------------------------------------------------
[INFO] :  ---------- progression: ( 0%) ---------- time spent: 00:01:25

# 25-6
- Incomplete output of prior.nc. 
  prior.nc doesn't save data when duration =7 day
  It needs to investigate why variables are not saved to prior.nc when duration >1 with wind pertubation. The issue maybe related to the following warning in nextsim.log. (searching the waring online, it may be related memory size, try smaller memory size for each run.
Reading nextsim.cfg...
[INFO] : -----------------------Simulation started on 2020-Jun-25 03:19:28
[INFO] : TIMESTEP= 200
[INFO] : DURATION= 604800
pseudo-random forcing is active for ensemble generation
 Using FFTW for Fourier transform
 Feel the power of the Fastest Fourier Transform in the West!
--------------------------------------------------------------------------
A process has executed an operation involving a call to the
"fork()" system call to create a child process.  Open MPI is currently
operating in a condition that could result in memory corruption or
other system errors; your job may hang, crash, or produce silent
data corruption.  The use of fork() (or system() or other calls that
create child processes) is strongly discouraged.

The process that invoked fork was:

  Local host:          [[2549,0],0] (PID 159425)

If you are *absolutely sure* that your application will successfully
and correctly survive a call to fork(), you may disable this warning
by setting the mpi_warn_on_fork MCA parameter to 0.
--------------------------------------------------------------------------
[INFO] :  ---------- progression: ( 0%) ---------- time spent: 00:01:25

# 22-6
install m_map on fram
put matlab file on fram

cd $FILTER
cdo merge /home/cheng/Desktop/data/reference_grid.nc  /home/cheng/Desktop/nextsim/data/prior/mem001.nc.analysis /home/cheng/Desktop/data/mem001.nc.analysis


# 17-6
  error in interpolate ensemble observation from background field
  set latitudes of observations >N85 in int grid_xy2fij


  interpolate_2d_obs  obsids,  src-> dst
    -> out[ii](=dst) = interpolate2d(o->fi, o->fj, ni, nj, **v(=src)**, mask, periodic_i);

  design a workflow to optimize LOCARD as well as other parameters with matlab.
  need to determine optimization function
  1. optimize one parameter like LOCARD by enumeration method

# 16-6
 locate the calculations of ensemble spread/innovation, increment in code. 
 take note of calc/update flowchart.

# 14-6
error found: prep_utils, line209            enkf_printf("        %d observations above allowed maximum of %.4g\n", nmax, ot->allowed_max);
allowed_max = dbl_max=10. dbl_max indicates the maxmium digits number for double variable. It is mistakenly used as the upper bound of obs. value.
for this case, observed sit>10 are ignored.

# 13-6 
  Tracking the issue: the shape of spread seems ok. about the amplitude is too small O(1.e-7)
  update.c ->das_writespread  ncw_copy_vardef

# 12-6
  get data from step2 wind perturabation run with ensemble size 17 done before
  assimilate the forecasts with one single observation.
  Observed small increment at the location
  change the observation location, try again. Encounter error of failed to find the cell containing the observatio location
  the shape of spread seems ok. about the amplitude is too small O(1.e-7)

# 11-6
  run 20 ensemble members with wind perturbation for one day
  observe spread in spread.nc. But zero increment. Ali suggested to try forecast with longer duration to have larger spread. And it is worthy to use inflation=2 then. 


# 10-6
run()->init()->initStateVector()
     ->exportStateVector()->initStateVector() (deleted, as prior.nc has been created in init())
                          ->updateStateVector->stateVectorAppendNetcdf(),  output_time=init_time (time here is wrong)
                          ->stateVectorAppendNetcdf() (Is it necessary? )

# 9-6
error: zero-values in **.nc.increment from enkf_update 
reason: enkf_update reads 2nd value of time dimension of the forecast data mem001.nc, which contains all zeros. It is resolved by reading from the 1st time slot. Considering no change of enkf-c code, it needs to change the nextsim/model/finiteelement.cpp->exportStateVector->stateVectorAppendNetcdf
  M_statevector.appendNetCDF(M_statevector_file, output_time);
M_statevector_file = prior.nc
output_time = ?


# 8-6
error: zero-values in **.nc.increment from enkf_update

# 7-6
outcome from make enkf is all zero. X5 is not zero.
source code of enkf_in_nextsim  is from nextsim. It is the enkf part of one_step_nextsim_enkf. Merge the two paths.Or copy the compiled executable files from enkf_in_nextsim to one_step_nextsim_enkf/filter
observation.nc from enkf_prep is empty, all obervations are marked as bad value.
track obs->nrange (bade value)  
  prep: main->obs_calcstats->&obs->data[i]->status=STATUS_RANGE  (error found)
  main->obs_add-> "common check": &obs->data[i]->status = STATUS_RANGE;  (original error)
solution: it needs to change the variable type in standard3 according to the cs2smos user manual description
        bug fixed, modify arry claim and index in smos_standard3


copy /gridutils-c/gridutils/*.h to enkf_in_nextsim to compile


# 6-6
realize standards in reader_smos.c are related to the sources of SMOS data. 
Thus, define a new standard - standard3 for the cs2smos data that going to be assimilated
reader_smos_standard3
    -> not recognize variables
      specify variable name based on the dataset
    -> ncw_get_att_int->nc_get_att_int   
      give the right keyword from the .nc file
      
# 5-6 
filename given in obs.prm is corrected.
glob_err in if-statement in glob() is changed to glob_nomatched in utils.c
find error in reading file (obs_add->readobs()->reader()->get_obsfiles->find_files->reader_smos_standard2->ncw_dim_exists->nc_inq_dimid )


fatal: unable to access 'http://github.com/nansencenter/nextsim/': Recv failure: Connection reset by peer
solution:  git config --global url."https://".insteadOf http://

# Errors
## 4-June-2020, all-zero output from EnKF-c
  __data directory is host machine, which is unknown in a docker container running enkf-c__
  changes:
  in main_job_submit.sh
        OBS_DIR = /data/CS2SMOS (for docker)
  in part2_core.sh: 
        docker run --rm -v $FILTER:/docker_io $NEXTSIM_DATA_DIR:/data $docker_image \
            sh -c  "cp /nextsim/modules/enkf/enkf-c/bin/enkf_* . &&  make enkf > enkf.out"
  also check FILE in obs.prm
  Because CS2SMOS data is 2D, while Ali studied SMOS data is 1D, the difference could be the reason of all-zero-output from EnKF-c.
  notice filter/obs is empty. Using make enkf_prep to write observations-orig.nc based on observation data specified in obs.prm.
  enkf-prep doesn't find valid observation from the observation data file.
  Path of the observation data is valid. 
  Enkf-c doesn't have a debug option.

# issues errors
issue1_error_multi-tasks_1node is on situation 2
Suspect the error is due to confliction of accessing common mesh file from multiple core
Small_arctic_10km.msh

> It should access par32small_arctic_10km.msh, but this mesh is copied to out directory, thus no in the working directory, where is the code for this.
> move small_arctic_10km.msh  *.mpp from sim/mesh to my own data directory chengsukun/src/data, and then softlink them to nextsim/data. remote nextsim_mesh_dir in cp -a $NEXTSIMDIR/data/* $NEXTSIM_DATA_DIR/* $SCRATCH/data in slurm.template.sh
>active debugging in nextsim.cfg [debugging]


# Experiment Setup

- Exp.1: Deterministic run
  
- Exp.2: Ensemble run with wind-perturbation
  
- Exp.3: Ensemble run wiht wind-perturbation_run & EnKF assimilated ice thickness

- Postprocess is to present the difference between Exp. 2 and Exp. 3, then discuss based on the comparison

## Exp.1: Deterministic run

- Simulation Duration is set as 7 days from 11-11 to 2018-11-18.   
  - Use restart file on 2018-11-11 from 1-year determinsitic run created by Timothy
  
## Exp.2: Ensemble run with wind-perturbation

- Same as Exp. 1
  
- Plan to run 20 ensemble members.
  
- Run two members at one time with 6 cpu cores for each member. 12 CPU cores in total.
  
- Notice the nextsim occupies more memory as duration increases. For a 7-day simulation, a run occupies almost 17 Gb in the end. Thus, members are run one by one.
  spinup_duration=0
  duration=7    # nextsim duration in a forecast-analysisf cycle, which is usually CS2SMOS frequency
  tduration=1   # number of nextsim-enkf (forecast-analysis) cycle. 
  UPDATE=0      # UPDATE=0 indicates forecast is executed without EnKF
## Exp.3: Ensemble run with wind-perturbation_run & EnKF assimilated ice thickness

- Same as Exp. 2
- Because memory is released after each forecast-analysis cycle, the computer has more avaiable memory to run multiple members in parallel.
- However, short duration of nextsim in each DA cycle leads to insuitable to study buoy trajectories of buoys like in the ensemble prediction study.
- ensemble runs on the next day are initialized using the analysis results that generated based on all the ensemble runs at this time slot. Thus, it cannot change ensemble size when doing Exp.3. It is less flexible compared with Exp. 2.
- Unknow crash occurs several times when running Exp. 3
- Key Parameters Settings
  duration=1
  tduration=7
  UPDATE=1
  ensemble size=20
  cpu core=7, 2 members at one time.
  Exp.3 is expected to cost 14 hours.

## Settings

- Modifications of __nextsim.cfg__ are added in job_submit script. 
- Set ECMWF data size as xdim, ydim in __pseudo2D.nml__
  
## Data sources

- ice-type=topaz
    /data/20181129_dm-metno-MODEL-topaz4-ARC-b20181120-fv02.0
- ocean-type=topaz
- atmosphere-type=ec2
       /data/ECMWF_forecast_arctic/ec2_start20181115
- bathymetry-type=etopo
    /data/ETOPO_Arctic_2arcmin

- Assimilation data: CS2SMOS ice thickness,e.g.,
    W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_20181112_20181118_r_v202_01_l4sit

## Forecast-Analysis Cycle (neXtSIM-EnKF)

- Generally, a Forecast-Analysis Cycle is 
  - Forecast: neXtSIM restart with analysis data (except the very first time)
  - Analysis: assimilate neXtSIM output with CS2SMOS ice thickness
  
- in .sh, tduration*duration is the total simulation time in days

## Other notes
-Reduce writing/reading in wind perturbation.
  Because of many times of writing/reading operations in the simulation, the computational efficiency depends on the hard disk capability. Using m.2 ssd harddive with 2Gb/s read/write capability could save considerable time.  
- The master core occupies most of the computer memory, increasing as duration increasing. Other cores occupy equally amount of memory with small fluctuation arround a constant. 

# git 
## discard location changes and pull from remote repository
  git fetch --all
  git reset --hard origin/master


## Moorings and prior (refer to Todo - 4)
-                  grid size            data size (initial size,  final size, tested duration 2 or 7day)
  Moorings.nc       501x391                  1589306,   7891730      
  prior.nc          522x528                  2224737,  19898089

- same name:output_timestep is in moorings and statevector
- restart data is recognized by basename=final  (field_basename.bin/dat)
 In this study, we will use prior.nc to study variables' spatial distribution, which data resolution is higher. 
mooring is turned off.


-----------------------
cd ~/src/nextsim

make fresh -j32

cp ./model/bin/nextsim.exec /cluster/home/chengsukun/src/IO_nextsim/test_Ne1_T4_D7/I1_L100_R1_K1/date2/mem001/bin

cd /cluster/home/chengsukun/src/IO_nextsim/test_Ne1_T4_D7/I1_L100_R1_K1/date2/mem001/

rm -f *.log

source ${NEXTSIM_ENV_ROOT_DIR}/run.fram.sh ./nextsim.cfg 1 -e ${NEXTSIM_ENV_ROOT_DIR}/nextsim.src

sq





Fatal error in PMPI_Bcast: Other MPI error, error stack:
PMPI_Bcast(2667)................: MPI_Bcast(buf=0x14034700, count=1803600, MPI_DOUBLE, root=0, MPI_COMM_WORLD) failed
MPIR_Bcast_impl(1804)...........: fail failed
MPIR_Bcast(1832)................: fail failed
I_MPIR_Bcast_intra(2056)........: Failure during collective
MPIR_Bcast_intra(1599)..........: fail failed
MPIR_Bcast_binomial(247)........: fail failed
MPIC_Recv(419)..................: fail failed
MPIC_Wait(270)..................: fail failed
PMPIDI_CH3I_Progress(623).......: fail failed
pkt_RTS_handler(317)............: fail failed
do_cts(662).....................: fail failed
MPID_nem_lmt_dcp_start_recv(302): fail failed
dcp_recv(165)...................: Internal MPI error!  Cannot read from remote process
 Two workarounds have been identified for this issue:
 1) Enable ptrace for non-root users with:
    echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
 2) Or, use:
    I_MPI_SHM_LMT=shm