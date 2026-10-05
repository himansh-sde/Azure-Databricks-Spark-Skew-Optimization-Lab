# Fetch your current Databricks user identity
data "databricks_current_user" "me" {}

# Provision the cluster using the variables defined earlier
resource "databricks_cluster" "skew_lab_cluster" {
  cluster_name            = var.cluster_name
  spark_version           = var.spark_version
  node_type_id            = var.node_type
  autotermination_minutes = var.auto_termination_minutes

  # Dynamic scaling to handle the intense workload of our skew lab
  autoscale {
    min_workers = var.min_workers
    max_workers = var.max_workers
  }

  # Required for Unity Catalog integration
  data_security_mode = "SINGLE_USER"
  single_user_name   = data.databricks_current_user.me.user_name

  # Pass our environment and project tags to the compute nodes
  custom_tags = var.tags
}
