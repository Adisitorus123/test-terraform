output "frontend_ip" {
  value = google_compute_instance.frontend.network_interface[0].access_config[0].nat_ip
}

output "backend_internal_ip" {
  value = google_compute_instance.backend.network_interface[0].network_ip
}

output "db_connection_name" {
  value = google_sql_database_instance.db.connection_name
}