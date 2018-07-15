#!/usr/bin/env bash
# Read README.txt of the source and maybe http://wiki.minetest.com/wiki/Installing_Mods

echo "This script will unpack and then build minetest from sources."
echo "either by let it itself download stuff from github."
echo "Or you can download each tarball of minetest and minetest_game and mods"
echo "and then tell this script where the tarballs are located."
echo 
echo "I wrote this once as a reminder of what I have done to get it done."
echo "Now it can do it all alone."
echo
echo "You simply can call this script without any arguments."
echo "But maybe you cant to edit some settings inside this script first."
echo 
echo "usage: [DEST_BASE] [TARBALL_FOLDER]"
echo
echo "optional DEST_BASE defaults to HOME/bin/ - where all binaries are build."
echo "optional SOURCE_BASEPATH defaults to . - this folder contains the (already downloaded) tarballs."
echo "SOURCE_BASEPATH is only needed when using tarballs and not github."
echo "SOURCE_BASEPATH is not used at all when using git to clone the sources straight from github."
echo "The executables of minetest (client/server) are found under"
echo "DEST_BASE/bin/minetest-${MINETEST_VERSION}/bin/"
echo
echo "you can start the client straight away."
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

MINETEST_VERSION=0.4.16

# I want to be able to jump over/into individual steps - for debugging

# Really install system packages? (needs sudo for this to work)
DO_INSTALL_SYSTEM_PACKAGES=YES

# Download sources and then inject into the *global* mods folder.
# It expects the mods NOT already been cloned/installed.
DO_INSTALL_MOD_DREAMBUILDER=TRUE

# Wardrobe actually is compatible with 3d_armor 
DO_INSTALL_MOD_WARDROBE=TRUE
DO_INSTALL_MOD_3D_ARMOR=TRUE

DO_INSTALL_MOD_VEHICLES=TRUE
DO_INSTALL_MOD_MOB_REDO=TRUE

##############################################
# here you can specify more stuff, normally leave it as is?
##############################################

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
USE_TARBALL_OR_GIT=GIT

# all as one-liner - so have the backslash as last character of each line here...
export BUILD_OPTS="-DRUN_IN_PLACE=${RUN_IN_PLACE} -DCMAKE_BUILD_TYPE=Release -DENABLE_GETTEXT=1 \
  -DENABLE_FREETYPE=1  -DBUILD_CLIENT=1 -DBUILD_SERVER=1 -DENABLE_CURL=1  -DENABLE_GLES=1 \
  -DENABLE_LEVELDB=0 -DENABLE_SPATIAL=1 -DENABLE_LUAJIT=1 -DENABLE_SYSTEM_GMP=1 \
  -DENABLE_REDIS=1 -DENABLE_SOUND=1"
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
mkdir ${DEST_BASE}/${MINETEST}
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

  # this is for 0.4.10
  #sudo apt-get install build-essential libirrlicht-dev cmake libbz2-dev libpng12-dev \ 
  #libjpeg8-dev libxxf86vm-dev libgl1-mesa-dev libsqlite3-dev libogg-dev libvorbis-dev \ 
  #libopenal-dev libcurl4-gnutls-dev libfreetype6-dev redis-server libhiredis-dev

  #this was for 0.4.14
  #sudo apt-get install build-essential libirrlicht-dev cmake libbz2-dev libpng12-dev \
  #libjpeg-dev libxxf86vm-dev libgl1-mesa-dev libsqlite3-dev libogg-dev libvorbis-dev \
  #libopenal-dev libcurl4-gnutls-dev libfreetype6-dev zlib1g-dev libgmp-dev libjsoncpp-dev

  #More depend. for follolwing options:
  #apt-get install libleveldb-dev redis-server libhiredis-dev 
  #apt-get install redis-server libhiredis-dev

  # this was for 0.4.16 - straight from README.txt
  sudo apt-get install build-essential libirrlicht-dev cmake libbz2-dev libpng-dev \
       libjpeg-dev libxxf86vm-dev libgl1-mesa-dev libsqlite3-dev libogg-dev libvorbis-dev \
       libopenal-dev libcurl4-gnutls-dev libfreetype6-dev zlib1g-dev libgmp-dev libjsoncpp-dev
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
    cd ${DEST_BASE}
    tar -xzf ${SOURCE_BASEPATH}/${MINETEST}.tar.gz 
    cd ${DEST_BASE}/${MINETEST}/games/
    tar -xzf ${SOURCE_BASEPATH}/${MINETEST_GAME}.tar.gz 
    mv ${MINETEST_GAME} minetest_game #hack - the subgame needs *this* name to be found

    cd ${CWD_TMP} # go back from where we came
  fi

  #todo no errors handled - just use one of either TAR or GIT please :-)
  if [[ $USE_TARBALL_OR_GIT == "GIT" ]]
  then
    # so we can go back later since here we must checkout desired version...
    export CWD_TMP=${PWD}

    echo "cloning sources from github... " | tee -a ${LOGFILE}

    echo git clone https://github.com/minetest/minetest.git ${DEST_BASE}/${MINETEST}
    git clone https://github.com/minetest/minetest.git ${DEST_BASE}/${MINETEST}

    cd ${DEST_BASE}/${MINETEST}
    # git tag # shows all available tags
    git checkout ${MINETEST_VERSION}
    # todo since version is user-input for this script, I should check, 
    # if that checkou was successfull...

    cd  ${DEST_BASE} 
    # this seems as a dirty hack for me: it MUST have this 
    # fixed name "minetest_game" and nothing else...
    echo git clone https://github.com/minetest/minetest_game.git ${DEST_BASE}/${MINETEST}/games/minetest_game
    git clone https://github.com/minetest/minetest_game.git ${DEST_BASE}/${MINETEST}/games/minetest_game
    cd  ${DEST_BASE}/${MINETEST}/games/minetest_game
    # git tag # shows all available tags
    git checkout ${MINETEST_VERSION}

    cd ${CWD_TMP} # go back from where we came
  fi
