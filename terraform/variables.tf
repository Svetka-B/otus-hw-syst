variable "cloudid" {
  description = "id облака"
  type        = string
  default     = "b1gm3c5oge1aic1tgr9s"
}

variable "token" {
  description = "OAuth-токен"
  type        = string
  default     = "y0__xCcgryLBRjB3RMggtHPtxaZJxKO0dSFYE6Ts-E9qNsJWEXV4g"
}

variable "folderid" {
  description = "id папки в облаке"
  type        = string
  default     = "b1gfpr0lssj35scju9pl"
}

variable "sshkeyspath" {
  description = "путь до публичного ключа"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "zone" {
  description = "зона провайдера"
  type        = string
  default     = "ru-central1-a"
}

variable "image_ubuntu" {
  description = "id образа ВМ ubuntu"
  type        = string
  default     = "fd845dr9j4h2aaq1m6ko"
}
// Поправить
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