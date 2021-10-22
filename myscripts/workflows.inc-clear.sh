##############################################################
# This is a framework for doing workflows with Profuse tasks #
##############################################################


#
# Make sure we always work from the directory the launched script lives in.
#

HERE="$(dirname $(readlink -f $0))"
cd "$HERE"

if [ "$?" != "0" ]; then
  echo "Failed to change directory to: $HERE"
  echo
  echo Aborting.
  exit 1
fi


#
# Create 'sites.txt' using CMDB data.
#

function create_site_list {
  OUTFILE=sites.list
  # Perform some sanity checks
  if [ -e $OUTFILE ]; then
     echo "Site file '$OUTFILE' already exists. Aborting."
     exit 1
  fi
  profuse-zonemaster-cmdb list-sites| tail -n +2|awk -F, '{print $1 $2}'|tr -d '"' > $OUTFILE

  echo
  echo "Created site list with $(cat $OUTFILE|wc -l) sites: $OUTFILE"
  echo

}


#
# Create unit lists from the file 'sites.txt' using CMDB data.
#

function create_unit_lists {
  INFILE=sites.list

  # Perform some sanity checks
  if [ ! -e $INFILE ]; then
     echo "Site file '$INFILE' not found. Aborting."
     exit 1
  fi
  if [ -e posservers.list -o -e posclients.list -o -e posadmins.list ]; then
    echo "Unit lists already exists. Aborting."
    exit 1
  fi

  # Gather site list
  SITES="$(get_active_lines $INFILE)"
  echo "Read $(echo $SITES|wc -w) sites from '$INFILE'"
  echo

  # Validate site list
  for SITE in $SITES; do
    profuse-zonemaster-cmdb list-site-profiles "$SITE" > /dev/null 2>&1
    if [ "$?" != "0" ]; then
      echo "Site '$SITE' not found. Aborting."
      exit 1
    fi
  done

  # Create lists
  echo "Gathering input list of all units..."
  TMP="$(mktemp)"
  profuse-zonemaster-cmdb show-units|tail -n +3|awk '{print $1}' > $TMP
  for SITE in $SITES; do
    echo Adding units to output list: $SITE
    cat $TMP|grep ^${SITE}s >> posservers.list
    cat $TMP|grep ^${SITE}t >> posclients.list
    cat $TMP|grep ^${SITE}w >> posadmins.list
  done
  rm $TMP

  echo
  echo Created unit lists:
  echo
  LISTS="posservers.list posclients.list posadmins.list"
  for L in $LISTS; do
    wc -l $L | awk '{printf "%-20s  %s units\n", $2 ":", $1}'
  done
  echo
  TOTAL="$(wc -l $LISTS | tail -1 | awk '{print $1}')"
  echo "Total units: $TOTAL"
}


#
# Select units for drop1 and drop2 redeploy roles
#
function create_units_lists_for_redeploy_drops {
  INFILE=sites.list

  # Perform some sanity checks
  if [ ! -e $INFILE ]; then
     echo "Site file '$INFILE' not found. Aborting."
     exit 1
  fi

  if [ -e posservers.list -o -e posclients.list -o -e posadmins.list ]; then
    echo "Unit lists already exists. Aborting."
    exit 1
  fi

  if [ -e drop1.list -o -e drop2.list ]; then
    echo "Drop lists already exists. Aborting."
    exit 1
  fi

  # Gather site list
  SITES="$(get_active_lines $INFILE)"
  echo "Read $(echo $SITES|wc -w) sites from '$INFILE'"
  echo

  # Validate site list
  for SITE in $SITES; do
    profuse-zonemaster-cmdb list-site-profiles "$SITE" > /dev/null 2>&1
    if [ "$?" != "0" ]; then
      echo "Site '$SITE' not found. Aborting."
      exit 1
    fi
  done

  TMP="$(mktemp)"
  TMP2="$(mktemp)"

  profuse-zonemaster-cmdb show-units|tail -n +3|awk '{print $1}' | sort > $TMP

  # Create empty list files
  touch posservers.list
  touch posadmins.list
  touch posclients.list
  touch drop1.list
  touch drop2.list

  for SITE in $SITES; do
    cat $TMP|grep ^${SITE}s >> posservers.list

    # Try first posadmin as drop 1
    DROP1=$(grep ^${SITE}w $TMP | head -1)
    if [ ! -z $DROP1 ]; then
      echo $DROP1 >> drop1.list
      echo $DROP1 >> posadmins.list
    else
      # No posadmin found, try assigning drop 1 from tills
      DROP1=$(grep ^${SITE}t $TMP | head -1)
      if [ ! -z $DROP1 ]; then
        echo $DROP1 >> drop1.list
        echo $DROP1 >> posclients.list
      else
        BAD=$(echo "$SITE has no unit suitable for drop1, aborting")
        break
      fi
    fi

    comm -23 $TMP drop1.list > $TMP2
    #Try assigning drop 2 from tills
    DROP2=$(grep ^${SITE}t $TMP2 | head -1)
    if [ ! -z $DROP2 ]; then
    echo $DROP2 >> drop2.list
    echo $DROP2 >> posclients.list
    else
    if [ "$FORCE" == "1" ]; then
      continue
    fi
    BAD=$(echo "$SITE has no unit suitable for drop2, aborting. Re-run with FORCE=1 to override.")
    break
    fi

  done

  rm $TMP2
  rm $TMP

  if [ -z "$BAD" ]; then
    echo "Drop lists ok"
    return
  else
    echo $BAD
    rm drop1.list
    rm drop2.list
    rm posservers.list
    rm posclients.list
    rm posadmins.list
    exit 1
  fi
}


#
# set drop tag
#
function set_drop_name_tag {
  # Determine drop number
  TARGET_TYPE="$(get_target_type_from_cwd)"

  # Determine listfile
  determine_listfile $TARGET_TYPE

  # Get drops
  DROPS=$(get_active_lines "$LISTFILE")

  # Create output directory and output ok list (error list only created when there is an error)
  mkdir out-log
  touch out-${TARGET_TYPE}-ok.list

  # set the tag
  for DROP in $DROPS; do
    profuse tag unit set $DROP profuse.drop.name "site-$TARGET_TYPE" > out-log/$DROP.txt 2>&1
    if [ $? == 0 ]; then
      echo $DROP >> out-${TARGET_TYPE}-ok.list
    else
      echo $DROP >> out-${TARGET_TYPE}-error.list
    fi
  done

  # Show results
  RESFILE="out-${TARGET_TYPE}-ok.list"
  if [ -s $RESFILE ]; then
    echo "OK:    $(cat $RESFILE|wc -l)"
  fi
  RESFILE="out-${TARGET_TYPE}-error.list"
  if [ -s $RESFILE ]; then
    echo "ERROR: $(cat $RESFILE|wc -l)"
    # If there was an error, we terminate here - even if some were ok above
    exit 1
  fi
}


