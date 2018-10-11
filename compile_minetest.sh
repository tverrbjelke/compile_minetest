#!/usr/bin/env bash
# Read README.txt of the source and maybe http://wiki.minetest.com/wiki/Installing_Mods

echo "This script will install dependencies and then minetest and then into minetest some mods "
echo "from sources - either by downloading sources direclty from github or by using pre-downloas."
echo "So you can download each tarball of minetest, minetest_game and mods"
echo "and then tell this script where the tarballs are located (but that is mosty "
echo "untested part of script )."
echo 
echo "I wrote this script once as a reminder of what I have done to get it done."
echo "Now the script can do it all alone."
echo
echo "You simply can call this script without any arguments."
echo "But maybe you want to edit some settings inside this script first."
echo 
echo "usage: [DEST_BASE] [TARBALL_FOLDER]"
echo
echo "optional DEST_BASE defaults to '$HOME/bin/' - where all binaries are build."
echo "optional SOURCE_BASEPATH defaults to '.' - this folder contains the (already downloaded) tarballs."
echo "SOURCE_BASEPATH is only needed when using tarballs and not github."
echo "SOURCE_BASEPATH is not used at all when using git to clone the sources straight from github."
echo "The executables of minetest (client/server) are found under"
echo 'DEST_BASE/bin/minetest-${MINETEST_VERSION}/bin/'
echo
echo "After installing you can start the client 'minetest' straight away."
echo "If you want to serve a world, you have to configure the mods once for the new world:" 
echo "After installing the mods, start Minetest (client), "
echo "go to the world's 'Configure' menu, click 'Enable All' then 'Save'."
echo "later you can simply run the minetestserver"
echo 
echo "remember also: the 1st logged in user gets automactically ADMIN rights inside the game."
echo "maybe you want to login / out with a special admin account once per session."

##############################################################
# Here you can set options and stuff
##############################################################

# The tag can be seen from https://github.com/minetest/minetest/tags
MINETEST_VERSION=0.4.17.1

# I want to be able to jump over/into individual steps - for debugging

# Really install system packages? (needs sudo for this to work)
DO_INSTALL_SYSTEM_PACKAGES=YES

# Download sources and then inject into the *global* mods folder.
# It expects the mods NOT already been cloned/installed.
DO_INSTALL_MOD_DREAMBUILDER=TRUE
# Her github repo is not public and needs login credentials to github.
# So you can specify here TAR to download her own tarball via wget
# it GIT to just get it from github via your login credentials
USE_TARBALL_OR_GIT_MOD_DREAMBUILDER=GIT

# Wardrobe actually is compatible with 3d_armor 
DO_INSTALL_MOD_WARDROBE=TRUE
DO_INSTALL_MOD_3D_ARMOR=TRUE

DO_INSTALL_MOD_VEHICLES=TRUE
DO_INSTALL_MOD_MOB=TRUE

DO_INSTALL_MOD_RANGEDWEAPONS=TRUE
USE_TARBALL_OR_GIT_MOD_RANGEDWEAPONS=ZIP


##############################################
# here you can specify more stuff, normally leave it as is?
##############################################

# Maybe you adopt this to aprox. the number of CPU Cores your computer has.
# Used for the -j flag when compiling minetest.
COMPILE_FLAG_J=$(nproc)

# untar / git-clone and prepare stuff ?
DO_PREPARE_BUILD=YES

# now also start build process? relates to the minetest binaries
# put to NO e.g. if you just whant to add mods to an existing minetest 
DO_BUILD=YES

# install locally =TRUE or system wide =FALSE ?
# this script only tested with TRUE (or must it be "1"?)
export RUN_IN_PLACE=TRUE

# switch: compile from git repo (already untarred) or unpack tarball first?
# if you are using tarball, we expect current working directory or $1 contains it.
# we expect SOURCE_BASEPATH and DEST_BASE folder to already exist...
# If you are using git, we expect the repo already cloned, e.g. 
# Some mods also can be installed either by git or tarball.
# (dreambuilder has its own flag USE_TARBALL_OR_GIT_MOD_DREAMBUILDER)
USE_TARBALL_OR_GIT=GIT

