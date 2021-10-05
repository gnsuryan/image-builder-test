identityName="imgBuilderIdentity"
imageResourceGroup="GNSURYAN_RG"
location="eastus"
subscriptionID=$(az account show --query id --output tsv)

az identity create --resource-group $imageResourceGroup --name $identityName

imgBuilderId=/subscriptions/$subscriptionID/resourcegroups/$imageResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$identityName

curl https://raw.githubusercontent.com/Azure/azvmimagebuilder/main/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json -o aibRoleImageCreation.json

imageRoleDefName="Azure Image Builder Image Def"$(date +'%s')

#replace placeholders in template
sed -i -e "s/<subscriptionID>/$subscriptionID/g" aibRoleImageCreation.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" aibRoleImageCreation.json
sed -i -e "s/Azure Image Builder Service Image Creation Role/$imageRoleDefName/g" aibRoleImageCreation.json

#create custom role
az role definition create --role-definition ./aibRoleImageCreation.json

#get user identity clientid
imgBuilderCliId=$(az identity show -g $imageResourceGroup -n $identityName --query clientId -o tsv)
imgBuilderObjId=$(az identity show -g $imageResourceGroup -n $identityName --query principalId -o tsv)


#assign owner role
az role assignment create --assignee-object-id "$imgBuilderObjId" --assignee-principal-type "ServicePrincipal" --role "owner"  --scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup

#assign custom role
az role assignment create --assignee-object-id "$imgBuilderObjId" --assignee-principal-type "ServicePrincipal" --role "$imageRoleDefName"  --scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup


curl https://raw.githubusercontent.com/Azure/azvmimagebuilder/main/quickquickstarts/0_Creating_a_Custom_Linux_Managed_Image/helloImageTemplateLinux.json -o helloImageTemplateLinux.json

    sed -i -e "s/<subscriptionID>/$subscriptionID/g" helloImageTemplateLinux.json
    sed -i -e "s/<rgName>/$imageResourceGroup/g" helloImageTemplateLinux.json
    sed -i -e "s/<region>/$location/g" helloImageTemplateLinux.json
    sed -i -e "s/<imageName>/$imageName/g" helloImageTemplateLinux.json
    sed -i -e "s/<runOutputName>/$runOutputName/g" helloImageTemplateLinux.json
    sed -i -e "s%<imgBuilderId>%$imgBuilderId%g" helloImageTemplateLinux.json

az resource create \
    --resource-group $imageResourceGroup \
    --properties @helloImageTemplateLinux.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplateLinux01

az resource invoke-action      --resource-group $imageResourceGroup      --resource-type  Microsoft.VirtualMachineImages/imageTemplates      -n helloImageTemplateLinux01      --action Run

az vm create \
  --resource-group $imageResourceGroup \
  --name aibImgVm0001 \
  --admin-username aibuser \
  --admin-password Weblogic@579 \
  --image $imageName \
  --location $location
  
