#!/usr/bin/env bash

# prerequisites: azure-cli, jq

source azure-config.env

echo "Creating Resource Group"
az group create \
    -n $RESOURCE_GROUP \
    --location $REGION >> /dev/null 


echo "Provisioning Batch Account"
az batch account create \
    -g $RESOURCE_GROUP \
    -n $BATCH_ACCOUNT \
    --location $REGION >> /dev/null

echo "Provisioning Storage Account"
storage_id=$(az storage account create \
    -g $RESOURCE_GROUP \
    -n $STORAGE_ACCOUNT \
    --location $REGION \
    --sku Standard_LRS  | jq -r .id)

echo "Logging in"
az batch account login \
    -g $RESOURCE_GROUP \
    -n $BATCH_ACCOUNT 

# identity to write into container 
echo "Assigning role to write into container"
az ad signed-in-user show --query id -o tsv | az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee @- \
    --scope $storage_id \
    >> /dev/null

echo "Assigning role to read from container"
az identity create \
    --resource-group $RESOURCE_GROUP \
    --name $IDENTITY \
    >> /dev/null

principal_id=$(az identity create \
    --resource-group $RESOURCE_GROUP \
    --name $IDENTITY | jq -r ".principalId")


identity_id=$(az identity create \
    --resource-group $RESOURCE_GROUP \
    --name $IDENTITY | jq -r ".id")

storage_scope=$(az storage account show \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP | jq -r ".id")


az role assignment create \
    --assignee $principal_id \
    --role "Storage Blob Data Contributor" \
    --scope $storage_scope \
    >> /dev/null
    



echo "Creating container"
az storage container create \
    --account-name $STORAGE_ACCOUNT \
    --name $CONTAINER_NAME \
    --auth-mode login \
    >> /dev/null


storage_key=$(az storage account keys list \
    --account-name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --query "[0].value" -o tsv)

sas=$(az storage container generate-sas \
    --account-name $STORAGE_ACCOUNT \
    --account-key $storage_key \
    --name $CONTAINER_NAME \
    --permissions lrw \
    --https-only \
    --expiry "$(date -u -d "2 days" '+%Y-%m-%dT%H:%MZ')" \
    -o tsv)




echo "Uploading corex-bin-boost-$NODE_ARCH.tar.gz"
az storage blob upload \
    --account-name $STORAGE_ACCOUNT \
    --container-name $CONTAINER_NAME \
    --name "corex-bin-boost-$NODE_ARCH.tar.gz" \
    --sas-token $sas \
    --file "./target/corex-bin-boost-$NODE_ARCH.tar.gz" \
    --overwrite
echo "Uploading corex.tar.gz"
az storage blob upload \
    --account-name $STORAGE_ACCOUNT \
    --container-name $CONTAINER_NAME \
    --name "corex.tar.gz" \
    --sas-token $sas \
    --file "./target/corex.tar.gz" \
    --overwrite

libs=$(az storage blob url \
    --account-name $STORAGE_ACCOUNT \
    --container-name $CONTAINER_NAME \
    --sas-token $sas \
    --name "corex-bin-boost-$NODE_ARCH.tar.gz"  | jq -r ".")


corex_files=$(az storage blob url \
    --account-name $STORAGE_ACCOUNT \
    --container-name $CONTAINER_NAME \
    --sas-token $sas \
    --name "corex.tar.gz"  | jq -r ".")


echo $sas > .AZURE_SAS