# all as one-liner - so have the backslash as last character of each line here...
# I had issues with LEVELDB, I will deactivate it.
export BUILD_OPTS="-DRUN_IN_PLACE=${RUN_IN_PLACE}   -DBUILD_CLIENT=1 -DBUILD_SERVER=1 \
  -DCMAKE_BUILD_TYPE=Release -DENABLE_CURL=1 -DENABLE_CURSES=1 \
  -DENABLE_FREETYPE=1 -DENABLE_GETTEXT=1 -DENABLE_GLES=1 \
  -DENABLE_LEVELDB=0 -DENABLE_REDIS=1 \
  -DENABLE_SOUND=1 \
  -DENABLE_SPATIAL=1 -DENABLE_LUAJIT=1 \
  -DENABLE_SYSTEM_GMP=1"

echo "Using this compile flags:"
echo ${BUILD_OPTS}



##############################################################
# the remainder of the script *should* work automagically...
##############################################################

# keep version numbers to allow having multiple inplace-installations
export MINETEST=minetest-${MINETEST_VERSION}
export MINETEST_GAME=minetest_game-${MINETEST_VERSION}

# we expect to be where the build-folder should be placed
# or script argument 1 contains the path
export DEST_BASE=${HOME}/bin
if [[ $1 != "" ]]
then
   export DEST_BASE=$1
fi

if [[ ! -d ${DEST_BASE} ]]
then
   echo "base folder did not exist, creating..."
   echo "mkdir -p ${DEST_BASE}"
   mkdir -p ${DEST_BASE}
fi

if [[ ! -d ${DEST_BASE} ]]
then
   echo "Error! No folder ${DEST_BASE}... exiting! "
   exit 1
fi

# todo should be empty, maybe better ask if to clear out existing folder?

if [[ -d ${DEST_BASE}/${MINETEST} ]] # already existed!
then
    echo "/!\ Caution: ${DEST_BASE}/${MINETEST} already existing - not daring to overwrite existing game!You can manually run this command to delete the folder and the re-run this script:"
    echo "rm -Rf  ${DEST_BASE}/${MINETEST}"
   exit 1
else
    mkdir -p ${DEST_BASE}/${MINETEST}
fi
   
# todo check if it now exists, writable etc... else: abort

# must be outside of clone dest folder, otherwise git clone cannot work
export LOGFILE=${DEST_BASE}/${MINETEST}-build.log
# creating clear logfile...
if ! echo "Logfile of last build run"  > ${LOGFILE} 
then
   echo Error! Cannot write access ${LOGFILE}! Aborting...
   exit 1
else 
  date | tee -a ${LOGFILE}
fi

echo Build- and destination folder: ${DEST_BASE} | tee -a ${LOGFILE}
echo Logfile is ${LOGFILE} | tee -a ${LOGFILE}

# todo ask if to proceed? or just do it?

if [[ $DO_INSTALL_SYSTEM_PACKAGES == "YES" ]]
then
  echo "installing needed system debain / ubuntu packages, need sudo password."  | tee  ${LOGFILE}

  # this was for 0.4.10
  #sudo apt-get install build-essential libirrlicht-dev cmake libbz2-dev libpng12-dev \ 
  #libjpeg8-dev libxxf86vm-dev libgl1-mesa-dev libsqlite3-dev libogg-dev libvorbis-dev \ 
  #libopenal-dev libcurl4-gnutls-dev libfreetype6-dev redis-server libhiredis-dev

  #this was for 0.4.14
  #sudo apt-get install build-essential libirrlicht-dev cmake libbz2-dev libpng12-dev \
  #libjpeg-dev libxxf86vm-dev libgl1-mesa-dev libsqlite3-dev libogg-dev libvorbis-dev \
  #libopenal-dev libcurl4-gnutls-dev libfreetype6-dev zlib1g-dev libgmp-dev libjsoncpp-dev

  #More dependencies for some options:
  #apt-get install libleveldb-dev redis-server libhiredis-dev 
  #apt-get install redis-server libhiredis-dev

  # this was for 0.4.16 and 0.4.17.1 - straight from README.txt of minetest and some build tools added
  # ncurses seem to be automatically installed by package xorg
  PKGS="build-essential libirrlicht-dev cmake libbz2-dev libpng-dev libjpeg-dev libxxf86vm-dev libgl1-mesa-dev libsqlite3-dev libogg-dev libvorbis-dev libopenal-dev libcurl4-gnutls-dev libfreetype6-dev zlib1g-dev libgmp-dev libjsoncpp-dev"
  PKGS="${PKGS} cmake git tar bzip2" # this is also needed
  PKGS="${PKGS} libcurl4-gnutls-dev libncursesw5-dev" # for --terminal to work properly
  echo "Installing packages via sudo apt install:" | tee -a ${LOGFILE}
  # echo ${PKGS} | tee -a ${LOGFILE}
  echo "sudo apt install ${PKGS}" | tee -a ${LOGFILE}
  sudo apt install ${PKGS}
