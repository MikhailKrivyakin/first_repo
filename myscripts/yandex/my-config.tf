terraform {
    required_providers {
        yandex = {
            source = "yandex-cloud/yandex"
        }

    }
}

provider "yandex" {
    token = "AQAAAAAIWfLBAATuwe-47KeRE0vCoYY5WLjg2Yg"
    cloud_id = "b1ggnchp3ivg1j2737iu"
    folder_id = "b1gf5igfo997i6vuc6ie"
    zone = "ru-central1-a"

}


resource "yandex_compute_instance" "VMtf" {
  name        = "vmtf1"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8sb6n3obd9rqfkt6nv"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.testsubnet.id}"
    nat = true
  }

  metadata = {
    foo      = "bar"
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_vpc_network" "testnetwork" {
    name = "network-from-tf"
}

resource "yandex_vpc_subnet" "testsubnet" {
  name = "from-tf-subnet"
  zone       = "ru-central1-a"
  network_id = "${yandex_vpc_network.testnetwork.id}"
  v4_cidr_blocks = ["10.2.0.0/16"]
  metadata = {
    ssh-keys = "ubuntu:${file("private1.pub")}"
  }
}