#
# delete drop tag
#
function delete_drop_name_tag {
  # Determine drop number
  TARGET_TYPE="$(get_target_type_from_cwd)"

  # Determine listfile
  determine_listfile $TARGET_TYPE

  # Get drops
  DROPS=$(get_active_lines "$LISTFILE")

  # Create output directory and output ok list (error list only created when there is an error)
  mkdir out-log
  touch out-${TARGET_TYPE}-ok.list

  # set the tag
  for DROP in $DROPS; do
    profuse tag unit delete $DROP profuse.drop.name > out-log/$DROP.txt 2>&1
    if [ $? == 0 ]; then
      echo $DROP >> out-${TARGET_TYPE}-ok.list
    else
      echo $DROP >> out-${TARGET_TYPE}-error.list
    fi
  done

  # Show results
  RESFILE="out-${TARGET_TYPE}-ok.list"
  if [ -s $RESFILE ]; then
    echo "OK:    $(cat $RESFILE|wc -l)"
  fi
  RESFILE="out-${TARGET_TYPE}-error.list"
  if [ -s $RESFILE ]; then
    echo "ERROR: $(cat $RESFILE|wc -l)"
    # If there was an error, we terminate here - even if some were ok above
    exit 1
  fi
}


#
# Refresh DNS zones in slaves
#
function refresh_site_dns_zones {
  TARGET_TYPE="$(get_target_type_from_cwd)"

  # Determine listfile
  determine_listfile $TARGET_TYPE

  # Get sites
  SITES=$(get_active_lines "$LISTFILE")

  mkdir out-log

  for ZONE in $SITES; do
    # Reload master zone config and refresh zone slaves
    profuse task run initiate-zone-transfer-zoneslaves $ZONE site 2>&1 >> out-log/$ZONE.txt
    if [ "$?" != "0" ]; then
      echo "refresh zone slaves failed. Aborting."
      echo $ZONE >> out-${TARGET_TYPE}-error.list
      continue
    fi
    echo $ZONE >> out-${TARGET_TYPE}-ok.list
  done

  # Show results
  RESFILE="out-${TARGET_TYPE}-ok.list"
  if [ -s $RESFILE ]; then
    echo "OK:    $(cat $RESFILE|wc -l)"
  fi
  RESFILE="out-${TARGET_TYPE}-error.list"
  if [ -s $RESFILE ]; then
    echo "ERROR: $(cat $RESFILE|wc -l)"
    # If there was an error, we terminate here - even if some were ok above
    exit 1
  fi
}


#
# Setup parallel with correct arguments to disable banner
#

function setup_parallel {
  local HAS_NO_NOTICE
  local HAS_WILL_CITE

  # Make sure we have GNU Parallell installed
  parallel --version > /dev/null
  if [ "$?" != "0" ]; then
    echo "You need GNU Parallell installed. Aborting."
    exit 99
  fi

  # Check if we need --no-notice or --will-cite argument to parallel (annoying...)
  HAS_NO_NOTICE="$(echo |parallel --no-notice 2>&1|grep "Unknown option: no-notice"|wc -l)"
  HAS_WILL_CITE="$(echo |parallel --will-cite 2>&1|grep "Unknown option: will-cite"|wc -l)"
  if [ "$HAS_NO_NOTICE" = "0" ]; then
    PARALLEL='parallel --no-notice'
  elif [ "$HAS_WILL_CITE" = "0" ]; then
    PARALLEL='parallel --will-cite'
  else
    PARALLEL='parallel'
  fi
}


#
# Run a function on a unit list, first argument must be full path to script or method name
#

function run_function {
  # Unless this is a controlled re-run we make sure no output files are present.
  if [ "$RERUN" != "1" ]; then
    if [ "$(ls -1|grep ^out-|wc -l)" -gt 0 ]; then
      echo "Output already exists - aborting. Maybe you want to do './do.sh save'?"
      exit 99
    fi
  fi

  # Start logging to the tasklog (TL)
  TL=$HERE/out-tasklog.txt
  (
    echo -e '\n====================  TASK STARTED  ====================\n'
    date
    echo
  ) >> $TL

  # Determine taskname
  TASKNAME=$1
  shift

  (do_run_task "$@") 2>&1 | tee -a $TL
  (
    echo
    date
    echo -e '\n==================== TASK COMPLETED ====================\n'
    echo
  ) >> $TL
}


#
# Run a task on a unit list, taken from profuse task dir.
#

function run_task {
  # Unless this is a controlled re-run we make sure no output files are present.
  if [ "$RERUN" != "1" ]; then
    if [ "$(ls -1|grep ^out-|wc -l)" -gt 0 ]; then
      echo "Output already exists - aborting. Maybe you want to do './do.sh save'?"
      exit 99
    fi
  fi

  # Start logging to the tasklog (TL)
  TL=$HERE/out-tasklog.txt
  (
    echo -e '\n====================  TASK STARTED  ====================\n'
    date
    echo
  ) >> $TL

  # Determine taskname and path
  TASKDIR=/opt/fujitsu/profuse/zonemaster/tasks
  TASKNAME=$TASKDIR/$1
  shift

  (do_run_task "$@") 2>&1 | tee -a $TL
  (
    echo
    date
    echo -e '\n==================== TASK COMPLETED ====================\n'
    echo
  ) >> $TL
}

#
# Actually do run the task set in $TASKNAME
#

