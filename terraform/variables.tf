# Переменные для Proxmox

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
  default     = "https://192.168.1.131:8006/"
}

variable "proxmox_api_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Разрешить insecure TLS для Proxmox API"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Имя ноды Proxmox"
  type        = string
  default     = "svtk"
}

variable "vm_bridge" {
  description = "Сетевой мост Proxmox"
  type        = string
  default     = "vmbr0"
}

variable "iscsi_bridge" {
  description = "Сетевой мост для iscsi"
  type        = string
  default     = "vmbr4"
}
variable "vm_datastore" {
  description = "Datastore для дисков виртуальных машин"
  type        = string
  default     = "local-lvm"
}

variable "cloudinit_datastore" {
  description = "Datastore для cloud-init"
  type        = string
  default     = "local-lvm"
}

variable "template_vm_id" {
  description = "VM ID cloud-init шаблона Ubuntu"
  type        = number
  default     = 110
}

variable "ssh_public_key_path" {
  description = "Путь до публичного SSH-ключа"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "vm_user" {
  description = "Пользователь, который будет создан внутри ВМ через cloud-init"
  type        = string
  default     = "svtk"
}

variable "vm_gateway" {
  description = "Шлюз по умолчанию для ВМ"
  type        = string
  default     = "192.168.1.1"
}

variable "vm_dns_servers" {
  description = "DNS серверы для ВМ"
  type        = list(string)
  default     = ["192.168.1.1", "8.8.8.8"]
}
