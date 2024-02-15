#!/bin/sh

set -e

# Check if gum is installed
if ! command -v gum &> /dev/null
then
    echo "gum could not be found"
    echo "Installing gum..."
    brew install gum    
fi

gum style \
	--foreground 212 --border-foreground 212 --border double \
	--align center --width 50 --margin "1 2" --padding "2 4" \
	'Welcome to GHAzDO investigation!' 'Check the active commiters in your Azure DevOps organization, project or repository.'

gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 50 --margin "1 2" --padding "2 4" \
    'Please provide the following information:'
PAT=$(gum input --placeholder="Enter your Azure DevOps Personal Access Token" --password --value="4g4uyxx2byevtovmpjoccqijg7ay4vj73rbpys7ldk2fd4pbhrga")
ORG_NAME=$(gum input --placeholder="Enter your Azure DevOps Organization Name" --value="returngisorg")

echo "At which level do you want to get the active commiters?"
CHOICE=$(gum choose "Organization" "Project" "Repository")

if [ "$CHOICE" = "Organization" ]; then
    echo "You chose Organization"

    # Org Meter Usage Estimate
    COUNT=$(gum spin --spinner dot --title "Investigating..." --show-output -- curl -u :$PAT -X GET \
            -s \
            -H "Accept: application/json" \
            "https://advsec.dev.azure.com/$ORG_NAME/_apis/management/meterUsageEstimate?api-version=7.2-preview.1" | jq '.count')

    echo "Active Commiters for $ORG_NAME: $COUNT"

elif [ "$CHOICE" = "Project" ]; then
    
    echo "You chose Project"
    ORG_NAME=$(gum input --placeholder="Enter your Azure DevOps Organization Name" --value="returngisorg")

    # Get the list of projects in the organization
    PROJECTS=$(gum spin --spinner dot --title "Investigating..." --show-output -- curl -u :$PAT -X GET \
            -H "Accept: application/json" \
            "https://dev.azure.com/$ORG_NAME/_apis/projects?api-version=7.1-preview.1" | jq '.')


    # Print how many projects you have in the organization
    echo "You have $(echo "$PROJECTS" | jq '.count') projects ✨ in your organization"
    
    echo "Project Id, Project Name, Active Commiters" > projects_active_commiters.csv

    # Iterate over the projects and get the meter usage estimate for each one
    echo $PROJECTS | jq -c '.value[]'   | while read i; do        

        # Get the project name and id
        PROJECT_NAME=$(echo $i | jq -r '.name')
        PROJECT_ID=$(echo $i | jq -r '.id')
        # Get the meter usage estimate for the project
        ACTIVE_COMMITTERS=$(curl -u :$PAT -X GET \
        -s \
        -H "Accept: application/json" \
        "https://advsec.dev.azure.com/$ORG_NAME/_apis/management/meterUsageEstimate?api-version=7.2-preview.1&projectIds=$PROJECT_ID" | jq '.count')

        # Create a temp file to store the data using Project Id, Project Name, Active Commiters format        
        echo "$PROJECT_ID, $PROJECT_NAME, $ACTIVE_COMMITTERS" >> active_commiters.csv
    done

    gum table < projects_active_commiters.csv -w 40,40,20 --height 20 | cut -d ',' -f 1

else
    echo "You chose Repository"

    # Get the list of projects in the organization
    PROJECTS=$(gum spin --spinner dot --title "Getting your projects..." --show-output -- curl -u :$PAT -X GET \
            -H "Accept: application/json" \
            "https://dev.azure.com/$ORG_NAME/_apis/projects?api-version=7.1-preview.1" | jq '.')
    
    echo "Project Id, Project Name, Active Commiters" > projects_active_commiters.csv

    echo $PROJECTS | jq -c '.value[]'   | while read i; do

        # Get the project name and id
        PROJECT_NAME=$(echo $i | jq -r '.name')
        PROJECT_ID=$(echo $i | jq -r '.id')
        # Get the meter usage estimate for the project
        ACTIVE_COMMITTERS=$(curl -u :$PAT -X GET \
        -s \
        -H "Accept: application/json" \
        "https://advsec.dev.azure.com/$ORG_NAME/_apis/management/meterUsageEstimate?api-version=7.2-preview.1&projectIds=$PROJECT_ID" | jq '.count')

        # Create a temp file to store the data using Project Id, Project Name, Active Commiters format        
        echo "$PROJECT_ID, $PROJECT_NAME, $ACTIVE_COMMITTERS" >> projects_active_commiters.csv
    done

    PROJECT_ID=$(gum table < projects_active_commiters.csv -w 40,40,20 --height 20 | cut -d ',' -f 1)

    echo "Project ID chosen: $PROJECT_ID"

    PROJECT_NAME=$(gum spin --spinner dot --title "Getting projects info..." --show-output -- curl -u :$PAT -X GET \
            -H "Accept: application/json" \
            "https://dev.azure.com/$ORG_NAME/_apis/projects/$PROJECT_ID?api-version=7.1-preview.4" | jq -r '.name')

    echo "Project Name chosen: $PROJECT_NAME"

    echo "Repo Id, Name, Active Commiters" > "${PROJECT_ID}_active_commiters_by_repo.csv"

    # Get the list of repositories in the project
   REPOS=$(gum spin --spinner dot --title "Getting repositories..." --show-output -- curl -u :$PAT -X GET \
            -H "Accept: application/json" \
            "https://dev.azure.com/$ORG_NAME/$PROJECT_ID/_apis/git/repositories/?api-version=4.1" | jq '.')

    # echo $REPOS

    echo "You have $(echo "$REPOS" | jq '.count') repositories ✨ in your project"

    # echo "Repository Id, Repository Name, Active Commiters" > repo_active_commiters.csv

    # Iterate over the repositories and get the meter usage estimate for each one
    echo $REPOS | jq -c '.value[]'   | while read i; do

        # Get the repository name and id
        REPO_NAME=$(echo $i | jq -r '.name')
        REPO_ID=$(echo $i | jq -r '.id')
        # Get the meter usage estimate for the repository
        ACTIVE_COMMITTERS=$(curl -u :$PAT -X GET \
        -s \
        -H "Accept: application/json" \
        "https://advsec.dev.azure.com/$ORG_NAME/_apis/management/meterUsageEstimate?api-version=7.2-preview.1&projectIds=$PROJECT_ID&repositoryIds=$REPO_ID" | jq '.count')

        # Create a temp file to store the data using Repository Id, Repository Name, Active Commiters format        
        echo "$REPO_ID, $REPO_NAME, $ACTIVE_COMMITTERS" >> "${PROJECT_ID}_active_commiters_by_repo.csv"
    done

    gum table < "${PROJECT_ID}_active_commiters_by_repo.csv" -w 40,40,20 --height 20 | cut -d ',' -f 1

fi