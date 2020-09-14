data "aws_eks_cluster" "cluster" {
  name = module.cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.cluster.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

module "network" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"            = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"   = "1"
  }
}

module "cluster" {
  source     = "github.com/terraform-aws-modules/terraform-aws-eks.git"

  cluster_name    = var.cluster_name
  cluster_version = "1.17"

  subnets = module.network.public_subnets
  vpc_id  = module.network.vpc_id

  worker_groups = [
    {
      name                 = "workers"
      instance_type        = var.worker_instance_type
      asg_desired_capacity = var.num_workers
      asg_min_size         = var.cluster_autoscale_min_workers
      asg_max_size         = var.cluster_autoscale_max_workers
      tags = concat([{
        key                 = "Name"
        value               = "${var.cluster_name}-workers-1"
        propagate_at_launch = true
      }
      ])
    }
  ]
}