function do_run_task {
  setup_parallel

  # Determine if we should run tasks staggered or not (outer loop, parallel sites)
  if [ "$STAGGER_OUTER_DELAY" != "" ]; then
    PARALLEL_EXTRA_OUTER_ARGS="$PARALLEL_EXTRA_OUTER_ARGS --delay $STAGGER_OUTER_DELAY"
  fi

  # Determine if we should run tasks staggered or not (inner loop, parallel units)
  if [ "$STAGGER_DELAY" != "" ]; then
    PARALLEL_EXTRA_ARGS="$PARALLEL_EXTRA_ARGS --delay $STAGGER_DELAY"
  fi

  # Determine bubble size for number of parallel sites (outer loop)
  # and for number of parallel units per site (inner loop)
  # Max number of forked processes will be NUM_PARALLEL * NUM_PARALLEL_PER_SITE
  NUM_PARALLEL=${BUBBLE_SIZE:-25}
  NUM_PARALLEL_PER_SITE=${BUBBLE_SIZE_PER_SITE:-30}

  # Determine target type from current directory name
  TARGET_TYPE="$(get_target_type_from_cwd)"

  # Determine listfile
  determine_listfile $TARGET_TYPE

  # Show what will be done
  NUM_TARGETS="$(get_active_lines "$LISTFILE"|wc -l)"
  echo -n "Running: [$NUM_TARGETS $TARGET_TYPE] '${TASKNAME##*/}' using NUM_PARALLEL=$NUM_PARALLEL, NUM_PARALLEL_PER_SITE=$NUM_PARALLEL_PER_SITE..."

  # Create output directory and output ok list (error list only created when there is an error)
  mkdir out-log
  touch out-${TARGET_TYPE}-ok.list

  # Create directory (and make sure it is empty) in which we store a file (=queue) per site.
  # Each file normally contains the site's units of a certain type.
  mkdir -p out-queue
  rm -f out-queue/*

  # Populate queue directory, we assume that the first six characters always is a site name
  get_active_lines "$LISTFILE" | $PARALLEL --joblog out-joblog-queue-create.txt 'unit={}; file=out-queue/${unit:0:6}; echo $unit >> $file'

  # Launch tasks with NUM_PARALLEL as max parallel sites and NUM_PARALLEL_PER_SITE is max parallel per site
  ls out-queue | $PARALLEL $PARALLEL_EXTRA_OUTER_ARGS -j $NUM_PARALLEL --joblog out-joblog-queue-exec.txt -I @@ \
                  "cat out-queue/@@ | $PARALLEL $PARALLEL_EXTRA_ARGS -j $NUM_PARALLEL_PER_SITE --joblog out-joblog-@@.txt \
                  'if $TASKNAME {} $* >> out-log/{}.txt 2>&1; then echo {} >> out-${TARGET_TYPE}-ok.list; true; else echo {} >> out-${TARGET_TYPE}-error.list; false; fi'"
  echo
  echo

  # Show results
  RESFILE="out-${TARGET_TYPE}-ok.list"
  if [ -s $RESFILE ]; then
    echo "OK:    $(cat $RESFILE|wc -l)"
  fi
  RESFILE="out-${TARGET_TYPE}-error.list"
  if [ -s $RESFILE ]; then
    echo "ERROR: $(cat $RESFILE|wc -l)"
    # If there was an error, we terminate here - even if some were ok above
    exit 1
  fi
}


#
# Run steps until there is a failure
#

function run_steps {
  # Must be in a screen/tmux session
  check_screen

  # Determine run mode
  RUN_MODE="$1"
  STOP_AT=""
  if [ "$RUN_MODE" = "" ]; then
    RUN_MODE="normal"
  elif [ "$RUN_MODE" = "normal" -o "$RUN_MODE" = "ignore-errors" -o "$RUN_MODE" = "confirm" ]; then
    : # Valid run mode found. Check for additional parameters.
    if [ "$2" != "" ]; then
      EXTRA_PARAM="$2"
      if [ "$EXTRA_PARAM" = "stop-at" ]; then
        STOP_AT="$3"
        if [ "$STOP_AT" = "" ]; then
          echo "Missing stop-at step specification. Aborting."
          exit 1
        fi
        if [[ ! "$STOP_AT" =~ ^[0-9][0-9]$ ]]; then
          echo "Invalid step specification: '$STOP_AT' (expected two digit number). Aborting."
          exit 1
        fi
        NUM_MATCHING_STEPS=$(ls|grep ^${STOP_AT}-|wc -l)
        if [ "$NUM_MATCHING_STEPS" = "0" ]; then
          echo "Invalid step specification: '$STOP_AT' - no such step found, aborting"
          exit 1
        fi
      else
        echo "Invalid extra parameter '$EXTRA_PARAM'. Aborting."
        exit 1
     fi
    fi
  else
    # Either -h was issued, or the arguments are invalid. Show usage then
    # return a suitable error code.
    echo
    echo "Available commands:"
    echo
    echo "  $0 normal [stop-at XX]         # Halt on errors (default)"
    echo "  $0 ignore-errors [stop-at XX]  # Ignores errors and continue"
    echo "  $0 confirm [stop-at XX]        # Stop for confirmation on each step"
    echo
    echo "Optional 'stop-at' argument ensures execution never proceeds past step XX."
    echo
    if [ "$RUN_MODE" != "-h" ]; then
      echo "Unknown run mode mode specified: '$RUN_MODE' - aborting."
      echo
      exit 1
    fi
    exit 0
  fi
  echo
  echo "Running steps using mode: $RUN_MODE"
  echo

  # Start the run logging to the runlog (RL)
  RL=$HERE/out-runlog.txt
  (
    echo -e '\n====================  RUN STARTED  ====================\n'
    date
    echo
  ) >> $RL
  (time do_run_steps $RUN_MODE) 2>&1 | tee -a $RL
  (
    echo
    date
    echo -e '\n==================== RUN COMPLETED ====================\n'
    echo
  ) >> $RL
}

function list_steps {
  find . -maxdepth 1 -regextype posix-extended -type d -regex '^\.\/[0-9]{2,}\-.+' | sed -e 's/.\///' | sort
}

function do_run_steps {
  # Get current run mode
  RUN_MODE="$1"

  # Find first step with no result in (looking from the last to first)
  # and designate it as the 'next' step.
  NEXT_STEP=""
  for STEP in $(list_steps|tac); do
    get_step_results $STEP
    if [ "$OK" != "0" -o "$ERROR" != "0" ]; then
      # Found some kind of result, done looking
      break
    fi
    # No result, this might be the next step.
    NEXT_STEP="$STEP"
  done

  # Check if we are at the beginning, done, or continuing
  AT_BEGINNING=0
  if [ "$NEXT_STEP" = "$STEP" ]; then
    AT_BEGINNING=1
    echo "Starting from the beginning: $STEP"
    CURRENT_STEP="$STEP"
  elif [ "$NEXT_STEP" = "" ]; then
    echo "No more steps to run. Done."
    return
  else
    echo
    echo "Info about last step that was run:"
    echo
    echo "  STEP:  $STEP"
    if [ "$OK" = "1" ]; then
      echo "  OK:    $NUM_OK"
    fi
    if [ "$ERROR" = "1" ]; then
      echo "  ERROR: $NUM_ERROR"
    fi
    echo
    if [ "$STOP_AT" != "" ]; then
      if [ "${NEXT_STEP:0:2}" -ge "$STOP_AT" ]; then
        echo "Instructed to not go past step $STOP_AT - stopping."
        exit 1
      fi
    fi
    echo "Choose one of the following options:"
    echo
    echo "1. Re-run failed items from the last step run: $STEP"
    echo "2. Resume from the next step: $NEXT_STEP"
    echo
    echo -n "Enter 1 or 2 to continue (anything else aborts): "
    read x
    echo
    if [ "$x" = "1" ]; then
      CURRENT_STEP="$STEP"
      DO_RERUN_FAILED=1
    elif [ "$x" = "2" ]; then
      CURRENT_STEP="$NEXT_STEP"
    else
      echo Aborted.
      exit 1
    fi
  fi

  # Continue
  if [ "$AT_BEGINNING" != "1" ]; then
    echo
    echo Continuing from step: $CURRENT_STEP
    echo
  fi
  SKIPPING=1
  for STEP in $(list_steps); do
    if [ "$STEP" = "$CURRENT_STEP" ]; then
      SKIPPING=0
    fi
    if [ "$SKIPPING" = "1" ]; then
      continue
    fi

    DO="$STEP/do.sh"

    if [ ! -x $DO ]; then
      echo "No executable $DO found. Aborting."
      exit 1
    fi

    if [ "$DO_RERUN_FAILED" = "1" ]; then
      DO="$STEP/do.sh rerun-failed"
      DO_RERUN_FAILED=0
    fi

    # Check if we should stop here
    if [ "$STOP_AT" != "" ]; then
      if [ "${STEP:0:2}" -ge "$STOP_AT" ]; then
        echo "Instructed to not go past step $STOP_AT - stopping."
        exit 1
      fi
    fi

    # Ask confirmation if in confirm mode
    if [ "$RUN_MODE" = "confirm" ]; then
      echo
      echo "*** ABOUT TO RUN STEP: $STEP ***"
      echo
      echo -n "Hit ENTER to confirm you wish to proceed, or ctrl-C to abort."
      read x
    fi

    # Run the step
    echo
    echo "*** RUNNING STEP: $STEP ***"
    echo
    $DO
    RES="$?"
    get_step_results $STEP
    if [ "$RES" != "0" -o "$OK" != "1" -o "$ERROR" != "0" ]; then
      echo
      echo "Errors during step: $STEP"
      echo
      if [ "$RUN_MODE" != "ignore-errors" ]; then
        echo "Aborting."
        echo
        exit 1
      fi
      if [ "$RES" = "99" ]; then
        echo "Workflow error - aborting even if 'ignore-errors' was specified."
        echo
        exit 1
      else
        echo "Errors found, but continuing anyway due to 'ignore-errors' being specified."
        echo
      fi
    fi
  done
}


#
# Show current status of all step directories
#

function show_status {
  local OPTION="$1"
  local STEP
  local prev_step_time
  local step_time

  # Hidden command to create devtool in current workflow
  if [ "$OPTION" = "make-devtool" ]; then
    BASE=/opt/fujitsu/profuse/zonemaster/misc/workflows/empty-template
    if [ -e "${BASE}/devtool.sh" ]; then
      cp -a ${BASE}/devtool.sh .
    else
      tar xf ${BASE}.tar.gz devtool.sh
      if [ "$?" != "0" ]; then
        echo "Failed to extract devtool.sh - internal error."
        exit 1
      fi
    fi
    echo "Created ./devtool.sh."
    exit 0
  fi

  # Show status
  prev_step_time=0
  printf '%-60s  %8s  %-10s\n' Step Duration Status
  printf '%-60s  %8s  %-10s\n' ------------------------------------------------------------  --------  ------
  for STEP in $(list_steps); do
    get_step_results $STEP
    if [ "$OK" = "0" -a "$ERROR" = "0" ]; then
       RES="-"
    elif [ "$OK" = "1" -a "$ERROR" = "0" ]; then
       RES="OK [$NUM_OK]"
    elif [ "$OK" = "0" -a "$ERROR" = "1" ]; then
       RES="ERROR [$NUM_ERROR]"
    else
       RES="OK [$NUM_OK]  ERROR [$NUM_ERROR]"
    fi

    # Determine which file to use to determine when step was finished
    shopt -s nullglob
    step_time=0
    for f in $(ls -1t $STEP/out-tasklog.txt $STEP/out-*.list 2>/dev/null) nonexistant-entry-ensuring-bash-syntax; do
       if [ -f "$f" ]; then
         # Found file, grab date
         step_time="$(stat $f '--format=%Y')"
         break
       fi
    done
    shopt -u nullglob

    # Determine duration, if possible
    if [ "$step_time" != "0" -a "$prev_step_time" != "0" -a "$prev_step_time" -le "$step_time" ]; then
        DURATION="$(date +%H:%M:%S -ud @$(expr $step_time - $prev_step_time))"
    else
        DURATION="  N/A   "
    fi

    # Stash away time for next loop
    prev_step_time=$step_time

    # Print results
    printf '%-60s  %8s  %-10s\n' $STEP "$DURATION" "$RES"
  done
  
  echo -e "\nNumbers of failed tills is:\n$error_list"
  
   
  printf '%-60s  %8s  %-10s\n' ------------------------------------------------------------  --------  ------
}


#
# Delete all output files
#

function delete_results {
  setup_parallel

  echo "== START of file and directory list =="
  find . -name 'out-*.list' -type f -exec echo '{}' \;
  # To find e.g. posclients.list generated by "do.sh rerun-failed"
  find . -name do.sh -exec dirname {} \; | $PARALLEL -I _DO_DIRS_ -m "find _DO_DIRS_ ! -name 'out*.list' -name '*.list' -type f"
  find . -name 'out-joblog*.txt' -type f -exec echo '{}' \;
  find . -name 'out-log' -type d -exec echo '{}/' \;
  find . -name 'out-queue' -type d -exec echo '{}/' \;
  find . -name 'out-runlog.txt' -type f -exec echo '{}' \;
  find . -name 'out-tasklog.txt' -type f -exec echo '{}' \;
  find . -name 'run-?' -type d -exec echo '{}' \;
  find . -name 'run-??' -type d -exec echo '{}' \;
  find . -name 'run-???' -type d -exec echo '{}' \;
  echo "== END of file and directory list =="

  echo
  echo "This will delete all the above output files (out-*) in all sub-directories."
  echo "It will also delete non symlinked *.list files (if listed above) in the"
  echo "steps directories assuming they are leftovers from rerun-failed runs."
  echo
  echo "Are you REALLY sure you want to delete all of the above"
  echo "files and directories? If so please say IAMSURE."
  echo
  echo -n "What do you say? "

  read x
  echo
  if [ "$x" = "IAMSURE" ]; then
    find $HERE -name 'out-*.list' -type f -exec rm -f '{}' \;
    find $HERE -name do.sh -exec dirname '{}' \; | $PARALLEL -I _DO_DIRS_ -m "find _DO_DIRS_ ! -name 'out*.list' -name '*.list' -type f -exec rm -f '{}' \;"
    find $HERE -name 'out-joblog*.txt' -type f -exec rm -f '{}' \;
    find $HERE -name 'out-log' -type d -exec rm -rf '{}' \; 2>/dev/null
    find $HERE -name 'out-queue' -type d -exec rm -rf '{}' \; 2>/dev/null
    find $HERE -name 'out-runlog.txt' -type f -exec rm -rf '{}' \; 2>/dev/null
    find $HERE -name 'out-tasklog.txt' -type f -exec rm -rf '{}' \; 2>/dev/null
    find $HERE -name 'run-?' -type d -exec rm -rf '{}' \; 2>/dev/null
    find $HERE -name 'run-??' -type d -exec rm -rf '{}' \; 2>/dev/null
    find $HERE -name 'run-???' -type d -exec rm -rf '{}' \; 2>/dev/null
    echo Ok. Deleted.
  else
    echo Aborted.
  fi
}


#
# Exposed API functions for adding/deleting profiles for sites in validating/do modes
#

function validate_delete_profiles {
  process_profiles delete 'validate'
}

function do_delete_profiles {
  process_profiles delete 'do'
}

function validate_add_profiles {
  process_profiles add 'validate'
}

function do_add_profiles {
  process_profiles add 'do'
}

#
# Process the profiles
#

function process_profiles {
  local OP="$1"
  local MODE="$2"
  local PROFILE_LIST=profiles_to_${OP}.list

  # Locate the listfile
  determine_listfile sites

  # Validate the profile names before continuing
  validate_profiles $PROFILE_LIST

  # Validate or modify the site profiles
  if [ "$MODE" = "validate" ]; then
    validate_site_profiles $OP $LISTFILE $PROFILE_LIST
  elif [ "$MODE" = "do" ]; then
    modify_site_profiles $OP $LISTFILE $PROFILE_LIST
  else
    echo "Internal error."
    exit 1
  fi
}


#
# Update files from cmdb
#

function cmdb_update_files {
  if [ ! -d out-log ]; then
    mkdir out-log
  fi
  echo "Running CMDB diff-files..."
  profuse-zonemaster-cmdb diff-files > out-log/diff-files.txt 2>&1
  if [ "$?" != "0" ]; then
    echo "diff-files failed. Aborting."
    exit 1
  fi
  echo "Running CMDB update-files..."
  profuse-zonemaster-cmdb update-files > out-log/update-files.txt 2>&1
  if [ "$?" != "0" ]; then
    echo "diff-files failed. Aborting."
    exit 1
  fi
}


#
# Refresh DC
#
function refresh_dc {
  mkdir -p out-log
  profuse refresh-dc > out-log/refresh-dc.txt 2>&1
  if [ "$?" != "0" ]; then
    echo "refresh DC failed. Aborting."
    exit 1
  fi
}


#
# Workflow pause step
#

function pause_workflow {
  echo
  echo -n "--- Pausing workflow, press ENTER to continue --- "
  read x
  echo
}


#
# Workflow devtool
#

function workflow_devtool {
  CMD="$1"
  if [ "$CMD" = "insert-step" ]; then

    # Validate step number
    INSERTSTEP="$2"
    validate_step_numbers
    validate_step $INSERTSTEP present

    # Remove leading 0 so we can do math
    INSERTSTEP="$(echo $INSERTSTEP|sed -e 's/^0*//')"

    # Go through steps from end and backwards, renumbering and stopping at the specified
    # step number.
    STEPS="$(list_steps|tac)"
    WORKDONE=0
    for STEP in $STEPS; do
      NUM="$(echo $STEP|awk -F- '{print $1}'|sed -e 's/^0*//')"
      NEXTNUM="$(expr $NUM + 1)"
      NAME="$(echo $STEP|sed -e 's/^...//')"
      NEWSTEPNAME="$(printf %02d-%s "$NEXTNUM" "$NAME")"
      if [ "$NUM" -lt "$INSERTSTEP" ]; then
        break
      fi
      WORKDONE=1
      echo "Renaming '$STEP' => '$NEWSTEPNAME'"
      mv "$STEP" "$NEWSTEPNAME"
    done
    if [ "$WORKDONE" = "1" ]; then
      echo
      echo "Space has been made available at step number $INSERTSTEP."
    else
      echo "No steps after $INSERTSTEP, nothing to do."
    fi
    exit 0

  elif [ "$CMD" = "remove-step" ]; then
    # Sanity checks
    REMOVESTEP="$2"
    validate_step_numbers
    validate_step $REMOVESTEP absent

    # Remove leading 0 so we can do math
    REMOVESTEP="$(echo $REMOVESTEP|sed -e 's/^0*//')"

    # Go through steps from the specified number + 1 and to the end while renumbering steps.
    STEPS="$(list_steps)"
    WORKDONE=0
    for STEP in $STEPS; do
      NUM="$(echo $STEP|awk -F- '{print $1}'|sed -e 's/^0*//')"
      NAME="$(echo $STEP|sed -e 's/^...//')"
      PREVNUM="$(expr $NUM - 1)"
      NEWSTEPNAME="$(printf %02d-%s "$PREVNUM" "$NAME")"
      if [ "$NUM" -gt "$REMOVESTEP" ]; then
        WORKDONE=1
        echo "Renaming '$STEP' => '$NEWSTEPNAME'"
        mv "$STEP" "$NEWSTEPNAME"
      fi
    done
    if [ "$WORKDONE" = "0" ]; then
      echo "No steps above $REMOVESTEP. Nothing done."
    else
      echo
      echo "Space at step $REMOVESTEP has been removed."
    fi
    exit 0
  else
    echo
    echo "Available commands: "
    echo
    echo "  $0 insert-step XX   # Insert a new step XX (renumbers steps)"
    echo "  $0 remove-step XX   # Remove step XX (renumbers steps)"
    echo
    if [ "$CMD" = "" -o "$CMD" = "-h" ]; then
      exit 0
    else
      echo "Invalid devtool command: $CMD"
      exit 1
    fi
  fi
}


