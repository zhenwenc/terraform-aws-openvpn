resource "aws_ecs_cluster" "this" {
  name = "${var.ecs_cluster_name}"
}

resource "aws_ecs_service" "this" {
  name                               = "${var.ecs_service_name}"
  cluster                            = "${aws_ecs_cluster.this.arn}"
  task_definition                    = "${aws_ecs_task_definition.this.arn}"
  scheduling_strategy                = "DAEMON"
  desired_count                      = 1
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
}

resource "aws_ecs_task_definition" "this" {
  family                = "openvpn"
  container_definitions = "${data.template_file.ecs_task_def.rendered}"

  volume {
    name      = "openvpn-data"
    host_path = "${var.ecs_volume_data}"
  }

  volume {
    name      = "openvpn-conf"
    host_path = "${var.ecs_volume_conf}"
  }
}

data "template_file" "ecs_task_def" {
  template = "${file("${path.module}/templates/task-def.json")}"

  vars {
    hash = "${md5(data.template_file.openvpn_server.rendered)}"
  }
}
