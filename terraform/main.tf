resource "google_compute_network" "vpc" {
  name = "app-vpc"
}

resource "google_compute_subnetwork" "public" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "private" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "frontend" {
  name         = "frontend-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork   = google_compute_subnetwork.public.id
    access_config {} # public IP
  }

  metadata_startup_script = <<-EOT
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo docker run -d -p 80:80 docker.io/adiboysitorus/frontend:latest
  EOT
}

resource "google_compute_instance" "backend" {
  name         = "backend-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata_startup_script = <<-EOT
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo docker run -d -p 3000:3000 docker.io/adiboysitorus/backend:latest
    EOT
}

resource "google_compute_global_address" "private_range" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_range.name]
}

resource "google_sql_database_instance" "db" {
  name             = "app-db"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      private_network = google_compute_network.vpc.self_link
    }
  }
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_user" "users" {
  name     = "appuser"
  instance = google_sql_database_instance.db.name
  password = "securepassword"
}