#
# Some handy helpers
#

function get_target_type_from_cwd {
  pwd | sed -re 's/^.*-([a-z0-9]+)$/\1/'
}

function get_active_lines {
  cat "$1" | grep -v '^$' | grep -v '^#'
}


function get_step_results {
  local STEP=$1
  OK=0
  ERROR=0
  if [ "$(cd $STEP; ls|grep '^out-.*-ok.list$'|wc -l)" -gt 0 ]; then
    OK=1
    NUM_OK="$(get_active_lines $STEP/out-*-ok.list | wc -l)"
  fi
  if [ "$(cd $STEP; ls|grep '^out-.*-error.list$'|wc -l)" -gt 0 ]; then
	 
      ERROR=1
    NUM_ERROR="$(get_active_lines $STEP/out-*-error.list | wc -l)"
	error_list="$(for failed in $(sort $STEP/out-*-error.list);do echo $failed; done)"
  fi
}


function determine_listfile {
  local TARGET_TYPE="$1"
  local LISTFILE_PATH="$2"

  # If we have a listfile of the correct type in the current dir, use that
  local l="./${TARGET_TYPE}.list"
  if [ -e "$l" ]; then
    echo "Using '$TARGET_TYPE' list from CURRENT directory."
    LISTFILE="$l"
    return
  fi

  # Locate the closest previous step with the supplied target type
  local FOUND=0
  local SKIPPING=1
  local THIS_STEP="$(basename $HERE)"
  local STEP=''

  for STEP in $(cd ..; list_steps|tac); do
    # Looking backwards, skip until we find the current step
    if [ "$SKIPPING" = "1" ]; then
      if [ "$STEP" = "$THIS_STEP" ]; then
        # Found this step, now we start looking
        SKIPPING=0
      fi
      continue
    fi
    local STEP_TYPE="$(echo "$STEP"|sed -re 's/^.*-([a-z]+)$/\1/')"
    if [ "$STEP_TYPE" = "$TARGET_TYPE" ]; then
      FOUND=1
      break
    fi
  done

  # If a previous matching step was found we use the output list
  if [ "$FOUND" = "1" ]; then
    echo "Using '$TARGET_TYPE' output list from step: $STEP."
    LISTFILE="$HERE/../$STEP/out-${TARGET_TYPE}-ok.list"
  else
    # Not found, use the list in the parent directory
    echo "Using '$TARGET_TYPE' list from PARENT directory."
    LISTFILE="../${TARGET_TYPE}.list"
  fi

  # Make sure list file is readable
  cat "$LISTFILE" > /dev/null 2>/dev/null
  if [ "$?" != "0" ]; then
    echo "Unable to read list '$LISTFILE'. Aborting."
    exit 99
  fi
}


