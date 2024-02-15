#!/bin/bash
################################################################################
#                              scriptTemplate                                  #
#                                                                              #
# The purpose of this script is to centrally obtain the active committers that #
# an Azure DevOps organization has in order to evaluate the cost of GHAzDO.    #
#                                                                              #
# Change History                                                               #
# 02/15/2024  Gisela Torres    First version of the script only for GHAzDo     #
#                                                                              #
#                                                                              #
################################################################################
################################################################################
################################################################################
#                                                                              #
#  Copyright (C) 2024       Gisela Torres                                      #
#  gisela.torres@returngis.net                                                 #
#                                                                              #
#  This program is free software; you can redistribute it and/or modify        #
#  it under the terms of the GNU General Public License as published by        #
#  the Free Software Foundation; either version 2 of the License, or           #
#  (at your option) any later version.                                         #
#                                                                              #
#  This program is distributed in the hope that it will be useful,             #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of              #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
#  GNU General Public License for more details.                                #
#                                                                              #
#  You should have received a copy of the GNU General Public License           #
#  along with this program; if not, write to the Free Software                 #
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA   #
#                                                                              #
################################################################################
################################################################################
################################################################################

set -e

############################ Functions ##########################################

function check_if_gum_is_installed() {
    if ! command -v gum &> /dev/null && [ ! -f "/home/linuxbrew/.linuxbrew/bin/gum" ] > /dev/null 2>&1
    then
        echo "gum could not be found"
        echo "Installing gum..."
        brew install gum    
    fi
}

function check_if_required_variables_are_set() {
    # Check if this variables are already set in the .env file
    if [ -f .env ]; then
        export $(cat .env | xargs)
    fi

    # If the variables are not set, ask for them

    if [ -z "$PAT" ]; then
        
        gum style \
        --foreground 212 --border-foreground 212 \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        'Please provide the following information:'

        # Required parameters
        ORG_NAME=$(gum input --header="Enter your Azure DevOps Organization Name" )
        PAT=$(gum input --header="Enter your Personal Access Token" --password)    

        # Save the info in an .env file
        echo "PAT=$PAT" > .env
        echo "ORG_NAME=$ORG_NAME" >> .env
    fi

}

############################ Variables ##########################################

############################ Main ###############################################

check_if_gum_is_installed
check_if_required_variables_are_set

gum style \
	--foreground 212 --border-foreground 212 --border double \
	--align center --width 50 --margin "1 2" --padding "2 4" \
	'Welcome to GHAzDO investigation!' 'Check the active committers in your Azure DevOps organization, project or repository.'

gum style \
    --foreground 212 --border-foreground 212 \
    --align center --width 50 --margin "1 2" --padding "2 4" \
     "At which level do you want to get the active committers?"

CHOICE=$(gum choose "Organization" "Project" "Repository")

if [ "$CHOICE" = "Organization" ]; then
    gum format --theme="pink" "You chose **Organization** 🏢"

    # Org Meter Usage Estimate
    COUNT=$(gum spin --spinner line --title "Investigating $ORG_NAME..." --show-output -- curl -u :$PAT -X GET \
            -s \
            -H "Accept: application/json" \
            "https://advsec.dev.azure.com/$ORG_NAME/_apis/management/meterUsageEstimate?api-version=7.2-preview.1" | jq '.count')
    
    gum format --theme="pink" "You have **$COUNT active committers** 🎉 in **$ORG_NAME**"

elif [ "$CHOICE" = "Project" ]; then
    
    gum format --theme="pink" "You chose **Project** 📁"

    # Get the list of projects in the organization
    PROJECTS=$(gum spin --spinner dot --title "Getting projects in $ORG_NAME..." --show-output -- curl -u :$PAT -X GET \
            -H "Accept: application/json" \
            "https://dev.azure.com/$ORG_NAME/_apis/projects?api-version=7.1-preview.1" | jq '.')


    # Print how many projects you have in the organization
    gum format --theme="pink"  "You have **$(echo $PROJECTS | jq '.count') projects** ✨ in **$ORG_NAME**"
    
    echo "Project Id, Project Name, Active Commiters" > projects_active_commiters.csv

    # Iterate over the projects and get the meter usage estimate for each one
    echo $PROJECTS | jq -c '.value[]'   | while read i; do        

        # Get the project name and id
        PROJECT_NAME=$(echo $i | jq -r '.name')
        PROJECT_ID=$(echo $i | jq -r '.id')
        
        gum log "📊 Getting meter usage estimate for $PROJECT_NAME..."

        # Get the meter usage estimate for the project
        ACTIVE_COMMITTERS=$(curl -u :$PAT -X GET \
        -s \
        -H "Accept: application/json" \
        "https://advsec.dev.azure.com/$ORG_NAME/_apis/management/meterUsageEstimate?api-version=7.2-preview.1&projectIds=$PROJECT_ID" | jq '.count')

        # Create a temp file to store the data using Project Id, Project Name, Active Commiters format        
        echo "$PROJECT_ID, $PROJECT_NAME, $ACTIVE_COMMITTERS" >> projects_active_commiters.csv
    done

    clear
    gum table < projects_active_commiters.csv -w 40,40,20 --height 20 --print --border.foreground 99 --header.foreground 212 | cut -d ',' -f 1

