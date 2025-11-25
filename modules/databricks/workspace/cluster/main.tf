resource "databricks_cluster" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  cluster_name               = lookup(var.config, "cluster_name", "")
  spark_version              = var.config["spark_version"]
  runtime_engine             = try(var.config["runtime_engine"], null)
  kind                       = try(var.config["kind"], null)
  use_ml_runtime             = try(var.config["use_ml_runtime"], null)
  is_single_node             = try(var.config["is_single_node"], null)
  data_security_mode         = try(var.config["data_security_mode"], null)
  single_user_name           = try(var.config["single_user_name"], null)
  idempotency_token          = try(var.config["idempotency_token"], null)
  node_type_id               = try(var.config["node_type_id"], null)
  driver_node_type_id        = try(var.config["driver_node_type_id"], null)
  instance_pool_id           = try(var.config["instance_pool_id"], null)
  driver_instance_pool_id    = try(var.config["driver_instance_pool_id"], null)
  policy_id                  = try(var.config["policy_id"], null)
  apply_policy_default_values = try(var.config["apply_policy_default_values"], null)
  autotermination_minutes    = try(var.config["autotermination_minutes"], 60)
  enable_elastic_disk        = try(var.config["enable_elastic_disk"], null)
  enable_local_disk_encryption = try(var.config["enable_local_disk_encryption"], null)
  is_pinned                  = try(var.config["is_pinned"], null)
  no_wait                    = try(var.config["no_wait"], true)
  num_workers                = try(var.config["num_workers"], null)

  dynamic "autoscale" {
    for_each = lookup(var.config, "autoscale", null) != null ? [var.config["autoscale"]] : []

    content {
      min_workers = try(autoscale.value["min_workers"], null)
      max_workers = try(autoscale.value["max_workers"], null)
    }
  }

  spark_conf      = try(var.config["spark_conf"], null)
  spark_env_vars  = try(var.config["spark_env_vars"], null)
  custom_tags     = try(var.config["custom_tags"], null)
  ssh_public_keys = try(var.config["ssh_public_keys"], null)

  dynamic "azure_attributes" {
    for_each = lookup(var.config, "azure_attributes", null) != null ? [var.config["azure_attributes"]] : []

    content {
      availability       = try(azure_attributes.value["availability"], null)
      first_on_demand    = try(azure_attributes.value["first_on_demand"], null)
      spot_bid_max_price = try(azure_attributes.value["spot_bid_max_price"], null)
    }
  }

  dynamic "workload_type" {
    for_each = lookup(var.config, "workload_type", null) != null ? [var.config["workload_type"]] : []

    content {
      clients {
        jobs      = try(workload_type.value.clients["jobs"], null)
        notebooks = try(workload_type.value.clients["notebooks"], null)
      }
    }
  }

  dynamic "docker_image" {
    for_each = lookup(var.config, "docker_image", null) != null ? [var.config["docker_image"]] : []

    content {
      url = docker_image.value["url"]

      dynamic "basic_auth" {
        for_each = lookup(docker_image.value, "basic_auth", null) != null ? [docker_image.value["basic_auth"]] : []

        content {
          username = basic_auth.value["username"]
          password = basic_auth.value["password"]
        }
      }
    }
  }

  dynamic "library" {
    for_each = try(var.config["library"], [])

    content {
      jar          = try(library.value["jar"], null)
      egg          = try(library.value["egg"], null)
      whl          = try(library.value["whl"], null)
      requirements = try(library.value["requirements"], null)

      dynamic "pypi" {
        for_each = lookup(library.value, "pypi", null) != null ? [library.value["pypi"]] : []

        content {
          package = pypi.value["package"]
          repo    = try(pypi.value["repo"], null)
        }
      }

      dynamic "maven" {
        for_each = lookup(library.value, "maven", null) != null ? [library.value["maven"]] : []

        content {
          coordinates = maven.value["coordinates"]
          repo        = try(maven.value["repo"], null)
          exclusions  = try(maven.value["exclusions"], null)
        }
      }

      dynamic "cran" {
        for_each = lookup(library.value, "cran", null) != null ? [library.value["cran"]] : []

        content {
          package = cran.value["package"]
          repo    = try(cran.value["repo"], null)
        }
      }
    }
  }

  dynamic "init_scripts" {
    for_each = try(var.config["init_scripts"], [])

    content {
      dynamic "dbfs" {
        for_each = lookup(init_scripts.value, "dbfs", null) != null ? [init_scripts.value["dbfs"]] : []

        content {
          destination = dbfs.value["destination"]
        }
      }

      dynamic "workspace" {
        for_each = lookup(init_scripts.value, "workspace", null) != null ? [init_scripts.value["workspace"]] : []

        content {
          destination = workspace.value["destination"]
        }
      }

      dynamic "volumes" {
        for_each = lookup(init_scripts.value, "volumes", null) != null ? [init_scripts.value["volumes"]] : []

        content {
          destination = volumes.value["destination"]
        }
      }

      dynamic "abfss" {
        for_each = lookup(init_scripts.value, "abfss", null) != null ? [init_scripts.value["abfss"]] : []

        content {
          destination = abfss.value["destination"]
        }
      }

      dynamic "file" {
        for_each = lookup(init_scripts.value, "file", null) != null ? [init_scripts.value["file"]] : []

        content {
          destination = file.value["destination"]
        }
      }
    }
  }

  dynamic "cluster_log_conf" {
    for_each = lookup(var.config, "cluster_log_conf", null) != null ? [var.config["cluster_log_conf"]] : []

    content {
      dynamic "dbfs" {
        for_each = lookup(cluster_log_conf.value, "dbfs", null) != null ? [cluster_log_conf.value["dbfs"]] : []

        content {
          destination = dbfs.value["destination"]
        }
      }

      dynamic "volumes" {
        for_each = lookup(cluster_log_conf.value, "volumes", null) != null ? [cluster_log_conf.value["volumes"]] : []

        content {
          destination = volumes.value["destination"]
        }
      }
    }
  }

  dynamic "cluster_mount_info" {
    for_each = try(var.config["cluster_mount_info"], [])

    content {
      local_mount_dir_path  = cluster_mount_info.value["local_mount_dir_path"]
      remote_mount_dir_path = try(cluster_mount_info.value["remote_mount_dir_path"], null)

      dynamic "network_filesystem_info" {
        for_each = lookup(cluster_mount_info.value, "network_filesystem_info", null) != null ? [cluster_mount_info.value["network_filesystem_info"]] : []

        content {
          server_address = network_filesystem_info.value["server_address"]
          mount_options  = try(network_filesystem_info.value["mount_options"], null)
        }
      }
    }
  }
}

resource "databricks_permissions" "this" {
  count = try(var.config.enabled, true) && contains(keys(var.config), "permissions") ? 1 : 0

  cluster_id = databricks_cluster.this[0].id

  dynamic "access_control" {
    for_each = try(var.config["permissions"], [])

    content {
      group_name             = try(access_control.value["group_name"], null)
      user_name              = try(access_control.value["user_name"], null)
      service_principal_name = try(access_control.value["service_principal_name"], null)
      permission_level       = access_control.value["permission_level"]
    }
  }
}