function validate_profiles {
  local PROFILE_LIST="$1"
  local OLD_IFS
  local PROFILE
  local ROW

  if [ ! -e "$PROFILE_LIST" ]; then
    echo "Failed to read profiles from: $PROFILE_LIST - aborting."
    exit 99
  fi

  echo "Validating profile names..."
  for ROW in $(get_active_lines $PROFILE_LIST); do
    OLD_IFS=$IFS
    IFS='|'
    for PROFILE in $(printf "$ROW"); do
      profuse-zonemaster-cmdb show-profile-tags "$PROFILE" >/dev/null

      if [ "$?" != "0" ]; then
        echo "Failed to validate profile in $PROFILE_LIST:"
        echo
        echo "    $PROFILE"
        echo
        exit 1
      fi

    done
    IFS=$OLD_IFS
  done
}


function validate_site_profiles {
  local OP="$1"   # Which operation we want to do (add/delete)
  local SITE_LIST="$2"
  local PROFILE_LIST="$3"
  local ALLOK
  local FOUND
  local FOUND_PIPE
  local PROFILE
  local RES
  local SITE
  local SITE_PROFILES

  echo "Validating site profiles before operation '$OP'..."
  FOUND_PIPE="$(get_active_lines $PROFILE_LIST | tr ' ' '\n' | grep "|" | wc -l)"

  if [ "$OP" = "add" -a "$FOUND_PIPE" != "0" ]; then
    # We can't handle multiple choices (separated by |) when adding profiles
    echo "Error - Site list $PROFILE_LIST not allowed to contain '|' when adding profiles"
    exit 1
  fi

  for SITE in $(get_active_lines $SITE_LIST); do
    SITE_PROFILES="$(profuse-zonemaster-cmdb list-site-profiles $SITE)"
    RES=$?

    echo "Validating site profiles for site $SITE..."

    if [ "$RES" != "0" ]; then
      echo "Site $SITE not listed in CMDB"
      ALLOK="0"
    else
      ALLOK="1"
      for PROFILE in $(get_active_lines $PROFILE_LIST); do
        FOUND="$(echo "$SITE_PROFILES" | tr ' ' '\n' | egrep "^($PROFILE)\$" | wc -l)"
        if [ "$OP" = "delete" -a "$FOUND" = "0" ]; then
          ALLOK=0
          if echo "$PROFILE" | grep -q '|'; then
            echo "Site $SITE missing any of the profiles $PROFILE."
            break
          else
            echo "Site $SITE missing profile $PROFILE."
            break
          fi
        elif [ "$OP" = "add" -a "$FOUND" = "1" ]; then
          ALLOK=0
          echo "Site $SITE should not have profile $PROFILE, but it does."
          break
        fi
      done
    fi

    if [ "$ALLOK" = "1" ]; then
      add_unique_row $SITE out-sites-ok.list
    else
      add_unique_row $SITE out-sites-error.list
    fi

  done
}


