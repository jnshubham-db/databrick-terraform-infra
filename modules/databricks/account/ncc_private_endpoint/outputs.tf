output "rule_id" {
  description = "The ID of the private endpoint rule"
  value       = try(databricks_mws_ncc_private_endpoint_rule.this[0].rule_id, null)
}

output "endpoint_name" {
  description = "The name of the Azure private endpoint resource"
  value       = try(databricks_mws_ncc_private_endpoint_rule.this[0].endpoint_name, null)
}

output "connection_state" {
  description = "The current status of this private endpoint"
  value       = try(databricks_mws_ncc_private_endpoint_rule.this[0].connection_state, null)
}

output "deactivated" {
  description = "Whether this private endpoint is deactivated"
  value       = try(databricks_mws_ncc_private_endpoint_rule.this[0].deactivated, null)
}

output "creation_time" {
  description = "Time in epoch milliseconds when this object was created"
  value       = try(databricks_mws_ncc_private_endpoint_rule.this[0].creation_time, null)
}

output "vpc_endpoint_id" {
  description = "The AWS VPC endpoint ID (AWS only)"
  value       = try(databricks_mws_ncc_private_endpoint_rule.this[0].vpc_endpoint_id, null)
}

