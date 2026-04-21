module "compute" {
  source = "../modules/compute"

  cluster_name = "my-cluster"

  ecr_image    = "458255180443.dkr.ecr.ap-south-1.amazonaws.com/my-app-repo"

  alb_sg_id    = "sg-018865ebba83b1002"
  ecs_sg_id    = "sg-0253d8abe71cb25db"

  subnet_ids   = ["subnet-0e5f0dbd261cb60de"]   # add more if you have
  vpc_id       = "vpc-078cd38c63b758304"
}