#!/bin/bash

# Example API request
# curl -X GET "$INVOKE_URL/resource-path"

# Method 1 (Hard coding)
# INVOKE_URL=https://ap3xnb99u4.execute-api.us-east-1.amazonaws.com

# Method 2 (API GW URL)
# Fetch invoke_url from the terraform codes
# INVOKE_URL=$(terraform output -raw invoke_url)
# echo "Using API Gateway URL: $INVOKE_URL"

# Method 3 (User Friendly URL)
INVOKE_URL=$(terraform output -raw dns)
echo "Using friendly URL for the API Gateway: $INVOKE_URL"

# add movies
echo "> add movies"
for i in $(seq 2001 2003); do
    json="$(jq -n --arg year "$i" --arg title "MovieTitle$i" '{year: $year, title: $title}')"
    curl \
        -X PUT \
        -H "Content-Type: application/json" \
        -d "$json" \
        "$INVOKE_URL/topmovies";
    echo
done

# get movies by year
echo "> get movies by year"
for i in $(seq 2001 2003); do
    curl "$INVOKE_URL/topmovies/$i"
    echo
done

# delete movie
echo "> delete movie from 2002"
curl -X DELETE "$INVOKE_URL/topmovies/2002"
echo

# get movies
echo "> get movies"
curl "$INVOKE_URL/topmovies"