fi #DO_INSTALL_SYSTEM_PACKAGES


if [[ $DO_PREPARE_BUILD == "YES" ]]
then
  echo "preparing build..."  | tee -a ${LOGFILE}

  #todo no errors handled
  if [[ $USE_TARBALL_OR_GIT == "TAR" ]]
  then
    # so we can go back later since we need cd to checkout desired version...
    CWD_TMP=$PWD 
  
    # we expect to be where the downloaded sources are located
    # or script argument 2 contains the path to the tarball.
    export SOURCE_BASEPATH=$(pwd)
    if [[ $2 != "" ]] 
    then
       export SOURCE_BASEPATH=$2
    fi
    # todo check if it exists and if not, abort with error

    echo "source tarball folder is: $SOURCE_BASEPATH" | tee -a ${LOGFILE}
  
    # we expect this folder to already exist...
    echo "cd ${DEST_BASE}" | tee -a ${LOGFILE}
    cd ${DEST_BASE}
    echo "tar -xzf ${SOURCE_BASEPATH}/${MINETEST}.tar.gz" | tee -a ${LOGFILE}
    tar -xzf ${SOURCE_BASEPATH}/${MINETEST}.tar.gz 
    echo "cd ${DEST_BASE}/${MINETEST}/games/"| tee -a ${LOGFILE}
    cd ${DEST_BASE}/${MINETEST}/games/
    echo "tar -xzf ${SOURCE_BASEPATH}/${MINETEST_GAME}.tar.gz " | tee -a ${LOGFILE}
    tar -xzf ${SOURCE_BASEPATH}/${MINETEST_GAME}.tar.gz 
    echo "mv ${MINETEST_GAME} minetest_game" | tee -a ${LOGFILE}
    mv ${MINETEST_GAME} minetest_game #hack - the subgame needs *this* name to be found
    echo "cd ${CWD_TMP}"| tee -a ${LOGFILE}
    cd ${CWD_TMP} # go back from where we came
  fi # TAR

  #todo no errors handled - just use one of either TAR or GIT please :-)
  if [[ $USE_TARBALL_OR_GIT == "GIT" ]]
  then
    # so we can go back later since here we must checkout desired version...
    export CWD_TMP=${PWD}

    echo "cloning sources from github... " | tee -a ${LOGFILE}

    echo "git clone https://github.com/minetest/minetest.git ${DEST_BASE}/${MINETEST} "| tee -a ${LOGFILE}
    git clone https://github.com/minetest/minetest.git ${DEST_BASE}/${MINETEST}

    echo "cd ${DEST_BASE}/${MINETEST}" | tee -a ${LOGFILE}
    cd ${DEST_BASE}/${MINETEST}
    # git tag # shows all available tags
    echo "git checkout ${MINETEST_VERSION}" | tee -a ${LOGFILE}
    git checkout ${MINETEST_VERSION}
    # todo since version is user-input for this script, I should check, 
    # if that checkou was successfull...

    echo "cd  ${DEST_BASE} " | tee -a ${LOGFILE}
    cd  ${DEST_BASE} 
    # this seems as a dirty hack for me: it MUST have this 
    # fixed name "minetest_game" and nothing else...
    echo "git clone https://github.com/minetest/minetest_game.git ${DEST_BASE}/${MINETEST}/games/minetest_game" | tee -a ${LOGFILE}
    git clone  https://github.com/minetest/minetest_game.git ${DEST_BASE}/${MINETEST}/games/minetest_game
    echo "cd  ${DEST_BASE}/${MINETEST}/games/minetest_game" | tee -a ${LOGFILE}
    cd  ${DEST_BASE}/${MINETEST}/games/minetest_game
    # git tag # shows all available tags
    echo "git checkout ${MINETEST_VERSION} "| tee -a ${LOGFILE}
    git checkout ${MINETEST_VERSION}

    echo "cd ${CWD_TMP} "| tee -a ${LOGFILE}
    cd ${CWD_TMP} # go back from where we came
  fi # GIT
