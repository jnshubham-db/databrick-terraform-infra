resource "databricks_alert" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  display_name          = var.config.name
  query_id              = var.config.query_id
  parent_path           = try(var.config.parent_path, null)
  seconds_to_retrigger  = try(var.config.seconds_to_retrigger, null)
  custom_subject        = try(var.config.custom_subject, null)
  custom_body           = try(var.config.custom_body, null)
  notify_on_ok          = try(var.config.notify_on_ok, false)
  owner_user_name       = try(var.config.owner_user_name, null)

  dynamic "condition" {
    for_each = try(var.config.condition, null) != null ? [var.config.condition] : []

    content {
      op                  = condition.value.op
      empty_result_state  = try(condition.value.empty_result_state, "UNKNOWN")

      operand {
        column {
          name = condition.value.operand.column.name
        }
      }

      dynamic "threshold" {
        for_each = try(condition.value.threshold, null) != null ? [condition.value.threshold] : []

        content {
          value {
            string_value = try(threshold.value.value.string_value, null)
            double_value = try(threshold.value.value.double_value, null)
            bool_value   = try(threshold.value.value.bool_value, null)
          }
        }
      }
    }
  }
}

