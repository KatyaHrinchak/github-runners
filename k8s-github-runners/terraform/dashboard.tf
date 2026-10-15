locals {
  arc_dashboard_panels = [
    {
      title = "Jobs"
      metrics = [
        { name = "gha_running_jobs", label = "Running jobs" },
        { name = "gha_assigned_jobs", label = "Assigned jobs" }
      ]
    },
    {
      title = "Runner health"
      metrics = [
        {
          name  = "gha_controller_pending_ephemeral_runners"
          label = "Pending runners"
        },
        {
          name  = "gha_controller_failed_ephemeral_runners"
          label = "Failed runners"
        }
      ]
    },
    {
      title = "Runner scaling"
      metrics = [
        { name = "gha_desired_runners", label = "Desired runners" },
        { name = "gha_registered_runners", label = "Registered runners" }
      ]
    },
    {
      title = "Runner limits"
      metrics = [
        { name = "gha_min_runners", label = "Minimum runners" },
        { name = "gha_max_runners", label = "Maximum runners" }
      ]
    }
  ]
}

resource "aws_cloudwatch_dashboard" "arc" {
  dashboard_name = "arc-runners"

  dashboard_body = jsonencode({
    start = "-PT1H"

    widgets = [
      for index, panel in local.arc_dashboard_panels : {
        type   = "chart"
        x      = (index % 2) * 12
        y      = floor(index / 2) * 6
        width  = 12
        height = 6

        properties = {
          title  = panel.title
          view   = "line"
          region = "us-east-1"

          data = {
            queries = [
              for query_index, metric in panel.metrics : {
                id       = "q${query_index}"
                type     = "cloudwatch-metrics"
                language = "PromQL"
                query    = try(metric.query, "${metric.name}{name=\"arc-runner-set\",namespace=\"arc-runners\"}")
                label    = metric.label
                step     = 30
              }
            ]
          }
        }
      }
    ]
  })
}