fi # DO_PREPARE_BUILD


if [[ $DO_BUILD == "YES" ]]
then
  echo "Entering build step..."  | tee -a ${LOGFILE}

  # so we can go back later since here we must checkout desired version...
  export CWD_TMP=${PWD}

  echo "here we will build all stuff..."| tee -a ${LOGFILE}
  echo "cd ${DEST_BASE}/${MINETEST}/build" | tee -a ${LOGFILE}
  cd ${DEST_BASE}/${MINETEST}/build
  echo "configuring..." | tee -a ${LOGFILE}
  echo "cmake .. ${BUILD_OPTS} &>> ${LOGFILE}"| tee -a ${LOGFILE}
  cmake .. ${BUILD_OPTS} &>> ${LOGFILE}

  echo "building..." | tee -a ${LOGFILE}
  echo "make -j${COMPILE_FLAG_J} >> ${LOGFILE} 2>&1" | tee -a ${LOGFILE}
  make -j${COMPILE_FLAG_J} >> ${LOGFILE} 2>&1	

  echo "done... check for problems in ${LOGFILE}" | tee -a ${LOGFILE}
  echo "binary of client and server should now be in ${DEST_BASE}/${MINETEST}/bin/" | tee -a ${LOGFILE}
  echo "cd ${CWD_TMP}" | tee -a ${LOGFILE}
  cd ${CWD_TMP} # go back from where we came
fi # DO_BUILD

#############################################################
# Install mods
#############################################################

# install all this mods globally.
MOD_DEST_PATH=${DEST_BASE}/${MINETEST}/mods

##############################################################

# had some issues installing this mod and so I tried both git and tarball installations. 
# Hence this two sources git and tarball here...
if [[ $DO_INSTALL_MOD_DREAMBUILDER == "TRUE" ]]
then
  MOD="dreambuilder_modpack"
  echo "installing ${MOD}, see  https://forum.minetest.net/viewtopic.php?f=11&t=9196" | tee -a ${LOGFILE}
  if [[  -d ${MOD_DEST_PATH}/${MOD} ]]
  then
      echo "${MOD_DEST_PATH}/${MOD} already exists, deleting old and reinstalling..." | tee -a ${LOGFILE}
      rm -Rf "${MOD_DEST_PATH}/${MOD}"
  fi

  # if [[ $USE_TARBALL_OR_GIT == "TAR" ]]
  if [[ $USE_TARBALL_OR_GIT_MOD_DREAMBUILDER == "TAR" ]]
  then
    CWD_TMP=${PWD}
    echo cd ${MOD_DEST_PATH}
    cd ${MOD_DEST_PATH}
    # todo check if wget is installed... and if download succeeded
    echo wget https://daconcepts.com/vanessa/hobbies/minetest/Dreambuilder_Modpack.tar.bz2
    wget https://daconcepts.com/vanessa/hobbies/minetest/Dreambuilder_Modpack.tar.bz2
    echo tar -xjf Dreambuilder_Modpack.tar.bz2
    tar -xjf Dreambuilder_Modpack.tar.bz2
    rm Dreambuilder_Modpack.tar.bz2
    echo cd ${CWD_TMP}
    cd ${CWD_TMP} # go back from where we came
    
  fi

  if [[ $USE_TARBALL_OR_GIT_MOD_DREAMBUILDER == "GIT" ]]
  then
      echo "As of July 2018 the github repo of Vanessa moved to gitlab. "| tee -a ${LOGFILE}
      echo "git clone https://gitlab.com/VanessaE/dreambuilder_modpack  ${MOD_DEST_PATH}/${MOD}"| tee -a ${LOGFILE}
      git clone https://gitlab.com/VanessaE/dreambuilder_modpack ${MOD_DEST_PATH}/${MOD}
  fi

  echo "dreambuilder_modpack should now be in ${MOD_DEST_PATH}/${MOD}/" | tee -a ${LOGFILE}
  echo "maybe you need to configure / tweek it..."  | tee -a ${LOGFILE}
