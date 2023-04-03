#!/bin/bash 
#
# Script to generate a new skill for the HermesMQTT.jl framework
# from the template.
#
SKILL="$1"
PACKAGE="$2"
DIR="$3"
  
SKILL="$(echo $SKILL | sed 's/[^a-zA-Z0-9]/_/g')" # remove special chars
DIR="$(echo $DIR | sed 's/\/$//')" # remove trailing slash

clean_chars() {
    echo "$@" | sed 's/[^a-zA-Z0-9 ]/_/g'
}

echo "HermesMQTT (aka Susi) new skill generator

           Andreas Dominik, Feb. 2023

You will be asked to enter names of skill, intents
and slots.
Please be aware that 

Skill name
  will end up as a filename; it schould only contain
  allowed charaters (recommended: 'a-zA-Z0-9' and '_')

Intent names
  will end up as name of a julia function; although
  special charaters will be replaced by '_' they should be used
  with care. Names like 'Susi:RunIrrigation' are OK.

Slot names 
  are will end up as keys for dictionaries and should be
  easily readable in order to allow debugging. It is good practice
  to only have 'a-zA-Z' and _ in the names.
  
  "

echo "creating new skill: $SKILL"
echo "in directory:       $DIR"

# enter intent names:
#
INTENTS=()
echo " "
echo "Enter the names of the intents for this skill:"
echo "(leave empty when finished)"
read -p "Name of the first intent: " INTENT
INTENTS+=($INTENT)

DONE=0
while [[ $DONE -eq 0 ]] ; do
  read -p "Name of the next intent: " INTENT
  
  if [[ -z $INTENT ]] ; then
    DONE=1
  else
    INTENTS+=($INTENT)
  fi
done
INTENTS_CLEAN=()
for i in ${!INTENTS[@]} ; do
  INTENTS_CLEAN[$i]=$(clean_chars ${INTENTS[$i]})
done


# enter slot names for each intent:
#
echo " "
for i in ${!INTENTS[@]} ; do
  echo "Enter a space-separated lists of slot names for each intent:"
  echo "(leave empty if no slots are required)"
  read -p "Slots for intent: \"${INTENTS[$i]}\": " SLOTS

  SLOTS=$(clean_chars $SLOTS) # remove special chars
  SLOTS_NAME="${INTENTS_CLEAN[$i]}_SLOTS"
  declare "$SLOTS_NAME"="$SLOTS"
done

# make complete slot list:
#
ALL_SLOTS=""
for I in ${INTENTS_CLEAN[@]} ; do
  SLOTS_NAME="${I}_SLOTS"
  ALL_SLOTS="$ALL_SLOTS ${!SLOTS_NAME}"
done

# remove duplicate SLOTS:
ALL_SLOTS=($(echo $ALL_SLOTS | tr ' ' '\n' | sort -u | tr '\n' ' '))


# def directories:
#
BIN_DIR="$PACKAGE/bin"
HERMES_DIR="$PACKAGE"
TEMPLATE_DIR="$HERMES_DIR/Template"
SKILLS_DIR="$DIR"
SKILL_DIR="$SKILLS_DIR/$SKILL"

# ask:
#
echo " "
echo "Generate skill skeleton for skill $SKILL with"
echo "    Intents: ${INTENTS[@]}"
echo "    Slots:   ${ALL_SLOTS[@]}"

echo "The skill will be generated in the directory "
echo "$SKILL_DIR"

ASK="yes"
read -e -i $ASK -p "Continue? " ASK
if [[ $ASK != "yes" ]] ; then
    echo "Skill generation aborted!"
    exit 0
else
    echo "Generating skill!"
fi

