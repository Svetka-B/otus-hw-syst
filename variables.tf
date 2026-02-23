variable "cloudid" {
  description = "id облака"
  type        = string
  default     = "b1gb137o5n2ud5hbgqa3"
}

variable "folderid" {
  description = "id папки в облаке"
  type        = string
  default     = "b1gn2l66op3nv6nuhe77"
}

variable "sshkeyspath" {
  description = "путь до публичного ключа"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "zone" {
  description = "пзона провайдера"
  type        = string
  default     = "ru-central1-a"
}

variable "image_ubuntu_2404" {
  description = "id образа ВМ ubuntu"
  type        = string
  default     = "fd83ica41cade1mj35sr"
}

variable "standart" {
  description = "тип ВМ"
  type        = string
  default     = "standard-v3"
}

variable "service_account_key" {
  description = "Путь к service account key"
  type        = string
  default     = "key.json"
}