fi # DO_INSTALL_SYSTEM_PACKAGES


if [[ $DO_BUILD == "YES" ]]
then
  echo "Entering build step..."  | tee -a ${LOGFILE}

  # so we can go back later since here we must checkout desired version...
  export CWD_TMP=${PWD}

  cd ${DEST_BASE}/${MINETEST}/build
  echo cd ${DEST_BASE}/${MINETEST}/build
  echo "here we will build all stuff..."| tee -a ${LOGFILE}

  echo "configuring..." | tee -a ${LOGFILE}
  cmake .. ${BUILD_OPTS} &>> ${LOGFILE}

  echo "building..." | tee -a ${LOGFILE}
  make -j4 >> ${LOGFILE} 2>&1	

  echo "done... check for problems in ${LOGFILE}" | tee -a ${LOGFILE}
  echo "binary of client and server should now be in ${DEST_BASE}/${MINETEST}/bin/" | tee -a ${LOGFILE}

  cd ${CWD_TMP} # go back from where we came

fi # DO_BUILD

#############################################################
# Install mods
#############################################################

# install all this mods globally.
MOD_DEST_PATH=${DEST_BASE}/${MINETEST}/mods

# had some issues installing this mod and so I tried both git and tarball installations. 
# Hence this two sources git and tarball here...
if [[ $DO_INSTALL_MOD_DREAMBUILDER == "TRUE" ]]
then
  MOD="dreambuilder_modpack"
  echo "installing ${MOD}, see  https://forum.minetest.net/viewtopic.php?f=11&t=9196" | tee -a ${LOGFILE}
  if [[  -d ${MOD_DEST_PATH}/${MOD} ]]
  then
      echo "${MOD_DEST_PATH}/${MOD} already exists, deleting old and reinstalling..."
      rm -Rf "${MOD_DEST_PATH}/${MOD}"
  fi

  if [[ $USE_TARBALL_OR_GIT == "TAR" ]]
  then
    CWD_TMP=${PWD}
    cd ${MOD_DEST_PATH}
    # todo check if wget is installed... and if download succeeded
    wget https://daconcepts.com/vanessa/hobbies/minetest/Dreambuilder_Modpack.tar.bz2
    tar -xjf Dreambuilder_Modpack.tar.bz2
    #rm Dreambuilder_Modpack.tar.bz2
    echo cd ${CWD_TMP} # go back from where we came
  fi

  if [[ $USE_TARBALL_OR_GIT == "GIT" ]]
  then
    git clone https://github.com/VanessaE/dreambuilder_modpack.git  ${MOD_DEST_PATH}/${MOD}
  fi

  echo "dreambuilder_modpack should now be in ${MOD_DEST_PATH}/${MOD}/" | tee -a ${LOGFILE}
  echo "maybe you need to configure / tweek it..."  | tee -a ${LOGFILE}
fi


if [[ $DO_INSTALL_MOD_WARDROBE == "TRUE" ]]
then
  MOD="wardrobe"
  echo "installing mod wardrobe, see https://forum.minetest.net/viewtopic.php?f=9&t=9680&hilit=wardrobe" | tee -a ${LOGFILE}
  # provided only by git

  if [[ -d ${MOD_DEST_PATH}/${MOD} ]]
  then
      echo "${MOD_DEST_PATH}/${MOD} already exists, deleting old and reinstalling..."
      rm -Rf "${MOD_DEST_PATH}/${MOD}"
  fi
  git clone https://github.com/prestidigitator/minetest-mod-wardrobe.git  ${MOD_DEST_PATH}/${MOD}

  echo "Mod wardrobe should now be in ${MOD_DEST_PATH}/${MOD}/" | tee -a ${LOGFILE}
  echo "maybe you need to configure and add some skins..."  | tee -a ${LOGFILE}
fi

