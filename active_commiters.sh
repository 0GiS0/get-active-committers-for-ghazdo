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
    
    echo "Project Id, Project Name, Active Commiters" > active_commiters.csv

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

    gum table < active_commiters.csv -w 40,40,20 --height 20 | cut -d ',' -f 1

else
    echo "You chose Repository"
fi