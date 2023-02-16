







az ad sp create-for-rbac --name "Tme_SPN" --role "Contributor" --scopes /subscriptions/4f32bf2b-63b7-4905-89b6-eef631e52a18 --sdk-aut -o jsonc

{
  "clientId": "f2447e7f-542a-4446-b936-5bfe40702403",
  "clientSecret": "FKb8Q~LwM_P1bBChfZp.ZtfLDmym-yiDkuvM~akh",
  "subscriptionId": "4f32bf2b-63b7-4905-89b6-eef631e52a18",
  "tenantId": "4c953047-dc2c-45a1-a0e2-fa113c905fe6",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}


