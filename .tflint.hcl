config {
  module = true
}

plugin "terraform" {
  enabled = true

  # Enable all standard Terraform linting rules (they can be disabled below):
  # https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/README.md
  preset = "all"
}
