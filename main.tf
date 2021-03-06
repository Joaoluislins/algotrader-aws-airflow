provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "airflow-test-vpc"
  cidr = "10.10.0.0/16"

  azs             = ["us-east-1a",     "us-east-1b",     "us-east-1c"    ]
  private_subnets = ["10.10.1.0/24",   "10.10.2.0/24",   "10.10.3.0/24"  ]
  public_subnets  = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]

  enable_dns_hostnames = true
}

resource "aws_db_instance" "airflow-database" {
  identifier                = "airflow-database"
  allocated_storage         = 20
  engine                    = "postgres"
  #engine_version            = "9.6.6"
  instance_class            = "db.t3.micro"
  db_name                   = "airflow"
  username                  = "airflow"
  password                  = "${var.db_password}"
  storage_type              = "gp2"
  backup_retention_period   = 14
  multi_az                  = false
  publicly_accessible       = false
  apply_immediately         = true
  db_subnet_group_name      = "${aws_db_subnet_group.airflow_subnetgroup.name}"
  final_snapshot_identifier = "airflow-database-final-snapshot-1"
  skip_final_snapshot       = true
  vpc_security_group_ids    = [ "${aws_security_group.allow_airflow_database.id}"]
  port                      = "5432"
}

resource "aws_db_subnet_group" "airflow_subnetgroup" {
  name        = "airflow-database-subnetgroup"
  description = "airflow database subnet group"
  subnet_ids  = [ "${module.vpc.public_subnets[0]}", "${module.vpc.public_subnets[1]}" ] ## colocar brackets e listar uma a um
}

resource "aws_security_group" "allow_airflow_database" {
  name        = "allow_airflow_database"
  description = "Controlling traffic to and from airflows rds instance."
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_airflow_database" {
  security_group_id = "${aws_security_group.allow_airflow_database.id}"
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"

  cidr_blocks = [
    "${aws_instance.airflow_instance.private_ip}/32"
  ]
}

resource "aws_instance" "airflow_instance" {
  key_name                    = "${var.key}"
  associate_public_ip_address = true
  ami                         = "ami-0c02fb55956c7d316" #"${var.ami}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${module.vpc.public_subnets[0]}"
  vpc_security_group_ids      = [ "${aws_security_group.airflow-security-group.id}", ]

  root_block_device {
    volume_size = 32
  }

  tags = {
    Name = "airflow"
  }

  user_data  = "${data.template_file.airflow_user_data.rendered}"
  depends_on = [
    aws_instance.airflow_instance,
    aws_db_instance.airflow-database,
  ]
}

data "template_file" "airflow_user_data" {
  template = "${file("${path.module}/userdata/userdata.sh")}"
  vars = {
    DB_ENDPOINT = aws_db_instance.airflow-database.endpoint
    AWS_ID = "${var.AWS_ID}"
    AWS_KEY = "${var.AWS_KEY}"
    db_password = "${var.db_password}"
    BEARER_TOKEN = "${var.bearer_token}"
  }
}

resource "aws_security_group" "airflow-security-group" {
  name        = "security_group_airflow"
  description = "Traffic to Airflow instance"
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ssh" {
  security_group_id = "${aws_security_group.airflow-security-group.id}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web" {
  security_group_id = "${aws_security_group.airflow-security-group.id}"
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

output "airflow_public_dns" {
  value = "${aws_instance.airflow_instance.public_dns}"
}

output "airflow_instance_private_ip" {
  value       = "${aws_instance.airflow_instance.private_ip}"
  description = "Private IP for the Airflow instance"
}

output "airflow_db_public_ip" {
  value       = "${aws_db_instance.airflow-database.endpoint}"
  description = "Endpoint address for the Airflow instance"
}

output "airflow_instance_public_ip" {
  value       = "${aws_instance.airflow_instance.public_ip}"
  description = "Public IP address for the Airflow instance"
}