function modify_site_profiles {
  local OP="$1"
  local SITE_LIST="$2"
  local PROFILE_LIST="$3"
  local FOUND
  local FOUND_PIPE
  local OLD_IFS
  local PROFILE
  local RES
  local ROW
  local SITE
  local SITE_PROFILES

  if [ ! -d out-log ]; then
    mkdir out-log
  fi

  if [ ! -f out-log/profile-changes-pid.txt ]; then
    printf $$ > out-log/profile-changes-pid.txt
  fi

  if [ -f "out-profile-changes.list" -a \
       \( -f "out-sites-ok.list" -o -f "out-sites-error.list" \) -a \
       "$$" != "$(cat out-log/profile-changes-pid.txt)" ]; then
    # It seems that we're trying to do a fresh run but the out-profile-changes.list
    # already exists which means that we might end up with duplicates in the log.
    # The rollback function will fail to work properly in that case.
    # One may end up here if one tries to do a fresh run but not all log files are
    # correctly removed. In that case use delete_results.sh to clean up.
    echo "Error - out-profile-changes.list already exists but no sites-*.list are found"
    exit 1
  fi

  FOUND_PIPE="$(get_active_lines $PROFILE_LIST | tr ' ' '\n' | grep "|" | wc -l)"
  if [ "$OP" = "add" -a "$FOUND_PIPE" != "0" ]; then
    # We can't handle multiple choices (separated by |) when adding profiles
    echo "Error - Site list $PROFILE_LIST not allowed to contain '|' when adding profiles"
    exit 1
  fi

  for SITE in $(get_active_lines $SITE_LIST); do
    RES=0

    echo "Modifying site profiles for site $SITE..."

    if [ "$OP" = "add" ]; then
      profuse-zonemaster-cmdb add-site-profiles $SITE $(get_active_lines $PROFILE_LIST)
      RES="$?"

      if [ "$RES" = "0" ]; then
        for PROFILE in $(get_active_lines $PROFILE_LIST); do
          add_row "$SITE ADD $PROFILE" out-profile-changes.list
        done
      fi

    elif [ "$OP" = "delete" ]; then
      SITE_PROFILES="$(profuse-zonemaster-cmdb list-site-profiles $SITE)"
      RES=$?

      if [ "$RES" = "0" ]; then
        for ROW in $(get_active_lines $PROFILE_LIST); do
          OLD_IFS="$IFS"
          IFS='|'

          for PROFILE in $(printf "$ROW"); do
            FOUND="$(echo "$SITE_PROFILES" | tr ' ' '\n' | grep "^$PROFILE\$" | wc -l)"
            if [ "$FOUND" != "0" ]; then
              profuse-zonemaster-cmdb delete-site-profiles $SITE "$PROFILE"
              RES="$?"
              if [ "$RES" = "0" ]; then
                add_row "$SITE DELETE $PROFILE" out-profile-changes.list
              else
                break
              fi
            fi
          done

          IFS="$OLD_IFS"
          if [ "$RES" != "0" ]; then
            break
          fi
        done
      fi

    else
      echo "Unknown operation '$OP'. Aborting."
      exit 1
    fi

    if [ "$RES" = "0" ]; then
      add_unique_row $SITE out-sites-ok.list
    else
      echo "Failed to $OP profile for site '$SITE'."
      add_unique_row $SITE out-sites-error.list
    fi

  done
}

