#!/bin/bash 
#
# Script to generate a new skill for the HermesMQTT.jl framework
# from the template.
#
TMPF=tempfile

read -p "Enter the name of the new skill: " SKILL

# enter intent names:
#
INTENTS=""
echo " "
echo "Enter the names of the intents for this skill:"
echo "(leave empty whne finished)"
read -p "Name of the first intent: " INTENT
INTENTS="$INTENTS $INTENT"

DONE=0
while [[ $DONE -eq 0 ]] ; do
  read -p "Name of the next intent: " INTENT
  
  if [[ -z $INTENT ]] ; then
    DONE=1
  else
    INTENTS="$INTENTS $INTENT"
  fi
done

# enter slot names for each intent:
#
echo " "
for INTENT in $INTENTS ; do
  echo "Enter a space-separated lists of slot names for each intent:"
  echo "(leave empty if no slots are required)"
  read -p "Slots for intent: \"$INTENT\": " SLOTS

  INTENT_CLEAN="$(echo $INTENT | sed 's/[\.-\+:;,\!\?<>]/_/g')"
  SLOTS_NAME="${INTENT_CLEAN}_SLOTS"
  declare "$SLOTS_NAME"="$SLOTS"
  # echo ${!SLOTS_NAME}
done

# make complete slot list:
#
ALL_SLOTS=""
for INTENT in $INTENTS ; do
  INTENT_CLEAN="$(echo $INTENT | sed 's/[\.-\+:;,\!\?]/_/g')"
  SLOTS_NAME="${INTENT_CLEAN}_SLOTS"
  ALL_SLOTS="$ALL_SLOTS ${!SLOTS_NAME}"
done

# for INTENT in $INTENTS ; do
#   echo "slots for $INTENT:"
#   SLOTS_NAME="${INTENT}_SLOTS"
#   echo "  ${!SLOTS_NAME}"
# done
# echo $ALL_SLOTS

# def directories:
#
BIN_THIS="$(realpath -- $BASH_SOURCE)"
BIN_DIR="$(dirname -- $BIN_THIS)"
HERMES_DIR="$(dirname -- $BIN_DIR)"
TEMPLATE_DIR="$HERMES_DIR/Template"
APPS_DIR="$(dirname -- $HERMES_DIR)"
SKILL_DIR=$APPS_DIR/$SKILL

# ask:
#
echo " "
echo "Generate skill skeleton for skill $SKILL with"
echo "    Intents: $INTENTS"
echo "    Slots:   $ALL_SLOTS"

echo "The skill will be generate in the directory $SKILL_DIR"

ASK="yes"
read -e -i $ASK -p "Continue? " ASK
if [[ $ASK != "yes" ]] ; then
    echo "Skill generation aborted!"
    exit 1
else
    echo "Generating skill!"
fi

# copy template files:
#
mkdir -p $SKILL_DIR
cp -r $TEMPLATE_DIR/Skill $SKILL_DIR/
cp $TEMPLATE_DIR/config.ini $SKILL_DIR/
cp $TEMPLATE_DIR/LOADER-TEMPLATE_SKILL.jl $SKILL_DIR/loader-TEMPLATE_SKILL.jl

cp $TEMPLATE_DIR/README.md $SKILL_DIR/

cd $SKILL_DIR

# modify config.ini
#
mv config.ini $TMPF
cat $TMPF | sed "s/TEMPLATE_SKILL/$SKILL/g" > config.ini

# modify loader:
#
cat 'loader-TEMPLATE_SKILL.jl' | sed "s/TEMPLATE_SKILL/$SKILL/g" > loader-$SKILL.jl
rm loader-TEMPLATE_SKILL.jl

cd Skill

# modify Modul:
#
cat 'TEMPLATE_SKILL.jl' | sed "s/TEMPLATE_SKILL/$SKILL/g" > ${SKILL}.jl
rm TEMPLATE_SKILL.jl

# add slotnames to config.jl:
#
SLOT_DEFS=""
for SLOT in $ALL_SLOTS ; do
    SLOT_DEFS="${SLOT_DEFS}const SLOT_${SLOT^^} = \"${SLOT}\"\n"
done
mv config.jl $TMPF
cat $TMPF | sed "s/SLOT_NAMES/$SLOT_DEFS/" > config.jl

# register intents in config.jl:
#
for INTENT in $INTENTS ; do
    INTENT_CLEAN="$(echo $INTENT | sed 's/[\.-\+:;,\!\?]/_/g')"
    REGISTER="Susi.register_intent_action(\"$INTENT\", ${INTENT_CLEAN}_action)"
    echo $REGISTER >> config.jl
done

# add actions for each intent:
#

cat skill-actions-1-head.jl > skill-actions.jl

for INTENT in $INTENTS ; do

    INTENT_CLEAN="$(echo $INTENT | sed 's/[\.-\+:;,\!\?]/_/g')"
    cat skill-actions-2-intent.jl | \
        sed "s/TEMPLATE_SKILL/$INTENT_CLEAN/g" | \
        sed "s/TEMPLATE_NAME_RAW/$INTENT/g"  >> skill-actions.jl

    SLOTS_NAME="${INTENT_CLEAN}_SLOTS"

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

# clean:
#
rm skill-actions-1-head.jl
rm skill-actions-2-intent.jl
rm skill-actions-3-slots.jl
rm skill-actions-4-foot.jl

