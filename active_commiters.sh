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

ADO_PERSONAL_ACCESS_TOKEN="4g4uyxx2byevtovmpjoccqijg7ay4vj73rbpys7ldk2fd4pbhrga"

echo "At which level do you want to get the active commiters?"
CHOICE=$(gum choose "Organization" "Project" "Repository")

if [ "$CHOICE" = "Organization" ]; then
    echo "You chose Organization"

    ORG_NAME=$(gum input --placeholder="Enter your Azure DevOps Organization Name" --value="returngisorg")

    # Org Meter Usage Estimate
    COUNT=$(gum spin --spinner dot --title "Investigating..." --show-output -- curl -u :$ADO_PERSONAL_ACCESS_TOKEN -X GET \
            -s \
            -H "Accept: application/json" \
            "https://advsec.dev.azure.com/$ORG_NAME/_apis/management/meterUsageEstimate?api-version=7.2-preview.1" | jq '.count')

    echo "Active Commiters for $ORG_NAME: $COUNT"

elif [ "$CHOICE" = "Project" ]; then
    
    echo "You chose Project"
    ORG_NAME=$(gum input --placeholder="Enter your Azure DevOps Organization Name" --value="returngisorg")

    # Get the list of projects in the organization
    PROJECTS=$(gum spin --spinner dot --title "Investigating..." --show-output -- curl -u :$ADO_PERSONAL_ACCESS_TOKEN -X GET \
            -H "Accept: application/json" \
            "https://dev.azure.com/$ORG_NAME/_apis/projects?api-version=7.1-preview.1" | jq '.')


    # Print how many projects you have in the organization
    echo "You have $(echo "$PROJECTS" | jq '.count') projects ✨ in your organization"
    
    # Iterate over the projects and get the meter usage estimate for each one
    echo $PROJECTS | jq -c '.value[]'   | while read i; do

        echo "-----------------------------------"
        # echo $i 
        # echo "-----------------------------------"
        

        # Get the project name and id
        PROJECT_NAME=$(echo $i | jq -r '.name')
        PROJECT_ID=$(echo $i | jq -r '.id')

        # Print the project name and id
        echo "Project Name: $PROJECT_NAME"
        echo "Project ID: $PROJECT_ID"        

        # Get the meter usage estimate for the project
        echo "Active Commiters: " $(curl -u :$ADO_PERSONAL_ACCESS_TOKEN -X GET \
        -s \
        -H "Accept: application/json" \
        "https://advsec.dev.azure.com/$ORG_NAME/_apis/management/meterUsageEstimate?api-version=7.2-preview.1&projectIds=$PROJECT_ID" | jq '.count')

        echo "-----------------------------------"

    done

else
    echo "You chose Repository"
fi

# PAT=$(gum input --placeholder="Enter your Azure DevOps Personal Access Token" --password)