function rollback_profiles {
  # Supposed to be a link to a previous step's out-profile-changes.list
  local PROFILE_CHANGES="out-profile-changes.list"
  local FOUND_IN_PROFILE_CHANGES
  local RES
  local ROWS_IN_SITES
  local SITE
  local SITES

  if [ ! -f "$PROFILE_CHANGES" ]; then
    echo "The file $PROFILE_CHANGES was not found"
    exit 1
  fi

  determine_listfile sites

  # Verify that all sites in LISTFILE (sites.list)
  # are present in the out-profile-changes.list
  ROWS_IN_SITES=$(cat "$LISTFILE" | wc -l)
  FOUND_IN_PROFILE_CHANGES=$(grep -f "$LISTFILE" "$PROFILE_CHANGES" | cut -d ' ' -f1 | sort -u | wc -l)
  if [ "$ROWS_IN_SITES" != "$FOUND_IN_PROFILE_CHANGES" ]; then
    echo "ERROR: Not all sites in sites.list are present in out-profile-changes.list, or duplicates in sites.list. Please correct"
    exit 1
  fi

  for SITE in $(get_active_lines "$LISTFILE"); do

    echo "Rollback site profiles for site $SITE..."

    tac "$PROFILE_CHANGES" | grep "^$SITE" | awk '
    {
      if (NF<3) {
        print "ERROR: Too few items at line", NR, "(reverse count)" > "/dev/stderr"
        exit 1
      }

      site = $1
      op = $2

      # Reverse
      if (op == "ADD") {
        op = "DELETE"
        profuse_arg = "delete-site-profiles"
      } else if (op == "DELETE") {
        op = "ADD"
        profuse_arg = "add-site-profiles"
      } else {
        print "ERROR: Missing ADD or DELETE at line", NR, "(reverse count)" > "/dev/stderr"
        exit 1
      }

      for(i=3;i<=NF;i++) {
        $(i-2) = $i
      }

      NF=NF-2
      profiles = $0

      status = system("profuse-zonemaster-cmdb " profuse_arg " " site " " profiles)
      if (status != 0) {
        exit 1
      }
    }
    '

    RES=$?
    if [ "$RES" = "0" ]; then
      add_unique_row $SITE out-sites-ok.list
    else
      echo "Failed to apply profile change for site '$SITE'."
      add_unique_row $SITE out-sites-error.list
    fi

  done

}

function sleep_minutes {
  # This function should only be run before or after (an)other function(s) in a step (do.sh) since
  # it does not modify *-ok|error.list files itself and thus will result in run-steps.sh to abort.
  # E.g. a line "run_task do-smth-posserver && sleep_minutes 10" or similar is ok but
  # a step (do.sh) only containing a row "sleep_minutes 10" will fail.
  local MINUTES=$1

  echo

  if ! echo $MINUTES | egrep -q '^[1-9][0-9]*$'; then
    echo "Error. sleep_minutes - argument must be a positive integer"
    exit 1
  fi

  echo "- Sleeping for $MINUTES minute(s). A 'z' per started minute will be displayed below."
  echo -n "  Hit enter to proceed sooner: "
  for i in $(seq 1 $MINUTES); do
    echo -n "z"
    [ $((i % 10)) -eq 0 ] && echo -n " "
    read -t 60 && break
  done
  echo
  echo
  true
}

function sleep_seconds {
  # See comment for sleep_minutes (applies here as well)
  local SECONDS=$1

  echo

  if ! echo $SECONDS | egrep -q '^[1-9][0-9]*$'; then
    echo "Error. sleep_seconde - argument must be a positive integer"
    exit 1
  fi

  echo "- Sleeping for $SECONDS second(s). A 'z' per started second will be displayed below."
  echo -n "  Hit enter to proceed sooner: "
  for i in $(seq 1 $SECONDS); do
    echo -n "z"
    [ $((i % 10)) -eq 0 ] && echo -n " "
    read -t 1 && break
  done
  echo
  echo
  true
}

function validate_step_numbers {
  local STEPS="$(list_steps)"
  local LASTNUM=""
  local LASTSTEP=""

  # Make sure we have no duplicates
  for STEP in $STEPS; do
    local NUM="$(echo $STEP|awk -F- '{print $1}'|sed -e 's/^0*//')"
    local NAME="$(echo $STEP|sed -e 's/^...//')"
    if [ "$NUM" = "$LASTNUM" ]; then
      echo "Malformed workflow - found two steps with identical numbers:"
      echo
      echo "  $LASTSTEP"
      echo "  $STEP"
      echo
      echo "Aborting."
      exit 1
    fi
    LASTNUM="$NUM"
    LASTSTEP="$STEP"
  done
}


function validate_step {
    local STEP_NUMBER=$1
    local STATE=$2

    # Validate step number in step name
    if [[ ! "$STEP_NUMBER" =~ ^[0-9][0-9]$ ]]; then
      echo "Illegal step number '$STEP_NUMBER', expected 00-99. Aborting."
      exit 1
    fi

    # Check existance
    local NUM_STEPS="$(ls|grep "^${STEP_NUMBER}-"|wc -l)"
    if [ "$STATE" == present ]; then
      if [ "$NUM_STEPS" = "0" ]; then
        echo "No step $STEP_NUMBER found. Aborting."
        exit 1
      fi
    elif [ "$STATE" == absent ]; then
      if [ "$NUM_STEPS" -gt "0" ]; then
        echo "Found $NUM_STEPS steps numbered $STEP_NUMBER:"
        echo
        ls|grep "^${STEP_NUMBER}-"|sed -e 's/^/  /'
        echo
        echo "If you wish to remove a step, delete the step folder first. Aborting."
        exit 1
      fi
    else
      echo Internal error.
      exit 1
    fi
}

#
# Adds row ITEM to OUTFILE if no identical row already exists
#

function add_unique_row {
  local ROW="$1"
  local OUTFILE="$2"
  if [ -e $OUTFILE ]; then
    if [ "$(cat "$OUTFILE"|grep "^$ROW\$"|wc -l)" -ge 1 ]; then
      # Row exists
      return
    fi
  fi
  echo "$ROW" >> $OUTFILE
}

function add_row {
  local ROW="$1"
  local OUTFILE="$2"
  echo "$ROW" >> $OUTFILE
}

