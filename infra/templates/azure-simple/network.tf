locals {
  tm_profile_name            = "${var.name}-tf"
  vnet_name                  = "${var.name}-vnet"
  tm_endpoint_name           = "${var.resource_group_location}_${var.name}"
  tm_dns_name                = "${var.name}-dns"
  appgateway_name            = "${var.name}-gateway"
  public_pip_name            = "${var.name}-ip"
}

module "vnet" {
  source                   = "github.com/Microsoft/bedrock/cluster/azure/vnet"
  vnet_name                = "${local.vnet_name}"
  address_space            = "${var.address_space}"
  resource_group_name      = "${azurerm_resource_group.svcplan.name}"
  resource_group_location  = "${azurerm_resource_group.svcplan.location}"
  subnet_names             = ["${var.subnet_names}"]
  subnet_prefixes          = ["${var.subnet_prefixes}"]
  subnet_service_endpoints = "${var.subnet_service_endpoints}"
}

module "traffic_manager_profile" {
  source                       = "../../modules/providers/azure/tm-profile"
  resource_group_name          = "${azurerm_resource_group.svcplan.name}"
  resource_group_location      = "${azurerm_resource_group.svcplan.location}"
  traffic_manager_profile_name = "${local.tm_profile_name}"
  traffic_manager_dns_name     = "${local.tm_dns_name}"
}

module "traffic_manager_endpoint" {
  source                              = "../../modules/providers/azure/tm-endpoint-ip"
  resource_group_name                 = "${azurerm_resource_group.svcplan.name}"
  traffic_manager_profile_name        = "${local.tm_profile_name}"
  public_ip_name                      = "${local.public_pip_name}"
  endpoint_name                       = "${local.tm_endpoint_name}"
}

module "app_gateway" {
  source                        = "../../modules/providers/azure/app-gateway"
  appgateway_name               = "${local.appgateway_name}"
  resource_group_name           = "${azurerm_resource_group.svcplan.name}"
  appgateway_frontend_port_name = "${var.appgateway_frontend_port_name}"
  virtual_network_name          = "${module.vnet.vnet_name}"
  public_pip_id                 = "${module.traffic_manager_endpoint.public_pip_id}"
  backend_http_protocol         = "${var.appgateway_backend_http_protocol}"
  http_listener_protocol        = "${var.appgateway_http_listener_protocol}"
  subnet_name                   = "${var.subnet_names[0]}"
  backendpool_fqdns             = "${module.app_service.app_service_uri}"
}