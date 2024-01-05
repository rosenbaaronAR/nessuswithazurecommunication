### This resource retrieves the current azurerm subscription ###
data "azurerm_subscription" "primary" {
}

### This resource retrieves the current azuread subscription ###

data "azuread_client_config" "current" {}

### My subscription required me to register a Microsoft.Communication provider ###
/*
resource "azurerm_resource_provider_registration" "aecs" {

  name = "Microsoft.Communication"

}
*/

## 1. deploy azure communication and azure email communication services services ##

resource "azurerm_communication_service" "acs" {

  name                = "nessustest-acs"
  resource_group_name = azurerm_resource_group.rg.name
  data_location       = "United States" 

}


resource "azurerm_email_communication_service" "aecs" {

  name                = "nessustest-aecs"
  data_location       = "United States"
  resource_group_name = azurerm_resource_group.rg.name

}

/*

resource "azapi_resource" "domains" {

    type = "Microsoft.Communication/emailServices/domains@2023-06-01-preview"
    name = "nessustestdomains"
    location = "global"
    parent_id = azurerm_email_communication_service.aecs.id
    body = jsonencode({
        properties = {
            domainManagement ="AzureManagedDomain"
            userEngagementTracking = "Disabled"
        }
    })
  
}
*/

## 2. Create custom role ###





resource "azurerm_role_definition" "aecs" {

  name        = "nessustest-emailsending"
  scope       = data.azurerm_subscription.primary.id
  description = " This role is a custom role to send email"
  permissions {
    actions = ["Microsoft.Communication/CommunicationServices/Read", "Microsoft.Communication/CommunicationServices/Write", "Microsoft.Communication/EmailServices/Write"]
  }
}


## 3. Create an entra application

resource "azuread_application" "aecs" {

  display_name = "nessustest-smtpauth"
}
## 4. Assign the role assignment ###

resource "azuread_service_principal" "aecs" {

  client_id = azuread_application.aecs.client_id




}

### Creating a new service principal only ###

resource "azuread_service_principal_password" "aecs" {

  service_principal_id = azuread_service_principal.aecs.id

}


resource "azurerm_role_assignment" "aecs" {
  scope                            = data.azurerm_subscription.primary.id
  role_definition_name             = azurerm_role_definition.aecs.name
  skip_service_principal_aad_check = true
  principal_id                     = azuread_service_principal.aecs.object_id

}

## 5. Create Certificate and Secret to be used ## 

resource "azuread_application_password" "aecs" {

  application_id = azuread_application.aecs.id

}
### The output section

output "azuread_application_password" {

  value     = azuread_application_password.aecs.value
  sensitive = true

}

output "client_id" {
  value = azuread_application.aecs.client_id
}

output "tenant_id" {

  value = data.azuread_client_config.current.tenant_id

}