function save_output_files {
  # Determine which files we need to save
  FILES="$(ls|grep '^\(out\|pos.*list$\)')"
  if [ "$FILES" = "" ]; then
    echo "No files to save, aborting."
    exit 1
  fi

  # Determine save directory and move files there
  for i in $(seq -w 1 999); do
    DIR="run-$i"
    if [ ! -e $DIR ]; then
      mkdir $DIR
      SAVE_DIR="$DIR"
      echo
      echo "Moving existing output files and input lists to: $DIR"
      echo
      mv $FILES $DIR/
      ls -l $DIR/
      echo
      echo "Save to '$SAVE_DIR' completed."
      echo
      return
    fi
  done

  echo "Failed to save output - too many run-?? directories."
  exit 1
}

function check_screen {
  # Refuse to run unless we're in a screen (or tmux/byobu) session.
  # Check in a few ways to be robust and to enable override by
  # setting the TERM variable if should be needed.
  local PS_PID
  local PPID_FOUND
  local TERM_FOUND

  PS_PID=$$

  # Check if $$ is run within a pseudo terminal, otherwise we skip this check (not BSD compatible)
  if echo $(ps -p $PS_PID -o tty=) | grep -q pts; then
    # Check if screen or tmux is in the process tree
    while [ $PS_PID -ne 1 ]; do
      PS_PID=$(ps -p $PS_PID -o ppid=)
      if echo $(ps -p $PS_PID -o comm=) | egrep -qi 'screen|tmux'; then
        PPID_FOUND=1
        break
      fi
    done

    # Check if TERM is set to screen (not failsafe)
    if [ "$TERM" = "screen" ]; then
      TERM_FOUND=1
    fi

    if [ "$PPID_FOUND" = "" -a "$TERM_FOUND" = "" ]; then
      echo
      echo "Aborting."
      echo "This command is required to run within a local screen or tmux session."
      echo
      echo "If this remote network connection dies the workflow"
      echo "execution may otherwise end up in an unknown state."
      echo
      exit 1
    fi
  fi
}

function configure_posserver_presync_releases {
  local PL="$(print_new_tags | filter_platform_release_tag_value)"
  if [ "$PL" != "" ]; then
    # Images are synced from the PL release. That is why this also needs to be
    # set in addition to FORCE_PROFUSE_SYNC_RELEASES.
    export FORCE_PROFUSE_PLATFORM_RELEASE="$PL"
    if is_ge_4_3_0 "$PL"; then
      export FORCE_PROFUSE_SYNC_RELEASES="$(print_presync_releases "$PL" | to_comma_separated_string)"
    fi
  fi
}

function is_ge_4_3_0 {
  local MAJOR=$(extract_version_component "$1" 0)
  local MINOR=$(extract_version_component "$1" 1)
  [ "$MAJOR" -gt "4" ] || ( [ "$MAJOR" = "4" ] && [ "$MINOR" -ge "3" ] )
}

function extract_version_component {
  python -c 'import sys; sys.stdout.write(sys.argv[1].strip().split(".")[int(sys.argv[2])])' "$1" "$2"
}

function print_presync_releases {
  local PL="$1"
  local BASE="$(strip_last_version_component "$PL")"
  echo "$BASE"
  echo "$PL"
  print_new_tags | filter_extra_release_tag_values
}

function print_new_tags {
  cat profiles_new.list | while read -r profile; do
    profuse-zonemaster-cmdb show-profile-tags "$profile" | awk '{print $3}'
  done
}

function filter_platform_release_tag_value {
  grep '^profuse\.platform\.release=[0-9.]*$' | cut -d= -f2-
}

function filter_extra_release_tag_values {
  grep '^profuse\.release\.extra\[[[:digit:]]\+\]=' | cut -d= -f2-
}

function strip_last_version_component {
  python -c 'import sys; sys.stdout.write(".".join(sys.argv[1].strip().split(".")[:-1]))' "$1"
}

function to_comma_separated_string {
  python -c 'import sys; sys.stdout.write(",".join(sys.stdin.read().strip().splitlines()))'
}

function activate_store_mpe {
  TARGET_TYPE="$(get_target_type_from_cwd)"

  # Determine listfile
  determine_listfile $TARGET_TYPE

  # Get sites
  SITES=$(get_active_lines "$LISTFILE")

  mkdir out-log

  for SITE in $SITES; do
    mpman store $SITE set address
    mpman store $SITE set status active
    if [ "$?" != "0" ]; then
      echo "Setting address and status for $SITE failed. Aborting."
      echo $SITE >> out-${TARGET_TYPE}-error.list
      continue
    fi
    echo $SITE >> out-${TARGET_TYPE}-ok.list
  done

  # Show results
  RESFILE="out-${TARGET_TYPE}-ok.list"
  if [ -s $RESFILE ]; then
    echo "OK:    $(cat $RESFILE|wc -l)"
  fi
  RESFILE="out-${TARGET_TYPE}-error.list"
  if [ -s $RESFILE ]; then
    echo "ERROR: $(cat $RESFILE|wc -l)"
    # If there was an error, we terminate here - even if some were ok above
    exit 1
  fi
}

# Process script arguments depending on $0
SCRIPT_NAME="$(basename $0)"
if [ "$SCRIPT_NAME" = "do.sh" ]; then
  # Must be in a screen/tmux session
  check_screen

  if [ "$1" = ""  -o "$1" = "run" ]; then
    : # Normal run, just continue the script
  elif [ "$1" = "save" ]; then
    save_output_files
    exit 0
  elif [ "$1" = "rerun-failed" ]; then
    # Make sure there are failed units to process
    TARGET_TYPE="$(get_target_type_from_cwd)"
    NUM_ERROR_FILES="$(ls|grep ^out-${TARGET_TYPE}-error.list$ | wc -l | awk '{print $1}')"
    if [ "$NUM_ERROR_FILES" != "1" ]; then
      echo "No failed units. Nothing to do."
      exit 0
    fi
    NUM_FAILED="$(wc -l out-${TARGET_TYPE}-error.list|awk '{print $1}')"
    echo "Re-running step for $NUM_FAILED ${TARGET_TYPE}."
    echo

    # Save files, then pull back what we need to the step directory
    save_output_files
    echo
    echo "Setting up re-run input using results from the previous run:"
    cp -a $SAVE_DIR/out-${TARGET_TYPE}-ok.list .
    cp -a $SAVE_DIR/out-${TARGET_TYPE}-error.list ${TARGET_TYPE}.list
    echo
    ls -1 out-* ${TARGET_TYPE}.list | sed -e 's/^/  /'
    echo
    echo Starting re-run.
    echo

    # Enable re-run mode, then continue the step.
    RERUN=1
  else
    echo "Usage: ./do.sh [<action>]"
    echo
    echo "Actions:"
    echo
    echo "    run           Run the step from the beginning"
    echo "    save          Save output data so step can be run again"
    echo "    rerun-failed  Save output data, then re-run units that failed previous run"
    echo
    echo "Default action: 'run'"
    if [ "$1" != "-h" ]; then
      echo
      echo "Unknown action: '$RUN_MODE' - aborting."
    fi
    exit 1
  fi
fi