if [[ $DO_INSTALL_MOD_VEHICLES == "TRUE" ]]
then
  MOD="vehicles"
  echo "installing mod ${MOD}" | tee -a ${LOGFILE}
  # for simplicity provided only via git
  # tarball would be  at wget https://github.com/D00Med/vehicles/archive/master.zip

  if [[ -d ${MOD_DEST_PATH}/${MOD} ]]
  then
      echo "${MOD_DEST_PATH}/${MOD} already exists, deleting old and reinstalling..."
      rm -Rf "${MOD_DEST_PATH}/${MOD}"
  fi

  git clone https://github.com/D00Med/vehicles.git ${MOD_DEST_PATH}/${MOD}

  echo "Mod vehicles should now be in ${MOD_DEST_PATH}/${MOD}/" | tee -a ${LOGFILE}
  echo "maybe you need to configure and activate/deactivate specific vehicles (e.g. the warplane/tank/assault_walker stuff)"  | tee -a ${LOGFILE}
fi

if [[ $DO_INSTALL_MOD_MOB_REDO == "TRUE" ]]
then
  MOD="mob_redo"
  echo "installing first ${MOB} and then some animals/monsters submods," | tee -a ${LOGFILE}
  echo "see https://forum.minetest.net/viewtopic.php?f=11&t=9917" | tee -a ${LOGFILE}
  # provided only by git

  # cannot use assitiative arrays, because order is important: 1st mob_redo!
  SUB_MODS=( "mob_redo" "mobs_animal" "mobs_monster" "mobs_npc" "mob_horse" )
  GIT_REPOS=( "https://github.com/tenplus1/mobs_redo.git" \
		  "https://github.com/tenplus1/mobs_animal.git" \
		  "https://github.com/tenplus1/mobs_monster.git" \
		  "https://github.com/tenplus1/mobs_npc.git" \
		  "https://github.com/tenplus1/mob_horse.git" )
  for ((i=0;i<${#SUB_MODS[@]};++i)); do
      SUB_MOD=${SUB_MODS[i]}
      REPO=${GIT_REPOS[i]}
      printf "installing mod %s from %s\n" "${SUB_MOD}" "${GIT_REPOS}"
      if [[ -d ${MOD_DEST_PATH}/${SUB_MOD} ]]
      then
	  echo "${MOD_DEST_PATH}/${SUB_MOD} already exists, deleting old and reinstalling..."
	  rm -Rf "${MOD_DEST_PATH}/${SUB_MOD}"
      fi
      git clone ${REPO}  ${MOD_DEST_PATH}/${SUB_MOD}
  done
  echo "maybe you need to configure some mobs in the relevant init.lua file..." | tee -a ${LOGFILE}
  echo "(I like to make all mobs (esp. horse) *much* rarer, factor 20-100)"  | tee -a ${LOGFILE}
fi
  
# 3d armor is probably comflicting with wardrobe?
if [[ $DO_INSTALL_MOD_3D_ARMOR == "TRUE" ]]
then
  MOD="3d_armor"
  echo "installing mod ${MOD}" | tee -a ${LOGFILE}
  # for simplicity provided only via git

  if [[ -d ${MOD_DEST_PATH}/${MOD} ]]
  then
      echo "${MOD_DEST_PATH}/${MOD} already exists, deleting old and reinstalling..."
      rm -Rf "${MOD_DEST_PATH}/${MOD}"
  fi

  git clone https://github.com/stujones11/minetest-3d_armor.git ${MOD_DEST_PATH}/${MOD}

  echo "Mod 3d_armor should now be in ${MOD_DEST_PATH}/${MOD}/" | tee -a ${LOGFILE}
  echo "see  https://forum.minetest.net/viewtopic.php?f=11&t=4654 "  | tee -a ${LOGFILE}
fi
  
# todo add more mods?
  
# farming redo already is part of deambuilder pack https://forum.minetest.net/viewtopic.php?f=11&t=90194
# maybe also some stuff like not so simple mobs, or survival mode stuff (hunger etc)
  
  

  
###########################################
# old stuff, kept for no good reason but to have em in mind...
###########################################


#= System wide =
#not sure if I wnana use it... because of the different folders...

#= In Local Folder =

# error with leveldb! Just leave it. 
# If you once tried to compile with leveldb, you then have to remove all stuff inside build/ - it just won't accept the -DENABLE_LEVELDB=0

# cmake .. -DRUN_IN_PLACE=1 -DCMAKE_BUILD_TYPE=Release -DENABLE_GETTEXT=1 -DENABLE_FREETYPE=1  -DBUILD_CLIENT=1 -DBUILD_SERVER=1 -DENABLE_CURL=1  -DENABLE_GLES=1 -DENABLE_LEVELDB=1 -DENABLE_REDIS=1 -DENABLE_SOUND=1

#cmake .. -DRUN_IN_PLACE=1 -DCMAKE_BUILD_TYPE=Release -DENABLE_GETTEXT=1 -DENABLE_FREETYPE=1  -DBUILD_CLIENT=1 -DBUILD_SERVER=1 -DENABLE_CURL=1  -DENABLE_GLES=1 -DENABLE_LEVELDB=1 -DENABLE_REDIS=1 -DENABLE_SOUND=1

#cmake -j4

