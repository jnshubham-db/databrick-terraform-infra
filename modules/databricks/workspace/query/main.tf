resource "databricks_query" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  display_name    = var.config.name
  warehouse_id    = try(var.config.warehouse_id, var.config.data_source_id, null)
  description     = try(var.config.description, null)
  parent_path     = try(var.config.parent_path, var.config.parent, null)
  run_as_mode     = try(var.config.run_as_mode, var.config.run_as_role, null)
  catalog         = try(var.config.catalog, null)
  schema          = try(var.config.schema, null)
  tags            = try(var.config.tags, null)
  apply_auto_limit = try(var.config.apply_auto_limit, null)
  owner_user_name = try(var.config.owner_user_name, null)

  query_text = var.config.query

  dynamic "parameter" {
    for_each = try(var.config.parameters, [])

    content {
      name  = parameter.value.name
      title = try(parameter.value.title, null)

      dynamic "text_value" {
        for_each = try(parameter.value.text, parameter.value.text_value, null) != null ? [try(parameter.value.text, parameter.value.text_value)] : []

        content {
          value = text_value.value.value
        }
      }

      dynamic "numeric_value" {
        for_each = try(parameter.value.number, parameter.value.numeric_value, null) != null ? [try(parameter.value.number, parameter.value.numeric_value)] : []

        content {
          value = numeric_value.value.value
        }
      }

      dynamic "enum_value" {
        for_each = try(parameter.value.enum, parameter.value.enum_value, null) != null ? [try(parameter.value.enum, parameter.value.enum_value)] : []

        content {
          enum_options = enum_value.value.enum_options
          values       = try(enum_value.value.values, null)
          
          dynamic "multi_values_options" {
            for_each = try(enum_value.value.multiple, enum_value.value.multi_values_options, null) != null ? [try(enum_value.value.multiple, enum_value.value.multi_values_options)] : []
            
            content {
              prefix    = try(multi_values_options.value.prefix, null)
              suffix    = try(multi_values_options.value.suffix, null)
              separator = try(multi_values_options.value.separator, null)
            }
          }
        }
      }

      dynamic "query_backed_value" {
        for_each = try(parameter.value.query, parameter.value.query_backed_value, null) != null ? [try(parameter.value.query, parameter.value.query_backed_value)] : []

        content {
          query_id = query_backed_value.value.query_id
          values   = try(query_backed_value.value.values, null)
          
          dynamic "multi_values_options" {
            for_each = try(query_backed_value.value.multiple, query_backed_value.value.multi_values_options, null) != null ? [try(query_backed_value.value.multiple, query_backed_value.value.multi_values_options)] : []
            
            content {
              prefix    = try(multi_values_options.value.prefix, null)
              suffix    = try(multi_values_options.value.suffix, null)
              separator = try(multi_values_options.value.separator, null)
            }
          }
        }
      }

      dynamic "date_value" {
        for_each = try(parameter.value.date, parameter.value.date_value, null) != null ? [try(parameter.value.date, parameter.value.date_value)] : []

        content {
          date_value          = try(date_value.value.date_value, date_value.value.value, null)
          dynamic_date_value  = try(date_value.value.dynamic_date_value, null)
          precision           = try(date_value.value.precision, null)
        }
      }

      dynamic "date_range_value" {
        for_each = try(parameter.value.date_range, parameter.value.date_range_value, null) != null ? [try(parameter.value.date_range, parameter.value.date_range_value)] : []

        content {
          dynamic "date_range_value" {
            for_each = try(date_range_value.value.date_range_value, date_range_value.value.start, null) != null ? [1] : []
            content {
              start = try(date_range_value.value.date_range_value.start, date_range_value.value.start, null)
              end   = try(date_range_value.value.date_range_value.end, date_range_value.value.end, null)
            }
          }
          dynamic_date_range_value = try(date_range_value.value.dynamic_date_range_value, null)
          start_day_of_week        = try(date_range_value.value.start_day_of_week, null)
          precision                = try(date_range_value.value.precision, null)
        }
      }
    }
  }
}
