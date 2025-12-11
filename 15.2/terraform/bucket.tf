## bucket.tf

// Переменные
variable "bucket_name" {
  description = "Name for the storage bucket"
  type        = string
  default     = "mspitsyn-bucket-2025"
}

variable "image_path" {
  description = "Local path to the image file"
  type        = string
  default     = "~/netology/clopro-homeworks/15.2/img/test.gif"
}


// Создаем сервисный аккаунт для backet
resource "yandex_iam_service_account" "sa" {
  folder_id = local.folder_id
  name      = "bucket-sa"
}

// Назначение роли сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = local.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
  depends_on = [yandex_iam_service_account.sa]
}

// Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "static access key for object storage"
}

// Создание бакета Object Storage с использованием ключа
resource "yandex_storage_bucket" "mspitsyn" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = var.bucket_name
}

// Загрузка картинки в бакет
resource "yandex_storage_object" "test-picture" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = var.bucket_name
  key    = "test.gif"
  source = var.image_path
  acl    = "public-read"
  depends_on = [yandex_storage_bucket.mspitsyn]
}