fi

###########################################################
if [[ $DO_INSTALL_MOD_WARDROBE == "TRUE" ]]
then
  MOD="wardrobe"
  echo "installing mod wardrobe, see https://forum.minetest.net/viewtopic.php?f=9&t=9680&hilit=wardrobe" | tee -a ${LOGFILE}
  # provided only by git

  if [[ -d ${MOD_DEST_PATH}/${MOD} ]]
  then
      echo "${MOD_DEST_PATH}/${MOD} already exists, deleting old and reinstalling..."| tee -a ${LOGFILE}
      rm -Rf "${MOD_DEST_PATH}/${MOD}"
  fi
  echo "git clone https://github.com/prestidigitator/minetest-mod-wardrobe.git  ${MOD_DEST_PATH}/${MOD}" | tee -a ${LOGFILE}
  git clone https://github.com/prestidigitator/minetest-mod-wardrobe.git  ${MOD_DEST_PATH}/${MOD}

  echo "Mod wardrobe should now be in ${MOD_DEST_PATH}/${MOD}/" | tee -a ${LOGFILE}
  echo "maybe you need to configure and add some skins..."  | tee -a ${LOGFILE}
fi
############################################################
if [[ $DO_INSTALL_MOD_VEHICLES == "TRUE" ]]
then
  MOD="vehicles"
  echo "installing mod ${MOD}" | tee -a ${LOGFILE}
  # for simplicity provided only via git
  # tarball would be  at wget https://github.com/D00Med/vehicles/archive/master.zip

  if [[ -d ${MOD_DEST_PATH}/${MOD} ]]
  then
      echo "${MOD_DEST_PATH}/${MOD} already exists, deleting old and reinstalling..." | tee -a ${LOGFILE}
      rm -Rf "${MOD_DEST_PATH}/${MOD}"
  fi

  echo "git clone https://github.com/D00Med/vehicles.git ${MOD_DEST_PATH}/${MOD}" | tee -a ${LOGFILE}
  git clone https://github.com/D00Med/vehicles.git ${MOD_DEST_PATH}/${MOD}

  echo "Mod vehicles should now be in ${MOD_DEST_PATH}/${MOD}/" | tee -a ${LOGFILE}
  echo "maybe you need to configure and activate/deactivate specific vehicles (e.g. the warplane/tank/assault_walker stuff)"  | tee -a ${LOGFILE}
fi
############################################################
# todo moved from github ? https://notabug.org/TenPlus1/mobs_redo
# git clone https://notabug.org/TenPlus1/mobs_redo.git

