#!/bin/bash
#
# install a skill from GitHub.
#
SKILLS_DIR=$1
SKILL_URL=$2

cd $SKILLS_DIR

echo "Installing skill from $SKILL_URL"
echo "to $SKILLS_DIR"

git clone $SKILL_URL

echo "Skill installed."
echo "Have a look into the config.ini file to configure the skill."
exit 0