else
    gum format --theme="pink" "You chose **Repository** 📁"

    # Get the list of projects in the organization
    PROJECTS=$(gum spin --spinner dot --title "Getting projects in $ORG_NAME..." --show-output -- curl -u :$PAT -X GET \
            -H "Accept: application/json" \
            "https://dev.azure.com/$ORG_NAME/_apis/projects?api-version=7.1-preview.1" | jq '.')
    
    echo "Project Id, Project Name" > projects.csv

    gum format --theme="pink"  "Getting projects in **$ORG_NAME**"

    echo $PROJECTS | jq -c '.value[]'   | while read i; do

        # Get the project name and id
        PROJECT_NAME=$(echo $i | jq -r '.name')
        PROJECT_ID=$(echo $i | jq -r '.id')
        # # Get the meter usage estimate for the project
        # ACTIVE_COMMITTERS=$(curl -u :$PAT -X GET \
        # -s \
        # -H "Accept: application/json" \
        # "https://advsec.dev.azure.com/$ORG_NAME/_apis/management/meterUsageEstimate?api-version=7.2-preview.1&projectIds=$PROJECT_ID" | jq '.count')

        # Create a temp file to store the data using Project Id, Project Name, Active Commiters format        
        echo "$PROJECT_ID, $PROJECT_NAME" >> projects.csv
    done

    gum format --theme="pink" "👇🏻 Please **choose a project** to get the active committers for its repositories"
    PROJECT_ID=$(gum table < projects.csv -w 40,40,20 --height 20 | cut -d ',' -f 1)

    # echo "Project ID chosen: $PROJECT_ID"

    PROJECT_NAME=$(gum spin --spinner dot --title "Getting projects info..." --show-output -- curl -u :$PAT -X GET \
            -H "Accept: application/json" \
            "https://dev.azure.com/$ORG_NAME/_apis/projects/$PROJECT_ID?api-version=7.1-preview.4" | jq -r '.name')

    
    gum format --theme="pink" "You chose **$PROJECT_NAME** 📁"
    echo "Repo Id, Name, Active Commiters" > "${PROJECT_ID}_active_commiters_by_repo.csv"

    # Get the list of repositories in the project
   REPOS=$(gum spin --spinner dot --title "Getting repositories..." --show-output -- curl -u :$PAT -X GET \
            -H "Accept: application/json" \
            "https://dev.azure.com/$ORG_NAME/$PROJECT_ID/_apis/git/repositories/?api-version=4.1" | jq '.')

    
    gum format --theme="pink" "You have $(echo "$REPOS" | jq '.count') repositories ✨ in **$PROJECT_NAME**"    
    
    # Iterate over the repositories and get the meter usage estimate for each one
    echo $REPOS | jq -c '.value[]'   | while read i; do

        # Get the repository name and id
        REPO_NAME=$(echo $i | jq -r '.name')
        REPO_ID=$(echo $i | jq -r '.id')

        gum log "📊 Getting meter usage estimate for $REPO_NAME..."

        # Get the meter usage estimate for the repository
        ACTIVE_COMMITTERS=$(curl -u :$PAT -X GET \
        -s \
        -H "Accept: application/json" \
        "https://advsec.dev.azure.com/$ORG_NAME/_apis/management/meterUsageEstimate?api-version=7.2-preview.1&projectIds=$PROJECT_ID&repositoryIds=$REPO_ID" | jq '.count')

        # Create a temp file to store the data using Repository Id, Repository Name, Active Commiters format        
        echo "$REPO_ID, $REPO_NAME, $ACTIVE_COMMITTERS" >> "${PROJECT_ID}_active_commiters_by_repo.csv"
    done

    gum table < "${PROJECT_ID}_active_commiters_by_repo.csv" -w 40,40,20 --height 20 --print --border.foreground 99 --header.foreground 212 | cut -d ',' -f 1

fi