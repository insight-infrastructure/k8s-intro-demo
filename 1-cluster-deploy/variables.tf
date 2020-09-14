variable "cluster_name" {
  default = "my-cluster"
}
variable "worker_instance_type" {
  default = "m4.large"
}
variable "num_workers" {
  default = "1"
}
variable "cluster_autoscale_min_workers" {
  default = "1"
}
variable "cluster_autoscale_max_workers" {
  default = "1"
}