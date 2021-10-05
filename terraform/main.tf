provider "aws" {
  region     = "ca-central-1"
}

terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.53.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.4.1"
    }
  }
  backend "s3" {
    bucket         = "security-app-poc-backend"
    key            = "terraform.tfstate"
    region         = "ca-central-1"
    dynamodb_table = "security-app-poc-backend"
  }
}

module "eks-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "eks-vpc"
  cidr = "172.30.0.0/16"

  azs             = ["ca-central-1a", "ca-central-1b"]
  private_subnets = ["172.30.1.0/24", "172.30.2.0/24"]
  public_subnets  = ["172.30.4.0/24", "172.30.5.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  public_subnet_tags = {
    "kubernetes.io/cluster/eks-cluster" = "owned"
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/eks-cluster" = "owned"
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    Environment = "dev"
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks-cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks-cluster.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

module "eks-cluster" {
  source                         = "terraform-aws-modules/eks/aws"
  cluster_name                   = "eks-cluster"
  cluster_version                = "1.19"
  subnets                        = module.eks-vpc.private_subnets
  vpc_id                         = module.eks-vpc.vpc_id
  cluster_endpoint_public_access = true
  cluster_create_timeout         = "45m"
  enable_irsa = true
  manage_aws_auth = true

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

  node_groups = {

    dev-ng = {
      desired_capacity = 1
      max_capacity     = 2
      min_capacity     = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      k8s_labels = {
        Environment = "dev"
      }
    }
  }
}


resource "aws_iam_policy" "ingress" {
  name_prefix = "ingress-${module.eks-cluster.cluster_id}"
  description = "ingress for cluster ${module.eks-cluster.cluster_id}"
  policy      = file("./ingress.json")
}

module "ingress" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  create_role                   = true
  role_name                     = "ingress-${module.eks-cluster.cluster_id}"
  provider_url                  = replace(module.eks-cluster.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.ingress.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
}