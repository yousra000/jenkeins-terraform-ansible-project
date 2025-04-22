terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }


  backend "s3" {
    bucket       = "terraform-state.tf1"
    region       = "us-east-1"
    key          = "jenkins_porject_terraform.tfstate"
    use_lockfile = true
  }
  
}
