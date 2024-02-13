# Estimate the committers that would be added to the customer's usage if Advanced Security was enabled for this organization.
ADO_ORGANIZATION="returngisorg"
ADO_PERSONAL_ACCESS_TOKEN=$1

# Org Meter Usage Estimate
curl -u :$ADO_PERSONAL_ACCESS_TOKEN -X GET \
-H "Accept: application/json" \
"https://advsec.dev.azure.com/$ADO_ORGANIZATION/_apis/management/meterUsageEstimate?api-version=7.2-preview.1"

# Get the list of projects in the organization
curl -u :$ADO_PERSONAL_ACCESS_TOKEN -X GET \
-H "Accept: application/json" \
"https://dev.azure.com/$ADO_ORGANIZATION/_apis/projects?api-version=7.1-preview.1" > projects.json

# Create a list with the project names and ids
PROJECTS=$(echo $PROJECTS_RAW | jq -r '.value[] | "\(.name)=\(.id)"')

# Print how many projects you have in the organization
echo "You have $(echo "$PROJECTS_RAW" | jq '.value | length') projects in your organization"

# Add a newline character between projects
echo -e "$PROJECTS" | tr ' ' '\n'

# Iterate over the projects and get the meter usage estimate for each one
jq -c '.value[]' projects.json  | while read i; do

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
    "https://advsec.dev.azure.com/$ADO_ORGANIZATION/_apis/management/meterUsageEstimate?api-version=7.2-preview.1&projectIds=$PROJECT_ID" | jq '.count')

    echo "-----------------------------------"

done

# Get the repos for each project

jq -c '.value[]' projects.json  | while read i; do

    # Get the project name and id
    PROJECT_NAME=$(echo $i | jq -r '.name')
    PROJECT_ID=$(echo $i | jq -r '.id')

    # Print the project name and id
    echo "Project Name: $PROJECT_NAME"
    echo "Project ID: $PROJECT_ID"

    # Get the repos for the project
    curl -u :$ADO_PERSONAL_ACCESS_TOKEN -X GET \
    -s \
    -H "Accept: application/json" \
    "https://dev.azure.com/$ADO_ORGANIZATION/_apis/git/repositories?api-version=7.1-preview.1&project=$PROJECT_ID" > repos.json

    # Create a list with the repo names and ids
    REPOS=$(jq -r '.value[] | "\(.name)=\(.id)"' repos.json)

    # Print how many repos you have in the project
    echo "You have $(jq '.value | length' repos.json) repos in your project"

    # Add a newline character between repos
    echo -e "$REPOS" | tr ' ' '\n'

    # Iterate over the repos and get the meter usage estimate for each one
    jq -c '.value[]' repos.json  | while read i; do

        # Get the repo name and id
        REPO_NAME=$(echo $i | jq -r '.name')
        REPO_ID=$(echo $i | jq -r '.id')

        # Print the repo name and id
        echo "Repo Name: $REPO_NAME"
        echo "Repo ID: $REPO_ID"

        # Get the meter usage estimate for the repo
        echo "Active Commiters: " $(curl -u :$ADO_PERSONAL_ACCESS_TOKEN -X GET \
        -s \
        -H "Accept: application/json" \
        "https://advsec.dev.azure.com/$ADO_ORGANIZATION/_apis/management/meterUsageEstimate?api-version=7.2-preview.1&projectIds=$PROJECT_ID&repositoryIds=$REPO_ID" | jq '.count')

        echo "-----------------------------------"

    done

done
