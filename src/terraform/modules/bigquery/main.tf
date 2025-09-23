# BigQuery Dataset
resource "google_bigquery_dataset" "dataset" {
  dataset_id                 = var.dataset_id
  friendly_name             = var.dataset_friendly_name
  description               = var.description
  location                  = var.location
  default_table_expiration_ms = var.default_table_expiration_ms
  labels                    = var.labels
  delete_contents_on_destroy = var.delete_contents_on_destroy

  project = var.project_id

}