if [[ $DO_INSTALL_MOD_MOB == "TRUE" ]]
then
  MOD="mob"
  echo "installing first ${MOB} and then some animals/monsters submods," | tee -a ${LOGFILE}
  echo "see https://forum.minetest.net/viewtopic.php?f=11&t=9917" | tee -a ${LOGFILE}
  echo "Watch out, that some of TenPlus1 mods are already part of dreambuilder mod!" | tee -a ${LOGFILE}
  # provided only by git
  

  # cannot use assotiative arrays, because order is important: 1st mob_redo!
  echo "this mobs in this order: " | tee -a ${LOGFILE}
  SUB_MODS=( "mob" "mobs_animal" "mobs_monster" "mobs_npc" "mob_horse" )
  GIT_REPOS=( "https://notabug.org/TenPlus1/mobs_redo.git" \
              "https://notabug.org/TenPlus1/mobs_animal.git" \
              "https://notabug.org/TenPlus1/mobs_monster.git" \
              "https://notabug.org/TenPlus1/mobs_npc.git" \
              "https://notabug.org/TenPlus1/mob_horse.git" ) 
  
  for ((i=0;i<${#SUB_MODS[@]};++i)); do
      SUB_MOD=${SUB_MODS[i]}
      REPO=${GIT_REPOS[i]}
      printf "installing mod %s from %s\n" "${SUB_MOD}" "${GIT_REPOS}"  | tee -a ${LOGFILE}
      if [[ -d ${MOD_DEST_PATH}/${SUB_MOD} ]]
      then
	  echo "${MOD_DEST_PATH}/${SUB_MOD} already exists, deleting old and reinstalling..."  | tee -a ${LOGFILE}
	  rm -Rf "${MOD_DEST_PATH}/${SUB_MOD}"
      fi
      echo "git clone ${REPO}  ${MOD_DEST_PATH}/${SUB_MOD}" | tee -a ${LOGFILE}
      git clone ${REPO}  ${MOD_DEST_PATH}/${SUB_MOD}
  done
  echo "maybe you need to configure some mobs in the relevant init.lua file..." | tee -a ${LOGFILE}
  echo "(I like to make all mobs (esp. horse) *much* rarer, factor 20-100)"  | tee -a ${LOGFILE}
fi

############################################################
if [[ $DO_INSTALL_MOD_3D_ARMOR == "TRUE" ]]
then
  MOD="3d_armor"
  echo "installing mod ${MOD}" | tee -a ${LOGFILE}
  echo "see https://github.com/stujones11/minetest-3d_armor/" | tee -a ${LOGFILE}
  echo "Minetest 0.4.16 - 0.4.17.1 need Version 0.4.12" | tee -a ${LOGFILE}
  MOD_3D_ARMOR_VERSION="version-0.4.12"
  # for simplicity provided only via git

  if [[ -d ${MOD_DEST_PATH}/${MOD} ]]
  then
      echo "${MOD_DEST_PATH}/${MOD} already exists, deleting old and reinstalling..."| tee -a ${LOGFILE}
      rm -Rf "${MOD_DEST_PATH}/${MOD}"
  fi

  echo "git clone https://github.com/stujones11/minetest-3d_armor.git ${MOD_DEST_PATH}/${MOD}"| tee -a ${LOGFILE}
  git clone https://github.com/stujones11/minetest-3d_armor.git ${MOD_DEST_PATH}/${MOD}
  # so we can go back later since here we must checkout desired version...
  export CWD_TMP_MOD=${PWD}
  cd ${MOD_DEST_PATH}/${MOD}
  git checkout ${MOD_3D_ARMOR_VERSION}
  cd ${CWD_TMP_MOD} # jump back
  
  echo "Mod 3d_armor version ${MOD_3D_ARMOR_VERSION} should now be in ${MOD_DEST_PATH}/${MOD}/" | tee -a ${LOGFILE}
  echo "see  https://forum.minetest.net/viewtopic.php?f=11&t=4654 "  | tee -a ${LOGFILE}
fi

###############################################################
if [[ $DO_INSTALL_MOD_RANGEDWEAPONS == "TRUE" ]]
then
  MOD="rangedweapons"
  echo "installing ${MOD}, see https://forum.minetest.net/viewtopic.php?f=9&t=15173&hilit=gun" | tee -a ${LOGFILE}
  if [[  -d ${MOD_DEST_PATH}/${MOD} ]]
  then
      echo "${MOD_DEST_PATH}/${MOD} already exists, deleting old and reinstalling..." | tee -a ${LOGFILE}
      rm -Rf "${MOD_DEST_PATH}/${MOD}"
  fi

  # only zip available
  if [[ $USE_TARBALL_OR_GIT_MOD_RANGEDWEAPONS == "ZIP" ]]
  then
    CWD_TMP=${PWD}
    echo cd ${MOD_DEST_PATH}
    cd ${MOD_DEST_PATH}
    # todo check if wget is installed... and if download succeeded
    # this mod comes as zip directly from the minetest forum, but the downloaded filename is odd...
    echo wget -O rangedweapons_0.3.zip https://forum.minetest.net/download/file.php?id=16336
    wget -O rangedweapons_0.3.zip https://forum.minetest.net/download/file.php?id=16336
    echo unzip rangedweapons_0.3.zip
    unzip rangedweapons_0.3.zip
    rm rangedweapons_0.3.zip
    echo cd ${CWD_TMP}
    cd ${CWD_TMP} # go back from where we came    
  fi

  echo "$MOD should now be in ${MOD_DEST_PATH}/${MOD}/" | tee -a ${LOGFILE}
  echo "maybe you need to configure / tweek it..."  | tee -a ${LOGFILE}
fi


# todo add more mods?
# farming redo already is part of deambuilder pack https://forum.minetest.net/viewtopic.php?f=11&t=90194
# maybe also some stuff like not so simple mobs, or survival mode stuff (hunger etc)
  
