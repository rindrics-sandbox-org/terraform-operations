generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      backend "local" {
        path = "./terraform.tfstate"
      }
    }
  EOF
}

generate "terraform" {
  path      = "terraform.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = "~> 1.9.5" # be consistent with `.terraform-version`

      required_providers {
        github = {
          source  = "integrations/github"
          version = "~> 6.3"
        }
      }
    }

    provider "github" {
      owner = "rindrics-sandbox-org"
      app_auth {
        pem_file = var.pem_content
      }
    }
  EOF
}

locals {
  teams_removed = [
    "team-1",
  ]
  teams_removed_sanitized = {
    for name in local.teams_removed : name => replace(name, "-", "_")
  }
}

generate "removed" {
  path      = "removed.tf"
  if_exists = "overwrite"
  contents = templatefile("templates/removed.tmpl", {
    team_names_map  = local.teams_removed_sanitized
  })
}

terraform {
  extra_arguments "common_variables" {
    commands = get_terraform_commands_that_need_vars()
    required_var_files = [
      "${path_relative_from_include()}/pem.tfvars",
      "${path_relative_from_include()}/users.tfvars",
    ]
  }
}