# copy template files:
#
echo " "
echo "copy template files"
mkdir -p $SKILL_DIR
cp -r $TEMPLATE_DIR/Skill $SKILL_DIR/
cp $TEMPLATE_DIR/config.ini $SKILL_DIR/
cp $TEMPLATE_DIR/config.ini $SKILL_DIR/config.ini.template
cp $TEMPLATE_DIR/.gitignore $SKILL_DIR/
cp $TEMPLATE_DIR/LOADER-TEMPLATE_SKILL.jl $SKILL_DIR/loader-TEMPLATE_SKILL.jl

cp $TEMPLATE_DIR/README.md $SKILL_DIR/

cd $SKILL_DIR
TMPF="$(mktemp generate_skill.XXXXXX)"

# modify config.ini
#
echo "... generate config.ini"
mv config.ini $TMPF
cat $TMPF | sed "s/TEMPLATE_SKILL/$SKILL/g" > config.ini

# modify loader:
#
echo "... generate loader"
cat 'loader-TEMPLATE_SKILL.jl' | sed "s/TEMPLATE_SKILL/$SKILL/g" > loader-$SKILL.jl
rm loader-TEMPLATE_SKILL.jl

cd Skill

# modify Modul:
#
echo "... generate skill module"
cat 'TEMPLATE_SKILL.jl' | sed "s/TEMPLATE_SKILL/$SKILL/g" > ${SKILL}.jl
rm TEMPLATE_SKILL.jl

# add slotnames to config.jl:
#
echo "... generate action function skeleton"
SLOT_DEFS=""
for SLOT in ${ALL_SLOTS[@]} ; do
    SLOT_DEFS="${SLOT_DEFS}const SLOT_${SLOT^^} = \"${SLOT}\"\n"
done
mv config.jl $TMPF
cat $TMPF | sed "s/SLOT_NAMES/$SLOT_DEFS/" > config.jl

# register intents in config.jl:
#
for i in ${!INTENTS[@]} ; do
    REGISTER="register_intent_action(\"${INTENTS[$i]}\", ${INTENTS_CLEAN[$i]}_action)"
    echo $REGISTER >> config.jl
done

# add actions for each intent:
#

cat skill-actions-1-head.jl > skill-actions.jl

for i in ${!INTENTS[@]} ; do

    cat skill-actions-2-intent.jl | \
        sed "s/TEMPLATE_SKILL/${INTENTS_CLEAN[$i]}/g" | \
        sed "s/TEMPLATE_NAME_RAW/${INTENTS[$i]}/g"  >> skill-actions.jl

    SLOTS_NAME="${INTENTS_CLEAN[$i]}_SLOTS"

    if [[ -z ${!SLOTS_NAME} ]] ; then
        echo "publish_say(:no_slot)" >> skill-actions.jl
    else
        FUN_SLOTS=""
        for SLOT in ${!SLOTS_NAME} ; do
            SLOT_CONST="SLOT_${SLOT^^}"
            cat skill-actions-3-slots.jl | sed "s/SLOT_NAME/$SLOT_CONST/g" >> skill-actions.jl
        done
    fi

    cat skill-actions-4-foot.jl >> skill-actions.jl
done

# make profile dir and empty ini-files for en, fr, de:
# create ini-file name:
#
echo "... generate profile files"
mkdir -p profiles/en/intents
mkdir -p profiles/fr/intents
mkdir -p profiles/de/intents
mkdir -p profiles/en/slots
mkdir -p profiles/fr/slots
mkdir -p profiles/de/slots

INI_FILE_NAME="$(echo $SKILL | tr '[:upper:]' '[:lower:]').ini"
echo " " > profiles/en/intents/$INI_FILE_NAME
echo " " > profiles/fr/intents/$INI_FILE_NAME
echo " " > profiles/de/intents/$INI_FILE_NAME



# clean:
#
rm skill-actions-1-head.jl
rm skill-actions-2-intent.jl
rm skill-actions-3-slots.jl
rm skill-actions-4-foot.jl
rm -f $TMPF
rm -f ../$TMPF

echo ""
echo "New HermesMQTT skill $SKILL generated in $SKILL_DIR."
exit 0
